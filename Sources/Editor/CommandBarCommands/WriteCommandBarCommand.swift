import Foundation

public struct WriteCommandBarCommand: CommandBarCommand {
    public let name = "write"
    public let help = "write <path>"

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return first == "write"
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        guard !input.rest.isEmpty else {
            editor.setStatusMessage(L10n["status.path_required"])
            return .handled
        }

        editor.writeBuffer(path: input.rest)
        return .handled
    }
}
