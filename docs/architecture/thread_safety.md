# Thread Safety & Concurrency Guide

This document outlines the thread-safety architecture, synchronization primitives, shared service designs, and data-race prevention guidelines across `zago`.

---

## 1. Concurrency Architecture Overview

`zago` employs a **hybrid concurrency model**:
- **Single-Writer Main Event Loop**: The interactive editor thread exclusively owns all buffer contents, cursor positions, selection state, undo history, renderer line caches, and UI mode state.
- **Concurrent Background Services**: Asynchronous tasks—such as IPC client requests, file system watchers, subprocess Git diff computations, and syntax highlighters—execute on dedicated background dispatch queues and worker threads.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Interactive Main Thread (UI Loop)                     │
│                                                                             │
│  • Buffer & Line Storage      • Cursor / Selection     • Double-Buffer Diff │
│  • Undo / Redo Snapshots      • Viewport Layout        • Proposal Queues    │
└──────────────────────────────────────▲──────────────────────────────────────┘
                                       │
                        performOnEditorLoop() + wakeup()
                                       │
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                    Shared Services & Background Workers                     │
│                                                                             │
│  • GitService (NSRecursiveLock)        • FileWatcher (Darwin/Win/Poll)      │
│  • GitCoordinator (NSRecursiveLock)    • ZagoIPCServer (Concurrent GCD)     │
│  • ClipboardCoordinator (NSLock)       • LayoutEngine Caches (NSLock)       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Shared Services & Thread Safety Guarantees

When background threads and the main UI loop access shared services concurrently, the services must guarantee internal thread safety without relying on the caller's execution context.

### 2.1 `GitService` & Cache Protection

`GitService` detects Git repository roots, branch names, and computes `HEAD` line diffs. Because `computeDiffAsync` offloads git execution to a background queue while `refreshScreen()` may synchronously query `detectRepository()` or `computeDiffSync()` on the main thread, all internal caches are protected by an `NSRecursiveLock`.

#### Protected State:
- `repoRootCache: [String: String]` (Path to repository root)
- `branchCache: [String: String]` (Branch name per repo root)
- `headCache: [String: [String]]` (Cached file contents at `HEAD`)
- `repositoryStateCache: [String: RepositoryState]` (HEAD file modification timestamps and sizes)

```swift
public final class GitService: GitServiceProtocol, @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var repoRootCache: [String: String] = [:]
    private var headCache: [String: [String]] = [:]
    
    public func detectRepository(for filePath: String?) -> GitRepositoryInfo? {
        lock.withLock {
            // Safe concurrent cache lookup and disk traversal
            if let cached = repoRootCache[pathToInspect] { return cached }
            ...
        }
    }
}
```

> **Why `NSRecursiveLock`?**
> In Swift, standard Swift `Dictionary` and `Array` instances are value types that use Copy-on-Write (CoW). Concurrent reads and writes across threads without locking corrupt the internal hash table metadata, causing memory corruption and immediate `EXC_BREAKPOINT` / `SIGTRAP` aborts during ARC retain/release or dictionary re-hashing. `NSRecursiveLock` allows nested calls (such as `computeDiffSync` invoking `detectRepository`) on the same thread without self-deadlock.

---

### 2.2 `GitCoordinator`

`GitCoordinator` bridges between editor buffers and `GitService`. It tracks dirty flags and current diff state:

- **State Protected by Lock**: `_currentDiffInfo` and `_isDirty`.
- **Thread Safety**: Thread-safe getters/setters via `lock.withLock`, enabling safe access when file watchers mark dirty from background queues.

---

### 2.3 `FileWatcher` & External Change Handling

`FileWatcher` listens to OS file-system notifications:
- **Darwin**: Uses `DispatchSourceFileSystemObject` on `DispatchQueue(label: "com.se.filewatcher.darwin")`.
- **Windows**: Uses Win32 `ReadDirectoryChangesW` / `WaitForMultipleObjects`.
- **Linux / Fallback**: Uses background polling.

#### Safe Notification Dispatch:
Background file watcher callbacks **never mutate editor buffers directly**. Instead, they dispatch changes back to the editor loop:

```swift
fileWatcherCoordinator.startWatching(path: buffer.filePath) { [weak self] in
    guard let self = self else { return }
    _ = try? self.performOnEditorLoop {
        guard self.displayConfig.autoReload else { return }
        self.handleExternalFileChange()
    }
}
```

---

## 3. Communication Bridge: `performOnEditorLoop`

To prevent data races on mutable editor state, background threads submit operations to `EditorLoopRequestQueue` via `Editor.performOnEditorLoop`:

```swift
public func performOnEditorLoop<T>(timeout: TimeInterval = 0.5, _ operation: @escaping () -> T) throws -> T {
    // 1. Fast path: if already on editor loop or in headless mode
    if !isInteractiveMode || Thread.current === editorLoopThread {
        return operation()
    }

    // 2. Enqueue request safely to thread-safe queue (protected by NSLock)
    let request = EditorLoopRequest(operation: operation)
    editorLoopRequests.enqueue {
        request.execute()
    }

    // 3. Wake up blocking readKey() via terminal self-pipe / Win32 console event
    terminal.wakeup()

    // 4. Await synchronous completion with bounded timeout
    return try request.wait(timeout: timeout)
}
```

---

## 4. Deadlock Prevention & System Call Guidelines

1. **Terminal Wakeup (Self-Pipe / Win32)**:
   - `terminal.readKey()` blocks in `poll()` or `ReadConsoleInputW`.
   - Calling `terminal.wakeup()` writes a byte to the self-pipe (`0x00`) or queues a synthetic NUL console event to unblock immediately.
2. **Process Pipe Buffer Drain**:
   - When spawning subprocesses (e.g. `git`), always read `pipe.fileHandleForReading.readDataToEndOfFile()` **before** calling `process.waitUntilExit()`. Reversing this order deadlocks when process stdout exceeds the 64KB OS pipe buffer.
3. **No Lock Inversion**:
   - Never hold a low-level service lock (e.g., `GitService.lock`) while calling `performOnEditorLoop` (which waits on the main thread). Always acquire locks in a hierarchical top-down order.

---

## 5. Rules for `@unchecked Sendable` Types

Classes marked `@unchecked Sendable` in `zago` must satisfy at least one of these criteria:
1. **Immutable state**: All properties are `let` constants initialized at construction.
2. **Mutex synchronization**: All mutable fields are private and strictly accessed within `NSLock.withLock` / `NSRecursiveLock.withLock`.
3. **Actor / Thread Confinement**: Documented to be confined strictly to the interactive `editorLoopThread` (e.g. `Buffer`, `Editor`).

---

## 6. Verification & Concurrency Testing

All concurrent services must be covered by multi-threaded unit tests:
- `Tests/GitCoordinatorTests.swift`: Verifies concurrent Git diff computation and dirty flag invalidation.
- `Tests/EditorEngineTests.swift`: Tests cross-thread `performOnEditorLoop` operations and timeout handling.
- `Tests/RealFileWatcherAtomicWritesTests.swift`: Verifies atomic file replaces and background watcher event coalescing.
