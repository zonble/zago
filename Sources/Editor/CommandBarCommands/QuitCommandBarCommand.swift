import Foundation

public struct QuitCommandBarCommand: CommandBarCommand {
    public let name = "quit"
    public let help = "quit [!]"
    public let completionNames = ["close", "exit", "quit", "q", ":q", "q!", ":q!"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return ["close", "exit", "quit", "q", ":q", "q!", ":q!"].contains(first)
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        guard let first = input.lowerFirstToken else { return .noMatch }
        if first == "q!" || first == ":q!" {
            editor.closeCurrentBuffer()
        } else {
            if editor.buffer.isModified {
                editor.promptExitSaveConfirm()
            } else {
                editor.closeCurrentBuffer()
            }
        }
        return .handled
    }
}
