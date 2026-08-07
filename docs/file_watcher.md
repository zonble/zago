# File System Watcher & External Modification Architecture (`FileWatcher`)

This document outlines the architecture, cross-platform mechanisms, atomic save recovery, and UI reload pipeline for external file modification watching in `zago`.

---

## 1. Overview & Architectural Decoupling

`zago` features automatic external file change detection (`autoReload`). To ensure that the `Editor` target remains **100% platform-agnostic** (without Windows WinSDK, C POSIX, or Darwin `kqueue` dependencies), file watching is decoupled using the `EditorFileIOStrategy` protocol:

```
┌───────────────────────────────────────────────────────────┐
│ Editor Target (Pure Swift, Platform-Agnostic)              │
│                                                           │
│  Editor.startFileWatcherForCurrentBuffer()                │
│       │                                                   │
│       ▼                                                   │
│  EditorFileIOStrategy.startWatchingFile(at:onChange:)     │
└───────────────────────────┬───────────────────────────────┘
                            │ (Protocol Interface)
┌───────────────────────────▼───────────────────────────────┐
│ zago Target (Desktop System Implementation)               │
│                                                           │
│  LocalEditorFileIOStrategy                                │
│       │                                                   │
│       ▼                                                   │
│  FileWatcher (Sources/zago/FileWatcher.swift)            │
│       ├── macOS: DispatchSource / kqueue (O_EVTONLY)       │
│       ├── Windows: Win32 FindFirstChangeNotificationW     │
│       └── Linux/Other: DispatchSourceTimer mtime polling  │
└───────────────────────────────────────────────────────────┘
```

---

## 2. Platform-Specific Watcher Implementations

`FileWatcher` utilizes native kernel event notifications on Darwin and Windows, falling back to lightweight `mtime` polling on Linux and POSIX platforms.

### 2.1 macOS (Darwin) - `DispatchSourceFileSystemObject`
- Opens a file descriptor using `open(path, O_EVTONLY)`. `O_EVTONLY` opens the file descriptor strictly for event monitoring without requesting read/write locks or modifying file access times.
- Listens for filesystem events: `[.write, .delete, .rename, .extend, .attrib]`.
- Dispatches events on a utility GCD background queue (`DispatchQueue(label: "com.se.filewatcher", qos: .utility)`).

### 2.2 Windows (Win32) - `FindFirstChangeNotificationW`
- Watches the parent directory of the target file via native WinSDK `FindFirstChangeNotificationW`.
- Monitored flags: `FILE_NOTIFY_CHANGE_LAST_WRITE`, `FILE_NOTIFY_CHANGE_SIZE`, `FILE_NOTIFY_CHANGE_FILE_NAME`.
- Executes a background monitoring loop calling `WaitForSingleObject(handle, 100)` to poll kernel signals without blocking the editor thread.
- Upon notification, compares the target file's `mtime` (`getModificationDate`) to filter out unrelated directory changes.

### 2.3 Linux & Non-Darwin Platforms - Timer Fallback
- Uses a `DispatchSourceTimer` scheduled every 0.5 seconds on a background queue.
- Polls `FileManager.default.attributesOfItem(atPath:)` for `.modificationDate` changes.

---

## 3. Atomic Save (Atomic Replace) Recovery Strategy

Modern text editors (VS Code, Vim, Xcode, TextEdit, Sublime) save files by **Atomic Replace**:
1. Write buffer to a temporary file (`path.tmp.123`).
2. Call `rename("path.tmp.123", "path")` to replace the target file atomically.

### The Inode Trap & Resolution
In BSD `kqueue` (macOS), an open file descriptor (`O_EVTONLY`) points to the **old file's inode**. When another editor performs an atomic rename, the old inode is unlinked, emitting `.rename` or `.delete` events to the existing descriptor.

`FileWatcher` handles atomic replace via `reopenWatchedFile(at:)`:

```swift
if events.contains(.delete) || events.contains(.rename) {
    // Atomic replace by external editor
    self.reopenWatchedFile(at: path)
}
```

1. **Descriptor Release**: Closes the unlinked `fileDescriptor` and cancels the previous `DispatchSource`.
2. **Settling Delay**: Schedules a `0.05s` delay (`asyncAfter`) to allow OS atomic rename locks to settle.
3. **Re-Open & Notify**: Re-opens `path` (binding to the new inode), updates `lastModificationDate`, and invokes `notifyChange()`.

---

## 4. Self-Save Suppression

When `zago` saves a file itself, `LocalEditorFileIOStrategy.writeTextFile` invokes:

```swift
fileWatcher.recordCurrentModificationDate()
```

This immediately updates `lastModificationDate` to match the newly written file's modification timestamp, preventing `FileWatcher` from triggering false-positive reload prompts for `zago`'s own save operations.

---

## 5. Reload & Screen Cache Invalidation Pipeline

When `FileWatcher` detects an external modification:

```
FileWatcher (Background Queue)
    │
    ▼ (DispatchQueue.main.async)
Editor.handleExternalFileChange()
    │
    ├── Buffer modified locally?
    │    ├── YES ──> Prompt user: [ confirmExternalReload ]
    │    └── NO  ──> Auto reload buffer: buffer.reloadFile()
    │
    ▼
renderer.invalidateScreenCache()  <-- Invalidates VT100 Screen Cache
    │
    ▼
Next Terminal Frame Render (Redraws newly reloaded text immediately)
```

By explicitly calling `renderer.invalidateScreenCache()`, `zago` ensures that external changes immediately update the terminal display without requiring manual keypresses or cursor movements.
