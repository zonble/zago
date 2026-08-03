import Foundation
import LogoEngine
import TextMetrics
import TextTransform

extension Editor {
    public func goToLocation(line oneBasedLine: Int, column oneBasedColumn: Int? = nil) {
        if isTableModeActive {
            setStatusMessage(L10n["status.goto_disabled_in_table_mode"])
            return
        }

        guard oneBasedLine > 0 else {
            setStatusMessage(L10n["status.invalid_line"])
            return
        }

        if isCanvasModeActive {
            if let oneBasedColumn, oneBasedColumn <= 0 {
                setStatusMessage(L10n["status.invalid_column"])
                return
            }
            let targetLine = oneBasedLine - 1
            guard isCanvasLineAllowed(targetLine) else {
                setStatusMessage(L10n["status.canvas_row_limit_exceeded"])
                return
            }
            let targetColumn = (oneBasedColumn ?? 1) - 1
            guard isCanvasColumnAllowed(targetColumn) else {
                setStatusMessage(L10n["status.canvas_column_limit_exceeded"])
                return
            }
            guard ensureCanvasLineExists(targetLine) else { return }
            buffer.lineIndex = targetLine
            canvasVisualColumn = targetColumn
            syncCanvasCursorToBuffer()
        } else if let oneBasedColumn {
            guard oneBasedColumn > 0 else {
                setStatusMessage(L10n["status.invalid_column"])
                return
            }
            let targetLine = max(0, min(oneBasedLine - 1, buffer.lines.count - 1))
            buffer.lineIndex = targetLine
            let zeroBasedColumn = oneBasedColumn - 1
            buffer.columnIndex = max(0, min(zeroBasedColumn, buffer.lines[targetLine].count))
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
            L10n.cursorInfo(
                currentLine: currentLine, totalLines: buffer.lines.count,
                percent: Int(Double(currentLine) / Double(buffer.lines.count) * 100), currentCol: currentCol,
                totalCol: line.count + 1, visualCol: visualCol, totalVisualCol: line.displayWidth + 1))
    }

    public func openBuffer(path: String) {
        let expanded = NSString(string: path).expandingTildeInPath
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue {
            openDirectoryBuffer(path: expanded)
            return
        }

        if let existingIndex = buffers.firstIndex(where: { $0.filePath == expanded }) {
            switchToBuffer(index: existingIndex)
        } else {
            openNewBuffer(filePath: expanded)
        }
    }

    public func openDocumentLinkAtCursor() {
        guard !buffer.isDirectoryBuffer else {
            setStatusMessage(L10n["status.no_document_link"])
            return
        }

        let line = buffer.lines[buffer.lineIndex]
        guard let link = DocumentLinkParser.link(atColumn: buffer.columnIndex, in: line),
            let path = DocumentLinkParser.resolvedPath(target: link.target, currentFilePath: buffer.filePath)
        else {
            setStatusMessage(L10n["status.no_document_link"])
            return
        }

        if isCurrentDocumentPath(path) {
            setStatusMessage(L10n["status.document_link_same_file"])
            return
        }

        openBuffer(path: path)
        setStatusMessage(String(format: L10n["status.opened_document_link"], path))
    }

    private func isCurrentDocumentPath(_ path: String) -> Bool {
        guard let currentPath = buffer.filePath, !currentPath.isEmpty else { return false }
        return standardizedDocumentPath(currentPath) == standardizedDocumentPath(path)
    }

    private func standardizedDocumentPath(_ path: String) -> String {
        let expanded = NSString(string: path).expandingTildeInPath
        return URL(fileURLWithPath: expanded).standardizedFileURL.path
    }

    public func transformSelectedText(id transformId: String, label: String) {
        guard let range = activeTextSelectionRange() else {
            setStatusMessage(L10n["status.no_text_selection"])
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
            selectionMark = nil
            if isTableModeActive {
                clampTableModeCursor()
            } else {
                buffer.clampCursor()
            }
            setStatusMessage(String(format: L10n["status.transformed_selection"], label))
        } catch {
            setStatusMessage(String(format: L10n["status.text_transform_failed"], "\(error)"))
        }
    }

    public func showTextCounts() {
        let (text, statusFormat) =
            if let range = activeTextSelectionRange() {
                (
                    buffer.textRange(
                        start: (line: range.start.line, col: range.start.column),
                        end: (line: range.end.line, col: range.end.column)),
                    L10n["status.word_count_selection"]
                )
            } else {
                (buffer.lines.joined(separator: "\n"), L10n["status.word_count_document"])
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
        guard !isCanvasModeActive, !buffer.isDirectoryBuffer, let mark = selectionMark else { return nil }
        let cursor = (line: buffer.lineIndex, column: buffer.columnIndex)
        let range = getOrderedRange(mark1: mark, mark2: cursor)
        guard range.start.line != range.end.line || range.start.column != range.end.column else { return nil }
        return range
    }

    public func writeBuffer(path: String) {
        doSave(to: path)
    }

    public func applyEditorSetting(setting: String, arg: String) {
        switch setting.lowercased() {
        case "wrap", "wrapcolumn":
            if arg == "off" || arg == "false" || arg == "none" {
                layoutEngine.setWrapColumn(nil)
            } else if let w = Int(arg), w > 0 {
                layoutEngine.setWrapColumn(w)
            } else {
                layoutEngine.setWrapColumn(nil)
            }
        case "ruler", "rulerbar", "showruler":
            if arg == "off" || arg == "false" {
                displayConfig.showRuler = false
            } else if arg == "on" || arg == "true" {
                displayConfig.showRuler = true
            } else {
                displayConfig.showRuler.toggle()
            }
        case "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers", "line_number":
            if arg == "off" || arg == "false" {
                displayConfig.showLineNumbers = false
            } else if arg == "on" || arg == "true" {
                displayConfig.showLineNumbers = true
            } else {
                displayConfig.showLineNumbers.toggle()
            }
        case "sublinenumbers", "sublinenumber", "subline-numbers", "subline-number", "subline_numbers",
            "subline_number", "sublines":
            if arg == "off" || arg == "false" {
                displayConfig.showSubLineNumbers = false
            } else if arg == "on" || arg == "true" {
                displayConfig.showSubLineNumbers = true
            } else {
                displayConfig.showSubLineNumbers.toggle()
            }
        case "canvas-mode", "canvasmode", "canvas_mode":
            if arg == "off" || arg == "false" {
                switchToTextMode()
            } else if arg == "on" || arg == "true" {
                switchToCanvasMode()
            } else {
                toggleCanvasMode()
            }
        case "syntax", "enablesyntax", "syntaxhighlight", "syntaxhighlighting":
            if arg == "off" || arg == "false" {
                displayConfig.enableSyntaxHighlight = false
            } else if arg == "on" || arg == "true" {
                displayConfig.enableSyntaxHighlight = true
            } else {
                displayConfig.enableSyntaxHighlight.toggle()
            }
        case "autoreload", "auto-reload", "auto_reload":
            if arg == "off" || arg == "false" {
                displayConfig.autoReload = false
            } else if arg == "on" || arg == "true" {
                displayConfig.autoReload = true
            } else {
                displayConfig.autoReload.toggle()
            }
        case "trim-trailing-whitespace", "trimtrailingwhitespace", "trim_trailing_whitespace",
            "trim-trailing-spaces", "trimtrailingspaces", "trim_trailing_spaces":
            if arg == "off" || arg == "false" {
                displayConfig.trimTrailingWhitespaceOnSave = false
            } else if arg == "on" || arg == "true" {
                displayConfig.trimTrailingWhitespaceOnSave = true
            } else {
                displayConfig.trimTrailingWhitespaceOnSave.toggle()
            }
        case "regex", "regexp", "enableregex":
            if arg == "off" || arg == "false" {
                isRegexSearchEnabled = false
            } else if arg == "on" || arg == "true" {
                isRegexSearchEnabled = true
            } else {
                isRegexSearchEnabled.toggle()
            }
        case "tab", "tabsize":
            if let size = Int(arg), size > 0 {
                displayConfig.tabSize = size
            }
        case "lang":
            if arg == "zh_tw" || arg == "zh" {
                L10n.currentLanguage = .zh_TW
            } else if arg == "en" {
                L10n.currentLanguage = .en
            }
        case "border", "borderstyle", "border-style", "border_style", "defaultborder", "defaultborderstyle",
            "default-border-style", "default_border_style":
            if let style = BorderStyle(arg) {
                defaultBorderStyle = style
                setStatusMessage(L10n.defaultBorder(style.rawValue))
            } else if arg.isEmpty {
                _ = commandRegistry.dispatch(id: .borderStyle, editor: self)
            } else {
                setStatusMessage(L10n.unknownBorderStyle(arg))
            }
        default:
            break
        }
    }

    public func saveBuffer(path: String?) {
        if let path, !path.isEmpty {
            writeBuffer(path: path)
        } else if let currentPath = buffer.filePath, !currentPath.isEmpty {
            writeBuffer(path: currentPath)
        } else {
            promptWriteFilePath()
        }
    }

    public func saveAndCloseBuffer(path: String?) {
        if let path, !path.isEmpty {
            writeBuffer(path: path)
            closeCurrentBuffer()
        } else if let currentPath = buffer.filePath, !currentPath.isEmpty {
            writeBuffer(path: currentPath)
            closeCurrentBuffer()
        } else {
            promptSaveAndExit()
        }
    }

    @discardableResult
    public func switchToBuffer(zeroBasedIndex index: Int, reportInvalid: Bool = false) -> Bool {
        guard index >= 0 && index < buffers.count else {
            if reportInvalid {
                setStatusMessage(L10n["status.no_such_buffer"])
            }
            return false
        }

        switchToBuffer(index: index)
        return true
    }

    @discardableResult
    public func switchToBuffer(oneBasedIndex index: Int, reportInvalid: Bool = false) -> Bool {
        switchToBuffer(zeroBasedIndex: index - 1, reportInvalid: reportInvalid)
    }
}
