import Editor
import Foundation

internal final class FallbackClipboardBackend: EditorClipboardStrategy, @unchecked Sendable {
    private var inMemoryText: String? = nil
    private var inMemoryBlock: CanvasBlockClipboard? = nil
    private let lock = NSLock()

    init() {}

    func copyText(_ text: String) {
        lock.lock()
        defer { lock.unlock() }
        inMemoryText = text
    }

    func copyBlock(_ block: CanvasBlockClipboard) {
        lock.lock()
        defer { lock.unlock() }
        inMemoryBlock = block
    }

    func getText() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return inMemoryText
    }

    func getBlock() -> CanvasBlockClipboard? {
        lock.lock()
        defer { lock.unlock() }
        return inMemoryBlock
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        inMemoryText = nil
        inMemoryBlock = nil
    }
}
