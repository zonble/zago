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
            buffer.insertString(text)
        case .insertNewline:
            buffer.insertNewline()
        case .setStatusMessage(let msg):
            setStatusMessage(msg)
        case .deleteChar:
            buffer.delete()
        case .backspaceChar:
            buffer.backspace()
        case .deleteLine:
            buffer.deleteLine()
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
            performSearch(query: query)
        case .markModified:
            buffer.isModified = true
        case .applySetting(let setting, let arg):
            applySetting(setting: setting, arg: arg)
        case .updateLineIndex(let lineIndex):
            buffer.lineIndex = lineIndex
        case .updateColumnIndex(let columnIndex):
            buffer.columnIndex = columnIndex
        case .setLine(let index, let text):
            if index >= 0 && index < buffer.lines.count {
                buffer.lines[index] = text
            }
        case .ensureLineExists(let index):
            while buffer.lines.count <= index {
                buffer.lines.append("")
            }
        case .gotoLine(let row):
            buffer.lineIndex = max(0, min(row, buffer.lines.count - 1))
            buffer.clampCursor()
        case .gotoCol(let col):
            let lineText =
                (buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count) ? buffer.lines[buffer.lineIndex] : ""
            buffer.columnIndex = max(0, min(col, lineText.count))
        case .clearBuffer:
            buffer.lines = [""]
            buffer.lineIndex = 0
            buffer.columnIndex = 0
            buffer.isModified = true
        case .switchBuffer(let idx):
            if idx >= 0 && idx < buffers.count {
                currentBufferIndex = idx
            }
        case .openBuffer(let path):
            openNewBuffer(filePath: path)
        case .closeBuffer:
            closeCurrentBuffer()
        case .nextBuffer:
            nextBuffer()
        case .prevBuffer:
            prevBuffer()
        }
    }

    public func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> Any? {
        switch query {
        case .currentLineIndex:
            return buffer.lineIndex
        case .currentColumnIndex:
            return buffer.columnIndex
        case .lineCount:
            return buffer.lines.count
        case .lineAt(let index):
            guard index >= 0 && index < buffer.lines.count else { return "" }
            return buffer.lines[index]
        case .bufferList:
            return buffers.map { $0.filePath ?? "Untitled" }
        case .currentBufferIndex:
            return currentBufferIndex
        case .bufferText:
            return buffer.lines.joined(separator: "\n")
        case .selectionText:
            if let mark = selectionMark {
                let (start, end) = getOrderedRange(
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

    private func applySetting(setting: String, arg: String) {
        switch setting.lowercased() {
        case "wrap", "wrapcolumn":
            if arg == "off" || arg == "false" || arg == "none" {
                layoutEngine.wrapColumn = nil
            } else if let w = Int(arg), w > 0 {
                layoutEngine.wrapColumn = w
            } else {
                layoutEngine.wrapColumn = nil
            }
        case "ruler", "rulerbar":
            if arg == "off" || arg == "false" {
                displayConfig.showRuler = false
            } else if arg == "on" || arg == "true" {
                displayConfig.showRuler = true
            } else {
                displayConfig.showRuler.toggle()
            }
        case "syntax":
            if arg == "off" || arg == "false" {
                displayConfig.enableSyntaxHighlight = false
            } else if arg == "on" || arg == "true" {
                displayConfig.enableSyntaxHighlight = true
            } else {
                displayConfig.enableSyntaxHighlight.toggle()
            }
        case "autoreload":
            if arg == "off" || arg == "false" {
                displayConfig.autoReload = false
            } else if arg == "on" || arg == "true" {
                displayConfig.autoReload = true
            } else {
                displayConfig.autoReload.toggle()
            }
        case "lang":
            if arg == "zh_tw" || arg == "zh" {
                L10n.currentLanguage = .zh_TW
            } else if arg == "en" {
                L10n.currentLanguage = .en
            }
        default:
            break
        }
    }
}

extension Editor {
    /// Evaluates LOGO code from selection mark, Markdown ```logo code fence, or current line/block.
    public func evalLogoCode() {
        let script: String

        // Priority 1: Selection Range
        if let mark = selectionMark {
            let (start, end) = getOrderedRange(mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
            script = buffer.cutRange(
                start: (line: start.line, col: start.column), end: (line: end.line, col: end.column))
            // Restore selection text back into buffer
            buffer.insertString(script)
            selectionMark = mark
        }
        // Priority 2: Markdown ```logo ... ``` code fence
        else if let fenceScript = extractMarkdownLogoFence() {
            script = fenceScript
        }
        // Priority 3: Current line or multi-line block (balanced [ ... ] or TO ... END)
        else {
            script = extractCurrentLineOrBlock()
        }

        let cleanScript = script.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanScript.isEmpty else { return }

        let logoEngine = LogoEngine(delegate: self)
        logoEngine.execute(cleanScript)

        if !logoEngine.hasSetStatusMessage {
            if let result = logoEngine.lastResult, !result.isEmpty {
                setStatusMessage("[Eval] \(result)")
            } else {
                setStatusMessage(L10n["status.logo_evaluated"])
            }
        }
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
