import Foundation

public struct PrevBufferCommand: Command {
    public let id: CommandID = .bufferPrev
    public let name = "Previous Buffer"
    public let description = "Switch to previous open buffer"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.prevBuffer()
        return .succeeded
    }
}

public struct NextBufferCommand: Command {
    public let id: CommandID = .bufferNext
    public let name = "Next Buffer"
    public let description = "Switch to next open buffer"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.nextBuffer()
        return .succeeded
    }
}

public struct NewBufferCommand: Command {
    public let id: CommandID = .bufferNew
    public let name = "New Buffer"
    public let description = "Open a new buffer"
    public let commandBarAliases = ["new"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.openNewBuffer()
        return .succeeded
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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.nextBuffer()
        return .succeeded
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard let token = input.lowerFirstToken else { return .noOp }
        if token == "bnext" {
            editor.nextBuffer()
            return .succeeded
        }
        if token == "bprev" {
            editor.prevBuffer()
            return .succeeded
        }

        let arg = input.rest.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch arg {
        case "":
            return .succeeded(
                message: String(
                    format: editor.l10n["status.buffer_position"], editor.currentBufferIndex + 1, editor.buffers.count))
        case "next":
            editor.nextBuffer()
        case "prev", "previous":
            editor.prevBuffer()
        default:
            guard let oneBasedIndex = Int(arg) else {
                return .succeeded(message: editor.l10n["status.no_such_buffer"])
            }
            _ = editor.switchToBuffer(oneBasedIndex: oneBasedIndex, reportInvalid: true)
        }
        return .succeeded
    }
}
