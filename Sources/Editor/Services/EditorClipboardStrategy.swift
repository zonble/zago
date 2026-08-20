import Foundation

/// Defines the strategy for reading and writing text and canvas block clipboard data.
public protocol EditorClipboardStrategy: AnyObject, Sendable {
    func copyText(_ text: String)
    func copyBlock(_ block: CanvasBlockClipboard)
    func getText() -> String?
    func getBlock() -> CanvasBlockClipboard?
    func clear()
}

/// In-memory clipboard strategy used by default for headless operations and standalone Editor testing.
public final class InMemoryClipboardStrategy: EditorClipboardStrategy, @unchecked Sendable {
    private var inMemoryText: String? = nil
    private var inMemoryBlock: CanvasBlockClipboard? = nil
    private let lock = NSLock()

    public init() {}

    public func copyText(_ text: String) {
        lock.lock()
        defer { lock.unlock() }
        inMemoryText = text
    }

    public func copyBlock(_ block: CanvasBlockClipboard) {
        lock.lock()
        defer { lock.unlock() }
        inMemoryBlock = block
    }

    public func getText() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return inMemoryText
    }

    public func getBlock() -> CanvasBlockClipboard? {
        lock.lock()
        defer { lock.unlock() }
        return inMemoryBlock
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        inMemoryText = nil
        inMemoryBlock = nil
    }
}
