import Foundation

public enum EditorLoopRequestError: Error, Equatable {
    case timedOut
}

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
        pending.forEach { $0() }
    }
}

#if !os(WASI)
    import Dispatch

    final class EditorLoopRequest<Result> {
        private enum State: Equatable { case pending, executing, completed, cancelled }

        private let lock = NSLock()
        private let semaphore = DispatchSemaphore(value: 0)
        private let operation: () -> Result
        private var state: State = .pending
        private var result: Result?

        init(operation: @escaping () -> Result) {
            self.operation = operation
        }

        func execute() {
            lock.lock()
            guard state == .pending else {
                lock.unlock()
                return
            }
            state = .executing
            lock.unlock()

            let value = operation()

            lock.lock()
            result = value
            state = .completed
            lock.unlock()
            semaphore.signal()
        }

        func wait(timeout: TimeInterval) throws -> Result {
            if semaphore.wait(timeout: .now() + timeout) == .success {
                lock.lock()
                defer { lock.unlock() }
                return result!
            }

            lock.lock()
            if state == .pending {
                state = .cancelled
            }
            lock.unlock()
            throw EditorLoopRequestError.timedOut
        }
    }
#endif
