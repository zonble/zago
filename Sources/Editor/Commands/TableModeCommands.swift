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

public struct CycleTableStyleCommand: Command {
    public let id: CommandID = .tableStyle
    public let name = "Cycle Table Style"
    public let description = "Switch default table style (Single -> Double -> Round -> ASCII -> Markdown)"
    public let keys: [Key] = [.alt("s"), .alt("S")]

    public init() {}

    public func execute(on editor: Editor) {
        switch editor.defaultTableBorderStyle {
        case .single:
            editor.defaultTableBorderStyle = .double
            editor.setStatusMessage("[ Default Table Style: Double Unicode (╔═║) ]")
        case .double:
            editor.defaultTableBorderStyle = .round
            editor.setStatusMessage("[ Default Table Style: Round Unicode (╭─│) ]")
        case .round:
            editor.defaultTableBorderStyle = .ascii
            editor.setStatusMessage("[ Default Table Style: ASCII (+-|) ]")
        case .ascii:
            editor.defaultTableBorderStyle = .markdown
            editor.setStatusMessage("[ Default Table Style: Markdown (|---|) ]")
        case .markdown:
            editor.defaultTableBorderStyle = .single
            editor.setStatusMessage("[ Default Table Style: Single Unicode (┌─│) ]")
        }
    }
}
