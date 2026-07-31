import Foundation

public struct BufferCommandBarCommand: CommandBarCommand {
    public let name = "buffer"
    public let help = "buffer [next|prev|N]"

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard !input.firstTokenIsAllUppercaseWord else { return false }
        return input.lowerFirstToken == "buffer"
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        let arg = input.rest.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch arg {
        case "":
            editor.setStatusMessage(
                String(format: L10n["status.buffer_position"], editor.currentBufferIndex + 1, editor.buffers.count))
        case "next":
            _ = editor.commandRegistry.dispatch(id: .bufferNext, editor: editor)
        case "prev", "previous":
            _ = editor.commandRegistry.dispatch(id: .bufferPrev, editor: editor)
        default:
            guard let oneBasedIndex = Int(arg) else {
                editor.setStatusMessage(L10n["status.no_such_buffer"])
                return .handled
            }
            _ = editor.switchToBuffer(oneBasedIndex: oneBasedIndex, reportInvalid: true)
        }
        return .handled
    }
}
