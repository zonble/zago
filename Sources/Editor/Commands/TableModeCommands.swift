import Foundation

public struct SwitchTextModeCommand: Command {
    public let id: CommandID = .textMode
    public let name = "Text Editing Mode"
    public let description = "Switch to Text Editing Mode"
    public let keys: [Key] = []
    public let commandBarAliases = ["text-mode"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.switchToTextMode()
        return .succeeded
    }
}

public struct ToggleCanvasModeCommand: Command {
    public let id: CommandID = .canvasToggle
    public let name = "Canvas Mode"
    public let description = "Toggle Canvas Mode"
    public let keys: [Key] = [.f8, .alt("v"), .alt("V")]
    public let commandBarAliases = ["canvas-mode"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleCanvasMode()
        return .succeeded
    }
}

public struct ToggleTableModeCommand: Command {
    public let id: CommandID = .tableToggle
    public let name = "Table Mode"
    public let description = "Toggle Table Mode for active cell"
    public let keys: [Key] = [.f7, .alt("t"), .alt("T")]
    public let commandBarAliases = ["table-mode"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.toggleTableMode()
        return .succeeded
    }
}

public struct CycleBorderStyleCommand: Command {
    public let id: CommandID = .borderStyle
    public let name = "Cycle Border Style"
    public let description =
        "Switch default border style (Single -> Heavy -> Double -> Round -> Double Round -> ASCII)"
    public let keys: [Key] = [.alt("s"), .alt("S")]
    public let commandBarAliases = ["border", "border-style"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        let message: String
        switch editor.defaultBorderStyle {
        case .single:
            editor.defaultBorderStyle = .heavy
            message = editor.l10n.defaultBorder("Heavy Unicode (┏━┃)")
        case .heavy:
            editor.defaultBorderStyle = .double
            message = editor.l10n.defaultBorder("Double Unicode (╔═║)")
        case .double:
            editor.defaultBorderStyle = .round
            message = editor.l10n.defaultBorder("Round Unicode (╭─│)")
        case .round:
            editor.defaultBorderStyle = .doubleRound
            message = editor.l10n.defaultBorder("Double Round Unicode (╭═║)")
        case .doubleRound:
            editor.defaultBorderStyle = .ascii
            message = editor.l10n.defaultBorder("ASCII (+-|)")
        case .ascii:
            editor.defaultBorderStyle = .asciiRound
            message = editor.l10n.defaultBorder("ASCII Rounded (/-\\|)")
        case .asciiRound:
            editor.defaultBorderStyle = .single
            message = editor.l10n.defaultBorder("Single Unicode (┌─│)")
        }
        return .succeeded(message: message)
    }
}
