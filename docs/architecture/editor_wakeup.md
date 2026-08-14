# Editor Wakeup and External Request Dispatch

This document explains how `zago` wakes the interactive editor loop when work
arrives from an external thread, such as the JSON-RPC IPC server.

## Problem

The interactive editor loop owns the mutable editor model. IPC worker threads
must not mutate buffers, cursor state, proposal queues, or renderer state
directly. Instead, they enqueue a closure for the editor loop and wait for that
closure to run.

The complication is that the editor loop spends most of its time blocked inside
`terminal.readKey()` waiting for keyboard input:

```swift
while isRunning {
    drainExternalRequests()
    refreshScreen()
    let key = terminal.readKey()
    drainExternalRequests()
    processKey(key)
}
```

Without a wakeup path, a JSON-RPC request can be parsed successfully by the IPC
server but then time out while waiting for the editor loop to drain the queued
operation. This is the source of `408 Editor request timed out`.

## Ownership Model

External editor operations follow this path:

1. An IPC connection reads a line-delimited JSON-RPC request.
2. `ZagoIPCServer` parses and dispatches the request.
3. `ZagoEditorIPCSession` converts the request into an editor operation.
4. `Editor.performOnEditorLoop` enqueues that operation.
5. `terminal.wakeup()` interrupts a blocked `readKey()`.
6. The editor loop drains the queued operation on the editor thread.
7. The IPC thread receives the result and returns the JSON-RPC response.

The important invariant is that editor state changes still happen on the editor
loop. `wakeup()` only makes the loop run sooner; it does not perform the editor
operation itself.

## `performOnEditorLoop`

`Editor.performOnEditorLoop` has two modes:

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

If the caller is already on the editor loop, or if the editor is not running
interactively, the operation runs immediately. Otherwise the operation is queued,
the terminal is woken, and the caller waits for the editor loop to execute it.

The timeout is intentionally short. A timeout means the transport worked, but
the editor loop did not drain the request quickly enough.

## POSIX Wakeup

On macOS and Linux, `PosixTerminal` uses a non-blocking pipe:

- The read end is included in the `poll()` set alongside `STDIN_FILENO`.
- `wakeup()` writes one byte to the pipe.
- `readByte()` consumes the byte and returns `nil`.
- `readKey()` returns `.unknown`, allowing the editor loop to continue.

This is a self-pipe wakeup. It does not inject terminal text and cannot appear
in the user buffer.

## Windows Wakeup

On Windows, `WindowsTerminal` reads interactive input from the console input
buffer using `ReadConsoleInputW`. The Windows implementation wakes that blocked
read by writing a synthetic key event to the same console input buffer:

```swift
public func wakeup() {
    wakeupLock.lock()
    wakeupRequested = true
    wakeupLock.unlock()

    let hInput = GetStdHandle(DWORD(bitPattern: -10))
    guard hInput != INVALID_HANDLE_VALUE, hInput != nil else { return }

    var record = INPUT_RECORD()
    record.EventType = WORD(KEY_EVENT)
    record.Event.KeyEvent.bKeyDown = true
    record.Event.KeyEvent.wRepeatCount = 1
    record.Event.KeyEvent.wVirtualKeyCode = 0
    record.Event.KeyEvent.wVirtualScanCode = 0
    record.Event.KeyEvent.uChar.UnicodeChar = 0
    record.Event.KeyEvent.dwControlKeyState = 0

    var written: DWORD = 0
    _ = WriteConsoleInputW(hInput, &record, 1, &written)
}
```

The synthetic event uses a NUL character (`UnicodeChar = 0`). The reader checks
the paired `wakeupRequested` flag before normal key handling:

```swift
let unit = keyEvent.uChar.UnicodeChar
if unit == 0, consumeWakeupRequest() {
    return nil
}
guard unit != 0 else {
    continue
}
```

This prevents the wakeup event from being interpreted as user input. The event
only breaks the blocking `ReadConsoleInputW` wait so control can return to the
editor loop.

## Why a Flag Is Needed

The NUL input event is internal, but ordinary console input can also contain key
events with no Unicode character, such as modifier or navigation events. The
`wakeupRequested` flag distinguishes a deliberate wakeup from unrelated
zero-character console events.

If a zero-character event is not paired with `wakeupRequested`, the reader keeps
scanning for real input. If it is paired, the reader consumes exactly one wakeup
and returns to the editor loop.

The flag is protected by `NSLock` because `wakeup()` can be called from an IPC
worker thread while `readKey()` runs on the editor thread.

## Failure Mode

If `wakeup()` is missing or does not unblock the active terminal read:

- `zago.client.register` can still succeed because registration is handled by
  the IPC server itself.
- editor-facing methods such as `zago.buffer.getBuffers`,
  `zago.buffer.getCursor`, or `zago.overlay.showPreview` enqueue work and then
  wait.
- the editor loop remains blocked in `readKey()`.
- the IPC response becomes `408 Editor request timed out`.

This means a `408` from editor-facing JSON-RPC methods is evidence that the IPC
transport reached the editor boundary, not that the named pipe or socket failed.

## Testing

`IPCServerTests.testExternalEditorRequestWakesBlockedTerminal` covers the core
contract:

1. Start a short editor loop with a terminal stub whose `readKey()` blocks.
2. Call `performOnEditorLoop` from an external thread.
3. Assert that `terminal.wakeup()` is called.
4. Let `readKey()` return after wakeup.
5. Assert that the queued editor operation runs and mutates the buffer.

Runtime smoke testing should additionally start `zago --ipc`, connect to the
published socket or named pipe, register a client, and verify that editor-facing
JSON-RPC methods such as `zago.buffer.getBuffers` and
`zago.overlay.showPreview` return successful responses instead of `408`.

## Design Rules

- Do not mutate editor state directly from IPC worker threads.
- Keep wakeup events invisible to the buffer and undo history.
- Wakeup should be best-effort and idempotent; multiple wakeups may collapse
  into one loop turn.
- Platform-specific wakeup logic belongs in the terminal driver, behind
  `EditorTerminal.wakeup()`.
- A successful wakeup only guarantees that the editor loop can run; the queued
  editor operation still owns validation, proposal limits, and buffer rules.
