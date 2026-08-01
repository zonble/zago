import Foundation

public struct OpenCommandBarCommand: CommandBarCommand {
    public let name = "open"
    public let help = "open <path>"
    public let completionNames = ["edit", "open", "e", ":e"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return first == "open" || first == "edit" || first == "e" || first == ":e"
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        guard !input.rest.isEmpty else {
            editor.setStatusMessage(L10n["status.path_required"])
            return .handled
        }

        editor.openBuffer(path: input.rest)
        return .handled
    }
}
