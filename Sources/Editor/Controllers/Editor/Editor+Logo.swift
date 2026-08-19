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
            reportOperationResult(.succeeded(message: msg))
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
        case .createTable(let rows, let cols, let cellWidth, let borderStyle, let rounded):
            tableModeController.createTable(
                rows: rows, cols: cols, cellWidth: cellWidth, borderStyle: borderStyle, rounded: rounded, enterMode: false, saveSnapshot: false)
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
                    reportOperationResult(.noOp(message: l10n["status.canvas_column_limit_exceeded"]))
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

    public func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> LogoEditorQueryResult? {
        switch query {
        case .currentLineIndex:
            return .integer(buffer.lineIndex)
        case .currentColumnIndex:
            if isCanvasModeActive {
                return .integer(canvasVisualColumn)
            } else {
                let lineStr =
                    (buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count)
                    ? buffer.lines[buffer.lineIndex] : ""
                let charCount = lineStr.count
                if buffer.columnIndex <= charCount {
                    return .integer(tableModeController.getVisualColumn(in: lineStr, col: buffer.columnIndex))
                } else {
                    return .integer(lineStr.displayWidth + (buffer.columnIndex - charCount))
                }
            }
        case .lineCount:
            return .integer(buffer.lines.count)
        case .lineAt(let index):
            guard index >= 0 && index < buffer.lines.count else { return .string("") }
            return .string(buffer.lines[index])
        case .defaultBorderStyle:
            return .borderStyle(defaultBorderStyle)
        case .defaultArrowStyle:
            return .arrowStyle(defaultArrowStyle)
        case .defaultBorderRounded:
            return .bool(isBorderRounded)
        case .hasCanvasBlockMark:
            return .bool(isCanvasModeActive && !isTableModeActive && buffer.canvasBlockMark != nil)
        case .canvasBlockFrame:
            guard isCanvasModeActive, !isTableModeActive, let rect = currentCanvasBlockRectangle(), rect.width > 0
            else {
                return nil
            }
            return .canvasBlockFrame(
                LogoCanvasBlockFrame(
                    lineIndex: rect.topLine,
                    visualColumn: rect.leftColumn,
                    width: rect.width,
                    height: rect.bottomLine - rect.topLine + 1
                ))
        case .hasTableCell:
            return .bool(isTableModeActive && currentTableCell != nil)
        case .bufferList:
            return .strings(buffers.map { $0.filePath ?? l10n["buffer.untitled"] })
        case .currentBufferIndex:
            return .integer(currentBufferIndex)
        case .bufferText:
            return .string(buffer.lines.joined(separator: "\n"))
        case .selectionText:
            if let mark = buffer.selectionMark {
                let (start, end) = TextBuffer.getOrderedRange(
                    mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
                let lines = buffer.lines
                if start.line == end.line && start.line < lines.count {
                    let line = lines[start.line]
                    let sCol = max(0, min(start.column, line.count))
                    let eCol = max(sCol, min(end.column, line.count))
                    return .string(
                        String(
                            line[
                                line.index(
                                    line.startIndex, offsetBy: sCol)..<line.index(line.startIndex, offsetBy: eCol)]
                        ))
                } else if start.line < lines.count && end.line < lines.count {
                    return .string(lines[start.line...end.line].joined(separator: "\n"))
                }
            }
            return .string("")
        case .isModified:
            return .bool(buffer.isModified)
        case .fileName:
            return .string(buffer.filePath ?? l10n["buffer.untitled"])
        }
    }

    public func logoEngine(_ engine: LogoEngine, readWordWithPrompt prompt: String) -> String? {
        guard isInteractiveMode else {
            flushPendingHeadlessLogoOutputBeforeRead()
            return terminal.readNonInteractiveLine(prompt: prompt)
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
                return nil
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

    public func logoEngine(_ engine: LogoEngine, readCharWithPrompt prompt: String) -> String? {
        guard isInteractiveMode else {
            flushPendingHeadlessLogoOutputBeforeRead()
            return terminal.readNonInteractiveChar(prompt: prompt)
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
            case .arrowUp:
                return "w"
            case .arrowDown:
                return "s"
            case .arrowLeft:
                return "a"
            case .arrowRight:
                return "d"
            case .esc, .ctrl("c"):
                return nil
            case .resize, .unknown:
                continue
            default:
                continue
            }
        }
    }

    private func flushPendingHeadlessLogoOutputBeforeRead() {
        let pendingLogoOutput = logoOutputHistory.filter { line in
            !(line.hasPrefix("--- [") && line.contains("] Run: "))
        }
        if !pendingLogoOutput.isEmpty {
            terminal.write(pendingLogoOutput.joined(separator: "\n") + "\n")
            logoOutputHistory.removeAll()
        } else if !buffer.lines.isEmpty {
            terminal.write(buffer.lines.joined(separator: "\n") + "\n")
        }

        buffer.lines = [""]
        buffer.lineIndex = 0
        buffer.columnIndex = 0
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
            reportOperationResult(.noOp(message: l10n.unknownTableBorder(style)))
            return
        }

        defaultBorderStyle = borderStyle
        reportOperationResult(.succeeded(message: l10n.defaultBorder(borderStyle.rawValue)))
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
        .box, .drawBox, .line, .vline, .table,
        .penDown, .penUp, .forward, .back, .turnRight, .turnLeft,
        .goto, .gotoline, .gotocol,
    ]

    /// Runs a LOGO script in full interactive TTY mode.
    func runInteractiveLogoScript(_ script: String) {
        isInteractiveMode = true
        defer {
            isInteractiveMode = false
            terminal.clearScreen()
            terminal.showCursor()
            terminal.disableRawMode()
        }

        do {
            try terminal.enableRawMode()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            if let data = (message + "\n").data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
            return
        }
        terminal.hideCursor()

        _ = runLogoScript(script)
    }

    @discardableResult
    public func runLogoScript(
        _ script: String,
        resultPrefix: String? = nil,
        successStatus: String? = nil
    ) -> Bool {
        runLogoScript(
            script,
            resultPrefix: resultPrefix,
            successStatus: successStatus,
            debugSourceBuffer: nil,
            debugStartLine: 0
        )
    }

    @discardableResult
    func runLogoScript(
        _ script: String,
        resultPrefix: String? = nil,
        successStatus: String? = nil,
        debugSourceBuffer: TextBuffer? = nil,
        debugStartLine: Int = 0
    ) -> Bool {
        let sourceBuffer = debugSourceBuffer ?? buffer
        guard buffer.allowsLogoExecution else {
            reportOperationResult(.noOp(message: l10n["status.directory_buffer_readonly"]))
            return false
        }

        if isTableModeActive, let blockedToken = firstTableModeBlockedLogoToken(in: script) {
            reportOperationResult(.noOp(message: l10n.disabledInTableMode(blockedToken)))
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

        let scriptName = buffer.filePath.map { ($0 as NSString).lastPathComponent } ?? l10n["buffer.untitled"]
        appendLogoOutputHeader(scriptName)

        let breakpointLines = Set(debuggerController.breakpoints(in: sourceBuffer))
        debuggerController.beginExecution(
            in: sourceBuffer, targetBuffer: buffer, startLine: debugStartLine, script: script)
        logoEngine.shouldPauseBeforeToken = { [script] token in
            let line =
                debugStartLine + script.prefix(token.sourceRange.lowerBound).reduce(0) { $1 == "\n" ? $0 + 1 : $0 }
            return breakpointLines.contains(line)
        }

        logoEngine.execute(script)

        if case .paused = logoEngine.executionState {
            showLogoDebuggerBuffer()
            reportOperationResult(.prompting(message: l10n["status.logo_debug_paused"]))
            return true
        }

        if logoEngine.hasUncaughtError, let err = logoEngine.lastError {
            let errText =
                "[ERROR \(err.code)]: \(err.message)" + (err.procedureName.map { " in procedure '\($0)'" } ?? "")
            appendLogoOutput(errText)
            reportOperationResult(.failed(err.message, message: l10n["status.logo_execution_error"]))
        } else if logoEngine.hasSetStatusMessage {
            // Status message set by engine
        } else if let resultPrefix, let result = logoEngine.lastResult, !result.isEmpty {
            appendLogoOutput(result)
            reportOperationResult(.succeeded(message: "\(resultPrefix)\(result)"))
        } else if let successStatus {
            reportOperationResult(.succeeded(message: successStatus))
        } else if let result = logoEngine.lastResult, !result.isEmpty {
            appendLogoOutput(result)
            reportOperationResult(.succeeded(message: result))
        }

        return true
    }

    private func firstTableModeBlockedLogoToken(in script: String) -> String? {
        firstTableModeBlockedLogoToken(in: LogoTokenizer.tokenize(script), visitedProcedures: [])
    }

    private func firstTableModeBlockedLogoToken(
        in tokens: [String], visitedProcedures: Set<String>
    ) -> String? {
        for token in tokens {
            if let primitive = logoEngine.parsePrimitive(token),
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
                in: procedure.bodyTokens.map(\.text), visitedProcedures: nextVisited)
            {
                return blockedToken
            }
        }

        return nil
    }

    /// Evaluates LOGO code from linear selection, Markdown ```logo code fence, or current line/block.
    func evalLogoCode() {
        let script: String
        let startLine: Int
        let sourceBuffer = buffer

        // Priority 1: Selection Range
        if let mark = buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
            script = buffer.textRange(
                start: (line: start.line, col: start.column), end: (line: end.line, col: end.column))
            startLine = start.line
        }
        // Priority 2: Markdown ```logo ... ``` code fence
        else if let fence = extractMarkdownLogoFence() {
            script = fence.script
            startLine = fence.startLine
        }
        // Priority 3: Current line or multi-line block (balanced [ ... ] or TO ... END)
        else {
            let block = extractCurrentLineOrBlock()
            script = block.script
            startLine = block.startLine
        }

        guard buffer.allowsLogoExecution else {
            reportOperationResult(.noOp(message: l10n["status.directory_buffer_readonly"]))
            return
        }

        let cleanScript = script.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanScript.isEmpty else { return }

        guard let firstToken = LogoTokenizer.tokenize(cleanScript).first else { return }
        guard isPotentialLogoScript(firstToken) else {
            let message = "[LOGO Error: I don't know how to \(firstToken)]"
            reportOperationResult(.failed(message, message: l10n["status.logo_execution_error"]))
            return
        }

        runLogoScript(
            script,
            resultPrefix: "[Eval] ",
            successStatus: l10n["status.logo_evaluated"],
            debugSourceBuffer: sourceBuffer,
            debugStartLine: startLine
        )
    }

    private func isPotentialLogoScript(_ firstToken: String) -> Bool {
        if logoEngine.parsePrimitive(firstToken) != nil || logoEngine.parseOperator(firstToken) != nil
            || logoEngine.customProcedures[firstToken.uppercased()] != nil
        {
            return true
        }
        if firstToken == "(" || firstToken == "[" || firstToken.hasPrefix(":") || firstToken.hasPrefix("?") {
            return true
        }
        if firstToken.hasPrefix("\"") || firstToken.hasPrefix("|") || Double(firstToken) != nil {
            return true
        }
        return false
    }

    private func extractMarkdownLogoFence() -> (script: String, startLine: Int)? {
        let currentLine = buffer.lineIndex
        var fenceStart: Int? = nil

        // Scan upwards to find ```logo
        for r in (0...currentLine).reversed() {
            let line = buffer.lines[r].trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("```logo") {
                fenceStart = r
                break
            }
            if line.hasPrefix("```") && r < currentLine && r != currentLine - 1 {
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

        guard let end = fenceEnd, currentLine >= start && currentLine <= end + 1 else { return nil }
        guard start + 1 < end else { return ("", start + 1) }

        return (buffer.lines[(start + 1)..<end].joined(separator: "\n"), start + 1)
    }

    private func extractCurrentLineOrBlock() -> (script: String, startLine: Int) {
        let currentLine = buffer.lineIndex
        guard currentLine < buffer.lines.count else { return ("", currentLine) }

        // Check if inside TO ... END procedure definition
        var toStart: Int? = nil
        for r in (0...currentLine).reversed() {
            let line = buffer.lines[r].trimmingCharacters(in: .whitespaces)
            let upper = line.uppercased()
            let tokens = upper.split(separator: " ").map(String.init)
            guard let firstToken = tokens.first else { continue }
            let hasTo = firstToken == "TO"
            let hasEnd = tokens.contains("END")

            if hasTo && hasEnd {
                if r == currentLine {
                    return (buffer.lines[r], r)
                } else {
                    break
                }
            } else if hasTo {
                toStart = r
                break
            } else if hasEnd && r < currentLine {
                break
            }
        }

        if let start = toStart {
            var end: Int? = nil
            for r in start..<buffer.lines.count {
                let line = buffer.lines[r].trimmingCharacters(in: .whitespaces)
                let tokens = line.uppercased().split(separator: " ").map(String.init)
                if tokens.contains("END") {
                    end = r
                    break
                }
            }
            if let end = end, currentLine >= start && currentLine <= end {
                return (buffer.lines[start...end].joined(separator: "\n"), start)
            }
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
            return (buffer.lines[currentLine...endLine].joined(separator: "\n"), currentLine)
        }

        return (lineText, currentLine)
    }
}
