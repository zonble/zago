import Foundation

public struct WriteCommandBarCommand: CommandBarCommand {
    public let name = "write"
    public let help = "write [path]"
    public let completionNames = ["write", "w", ":w"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return first == "write" || first == "w" || first == ":w"
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        if input.rest.isEmpty {
            editor.saveBuffer(path: nil)
        } else {
            editor.writeBuffer(path: input.rest)
        }
        return .handled
    }
}
