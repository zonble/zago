import Foundation
import TextMetrics

extension Editor {
    public func goToLocation(line oneBasedLine: Int, column oneBasedColumn: Int? = nil) {
        guard oneBasedLine > 0 else {
            setStatusMessage(L10n["status.invalid_line"])
            return
        }

        let targetLine = max(0, min(oneBasedLine - 1, buffer.lines.count - 1))
        buffer.lineIndex = targetLine

        if let oneBasedColumn {
            guard oneBasedColumn > 0 else {
                setStatusMessage(L10n["status.invalid_column"])
                return
            }
            let zeroBasedColumn = oneBasedColumn - 1
            if isCanvasModeActive {
                canvasVisualColumn = max(0, zeroBasedColumn)
                syncCanvasCursorToBuffer()
            } else {
                buffer.columnIndex = max(0, min(zeroBasedColumn, buffer.lines[targetLine].count))
            }
        } else {
            if isCanvasModeActive {
                canvasVisualColumn = 0
                syncCanvasCursorToBuffer()
            } else {
                buffer.columnIndex = 0
            }
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
        openNewBuffer(filePath: path)
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

        currentBufferIndex = index
        topVLineIndex = 0
        clearActiveMark()
        startFileWatcherForCurrentBuffer()
        return true
    }

    @discardableResult
    public func switchToBuffer(oneBasedIndex index: Int, reportInvalid: Bool = false) -> Bool {
        switchToBuffer(zeroBasedIndex: index - 1, reportInvalid: reportInvalid)
    }
}
