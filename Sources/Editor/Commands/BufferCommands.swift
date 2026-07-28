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

    public init() {}

    public func execute(on editor: Editor) {
        editor.openNewBuffer()
    }
}
