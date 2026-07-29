import Foundation

public struct ToggleTableModeCommand: Command {
    public let id: CommandID = .tableToggle
    public let name = "Table Mode"
    public let description = "Toggle Table Mode for active cell"
    public let keys: [Key] = [.alt("t"), .alt("T")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.toggleTableMode()
    }
}

public struct CycleBorderStyleCommand: Command {
    public let id: CommandID = .borderStyle
    public let name = "Cycle Border Style"
    public let description = "Switch default border style (Single -> Double -> Round -> Double Round -> ASCII -> Markdown)"
    public let keys: [Key] = [.alt("s"), .alt("S")]

    public init() {}

    public func execute(on editor: Editor) {
        switch editor.defaultBorderStyle {
        case .single:
            editor.defaultBorderStyle = .double
            editor.setStatusMessage("[ Default Border Style: Double Unicode (╔═║) ]")
        case .double:
            editor.defaultBorderStyle = .round
            editor.setStatusMessage("[ Default Border Style: Round Unicode (╭─│) ]")
        case .round:
            editor.defaultBorderStyle = .doubleRound
            editor.setStatusMessage("[ Default Border Style: Double Round Unicode (╭═║) ]")
        case .doubleRound:
            editor.defaultBorderStyle = .ascii
            editor.setStatusMessage("[ Default Border Style: ASCII (+-|) ]")
        case .ascii:
            editor.defaultBorderStyle = .markdown
            editor.setStatusMessage("[ Default Border Style: Markdown (|---|) ]")
        case .markdown:
            editor.defaultBorderStyle = .single
            editor.setStatusMessage("[ Default Border Style: Single Unicode (┌─│) ]")
        }
    }
}
