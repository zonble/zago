# Testing Guidelines & Best Practices for `zago`

This document defines testing conventions and mandatory guidelines for human developers and AI coding assistants working on the `zago` codebase.

---

## ⚠️ Critical Rule: Always Use `UUID().uuidString` for Temporary Test Files

### 1. The Windows File Sharing Restriction (`Win32Error code 32`)

On Windows, the Win32 file system enforces strict file handle locking semantics. If a test uses a hardcoded static temporary file name (such as `"test_gen_.serc"` or `"test_file.txt"`):

1. Concurrent test execution (Swift Testing parallel runner) may attempt to open, write, or delete the exact same file path simultaneously.
2. Windows File Watchers, antivirus scanners, or OS indexers holding transient open file handles will trigger a **Win32 Error 32 (`ERROR_SHARING_VIOLATION`)**:
   > `The process cannot access the file because it is being used by another process.`

### 2. Mandatory Requirement for AI Agents & Developers

**ANY temporary file created during unit tests MUST incorporate a `UUID().uuidString` to guarantee absolute path uniqueness across concurrent test runs:**

#### ❌ Incorrect (Will fail intermittently on Windows CI):
```swift
// DO NOT USE hardcoded static file names in temporary directory
let tmpPath = FileManager.default.temporaryDirectory
    .appendingPathComponent("test_gen_.serc").path
```

#### ✅ Correct:
```swift
// ALWAYS use UUID().uuidString for temporary test paths
let tmpPath = FileManager.default.temporaryDirectory
    .appendingPathComponent("test_gen_\(UUID().uuidString).serc").path
```

---

## Additional Unit Testing Rules

### 1. Proper Resource Teardown
Always register file cleanup in a `defer` block immediately after defining temporary file paths or instantiating file watchers:

```swift
let tmpPath = FileManager.default.temporaryDirectory
    .appendingPathComponent("test_editor_\(UUID().uuidString).txt").path
defer {
    editor.stopFileWatcherForCurrentBuffer()
    try? FileManager.default.removeItem(atPath: tmpPath)
}
```

### 2. Use Mock / Strategy Classes for Headless Tests
- For pure editor state and buffer tests, prefer `MemoryEditorFileIOStrategy` or `TestLocalEditorFileIOStrategy.shared`.
- Pass `language: .zh_TW` or `language: .en` explicitly when testing localized strings or UI modals to prevent reliance on the host OS `LANG` environment variable.
