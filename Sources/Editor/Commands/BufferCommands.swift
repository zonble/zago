import Foundation

struct PrevBufferCommand: Command {
    let id: CommandID = .bufferPrev
    let name = "Previous Buffer"
    let description = "Switch to previous open buffer"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.prevBuffer()
        return .succeeded
    }
}

struct NextBufferCommand: Command {
    let id: CommandID = .bufferNext
    let name = "Next Buffer"
    let description = "Switch to next open buffer"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.nextBuffer()
        return .succeeded
    }
}

struct NewBufferCommand: Command {
    let id: CommandID = .bufferNew
    let name = "New Buffer"
    let description = "Open a new buffer"
    let commandBarAliases = ["new"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.openNewBuffer()
        return .succeeded
    }
}

struct BufferCommand: Command {
    let id: CommandID = .bufferNext
    let name = "Buffer"
    let description = "Buffer management (next, prev, N)"
    let commandBarAliases: [String] = ["buffer", "bnext", "bprev"]

    init() {}

    func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.nextBuffer()
        return .succeeded
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
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
