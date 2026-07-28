import Foundation
import LogoEngine

extension Editor: LogoEditorContext {
    public var lineIndex: Int {
        get { buffer.lineIndex }
        set { buffer.lineIndex = newValue }
    }

    public var columnIndex: Int {
        get { buffer.columnIndex }
        set { buffer.columnIndex = newValue }
    }

    public var lineCount: Int {
        buffer.lines.count
    }

    public func clampCursor() {
        buffer.clampCursor()
    }

    public func insertString(_ text: String) {
        buffer.insertString(text)
    }

    public func insertNewline() {
        buffer.insertNewline()
    }

    public func delete() {
        buffer.delete()
    }

    public func backspace() {
        buffer.backspace()
    }

    public func getLine(at index: Int) -> String {
        guard index >= 0 && index < buffer.lines.count else { return "" }
        return buffer.lines[index]
    }

    public func setLine(at index: Int, text: String) {
        if index >= 0 && index < buffer.lines.count {
            buffer.lines[index] = text
        }
    }

    public func ensureLineExists(at index: Int) {
        while buffer.lines.count <= index {
            buffer.lines.append("")
        }
    }

    public func markBufferModified() {
        buffer.isModified = true
    }

    public func applySetting(_ setting: String, arg: String) {
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

    public func dispatchCommand(_ command: LogoEditorCommand) {
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
}
