import Foundation
import Testing
import TextEncoding
@testable import Editor

@Suite struct CoordinatorTests {
    final class MockFileIOStrategy: EditorFileIOStrategy, @unchecked Sendable {
        var watchedPath: String?
        var changeHandler: (@Sendable () -> Void)?

        func startWatchingFile(at path: String, onChange: @escaping @Sendable () -> Void) {
            watchedPath = path
            changeHandler = onChange
        }

        func stopWatchingFile(at path: String) {
            if watchedPath == path {
                watchedPath = nil
                changeHandler = nil
            }
        }

        func homeDirectoryPath() -> String { "/home/user" }
        func currentDirectoryPath() -> String { "/work" }
        func parentDirectory(of path: String) -> String { "/" }
        func childPath(_ name: String, in directory: String) -> String { directory + "/" + name }
        func normalizePath(_ path: String, isDirectory: Bool) -> String { path }
        func fileInfo(at path: String) -> EditorFileInfo { EditorFileInfo(exists: true, isDirectory: false) }
        func readTextFile(at path: String) throws -> TextReadResult { TextReadResult(content: "", encoding: .utf8) }
        func writeTextFile(_ content: String, to path: String, encoding: String.Encoding) throws {}
        func listDirectory(at path: String) throws -> [EditorDirectoryEntry] { [] }
    }

    @Test func testFileWatcherCoordinatorLifecycle() {
        final class TestState: @unchecked Sendable {
            var triggered = false
        }
        let state = TestState()
        let mock = MockFileIOStrategy()
        let coordinator = FileWatcherCoordinator(fileIOStrategy: mock)

        coordinator.startWatching(path: "/path/to/watched.txt") {
            state.triggered = true
        }

        #expect(coordinator.currentWatchedPath == "/path/to/watched.txt")
        #expect(mock.watchedPath == "/path/to/watched.txt")

        mock.changeHandler?()
        #expect(state.triggered == true)

        coordinator.stopWatching()
        #expect(coordinator.currentWatchedPath == nil)
        #expect(mock.watchedPath == nil)
    }

    @Test func testClipboardCoordinatorClear() {
        let clipboard = ClipboardCoordinator()
        clipboard.clipboardText = "copied text"
        clipboard.lastMutationTime = Date()
        clipboard.lastIsPaste = true

        #expect(clipboard.clipboardText == "copied text")
        #expect(clipboard.lastIsPaste == true)

        clipboard.clear()
        #expect(clipboard.clipboardText == nil)
        #expect(clipboard.lastMutationTime == nil)
        #expect(clipboard.lastIsPaste == false)
    }
}
