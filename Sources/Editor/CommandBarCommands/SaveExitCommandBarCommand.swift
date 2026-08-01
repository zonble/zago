import Foundation

public struct SaveExitCommandBarCommand: CommandBarCommand {
    public let name = "wq"
    public let help = "wq [path] or x"
    public let completionNames = ["file", "save-exit", "save_exit", "saveexit", "wq", ":wq", "wq!", ":wq!", "x", ":x"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return ["file", "save-exit", "save_exit", "saveexit", "wq", ":wq", "wq!", ":wq!", "x", ":x"].contains(first)
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        guard let first = input.lowerFirstToken else { return .noMatch }
        let targetPath = input.rest.isEmpty ? nil : input.rest

        if first == "x" || first == ":x" {
            if editor.buffer.isModified {
                editor.saveAndCloseBuffer(path: targetPath)
            } else {
                editor.closeCurrentBuffer()
            }
        } else {
            editor.saveAndCloseBuffer(path: targetPath)
        }
        return .handled
    }
}
