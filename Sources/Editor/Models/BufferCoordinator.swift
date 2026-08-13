/// Owns the editor's buffer collection and active-buffer index.
///
/// `Editor` still exposes compatibility accessors for existing commands and
/// tests, but index clamping and active-buffer replacement live here.
final class BufferCoordinator {
    private var storage: [TextBuffer]
    private var activeIndexStorage: Int = 0

    init(buffers: [TextBuffer]) {
        self.storage = buffers.isEmpty ? [TextBuffer()] : buffers
    }

    var buffers: [TextBuffer] {
        get { storage }
        set {
            storage = newValue.isEmpty ? [TextBuffer()] : newValue
            activeIndexStorage = clampedIndex(activeIndexStorage)
        }
    }

    var activeIndex: Int {
        get {
            activeIndexStorage = clampedIndex(activeIndexStorage)
            return activeIndexStorage
        }
        set {
            activeIndexStorage = clampedIndex(newValue)
        }
    }

    var activeBuffer: TextBuffer {
        get {
            storage[activeIndex]
        }
        set {
            storage[activeIndex] = newValue
        }
    }

    var count: Int { storage.count }

    func appendAndActivate(_ buffer: TextBuffer) {
        storage.append(buffer)
        activeIndexStorage = storage.count - 1
    }

    @discardableResult
    func removeActive() -> Bool {
        guard storage.count > 1 else { return false }
        storage.remove(at: activeIndex)
        activeIndexStorage = clampedIndex(activeIndexStorage)
        return true
    }

    func nextIndex() -> Int? {
        guard storage.count > 1 else { return nil }
        return (activeIndex + 1) % storage.count
    }

    func previousIndex() -> Int? {
        guard storage.count > 1 else { return nil }
        return (activeIndex - 1 + storage.count) % storage.count
    }

    func isValidIndex(_ index: Int) -> Bool {
        index >= 0 && index < storage.count
    }

    private func clampedIndex(_ index: Int) -> Int {
        guard !storage.isEmpty else { return 0 }
        return max(0, min(index, storage.count - 1))
    }
}
