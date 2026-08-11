import Foundation

final class EditorLoopRequestQueue {
    private let lock = NSLock()
    private var requests: [() -> Void] = []

    func enqueue(_ request: @escaping () -> Void) {
        lock.lock()
        requests.append(request)
        lock.unlock()
    }

    func drain() {
        lock.lock()
        let pending = requests
        requests.removeAll(keepingCapacity: true)
        lock.unlock()

        for request in pending {
            request()
        }
    }
}

final class EditorLoopRequestResult<T> {
    var value: T?
    var completed = false
}
