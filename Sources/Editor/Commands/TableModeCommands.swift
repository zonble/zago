import Foundation

public struct SwitchTextModeCommand: Command {
    public let id: CommandID = .textMode
    public let name = "Text Editing Mode"
    public let description = "Switch to Text Editing Mode"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        editor.switchToTextMode()
    }
}

public struct ToggleCanvasModeCommand: Command {
    public let id: CommandID = .canvasToggle
    public let name = "Canvas Mode"
    public let description = "Toggle Canvas Mode"
    public let keys: [Key] = [.f7, .alt("v"), .alt("V")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.toggleCanvasMode()
    }
}

public struct ToggleTableModeCommand: Command {
    public let id: CommandID = .tableToggle
    public let name = "Table Mode"
    public let description = "Toggle Table Mode for active cell"
    public let keys: [Key] = [.f8, .alt("t"), .alt("T")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.toggleTableMode()
    }
}

public struct CycleBorderStyleCommand: Command {
    public let id: CommandID = .borderStyle
    public let name = "Cycle Border Style"
    public let description =
        "Switch default border style (Single -> Double -> Round -> Double Round -> ASCII -> Markdown)"
    public let keys: [Key] = [.alt("s"), .alt("S")]

    public init() {}

    public func execute(on editor: Editor) {
        switch editor.defaultBorderStyle {
        case .single:
            editor.defaultBorderStyle = .double
            editor.setStatusMessage(L10n.defaultBorder("Double Unicode (╔═║)"))
        case .double:
            editor.defaultBorderStyle = .round
            editor.setStatusMessage(L10n.defaultBorder("Round Unicode (╭─│)"))
        case .round:
            editor.defaultBorderStyle = .doubleRound
            editor.setStatusMessage(L10n.defaultBorder("Double Round Unicode (╭═║)"))
        case .doubleRound:
            editor.defaultBorderStyle = .ascii
            editor.setStatusMessage(L10n.defaultBorder("ASCII (+-|)"))
        case .ascii:
            editor.defaultBorderStyle = .asciiRound
            editor.setStatusMessage(L10n.defaultBorder("ASCII Rounded (/-\\|)"))
        case .asciiRound:
            editor.defaultBorderStyle = .single
            editor.setStatusMessage(L10n.defaultBorder("Single Unicode (┌─│)"))
        }
    }
}
