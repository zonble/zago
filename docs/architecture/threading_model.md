# Threading Model & Concurrency Architecture

This document describes the concurrency architecture, thread ownership rules, and synchronization mechanisms across `zago`.

---

## 1. Core Architecture & Ownership Philosophy

`zago` is built around a **Single-Writer / Actor-style Editor Thread** model:

```
                      ┌──────────────────────────────────────────────┐
                      │             Editor Event Loop                │
                      │          (Interactive Main Thread)           │
                      │                                              │
                      │  • Owns Buffers, TextStorage, Lines          │
                      │  • Owns Cursor, Selection, Marks             │
                      │  • Owns Undo/Redo History                    │
                      │  • Owns Terminal Renderer & Screen Diff      │
                      │  • Owns AI Proposal Queue & Approvals        │
                      └─────────────▲──────────────────▲─────────────┘
                                    │                  │
               drainExternalRequests│                  │drainExternalRequests
                       & wakeup()   │                  │  & wakeup()
                                    │                  │
        ┌───────────────────────────┴────┐       ┌─────┴────────────────────────┐
        │       IPC Server Subsystem     │       │   File System Watcher &      │
        │    (Concurrent Worker Queues)  │       │   Debounced Workers (GCD)    │
        │                                │       │                              │
        │  • Socket / Named Pipe Accept  │       │  • File Modification Polling │
        │  • JSON-RPC 2.0 Parser         │       │  • Git HEAD Diff Debouncer   │
        │  • Client Session Management   │       │  • Spellchecker Fallback     │
        └────────────────────────────────┘       └──────────────────────────────┘
```

### Key Invariants

1. **Exclusive Editor Ownership**: All mutable editor data structures (buffer lines, cursor coordinates, selection ranges, undo snapshots, screen renderer cache, and proposal queues) are owned exclusively by the interactive editor thread (`editorLoopThread`).
2. **No Direct Background Mutation**: Background worker threads (IPC handlers, file watchers, Git diff debouncers) **must never directly mutate editor state**.
3. **Bridge via `performOnEditorLoop`**: External threads that need to query or update editor state must package operations as closures, enqueue them via `Editor.performOnEditorLoop`, wake up the editor thread, and wait for synchronous completion with a bounded timeout.

---

## 2. The Interactive Editor Event Loop

The editor lifecycle runs in `Editor.run()`:

```swift
while isRunning {
    drainExternalRequests()
    refreshScreen()
    let key = terminal.readKey()
    drainExternalRequests()
    if key == .resize {
        renderer.invalidateScreenCache()
        terminal.clearScreen()
        continue
    }
    processKey(key)
}
```

### Request Draining & Terminal Blocking

* Under normal operation, the editor thread spends the vast majority of its time blocked inside `terminal.readKey()`, waiting for user input.
* `drainExternalRequests()` is invoked **both before rendering and immediately after unblocking from `readKey()`**, ensuring that incoming external operations are processed promptly without adding latency to user keystrokes.

---

## 3. External Request Dispatch & Wakeup Mechanism

When an external thread (such as an IPC worker) needs editor access, it calls `Editor.performOnEditorLoop(timeout:_:)`:

```swift
public func performOnEditorLoop<T>(timeout: TimeInterval = 0.5, _ operation: @escaping () -> T) throws -> T {
    if !isInteractiveMode || Thread.current === editorLoopThread {
        return operation()
    }

    let request = EditorLoopRequest(operation: operation)
    editorLoopRequests.enqueue {
        request.execute()
    }
    terminal.wakeup()
    return try request.wait(timeout: timeout)
}
```

### Platform-Specific Wakeup Implementations

Because `terminal.readKey()` is a blocking system call, the terminal driver must provide an out-of-band wakeup mechanism:

1. **POSIX (macOS & Linux)**:
   * Uses a **self-pipe** (`pipe()`).
   * `readKey()` monitors both `STDIN_FILENO` and the self-pipe read descriptor via `poll()`.
   * `terminal.wakeup()` writes a single byte (`0x00`) to the pipe write end, instantly unblocking `poll()`.
   * The reader consumes the byte, returns `.unknown`, and the editor loop immediately executes `drainExternalRequests()`.

2. **Windows (Win32 Console Subsystem)**:
   * `WindowsTerminal` reads console events via blocking `ReadConsoleInputW`.
   * `terminal.wakeup()` sets an atomic/locked `wakeupRequested` flag and injects a synthetic `KEY_EVENT` record containing a NUL character (`UnicodeChar = 0`) via `WriteConsoleInputW`.
   * When `ReadConsoleInputW` unblocks on the NUL key event and verifies `consumeWakeupRequest() == true`, it discards the synthetic event without polluting the buffer or status line, allowing the editor loop to drain queued requests.

---

## 4. IPC Server & Worker Threading Architecture

`ZagoIPCServer` hosts the JSON-RPC 2.0 API over local IPC transports.

```
                  ┌─────────────────────────────────────┐
                  │      ZagoIPCServer.start()          │
                  │   Creates Session & Socket / Pipe   │
                  └──────────────────┬──────────────────┘
                                     │
                        queue.async  │ (Dedicated Listener Thread)
                                     ▼
                  ┌─────────────────────────────────────┐
                  │            acceptLoop()             │
                  │   Waits for Client Connections      │
                  └──────────────────┬──────────────────┘
                                     │
                        queue.async  │ (Concurrent Dispatch Queue)
                                     ▼
                  ┌─────────────────────────────────────┐
                  │     handleClientConnection()        │
                  │   Line-delimited JSON-RPC Worker    │
                  └──────────────────┬──────────────────┘
                                     │
               performOnEditorLoop() │ (Requires Editor Access)
                                     ▼
                  ┌─────────────────────────────────────┐
                  │    Editor Event Loop Dispatches     │
                  └─────────────────────────────────────┘
```

### Transport & Concurrency Details

* **Dispatch Queue**: Uses a concurrent `DispatchQueue(label: "org.zago.ipcserver", attributes: .concurrent)`.
* **Connection Slots**: Throttled using a `DispatchSemaphore(value: limits.maxConnections)`.
* **POSIX Unix Domain Sockets**:
  * Bound to `/tmp/zago-<pid>-<nonce>.sock`.
  * `acceptLoop` blocks on `accept()`. When `server.stop()` closes the listening file descriptor, `accept()` returns `EBADF`/`EINVAL` and exits cleanly.
* **Windows Named Pipes (`\\.\pipe\zago-<pid>-<nonce>`)**:
  * Created with `PIPE_NOWAIT` to prevent `ConnectNamedPipe` from permanently deadlocking in the kernel when stopping or during test teardown.
  * `waitForClientConnection` polls `ConnectNamedPipe` with a 10ms sleep while checking `isListening`.
  * Once a client connects, `SetNamedPipeHandleState` switches the handle to `PIPE_WAIT` mode so subsequent `ReadFile` / `WriteFile` operations execute synchronously and reliably.
  * When `stop()` sets `isListening = false`, the accept loop terminates within $\le 10\text{ ms}$, ensuring no leaked threads or hanging test runners.

---

## 5. Background File Watcher & Debounced Tasks

### 1. `FileWatcher`
* Runs background file modification detection (`DispatchSourceFileSystemObject` on Darwin, polling / `WaitForMultipleObjects` on Windows).
* Upon detecting file changes on disk, it invokes its callback on a background queue.
* The Editor dependencies verify modification times against in-memory timestamps and, if an external change is confirmed, schedule an auto-reload through the editor loop.

### 2. Debounced Git Diff Worker
* `GitService.computeDiffAsync` offloads `git diff` / `git status` subprocess execution to a background queue.
* Results are debounced so rapid cursor navigation never blocks the main UI thread, maintaining 0ms UI input latency.

### 3. Thread-Safe Viewport & Syntax Caches
* `LayoutEngine.lineCache`: Caches wrapped line segment calculations per line index to avoid redundant CJK width traversals.
* `SyntaxHighlighter.rowCache`: Thread-safe caching for line token arrays.

---

## 6. Concurrency Rules & Coding Standards

1. **Single Writer Rule**: Never access mutable properties of `Buffer`, `Editor`, `ProposalQueue`, or `Renderer` from background tasks without routing through `performOnEditorLoop`.
2. **Graceful Worker Shutdown**: Never block indefinitely in Win32 or POSIX system calls without a cancellation token, non-blocking polling, or explicit unblock notification.
3. **No Unsafe Handle Invalidation**: On Windows, do not call `CloseHandle` from thread A while thread B is actively blocked in a synchronous wait on that handle; use non-blocking accept loops or signal stop events first.
4. **Bounded Timeouts**: All cross-thread IPC invocations must have reasonable timeouts (default 0.5s–10.0s) so client failures return `408 Editor request timed out` rather than hanging the system.
5. **No Artificial Sleep Dependencies in Tests**: Unit tests must use event-driven hooks (`performOnEditorLoop`, `drainExternalRequests`, or `TestLocalEditorFileIOStrategy`) rather than arbitrary `Thread.sleep` calls.
