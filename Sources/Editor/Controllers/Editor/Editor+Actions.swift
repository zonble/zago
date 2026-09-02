import Foundation
import LogoEngine
import TextMetrics
import TextTransform

extension Editor {
    @discardableResult
    func goToLocation(line oneBasedLine: Int, column oneBasedColumn: Int? = nil) -> EditorOperationResult {
        guard oneBasedLine > 0 else {
            return reportOperationResult(.noOp(message: l10n["status.invalid_line"]))
        }

        if isTableModeActive, currentTableCell != nil {
            if let oneBasedColumn, oneBasedColumn <= 0 {
                return reportOperationResult(.noOp(message: l10n["status.invalid_column"]))
            }
            let targetLine = oneBasedLine - 1
            let targetColumn = (oneBasedColumn ?? buffer.columnIndex + 1) - 1
            guard
                let clamped = tableModeController.clampedPositionInCurrentCell(
                    line: targetLine, column: targetColumn)
            else {
                return reportOperationResult(.noOp(message: l10n["status.goto_disabled_in_table_mode"]))
            }
            buffer.lineIndex = clamped.line
            buffer.columnIndex = clamped.column
        } else if isCanvasModeActive {
            if let oneBasedColumn, oneBasedColumn <= 0 {
                return reportOperationResult(.noOp(message: l10n["status.invalid_column"]))
            }
            let targetLine = oneBasedLine - 1
            guard isCanvasLineAllowed(targetLine) else {
                return reportOperationResult(.noOp(message: l10n["status.canvas_row_limit_exceeded"]))
            }
            let targetColumn = (oneBasedColumn ?? 1) - 1
            guard isCanvasColumnAllowed(targetColumn) else {
                return reportOperationResult(.noOp(message: l10n["status.canvas_column_limit_exceeded"]))
            }
            guard ensureCanvasLineExists(targetLine) else { return .noOp }
            buffer.lineIndex = targetLine
            canvasVisualColumn = targetColumn
            syncCanvasCursorToBuffer()
        } else if let oneBasedColumn {
            guard oneBasedColumn > 0 else {
                return reportOperationResult(.noOp(message: l10n["status.invalid_column"]))
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
        return reportOperationResult(
            .succeeded(
                message: l10n.cursorInfo(
                    currentLine: currentLine, totalLines: buffer.lines.count,
                    percent: Int(Double(currentLine) / Double(buffer.lines.count) * 100), currentCol: currentCol,
                    totalCol: line.count + 1, visualCol: visualCol, totalVisualCol: line.displayWidth + 1)))
    }

    func openDirectoryBuffer(path: String? = nil) {
        let dirPath =
            path
            ?? (buffer.filePath != nil
                ? fileIOStrategy.parentDirectory(of: buffer.filePath!) : fileIOStrategy.currentDirectoryPath())
        var expanded = fileIOStrategy.normalizePath(dirPath, isDirectory: true)

        var checkPath = expanded
        while true {
            let info = fileIOStrategy.fileInfo(at: checkPath)
            if info.exists && info.isDirectory {
                expanded = checkPath
                break
            }
            let parent = fileIOStrategy.parentDirectory(of: checkPath)
            if parent == checkPath || parent.isEmpty {
                let cur = fileIOStrategy.currentDirectoryPath()
                if fileIOStrategy.fileInfo(at: cur).exists {
                    expanded = cur
                } else {
                    expanded = fileIOStrategy.homeDirectoryPath()
                }
                break
            }
            checkPath = parent
        }

        if let existingIndex = buffers.firstIndex(where: { $0.filePath == expanded }) {
            switchToBuffer(index: existingIndex)
        } else {
            openNewBuffer(filePath: expanded)
        }
    }

    @discardableResult
    func openBuffer(path: String) -> EditorOperationResult {
        let expanded = fileIOStrategy.normalizePath(path, isDirectory: false)
        let info = fileIOStrategy.fileInfo(at: expanded)
        if info.exists, info.isDirectory {
            openDirectoryBuffer(path: expanded)
            return .succeeded
        }
        if maxFileSizeBytes > 0 && info.size > maxFileSizeBytes {
            let error = EditorFileError.fileTooLarge(size: info.size, limit: maxFileSizeBytes)
            let message = error.localizedDescription
            if let existingIndex = buffers.firstIndex(where: { $0.filePath == expanded }) {
                switchToBuffer(index: existingIndex)
            } else {
                openNewBuffer(filePath: expanded)
            }
            return reportOperationResult(.failed(message, message: l10n.errorOpeningFile(error: message)))
        }
        if info.exists {
            do {
                _ = try fileIOStrategy.readTextFile(at: expanded)
            } catch {
                let message = error.localizedDescription
                return reportOperationResult(.failed(message, message: l10n.errorOpeningFile(error: message)))
            }
        }

        if let existingIndex = buffers.firstIndex(where: { $0.filePath == expanded }) {
            switchToBuffer(index: existingIndex)
        } else {
            openNewBuffer(filePath: expanded)
        }
        return .succeeded
    }

    @discardableResult
    func openDocumentLinkAtCursor() -> EditorOperationResult {
        guard !buffer.isDirectoryBuffer else {
            return reportOperationResult(.noOp(message: l10n["status.no_document_link"]))
        }

        let line = buffer.lines[buffer.lineIndex]
        guard let link = DocumentLinkParser.link(atColumn: buffer.columnIndex, in: line),
            let parsedTarget = DocumentLinkParser.parseTarget(link.target)
        else {
            return reportOperationResult(.noOp(message: l10n["status.no_document_link"]))
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
                    return reportOperationResult(
                        .succeeded(message: String(format: l10n["status.jumped_to_anchor"], anchor)))
                } else {
                    return reportOperationResult(
                        .noOp(message: String(format: l10n["status.anchor_not_found"], anchor)))
                }
            } else {
                return reportOperationResult(.noOp(message: l10n["status.document_link_same_file"]))
            }
        }

        if let targetPath = resolvedPath {
            let result = openBuffer(path: targetPath)
            guard result.isSucceeded else { return result }
            if let anchor = parsedTarget.anchor {
                if let targetLine = DocumentLinkParser.findAnchorLineIndex(
                    anchor: anchor, in: buffer.lines, syntaxName: activeLanguageSyntax?.name)
                {
                    buffer.lineIndex = targetLine
                    buffer.columnIndex = 0
                    buffer.clampCursor()
                }
            }
            return reportOperationResult(
                .succeeded(message: String(format: l10n["status.opened_document_link"], targetPath)))
        }
        return .noOp
    }

    private func isCurrentDocumentPath(_ path: String) -> Bool {
        guard let currentPath = buffer.filePath, !currentPath.isEmpty else { return false }
        return standardizedDocumentPath(currentPath) == standardizedDocumentPath(path)
    }

    private func standardizedDocumentPath(_ path: String) -> String {
        fileIOStrategy.normalizePath(path, isDirectory: false)
    }

    @discardableResult
    func transformSelectedText(id transformId: String, label: String) -> EditorOperationResult {
        guard let range = activeTextSelectionRange() else {
            return reportOperationResult(.noOp(message: l10n["status.no_text_selection"]))
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
            return reportOperationResult(
                .succeeded(message: String(format: l10n["status.transformed_selection"], label)))
        } catch {
            return reportOperationResult(
                .failed("\(error)", message: String(format: l10n["status.text_transform_failed"], "\(error)")))
        }
    }

    @discardableResult
    func showTextCounts() -> EditorOperationResult {
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
        return reportOperationResult(.succeeded(message: String(format: statusFormat, textCountSummary(for: text))))
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
    func writeBuffer(path: String) -> EditorOperationResult {
        doSave(to: path)
    }

    public func apply(_ setting: EditorSettingUpdate) {
        switch setting {
        case .wrap(let column): layoutEngine.setWrapColumn(column)
        case .fill(let width): fillColumn = width
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
        case .noNewlines(let value):
            displayConfig.noNewlines = resolve(value, current: displayConfig.noNewlines)
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
                reportOperationResult(.succeeded(message: l10n.defaultBorder(style.rawValue)))
            } else if rawValue.isEmpty {
                _ = commandRegistry.dispatch(id: .borderStyle, editor: self)
            } else {
                reportOperationResult(.noOp(message: l10n.unknownBorderStyle(rawValue)))
            }
        case .arrow(let style):
            if let style { defaultArrowStyle = style }
        case .ipc(let value):
            let enabled = resolve(value, current: displayConfig.ipcEnabled)
            displayConfig.ipcEnabled = enabled
            effectDelegate?.editor(self, didEmit: .ipcEnabled(enabled))
        case .keymap(let preset):
            keymapManager.loadPreset(preset)
            reportOperationResult(.succeeded(message: "Keymap preset set to \(preset.rawValue)"))
        case .modernbindings(let value):
            let isModern = resolve(value, current: keymapManager.activePreset == .modern)
            keymapManager.loadPreset(isModern ? .modern : .classic)
            reportOperationResult(.succeeded(message: "Modern keybindings \(isModern ? "enabled" : "disabled")"))
        case .maxFileSize(let bytes):
            maxFileSizeBytes = bytes
        case .largeFileThreshold(let bytes):
            largeFileThresholdBytes = bytes
        case .maxLineHighlightLength(let len):
            syntaxHighlighter.maxLineHighlightLength = len
        case .backup(let value):
            backup = resolve(value, current: backup)
            reportOperationResult(.succeeded(message: "Backup \(backup ? "enabled" : "disabled")"))
        case .backupDir(let dir):
            backupDir = dir
            if let dir {
                reportOperationResult(.succeeded(message: "Backup directory set to \(dir)"))
            } else {
                reportOperationResult(.succeeded(message: "Backup directory reset to default"))
            }
        case .launchToJournal(let value):
            launchToJournal = resolve(value, current: launchToJournal)
            reportOperationResult(.succeeded(message: "Launch to journal \(launchToJournal ? "enabled" : "disabled")"))
        case .journalFolder(let folder):
            journalFolder = folder
            if let folder {
                reportOperationResult(.succeeded(message: "Journal folder set to \(folder)"))
            } else {
                reportOperationResult(.succeeded(message: "Journal folder reset to default"))
            }
        case .mouse(let value):
            let enabled = resolve(value, current: displayConfig.enableMouse)
            displayConfig.enableMouse = enabled
            reportOperationResult(.succeeded(message: "Mouse \(enabled ? "enabled" : "disabled")"))
        case .zero(let value):
            let enabled = resolve(value, current: displayConfig.isZeroMode)
            displayConfig.isZeroMode = enabled
            reportOperationResult(.succeeded(message: l10n.zeroModeState(enabled ? "enabled" : "disabled")))
        case .indicator(let value):
            let enabled = resolve(value, current: displayConfig.showIndicator)
            displayConfig.showIndicator = enabled
            reportOperationResult(.succeeded(message: l10n.indicatorState(enabled ? "enabled" : "disabled")))
        }
    }

    private func resolve(_ requested: Bool?, current: Bool) -> Bool {
        requested ?? !current
    }

    @discardableResult
    func saveBuffer(path: String?) -> EditorOperationResult {
        if let path, !path.isEmpty {
            return writeBuffer(path: path)
        } else if let currentPath = buffer.filePath, !currentPath.isEmpty {
            return writeBuffer(path: currentPath)
        } else {
            promptWriteFilePath()
            return .prompting
        }
    }

    @discardableResult
    func saveAndCloseBuffer(path: String?) -> EditorOperationResult {
        if let path, !path.isEmpty {
            return doSave(to: path) { [weak self] in self?.closeCurrentBuffer() }
        } else if let currentPath = buffer.filePath, !currentPath.isEmpty {
            return doSave(to: currentPath) { [weak self] in self?.closeCurrentBuffer() }
        } else {
            promptSaveAndExit()
            return .prompting
        }
    }

    @discardableResult
    func switchToBuffer(zeroBasedIndex index: Int, reportInvalid: Bool = false) -> Bool {
        guard index >= 0 && index < buffers.count else {
            if reportInvalid {
                reportOperationResult(.noOp(message: l10n["status.no_such_buffer"]))
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
