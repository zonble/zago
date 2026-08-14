import Foundation
import LogoEngine
import TextMetrics
import TextTransform

extension Editor {
    func goToLocation(line oneBasedLine: Int, column oneBasedColumn: Int? = nil) {
        guard oneBasedLine > 0 else {
            setStatusMessage(l10n["status.invalid_line"])
            return
        }

        if isTableModeActive, currentTableCell != nil {
            if let oneBasedColumn, oneBasedColumn <= 0 {
                setStatusMessage(l10n["status.invalid_column"])
                return
            }
            let targetLine = oneBasedLine - 1
            let targetColumn = (oneBasedColumn ?? buffer.columnIndex + 1) - 1
            guard let clamped = tableModeController.clampedPositionInCurrentCell(
                line: targetLine, column: targetColumn)
            else {
                setStatusMessage(l10n["status.goto_disabled_in_table_mode"])
                return
            }
            buffer.lineIndex = clamped.line
            buffer.columnIndex = clamped.column
        } else if isCanvasModeActive {
            if let oneBasedColumn, oneBasedColumn <= 0 {
                setStatusMessage(l10n["status.invalid_column"])
                return
            }
            let targetLine = oneBasedLine - 1
            guard isCanvasLineAllowed(targetLine) else {
                setStatusMessage(l10n["status.canvas_row_limit_exceeded"])
                return
            }
            let targetColumn = (oneBasedColumn ?? 1) - 1
            guard isCanvasColumnAllowed(targetColumn) else {
                setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
                return
            }
            guard ensureCanvasLineExists(targetLine) else { return }
            buffer.lineIndex = targetLine
            canvasVisualColumn = targetColumn
            syncCanvasCursorToBuffer()
        } else if let oneBasedColumn {
            guard oneBasedColumn > 0 else {
                setStatusMessage(l10n["status.invalid_column"])
                return
            }
            let targetLine = max(0, min(oneBasedLine - 1, buffer.lines.count - 1))
            buffer.lineIndex = targetLine
            let zeroBasedVisualColumn = oneBasedColumn - 1
            buffer.columnIndex = tableModeController.getCharIndexForVisualColumn(
                in: buffer.lines[targetLine], targetVisualCol: zeroBasedVisualColumn)
        } else {
            let targetLine = max(0, min(oneBasedLine - 1, buffer.lines.count - 1))
            buffer.lineIndex = targetLine
            buffer.columnIndex = 0
        }

        buffer.clampCursor()
        let currentLine = buffer.lineIndex + 1
        let currentCol = buffer.columnIndex + 1
        let line = buffer.lines[buffer.lineIndex]
        let visualCol =
            isCanvasModeActive
            ? canvasVisualColumn + 1
            : line.visualColumn(forCharacterOffset: buffer.columnIndex) + 1
        setStatusMessage(
            l10n.cursorInfo(
                currentLine: currentLine, totalLines: buffer.lines.count,
                percent: Int(Double(currentLine) / Double(buffer.lines.count) * 100), currentCol: currentCol,
                totalCol: line.count + 1, visualCol: visualCol, totalVisualCol: line.displayWidth + 1))
    }

    func openDirectoryBuffer(path: String? = nil) {
        let dirPath =
            path
            ?? (buffer.filePath != nil
                ? fileIOStrategy.parentDirectory(of: buffer.filePath!) : fileIOStrategy.currentDirectoryPath())
        let expanded = fileIOStrategy.normalizePath(dirPath, isDirectory: true)
        if let existingIndex = buffers.firstIndex(where: { $0.filePath == expanded }) {
            switchToBuffer(index: existingIndex)
        } else {
            openNewBuffer(filePath: expanded)
        }
    }

    func openBuffer(path: String) {
        let expanded = fileIOStrategy.normalizePath(path, isDirectory: false)
        let info = fileIOStrategy.fileInfo(at: expanded)
        if info.exists, info.isDirectory {
            openDirectoryBuffer(path: expanded)
            return
        }
        if info.exists {
            do {
                _ = try fileIOStrategy.readTextFile(at: expanded)
            } catch {
                setStatusMessage(l10n.errorOpeningFile(error: error.localizedDescription))
                return
            }
        }

        if let existingIndex = buffers.firstIndex(where: { $0.filePath == expanded }) {
            switchToBuffer(index: existingIndex)
        } else {
            openNewBuffer(filePath: expanded)
        }
    }

    func openDocumentLinkAtCursor() {
        guard !buffer.isDirectoryBuffer else {
            setStatusMessage(l10n["status.no_document_link"])
            return
        }

        let line = buffer.lines[buffer.lineIndex]
        guard let link = DocumentLinkParser.link(atColumn: buffer.columnIndex, in: line),
            let parsedTarget = DocumentLinkParser.parseTarget(link.target)
        else {
            setStatusMessage(l10n["status.no_document_link"])
            return
        }

        let resolvedPath: String?
        if let pathPart = parsedTarget.path {
            resolvedPath = DocumentLinkParser.resolvedPath(target: pathPart, currentFilePath: buffer.filePath)
        } else {
            resolvedPath = nil
        }

        let isSameFile = (resolvedPath == nil) || isCurrentDocumentPath(resolvedPath!)

        if isSameFile {
            if let anchor = parsedTarget.anchor {
                if let targetLine = DocumentLinkParser.findAnchorLineIndex(
                    anchor: anchor, in: buffer.lines, syntaxName: activeLanguageSyntax?.name)
                {
                    buffer.lineIndex = targetLine
                    buffer.columnIndex = 0
                    buffer.clampCursor()
                    setStatusMessage(String(format: l10n["status.jumped_to_anchor"], anchor))
                } else {
                    setStatusMessage(String(format: l10n["status.anchor_not_found"], anchor))
                }
            } else {
                setStatusMessage(l10n["status.document_link_same_file"])
            }
            return
        }

        if let targetPath = resolvedPath {
            openBuffer(path: targetPath)
            if let anchor = parsedTarget.anchor {
                if let targetLine = DocumentLinkParser.findAnchorLineIndex(
                    anchor: anchor, in: buffer.lines, syntaxName: activeLanguageSyntax?.name)
                {
                    buffer.lineIndex = targetLine
                    buffer.columnIndex = 0
                    buffer.clampCursor()
                }
            }
            setStatusMessage(String(format: l10n["status.opened_document_link"], targetPath))
        }
    }

    private func isCurrentDocumentPath(_ path: String) -> Bool {
        guard let currentPath = buffer.filePath, !currentPath.isEmpty else { return false }
        return standardizedDocumentPath(currentPath) == standardizedDocumentPath(path)
    }

    private func standardizedDocumentPath(_ path: String) -> String {
        fileIOStrategy.normalizePath(path, isDirectory: false)
    }

    func transformSelectedText(id transformId: String, label: String) {
        guard let range = activeTextSelectionRange() else {
            setStatusMessage(l10n["status.no_text_selection"])
            return
        }

        let selectedText = buffer.textRange(
            start: (line: range.start.line, col: range.start.column),
            end: (line: range.end.line, col: range.end.column))

        do {
            let transformed = try TextTransformer.apply(transformId, to: selectedText)
            saveUndoSnapshot()
            _ = buffer.cutRange(
                start: (line: range.start.line, col: range.start.column),
                end: (line: range.end.line, col: range.end.column))
            buffer.lineIndex = range.start.line
            buffer.columnIndex = range.start.column
            buffer.insertString(transformed)
            buffer.selectionMark = nil
            if isTableModeActive {
                tableModeController.clampTableModeCursor()
            } else {
                buffer.clampCursor()
            }
            setStatusMessage(String(format: l10n["status.transformed_selection"], label))
        } catch {
            setStatusMessage(String(format: l10n["status.text_transform_failed"], "\(error)"))
        }
    }

    func showTextCounts() {
        let (text, statusFormat) =
            if let range = activeTextSelectionRange() {
                (
                    buffer.textRange(
                        start: (line: range.start.line, col: range.start.column),
                        end: (line: range.end.line, col: range.end.column)),
                    l10n["status.word_count_selection"]
                )
            } else {
                (buffer.lines.joined(separator: "\n"), l10n["status.word_count_document"])
            }
        setStatusMessage(String(format: statusFormat, textCountSummary(for: text)))
    }

    func hasActiveTextSelection() -> Bool {
        activeTextSelectionRange() != nil
    }

    private func textCountSummary(for text: String) -> String {
        let charCount = TextAnalyzer.characterCount(in: text)
        let wordCount = TextAnalyzer.wordCount(in: text)
        let cjkCount = TextAnalyzer.cjkCharacterCount(in: text)
        let emojiCount = TextAnalyzer.emojiCount(in: text)
        let lineCount = TextAnalyzer.lineCount(in: text)

        var parts = [
            "\(charCount) \(charCount == 1 ? "char" : "chars")",
            "\(wordCount) \(wordCount == 1 ? "word" : "words")",
        ]
        if cjkCount > 0 {
            parts.append("\(cjkCount) CJK \(cjkCount == 1 ? "char" : "chars")")
        }
        if emojiCount > 0 {
            parts.append("\(emojiCount) \(emojiCount == 1 ? "emoji" : "emojis")")
        }
        parts.append("\(lineCount) \(lineCount == 1 ? "line" : "lines")")
        return parts.joined(separator: ", ")
    }

    private func activeTextSelectionRange() -> (start: (line: Int, column: Int), end: (line: Int, column: Int))? {
        guard !isCanvasModeActive, !buffer.isDirectoryBuffer, let mark = buffer.selectionMark else { return nil }
        let cursor = (line: buffer.lineIndex, column: buffer.columnIndex)
        let range = TextBuffer.getOrderedRange(mark1: mark, mark2: cursor)
        guard range.start.line != range.end.line || range.start.column != range.end.column else { return nil }
        return range
    }

    @discardableResult
    func writeBuffer(path: String) -> Bool {
        doSave(to: path)
    }

    public func apply(_ setting: EditorSettingUpdate) {
        switch setting {
        case .wrap(let column): layoutEngine.setWrapColumn(column)
        case .ruler(let value): displayConfig.showRuler = resolve(value, current: displayConfig.showRuler)
        case .lineNumbers(let value):
            displayConfig.showLineNumbers = resolve(value, current: displayConfig.showLineNumbers)
        case .subLineNumbers(let value):
            displayConfig.showSubLineNumbers = resolve(value, current: displayConfig.showSubLineNumbers)
        case .canvasMode(let value):
            let enabled = resolve(value, current: isCanvasModeActive)
            enabled ? switchToCanvasMode() : switchToTextMode()
        case .syntaxHighlighting(let value):
            displayConfig.enableSyntaxHighlight = resolve(value, current: displayConfig.enableSyntaxHighlight)
        case .autoReload(let value): displayConfig.autoReload = resolve(value, current: displayConfig.autoReload)
        case .trimTrailingWhitespace(let value):
            displayConfig.trimTrailingWhitespaceOnSave = resolve(
                value, current: displayConfig.trimTrailingWhitespaceOnSave)
        case .regex(let value): isRegexSearchEnabled = resolve(value, current: isRegexSearchEnabled)
        case .debug(let value): debugMode = resolve(value, current: debugMode)
        case .smartTab(let value): displayConfig.smartTab = resolve(value, current: displayConfig.smartTab)
        case .listIndentSize(let size): displayConfig.listIndentSize = size
        case .listWrapIndent(let value):
            displayConfig.listWrapIndent = resolve(value, current: displayConfig.listWrapIndent)
        case .gitDiff(let value): displayConfig.showGitDiff = resolve(value, current: displayConfig.showGitDiff)
        case .spellLanguage(let language): spellChecker.setLanguage(language)
        case .tabSize(let size): displayConfig.tabSize = size
        case .language(let language):
            self.language = language
            usesExplicitLanguage = true
            for buffer in buffers {
                if let directoryBuffer = buffer as? DirectoryBuffer {
                    directoryBuffer.loadDirectory(at: directoryBuffer.directoryPath, language: language)
                }
            }
        case .border(let style, let rawValue):
            if let style {
                defaultBorderStyle = style
                setStatusMessage(l10n.defaultBorder(style.rawValue))
            } else if rawValue.isEmpty {
                _ = commandRegistry.dispatch(id: .borderStyle, editor: self)
            } else {
                setStatusMessage(l10n.unknownBorderStyle(rawValue))
            }
        case .arrow(let style):
            if let style { defaultArrowStyle = style }
        case .ipc(let value):
            let enabled = resolve(value, current: displayConfig.ipcEnabled)
            displayConfig.ipcEnabled = enabled
            effectDelegate?.editor(self, didEmit: .ipcEnabled(enabled))
        }
    }

    private func resolve(_ requested: Bool?, current: Bool) -> Bool {
        requested ?? !current
    }

    func saveBuffer(path: String?) {
        if let path, !path.isEmpty {
            writeBuffer(path: path)
        } else if let currentPath = buffer.filePath, !currentPath.isEmpty {
            writeBuffer(path: currentPath)
        } else {
            promptWriteFilePath()
        }
    }

    func saveAndCloseBuffer(path: String?) {
        if let path, !path.isEmpty {
            doSave(to: path) { [weak self] in self?.closeCurrentBuffer() }
        } else if let currentPath = buffer.filePath, !currentPath.isEmpty {
            doSave(to: currentPath) { [weak self] in self?.closeCurrentBuffer() }
        } else {
            promptSaveAndExit()
        }
    }

    @discardableResult
    func switchToBuffer(zeroBasedIndex index: Int, reportInvalid: Bool = false) -> Bool {
        guard index >= 0 && index < buffers.count else {
            if reportInvalid {
                setStatusMessage(l10n["status.no_such_buffer"])
            }
            return false
        }

        switchToBuffer(index: index)
        return true
    }

    @discardableResult
    func switchToBuffer(oneBasedIndex index: Int, reportInvalid: Bool = false) -> Bool {
        switchToBuffer(zeroBasedIndex: index - 1, reportInvalid: reportInvalid)
    }

    func commentPrefix(at lineIndex: Int) -> String {
        syntaxHighlighter.commentPrefix(
            for: buffer.filePath,
            lines: buffer.lines,
            bufferLineIndex: lineIndex
        )
    }

    func commentPrefix(for filePath: String?) -> String {
        syntaxHighlighter.commentPrefix(
            for: filePath,
            lines: [],
            bufferLineIndex: 0
        )
    }

    func toggleComment() {
        guard !buffer.isDirectoryBuffer else { return }
        saveUndoSnapshot()

        if isTableModeActive, currentTableCell != nil {
            toggleCommentInCurrentTableCell()
            return
        }

        let startLine: Int
        let endLine: Int

        if let mark = buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
            startLine = start.line
            endLine = end.line
        } else {
            let cur = min(max(0, buffer.lineIndex), max(0, buffer.lines.count - 1))
            startLine = cur
            endLine = cur
        }

        let prefix = commentPrefix(at: startLine)
        let cleanPrefix = prefix.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        var allCommented = true
        var nonCount = 0
        var minIndent = Int.max

        for lineIdx in startLine...endLine {
            guard lineIdx < buffer.lines.count else { continue }
            let line = buffer.lines[lineIdx]
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            nonCount += 1
            if !trimmed.hasPrefix(cleanPrefix) {
                allCommented = false
            }

            var indent = 0
            for ch in line {
                if ch == " " || ch == "\t" {
                    indent += 1
                } else {
                    break
                }
            }
            minIndent = min(minIndent, indent)
        }

        if nonCount == 0 {
            allCommented = false
            minIndent = 0
        } else if minIndent == Int.max {
            minIndent = 0
        }

        for lineIdx in startLine...endLine {
            guard lineIdx < buffer.lines.count else { continue }
            let line = buffer.lines[lineIdx]
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            if allCommented {
                if trimmed.isEmpty {
                    buffer.lines[lineIdx] = ""
                    continue
                }
                if let prefixRange = line.range(of: cleanPrefix) {
                    var newText = line
                    let afterIdx = prefixRange.upperBound
                    if afterIdx < newText.endIndex && newText[afterIdx] == " " {
                        newText.removeSubrange(prefixRange.lowerBound...afterIdx)
                    } else {
                        newText.removeSubrange(prefixRange)
                    }
                    if cleanPrefix == "<!--" {
                        if newText.hasSuffix(" -->") {
                            newText.removeLast(4)
                        } else if newText.hasSuffix("-->") {
                            newText.removeLast(3)
                        }
                    }
                    if newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        newText = ""
                    }
                    buffer.lines[lineIdx] = newText
                }
            } else {
                if trimmed.isEmpty {
                    let indentStr = String(repeating: " ", count: minIndent)
                    buffer.lines[lineIdx] = indentStr + cleanPrefix
                } else {
                    var currentIndent = 0
                    for ch in line {
                        if ch == " " || ch == "\t" {
                            currentIndent += 1
                        } else {
                            break
                        }
                    }
                    let actualIndent = min(currentIndent, minIndent)
                    let indentStr = String(repeating: " ", count: actualIndent)
                    let restOfLine = String(line.dropFirst(currentIndent))
                    let extraIndentCount = currentIndent - actualIndent
                    let extraIndent = extraIndentCount > 0 ? String(repeating: " ", count: extraIndentCount) : ""

                    let suffix = cleanPrefix == "<!--" ? " -->" : ""
                    let newText = indentStr + prefix + extraIndent + restOfLine + suffix
                    buffer.lines[lineIdx] = newText
                }
            }
        }

        buffer.isModified = true
    }

    private func toggleCommentInCurrentTableCell() {
        guard let cell = currentTableCell else { return }

        let rawStartLine: Int
        let rawEndLine: Int
        if let mark = buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
            rawStartLine = start.line
            rawEndLine = end.line
        } else {
            let cur = min(max(0, buffer.lineIndex), max(0, buffer.lines.count - 1))
            rawStartLine = cur
            rawEndLine = cur
        }

        let startLine = max(cell.innerMinLine, rawStartLine)
        let endLine = min(cell.innerMaxLine, rawEndLine)
        guard startLine <= endLine else { return }

        let prefix = commentPrefix(at: startLine)
        let cleanPrefix = prefix.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var allCommented = true
        var nonCount = 0
        var minIndent = Int.max

        for lineIdx in startLine...endLine {
            guard let bounds = tableModeController.currentCellInnerBounds(on: lineIdx) else { continue }
            let line = buffer.lines[lineIdx]
            let chars = Array(line)
            let innerText = String(chars[bounds.start..<bounds.end])
            let trimmed = trimmedCommentFragment(innerText)
            if trimmed.isEmpty { continue }

            nonCount += 1
            if !trimmed.hasPrefix(cleanPrefix) {
                allCommented = false
            }

            var indent = 0
            for ch in innerText {
                if ch == " " || ch == "\t" {
                    indent += 1
                } else {
                    break
                }
            }
            minIndent = min(minIndent, indent)
        }

        if nonCount == 0 {
            allCommented = false
            minIndent = 0
        } else if minIndent == Int.max {
            minIndent = 0
        }

        for lineIdx in startLine...endLine {
            guard let bounds = tableModeController.currentCellInnerBounds(on: lineIdx) else { continue }
            let line = buffer.lines[lineIdx]
            let chars = Array(line)
            let innerText = String(chars[bounds.start..<bounds.end])
            let innerWidth = innerText.displayWidth
            let trimmed = trimmedCommentFragment(innerText)
            let newInnerText: String

            if allCommented {
                if trimmed.isEmpty {
                    newInnerText = ""
                } else if let prefixRange = innerText.range(of: cleanPrefix) {
                    var newText = innerText
                    let afterIdx = prefixRange.upperBound
                    if afterIdx < newText.endIndex && newText[afterIdx] == " " {
                        newText.removeSubrange(prefixRange.lowerBound...afterIdx)
                    } else {
                        newText.removeSubrange(prefixRange)
                    }
                    if cleanPrefix == "<!--" {
                        if newText.hasSuffix(" -->") {
                            newText.removeLast(4)
                        } else if newText.hasSuffix("-->") {
                            newText.removeLast(3)
                        }
                    }
                    newInnerText = newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : newText
                } else {
                    newInnerText = innerText
                }
            } else if trimmed.isEmpty {
                let indentStr = String(repeating: " ", count: minIndent)
                newInnerText = indentStr + cleanPrefix
            } else {
                var currentIndent = 0
                for ch in innerText {
                    if ch == " " || ch == "\t" {
                        currentIndent += 1
                    } else {
                        break
                    }
                }
                let actualIndent = min(currentIndent, minIndent)
                let indentStr = String(repeating: " ", count: actualIndent)
                let restOfLine = String(innerText.dropFirst(currentIndent))
                let extraIndentCount = currentIndent - actualIndent
                let extraIndent = extraIndentCount > 0 ? String(repeating: " ", count: extraIndentCount) : ""
                let suffix = cleanPrefix == "<!--" ? " -->" : ""
                newInnerText = indentStr + prefix + extraIndent + restOfLine + suffix
            }

            let prefixText = String(chars[..<bounds.start])
            let suffixText = String(chars[bounds.end...])
            buffer.lines[lineIdx] = prefixText + newInnerText.paddedToDisplayWidth(innerWidth) + suffixText
        }

        buffer.isModified = true
    }

    private func trimmedCommentFragment(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
