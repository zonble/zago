import Foundation

public struct DirCommandBarCommand: CommandBarCommand {
    public let name = "dir"
    public let help = "dir [path] or ls [path]"
    public let completionNames = ["dir", "ls"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return first == "dir" || first == "ls"
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        editor.openDirectoryBuffer(path: input.rest.isEmpty ? nil : input.rest)
        return .handled
    }
}
