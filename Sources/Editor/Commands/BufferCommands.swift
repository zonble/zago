import Foundation

public struct PrevBufferCommand: Command {
    public let id: CommandID = .bufferPrev
    public let name = "Previous Buffer"
    public let description = "Switch to previous open buffer"
    public let keys: [Key] = [.alt(","), .alt("<")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.prevBuffer()
    }
}

public struct NextBufferCommand: Command {
    public let id: CommandID = .bufferNext
    public let name = "Next Buffer"
    public let description = "Switch to next open buffer"
    public let keys: [Key] = [.alt("."), .alt(">")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.nextBuffer()
    }
}

public struct NewBufferCommand: Command {
    public let id: CommandID = .bufferNew
    public let name = "New Buffer"
    public let description = "Open a new buffer"
    public let keys: [Key] = [.ctrl("N")]
    public let commandBarAliases = ["new"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.openNewBuffer()
    }
}

public struct BufferCommand: Command {
    public let id: CommandID = .bufferNext
    public let name = "Buffer"
    public let description = "Buffer management (next, prev, N)"
    public let commandBarAliases: [String] = ["buffer", "bnext", "bprev"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    public func execute(on editor: Editor) {
        editor.nextBuffer()
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        guard let token = input.lowerFirstToken else { return .noMatch }
        if token == "bnext" {
            editor.nextBuffer()
            return .handled
        }
        if token == "bprev" {
            editor.prevBuffer()
            return .handled
        }

        let arg = input.rest.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch arg {
        case "":
            editor.setStatusMessage(
                String(format: L10n["status.buffer_position"], editor.currentBufferIndex + 1, editor.buffers.count))
        case "next":
            editor.nextBuffer()
        case "prev", "previous":
            editor.prevBuffer()
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
