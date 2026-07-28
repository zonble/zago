import Foundation
import LogoEngine

extension Editor: LogoEngineDelegate {
    public func logoEngineCurrentLineIndex(_ engine: LogoEngine) -> Int {
        buffer.lineIndex
    }

    public func logoEngine(_ engine: LogoEngine, didUpdateLineIndex lineIndex: Int) {
        buffer.lineIndex = lineIndex
    }

    public func logoEngineCurrentColumnIndex(_ engine: LogoEngine) -> Int {
        buffer.columnIndex
    }

    public func logoEngine(_ engine: LogoEngine, didUpdateColumnIndex columnIndex: Int) {
        buffer.columnIndex = columnIndex
    }

    public func logoEngineLineCount(_ engine: LogoEngine) -> Int {
        buffer.lines.count
    }

    public func logoEngine(_ engine: LogoEngine, lineAt index: Int) -> String {
        guard index >= 0 && index < buffer.lines.count else { return "" }
        return buffer.lines[index]
    }

    public func logoEngine(_ engine: LogoEngine, setLineAt index: Int, text: String) {
        if index >= 0 && index < buffer.lines.count {
            buffer.lines[index] = text
        }
    }

    public func logoEngine(_ engine: LogoEngine, ensureLineExistsAt index: Int) {
        while buffer.lines.count <= index {
            buffer.lines.append("")
        }
    }

    public func logoEngineDidRequestSaveUndoSnapshot(_ engine: LogoEngine) {
        saveUndoSnapshot()
    }

    public func logoEngineDidRequestClampCursor(_ engine: LogoEngine) {
        buffer.clampCursor()
    }

    public func logoEngine(_ engine: LogoEngine, didRequestInsertText text: String) {
        buffer.insertString(text)
    }

    public func logoEngineDidRequestInsertNewline(_ engine: LogoEngine) {
        buffer.insertNewline()
    }

    public func logoEngine(_ engine: LogoEngine, didRequestSetStatusMessage message: String) {
        setStatusMessage(message)
    }

    public func logoEngineDidRequestDelete(_ engine: LogoEngine) {
        buffer.delete()
    }

    public func logoEngineDidRequestBackspace(_ engine: LogoEngine) {
        buffer.backspace()
    }

    public func logoEngineDidRequestDeleteLine(_ engine: LogoEngine) {
        buffer.deleteLine()
    }

    public func logoEngine(_ engine: LogoEngine, didRequestMoveCursorVirtual deltaRow: Int) {
        moveCursorVirtual(deltaRow: deltaRow)
    }

    public func logoEngine(_ engine: LogoEngine, didRequestDispatchCommand command: LogoEditorCommand) {
        switch command {
        case .moveLeft: _ = commandRegistry.dispatch(id: .moveLeft, editor: self)
        case .moveRight: _ = commandRegistry.dispatch(id: .moveRight, editor: self)
        case .moveHome: _ = commandRegistry.dispatch(id: .moveHome, editor: self)
        case .moveEnd: _ = commandRegistry.dispatch(id: .moveEnd, editor: self)
        case .editMark: _ = commandRegistry.dispatch(id: .editMark, editor: self)
        case .editCut: _ = commandRegistry.dispatch(id: .editCut, editor: self)
        case .editUncut: _ = commandRegistry.dispatch(id: .editUncut, editor: self)
        case .editJustify: _ = commandRegistry.dispatch(id: .editJustify, editor: self)
        }
    }

    public func logoEngine(_ engine: LogoEngine, didRequestSearch query: String) {
        performSearch(query: query)
    }

    public func logoEngineDidMarkBufferModified(_ engine: LogoEngine) {
        buffer.isModified = true
    }

    public func logoEngine(_ engine: LogoEngine, didApplySetting setting: String, arg: String) {
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
