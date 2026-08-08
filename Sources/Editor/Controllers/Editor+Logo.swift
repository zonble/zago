import Diagram
import Foundation
import LogoEngine

extension Editor: LogoEngineDelegate {
    public func logoEngine(_ engine: LogoEngine, performAction action: LogoEditorAction) {
        switch action {
        case .saveUndoSnapshot:
            saveUndoSnapshot()
        case .clampCursor:
            buffer.clampCursor()
        case .insertText(let text):
            if isTableModeActive, currentTableCell != nil {
                tableModeController.insertTextInCurrentTableCell(text)
            } else if isCanvasModeActive {
                insertCanvasString(text)
            } else {
                buffer.insertString(text)
            }
            appendLogoOutput(text)
        case .insertNewline:
            insertNewlineForLogo()
        case .setStatusMessage(let msg):
            setStatusMessage(msg)
            appendLogoOutput(msg)
        case .deleteChar:
            buffer.delete()
        case .backspaceChar:
            buffer.backspace()
        case .deleteLine:
            deleteCurrentLine()
        case .joinLine(let separator):
            joinCurrentLine(separator: separator)
        case .replaceText(let old, let new):
            replaceText(old: old, new: new)
        case .indentLines(let levels):
            indentSelectedOrCurrentLines(levels: levels)
        case .outdentLines(let levels):
            outdentSelectedOrCurrentLines(levels: levels)
        case .createTable(let rows, let cols, let cellWidth):
            tableModeController.createTable(
                rows: rows, cols: cols, cellWidth: cellWidth, enterMode: false, saveSnapshot: false)
        case .insertDiagramSnippet(let arg):
            if let typeStr = arg, let snippet = DiagramSnippets.findDiagramSnippet(by: typeStr) {
                DiagramSnippets.insertSnippet(snippet, into: self)
            } else {
                _ = commandRegistry.dispatch(id: .diagramMenu, editor: self)
            }
        case .setBorderStyle(let style):
            setBorderStyle(style)
        case .setArrowStyle(let style):
            setArrowStyle(style)
        case .nextBorderStyle:
            _ = commandRegistry.dispatch(id: .borderStyle, editor: self)
        case .moveCursorVirtual(let delta):
            moveCursorVirtual(deltaRow: delta)
        case .moveLeft: _ = commandRegistry.dispatch(id: .moveLeft, editor: self)
        case .moveRight: _ = commandRegistry.dispatch(id: .moveRight, editor: self)
        case .moveHome: _ = commandRegistry.dispatch(id: .moveHome, editor: self)
        case .moveEnd: _ = commandRegistry.dispatch(id: .moveEnd, editor: self)
        case .editMark: _ = commandRegistry.dispatch(id: .editMark, editor: self)
        case .editCut: _ = commandRegistry.dispatch(id: .editCut, editor: self)
        case .editUncut: _ = commandRegistry.dispatch(id: .editUncut, editor: self)
        case .editJustify: _ = commandRegistry.dispatch(id: .editJustify, editor: self)
        case .search(let query):
            searchController.performSearch(query: query)
        case .markModified:
            buffer.isModified = true
        case .updateLineIndex(let lineIndex):
            if isCanvasModeActive {
                guard isCanvasLineAllowed(lineIndex), ensureCanvasLineExists(lineIndex) else { return }
                buffer.lineIndex = max(0, lineIndex)
                syncCanvasCursorToBuffer()
                return
            }
            while buffer.lines.count <= lineIndex {
                buffer.lines.append("")
            }
            buffer.lineIndex = max(0, lineIndex)
        case .updateColumnIndex(let columnIndex):
            if isCanvasModeActive {
                guard isCanvasColumnAllowed(columnIndex) else {
                    setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
                    return
                }
                canvasVisualColumn = max(0, columnIndex)
                syncCanvasCursorToBuffer()
            } else {
                let lineStr =
                    (buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count)
                    ? buffer.lines[buffer.lineIndex] : ""
                let maxDisplayWidth = lineStr.displayWidth
                if columnIndex <= maxDisplayWidth {
                    buffer.columnIndex = tableModeController.getCharIndexForVisualColumn(
                        in: lineStr, targetVisualCol: max(0, columnIndex))
                } else {
                    buffer.columnIndex = lineStr.count + (columnIndex - maxDisplayWidth)
                }
            }
        case .setLine(let index, let text):
            if index >= 0 && index < buffer.lines.count {
                buffer.lines[index] = text
            }
        case .ensureLineExists(let index):
            if isCanvasModeActive {
                _ = ensureCanvasLineExists(index)
                return
            }
            while buffer.lines.count <= index {
                buffer.lines.append("")
            }
        case .refreshScreen:
            refreshScreen()
        case .fillCanvasBlock(let text):
            _ = fillCanvasBlock(with: text)
        case .fillTableCell(let text):
            _ = tableModeController.fillCurrentTableCell(with: text)
        case .gotoLine(let row):
            goToLocation(line: row + 1, column: nil)
        case .gotoCol(let col):
            goToLocation(line: buffer.lineIndex + 1, column: col + 1)
        case .clearBuffer:
            buffer.lines = [""]
            buffer.lineIndex = 0
            buffer.columnIndex = 0
            buffer.isModified = true
        }
    }

    public func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> Any? {
        switch query {
        case .currentLineIndex:
            return buffer.lineIndex
        case .currentColumnIndex:
            if isCanvasModeActive {
                return canvasVisualColumn
            } else {
                let lineStr =
                    (buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count)
                    ? buffer.lines[buffer.lineIndex] : ""
                let charCount = lineStr.count
                if buffer.columnIndex <= charCount {
                    return tableModeController.getVisualColumn(in: lineStr, col: buffer.columnIndex)
                } else {
                    return lineStr.displayWidth + (buffer.columnIndex - charCount)
                }
            }
        case .lineCount:
            return buffer.lines.count
        case .lineAt(let index):
            guard index >= 0 && index < buffer.lines.count else { return "" }
            return buffer.lines[index]
        case .defaultBorderStyle:
            return defaultBorderStyle
        case .defaultArrowStyle:
            return defaultArrowStyle
        case .hasCanvasBlockMark:
            return isCanvasModeActive && !isTableModeActive && buffer.canvasBlockMark != nil
        case .canvasBlockFrame:
            guard isCanvasModeActive, !isTableModeActive, let rect = currentCanvasBlockRectangle(), rect.width > 0
            else {
                return nil
            }
            return LogoCanvasBlockFrame(
                lineIndex: rect.topLine,
                visualColumn: rect.leftColumn,
                width: rect.width,
                height: rect.bottomLine - rect.topLine + 1
            )
        case .hasTableCell:
            return isTableModeActive && currentTableCell != nil
        case .bufferList:
            return buffers.map { $0.filePath ?? "Untitled" }
        case .currentBufferIndex:
            return currentBufferIndex
        case .bufferText:
            return buffer.lines.joined(separator: "\n")
        case .selectionText:
            if let mark = buffer.selectionMark {
                let (start, end) = TextBuffer.getOrderedRange(
                    mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
                let lines = buffer.lines
                if start.line == end.line && start.line < lines.count {
                    let line = lines[start.line]
                    let sCol = max(0, min(start.column, line.count))
                    let eCol = max(0, min(end.column, line.count))
                    return String(
                        line[line.index(line.startIndex, offsetBy: sCol)..<line.index(line.startIndex, offsetBy: eCol)])
                } else if start.line < lines.count && end.line < lines.count {
                    return lines[start.line...end.line].joined(separator: "\n")
                }
            }
            return ""
        case .isModified:
            return buffer.isModified
        case .fileName:
            return buffer.filePath ?? "Untitled"
        }
    }

    public func logoEngine(_ engine: LogoEngine, readWordWithPrompt prompt: String) -> String {
        guard isInteractiveMode else {
            return terminal.readNonInteractiveLine(prompt: prompt) ?? ""
        }

        promptInputText = ""
        promptCursorIndex = 0
        currentPromptMode = .logoReadWord(prompt: prompt)
        refreshScreen()

        defer {
            currentPromptMode = .none
            promptInputText = ""
            promptCursorIndex = 0
            refreshScreen()
        }

        while true {
            let key = terminal.readKey()
            switch key {
            case .enter:
                return promptInputText
            case .esc, .ctrl("c"):
                return ""
            case .backspace:
                if promptCursorIndex > 0 {
                    let idx = promptInputText.index(promptInputText.startIndex, offsetBy: promptCursorIndex - 1)
                    promptInputText.remove(at: idx)
                    promptCursorIndex -= 1
                    refreshScreen()
                }
            case .delete:
                if promptCursorIndex < promptInputText.count {
                    let idx = promptInputText.index(promptInputText.startIndex, offsetBy: promptCursorIndex)
                    promptInputText.remove(at: idx)
                    refreshScreen()
                }
            case .arrowLeft:
                if promptCursorIndex > 0 {
                    promptCursorIndex -= 1
                    refreshScreen()
                }
            case .arrowRight:
                if promptCursorIndex < promptInputText.count {
                    promptCursorIndex += 1
                    refreshScreen()
                }
            case .home, .ctrl("a"):
                promptCursorIndex = 0
                refreshScreen()
            case .end, .ctrl("e"):
                promptCursorIndex = promptInputText.count
                refreshScreen()
            case .ctrl("u"):
                promptInputText = ""
                promptCursorIndex = 0
                refreshScreen()
            case .char(let ch):
                let idx = promptInputText.index(promptInputText.startIndex, offsetBy: promptCursorIndex)
                promptInputText.insert(ch, at: idx)
                promptCursorIndex += 1
                refreshScreen()
            default:
                break
            }
        }
    }

    public func logoEngine(_ engine: LogoEngine, readCharWithPrompt prompt: String) -> String {
        guard isInteractiveMode else {
            return terminal.readNonInteractiveChar(prompt: prompt) ?? ""
        }

        promptInputText = ""
        promptCursorIndex = 0
        currentPromptMode = .logoReadChar(prompt: prompt)
        refreshScreen()

        defer {
            currentPromptMode = .none
            promptInputText = ""
            promptCursorIndex = 0
            refreshScreen()
        }

        while true {
            let key = terminal.readKey()
            switch key {
            case .char(let ch):
                return String(ch)
            case .enter:
                return "\n"
            case .esc, .ctrl("c"):
                return ""
            case .resize, .unknown:
                continue
            default:
                continue
            }
        }
    }

    private func selectedOrCurrentLineRange() -> ClosedRange<Int> {
        if let mark = buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
            let startLine = max(0, min(start.line, buffer.lines.count - 1))
            let endLine = max(0, min(end.line, buffer.lines.count - 1))
            return startLine...endLine
        }
        let line = max(0, min(buffer.lineIndex, buffer.lines.count - 1))
        return line...line
    }

    private func insertNewlineForLogo() {
        if isTableModeActive, currentTableCell != nil {
            tableModeController.moveToNextTableCellLineOrCell()
        } else if isCanvasModeActive {
            insertCanvasNewline()
        } else {
            buffer.insertNewline()
        }
    }

    private func joinCurrentLine(separator: String) {
        if isTableModeActive, currentTableCell != nil {
            tableModeController.joinCurrentTableCellLine(separator: separator)
            return
        }
        guard buffer.lineIndex + 1 < buffer.lines.count else { return }
        let currentLine = buffer.lines[buffer.lineIndex]
        let nextLine = buffer.lines.remove(at: buffer.lineIndex + 1)
        buffer.lines[buffer.lineIndex] = currentLine + separator + nextLine
        buffer.columnIndex = currentLine.count + separator.count
        buffer.isModified = true
    }

    private func replaceText(old: String, new: String) {
        guard !old.isEmpty else { return }
        var didReplace = false
        let range = selectedOrCurrentLineRange()
        for lineIndex in range {
            let replaced = buffer.lines[lineIndex].replacingOccurrences(of: old, with: new)
            if replaced != buffer.lines[lineIndex] {
                buffer.lines[lineIndex] = replaced
                didReplace = true
            }
        }
        if didReplace {
            buffer.isModified = true
            buffer.selectionMark = nil
        }
    }

    private func indentSelectedOrCurrentLines(levels: Int) {
        let count = max(1, levels)
        let prefix = String(repeating: " ", count: max(1, displayConfig.tabSize) * count)
        for lineIndex in selectedOrCurrentLineRange() {
            buffer.lines[lineIndex] = prefix + buffer.lines[lineIndex]
        }
        buffer.columnIndex += prefix.count
        buffer.isModified = true
    }

    private func outdentSelectedOrCurrentLines(levels: Int) {
        let targetCount = max(1, displayConfig.tabSize) * max(1, levels)
        for lineIndex in selectedOrCurrentLineRange() {
            var line = buffer.lines[lineIndex]
            var removed = 0
            while removed < targetCount, line.first == " " {
                line.removeFirst()
                removed += 1
            }
            buffer.lines[lineIndex] = line
            if lineIndex == buffer.lineIndex {
                buffer.columnIndex = max(0, buffer.columnIndex - removed)
            }
        }
        buffer.isModified = true
    }

    private func setBorderStyle(_ style: String) {
        guard let borderStyle = BorderStyle(style) else {
            setStatusMessage(l10n.unknownTableBorder(style))
            return
        }

        defaultBorderStyle = borderStyle
        setStatusMessage(l10n.defaultBorder(borderStyle.rawValue))
    }

    private func setArrowStyle(_ style: String) {
        guard let arrowStyle = ArrowStyle(style) else {
            return
        }
        defaultArrowStyle = arrowStyle
    }

}

extension Editor {
    private static let tableModeBlockedLogoPrimitives: Set<LogoPrimitive> = [
        .box, .drawBox, .line, .hr, .vline, .vhr, .table,
        .penDown, .penUp, .forward, .back, .turnRight, .turnLeft,
        .goto, .gotoline, .gotocol,
    ]

    @discardableResult
    public func runLogoScript(_ script: String, resultPrefix: String? = nil, successStatus: String? = nil) -> Bool {
        if isTableModeActive, let blockedToken = firstTableModeBlockedLogoToken(in: script) {
            setStatusMessage(l10n.disabledInTableMode(blockedToken))
            return false
        }

        let isLogoFile = buffer.filePath?.lowercased().hasSuffix(".logo") == true

        if isLogoFile {
            let canvasBuf = ensureLogoCanvasBuffer()
            if let idx = findLogoCanvasBufferIndex() {
                switchToBuffer(index: idx)
                canvasBuf.lines = Array(repeating: String(repeating: " ", count: 80), count: 24)
                canvasBuf.lineIndex = 0
                canvasBuf.columnIndex = 0
                canvasVisualColumn = 0
            }
        }

        let scriptName = buffer.filePath.map { ($0 as NSString).lastPathComponent } ?? "Untitled"
        appendLogoOutputHeader(scriptName)

        logoEngine.execute(script)

        if logoEngine.hasUncaughtError, let err = logoEngine.lastError {
            let errText =
                "[ERROR \(err.code)]: \(err.message)" + (err.procedureName.map { " in procedure '\($0)'" } ?? "")
            appendLogoOutput(errText)
            setStatusMessage("Error in LOGO execution. Press Alt+L or type :output to view.")
        } else if logoEngine.hasSetStatusMessage {
            // Status message set by engine
        } else if let resultPrefix, let result = logoEngine.lastResult, !result.isEmpty {
            appendLogoOutput(result)
            setStatusMessage("\(resultPrefix)\(result)")
        } else if let successStatus {
            setStatusMessage(successStatus)
        } else if let result = logoEngine.lastResult, !result.isEmpty {
            appendLogoOutput(result)
            setStatusMessage(result)
        }

        return true
    }

    private func firstTableModeBlockedLogoToken(in script: String) -> String? {
        firstTableModeBlockedLogoToken(in: logoEngine.tokenize(script), visitedProcedures: [])
    }

    private func firstTableModeBlockedLogoToken(
        in tokens: [String], visitedProcedures: Set<String>
    ) -> String? {
        for token in tokens {
            if let primitive = LogoPrimitive.from(token),
                Self.tableModeBlockedLogoPrimitives.contains(primitive)
            {
                return token.uppercased()
            }

            let procedureName = token.uppercased()
            guard !visitedProcedures.contains(procedureName),
                let procedure = logoEngine.customProcedures[procedureName]
            else {
                continue
            }

            var nextVisited = visitedProcedures
            nextVisited.insert(procedureName)
            if let blockedToken = firstTableModeBlockedLogoToken(
                in: procedure.bodyTokens, visitedProcedures: nextVisited)
            {
                return blockedToken
            }
        }

        return nil
    }

    /// Evaluates LOGO code from linear selection, Markdown ```logo code fence, or current line/block.
    public func evalLogoCode() {
        let script: String

        // Priority 1: Selection Range
        if let mark = buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
            script = buffer.cutRange(
                start: (line: start.line, col: start.column), end: (line: end.line, col: end.column))
            // Restore selection text back into buffer
            buffer.insertString(script)
            buffer.selectionMark = mark
        }
        // Priority 2: Markdown ```logo ... ``` code fence
        else if let fenceScript = extractMarkdownLogoFence() {
            script = fenceScript
        }
        // Priority 3: Current line or multi-line block (balanced [ ... ] or TO ... END)
        else {
            script = extractCurrentLineOrBlock()
        }

        guard buffer.allowsLogoExecution else {
            setStatusMessage(l10n["status.directory_buffer_readonly"])
            return
        }

        let cleanScript = script.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanScript.isEmpty else { return }

        runLogoScript(cleanScript, resultPrefix: "[Eval] ", successStatus: l10n["status.logo_evaluated"])
    }

    private func extractMarkdownLogoFence() -> String? {
        let currentLine = buffer.lineIndex
        var fenceStart: Int? = nil

        // Scan upwards to find ```logo
        for r in (0...currentLine).reversed() {
            let line = buffer.lines[r].trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("```logo") {
                fenceStart = r
                break
            }
            if line.hasPrefix("```") && r < currentLine {
                break
            }
        }

        guard let start = fenceStart else { return nil }

        // Scan downwards to find closing ```
        var fenceEnd: Int? = nil
        for r in (start + 1)..<buffer.lines.count {
            let line = buffer.lines[r].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("```") {
                fenceEnd = r
                break
            }
        }

        guard let end = fenceEnd, currentLine >= start && currentLine <= end else { return nil }
        guard start + 1 < end else { return "" }

        return buffer.lines[(start + 1)..<end].joined(separator: "\n")
    }

    private func extractCurrentLineOrBlock() -> String {
        let currentLine = buffer.lineIndex
        guard currentLine < buffer.lines.count else { return "" }

        // Check if inside TO ... END procedure definition
        var toStart: Int? = nil
        for r in (0...currentLine).reversed() {
            let line = buffer.lines[r].trimmingCharacters(in: .whitespaces)
            let upper = line.uppercased()
            if upper.hasPrefix("TO ") || upper == "TO" {
                toStart = r
                break
            }
            if upper == "END" && r < currentLine {
                break
            }
        }

        if let start = toStart {
            var end = currentLine
            for r in start..<buffer.lines.count {
                let line = buffer.lines[r].trimmingCharacters(in: .whitespaces)
                if line.uppercased() == "END" {
                    end = r
                    break
                }
            }
            return buffer.lines[start...end].joined(separator: "\n")
        }

        // Multi-line balanced bracket check: if current line opens '[' without closing, scan down
        let lineText = buffer.lines[currentLine]
        var openCount = lineText.filter { $0 == "[" }.count
        var closeCount = lineText.filter { $0 == "]" }.count
        var endLine = currentLine

        while openCount > closeCount && endLine + 1 < buffer.lines.count {
            endLine += 1
            let nextLine = buffer.lines[endLine]
            openCount += nextLine.filter { $0 == "[" }.count
            closeCount += nextLine.filter { $0 == "]" }.count
        }

        if endLine > currentLine {
            return buffer.lines[currentLine...endLine].joined(separator: "\n")
        }

        return lineText
    }
}
