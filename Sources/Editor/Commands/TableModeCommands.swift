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
