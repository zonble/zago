import Foundation
import Testing

@testable import Editor

@Suite(.serialized)
struct DirectoryBufferTests {

    @Test func testDirectoryBufferInitializationAndFormatting() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("subfolder")
        let hiddenSubDir = workDir.appendingPathComponent(".hidden-folder")
        let fileURL = workDir.appendingPathComponent("notes.md")
        let hiddenFileURL = workDir.appendingPathComponent(".gitignore")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: hiddenSubDir, withIntermediateDirectories: true)
        try "# Notes".write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)
        try "*.swp".write(to: hiddenFileURL, atomically: testAtomicallyOption, encoding: .utf8)
        let editor = Editor(
            options: EditorOptions(filePaths: [workDir.path], autoReload: false),
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        let buffer = editor.buffer
        #expect(buffer is DirectoryBuffer)
        #expect(buffer.isDirectoryBuffer == true)
        #expect(buffer.isReadOnly == true)
        #expect(buffer.allowsLogoExecution == false)

        let dirBuffer = try #require(buffer as? DirectoryBuffer)
        let l10n = L10n()
        #expect(dirBuffer.lines.count >= 5)
        #expect(dirBuffer.lines[0].contains(l10n["dirbuf.header_directory"].replacingOccurrences(of: "%@", with: "")))
        #expect(dirBuffer.lines[3] == "  \(l10n.dirBufUpDir)")

        // Contains subfolder and file
        #expect(dirBuffer.lines.contains("  ▸ subfolder/"))
        #expect(dirBuffer.lines.contains("  ▸ .hidden-folder/"))
        #expect(dirBuffer.lines.contains("  notes.md"))
        #expect(dirBuffer.lines.contains("  .gitignore"))
    }

    @Test func testDirectoryBufferTraditionalChineseLocalization() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_tc_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workDir) }

        let fileIO = TestLocalEditorFileIOStrategy.shared
        let dirBuffer = DirectoryBuffer(directoryPath: workDir.path, fileIO: fileIO, language: .zh_TW)
        let l10n = L10n(language: .zh_TW)

        #expect(dirBuffer.lines.count >= 4)
        #expect(dirBuffer.lines[0].contains("目錄:"))
        #expect(dirBuffer.lines[1] == l10n.dirBufHeaderInstructions)
        #expect(dirBuffer.lines[3] == "  \(l10n.dirBufUpDir)")
    }

    @Test func testDirectoryBufferNavigationAndFileOpening() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_nav_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("subfolder")
        let fileURL = workDir.appendingPathComponent("target.txt")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "Target file content".write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)
        let editor = Editor(filePath: workDir.path)
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }
        #expect(editor.buffer is DirectoryBuffer)

        let dirBuffer = try #require(editor.buffer as? DirectoryBuffer)

        // Find line index for subfolder
        if let idx = dirBuffer.lines.firstIndex(where: { $0.hasSuffix("▸ subfolder/") }) {
            dirBuffer.lineIndex = idx
            let handled = dirBuffer.activateEntry(editor: editor)
            #expect(handled == true)
            #expect(dirBuffer.directoryPath.hasSuffix("subfolder"))
        } else {
            Issue.record("Expected ▸ subfolder/ line in directory buffer")
        }

        // Navigate up
        let upHandled = dirBuffer.navigateUp(editor: editor)
        #expect(upHandled == true)
        #expect(dirBuffer.directoryPath == workDir.path)

        // Open target.txt
        if let fileIdx = dirBuffer.lines.firstIndex(where: { $0.hasSuffix("target.txt") }) {
            dirBuffer.lineIndex = fileIdx
            let fileHandled = dirBuffer.activateEntry(editor: editor)
            #expect(fileHandled == true)
            // Editor should now have opened target.txt as a TextBuffer
            #expect(editor.buffer.isDirectoryBuffer == false)
            #expect(editor.buffer.lines.first == "Target file content")
        } else {
            Issue.record("Expected   target.txt line in directory buffer")
        }
    }

    @Test func testDirAndLsCommandBarCommands() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let editor = Editor()
        defer { editor.stopFileWatcherForCurrentBuffer() }
        let initialBufCount = editor.buffers.count

        let res = editor.commandBarRegistry.dispatch("dir \(tempDir.path)", editor: editor)
        #expect(res == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.isDirectoryBuffer == true)
        #expect(editor.buffers.count == initialBufCount + 1)

        // Running dir again while already in same directory buffer reuses buffer instead of creating duplicate
        let res2 = editor.commandBarRegistry.dispatch("ls \(tempDir.path)", editor: editor)
        #expect(res2 == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffers.count == initialBufCount + 1)

        let res3 = editor.commandBarRegistry.dispatch("DIR \(tempDir.path)", editor: editor)
        #expect(res3 == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffers.count == initialBufCount + 1)
    }

    @Test func testDirCommandNormalizesPathComponents() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_norm_\(UUID().uuidString)")
        let childDir = workDir.appendingPathComponent("child")
        let markerFile = workDir.appendingPathComponent("marker.txt")

        try FileManager.default.createDirectory(at: childDir, withIntermediateDirectories: true)
        try "marker".write(to: markerFile, atomically: testAtomicallyOption, encoding: .utf8)
        let editor = Editor()
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        let pathWithParentComponent = childDir.appendingPathComponent("..").path
        let res = editor.commandBarRegistry.dispatch("dir \(pathWithParentComponent)", editor: editor)

        #expect(res == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        let resolvedMarkerPath = URL(
            fileURLWithPath: (editor.buffer as? DirectoryBuffer)?.directoryPath ?? "",
            isDirectory: true
        )
        .appendingPathComponent("marker.txt")
        .path
        #expect(FileManager.default.fileExists(atPath: resolvedMarkerPath))
    }

    @Test func testDirWithoutPathFromFileBufferOpensParentDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_parent_\(UUID().uuidString)")
        let fileURL = workDir.appendingPathComponent("notes.md")

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        try "# Notes".write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)
        let editor = Editor(filePath: fileURL.path)
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }
        let res = editor.commandBarRegistry.dispatch("dir", editor: editor)

        #expect(res == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect((editor.buffer as? DirectoryBuffer)?.directoryPath == workDir.standardizedFileURL.path)
    }

    @Test func testDirCommandExpandsHomeDirectory() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let editor = Editor()
        defer { editor.stopFileWatcherForCurrentBuffer() }
        let res = editor.commandBarRegistry.dispatch("dir ~", editor: editor)

        #expect(res == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect((editor.buffer as? DirectoryBuffer)?.directoryPath == home.path)
    }

    @Test func testDirectoryBufferReadOnlyAndLogoBlock() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let editor = Editor(filePath: tempDir.path)
        defer { editor.stopFileWatcherForCurrentBuffer() }
        #expect(editor.buffer.isDirectoryBuffer == true)

        let initialLinesCount = editor.buffer.lines.count

        // Enter on empty line 2 does not insert a newline
        editor.buffer.lineIndex = 2
        let enterHandled = editor.buffer.handleKey(.enter, editor: editor)
        #expect(enterHandled == true)
        #expect(editor.buffer.lines.count == initialLinesCount)

        // Typing character in DirectoryBuffer returns true (handled) and blocks mutation
        let handledChar = editor.buffer.handleKey(.char("a"), editor: editor)
        #expect(handledChar == true)
        #expect(editor.statusMessage == editor.l10n["status.directory_buffer_readonly"])

        // Evaluating LOGO in DirectoryBuffer is blocked
        editor.evalLogoCode()
        #expect(editor.statusMessage == editor.l10n["status.directory_buffer_readonly"])
    }

    @Test func testDirectoryBufferBinaryFileBlockingAndMenuVisibility() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_bin_\(UUID().uuidString)")
        let binFile = workDir.appendingPathComponent("app.bin")

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE])
        try binaryData.write(to: binFile)
        let editor = Editor(filePath: workDir.path)
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }
        #expect(editor.buffer is DirectoryBuffer)

        let dirBuffer = try #require(editor.buffer as? DirectoryBuffer)
        if let idx = dirBuffer.lines.firstIndex(where: { $0.contains("app.bin") }) {
            dirBuffer.lineIndex = idx
            dirBuffer.activateEntry(editor: editor)
            #expect(editor.statusMessage == editor.l10n["status.cannot_open_binary_file"])
            #expect(editor.buffer.isDirectoryBuffer == true)
        } else {
            Issue.record("Expected app.bin entry in directory buffer")
        }

        // Verify mode toggle menu items are hidden in Directory Mode
        editor.menuBar.updateCategories(for: editor)
        let editCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
        #expect(editCategory != nil)
        let modeItems = editCategory?.items.filter {
            ["menu.edit.text_editing_mode", "menu.edit.canvas_mode", "menu.edit.table_editing_mode"].contains(
                $0.titleKey)
        }
        #expect(modeItems?.isEmpty == true)
    }

    @Test func testDirectoryBufferSelectedLineInverseRendering() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_render_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("folder_a")
        let fileURL = workDir.appendingPathComponent("file_b.txt")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "Content".write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)
        let editor = Editor(filePath: workDir.path)
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }
        #expect(editor.buffer is DirectoryBuffer)

        let dirBuffer = try #require(editor.buffer as? DirectoryBuffer)
        // Line 3 is '.. (up a dir)'
        dirBuffer.lineIndex = 3
        let outputLine3 = editor.renderer.render(editor: editor, rows: 12, cols: 60)
        #expect(outputLine3.contains("\u{1B}[7m"))
        // Check that inverse style extends with padding spaces
        #expect(outputLine3.contains(" \u{1B}[0m") || outputLine3.contains(" \u{1B}[27m"))

        // Move to folder_a
        if let folderIdx = dirBuffer.lines.firstIndex(where: { $0.contains("folder_a") }) {
            dirBuffer.lineIndex = folderIdx
            let outputFolder = editor.renderer.render(editor: editor, rows: 12, cols: 60)
            #expect(outputFolder.contains("\u{1B}[7m"))
            #expect(outputFolder.contains("folder_a"))
        } else {
            Issue.record("Expected folder_a in directory buffer")
        }
    }

    @Test func testDirectoryBufferPreservesViewportWhenExitingFileBuffer() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_viewport_\(UUID().uuidString)")
        let fileURL = workDir.appendingPathComponent("sample.txt")

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        let longText = (1...100).map { "Line \($0)" }.joined(separator: "\n")
        try longText.write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)
        let editor = Editor(filePath: workDir.path)
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }
        #expect(editor.buffer is DirectoryBuffer)
        let dirBuffer = try #require(editor.buffer as? DirectoryBuffer)
        #expect(dirBuffer.topVLineIndex == 0)

        // Find and open sample.txt
        if let idx = dirBuffer.lines.firstIndex(where: { $0.contains("sample.txt") }) {
            dirBuffer.lineIndex = idx
            let initialDirLineIndex = dirBuffer.lineIndex
            dirBuffer.activateEntry(editor: editor)
            #expect(editor.buffer.isDirectoryBuffer == false)

            // Scroll down in sample.txt
            editor.buffer.lineIndex = 50
            editor.adjustViewport(mainAreaHeight: 20, textWidth: 80)
            #expect(editor.topVLineIndex > 0)

            // Close sample.txt to return to directory buffer
            editor.closeCurrentBuffer()
            #expect(editor.buffer is DirectoryBuffer)
            #expect(editor.buffer.lineIndex == initialDirLineIndex)
            #expect(editor.topVLineIndex == 0)
        } else {
            Issue.record("Expected sample.txt in directory buffer")
        }
    }

    @Test func testDirCommandInNonExistentDirectoryFallsBackToExistingParent() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let baseDir = tempDir.appendingPathComponent("test_base_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: baseDir) }

        let nonExistentSubDir = baseDir.appendingPathComponent("non_existent_journal")
        let nonExistentFile = nonExistentSubDir.appendingPathComponent("today.md")

        let editor = Editor(
            options: EditorOptions(filePaths: [nonExistentFile.path], autoReload: false),
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )
        defer { editor.stopFileWatcherForCurrentBuffer() }

        #expect(editor.buffer.filePath == nonExistentFile.path)

        // Invoke :dir
        editor.openDirectoryBuffer(path: nil)

        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.isDirectoryBuffer == true)
        let dirBuf = try #require(editor.buffer as? DirectoryBuffer)
        #expect(dirBuf.directoryPath == baseDir.path)
    }

    @Test func testDirectoryBufferKeyNavigation() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_keys_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("sub")
        let file1 = workDir.appendingPathComponent("a.txt")
        let file2 = workDir.appendingPathComponent("b.txt")

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "a".write(to: file1, atomically: testAtomicallyOption, encoding: .utf8)
        try "b".write(to: file2, atomically: testAtomicallyOption, encoding: .utf8)

        let fileIO = TestLocalEditorFileIOStrategy.shared
        let dirBuf = DirectoryBuffer(directoryPath: workDir.path, fileIO: fileIO)
        let editor = Editor(
            options: EditorOptions(filePaths: [workDir.path], autoReload: false),
            dependencies: EditorDependencies(
                fileIOStrategy: fileIO,
                terminal: TestEditorTerminal.shared
            )
        )
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        dirBuf.lineIndex = 3 // Set cursor to line 3 (".. (up a dir)")

        // Down arrow moves to next entry
        let handledDown = dirBuf.handleKey(.arrowDown, editor: editor)
        #expect(handledDown == true)
        #expect(dirBuf.lineIndex == 4)

        // 'j' key also moves down
        let handledJ = dirBuf.handleKey(.char("j"), editor: editor)
        #expect(handledJ == true)
        #expect(dirBuf.lineIndex == 5)

        // 'k' key moves up
        let handledK = dirBuf.handleKey(.char("k"), editor: editor)
        #expect(handledK == true)
        #expect(dirBuf.lineIndex == 4)

        // Up arrow moves up, but not above line 3
        _ = dirBuf.handleKey(.arrowUp, editor: editor)
        #expect(dirBuf.lineIndex == 3)
        _ = dirBuf.handleKey(.arrowUp, editor: editor)
        #expect(dirBuf.lineIndex == 3)
    }

    @Test func testDirectoryBufferDisablesSoftwrap() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_wrap_\(UUID().uuidString)")
        let fileURL = workDir.appendingPathComponent("doc.txt")

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        try "Long content".write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)

        let fileIO = TestLocalEditorFileIOStrategy.shared
        let editor = Editor(
            options: EditorOptions(filePaths: [fileURL.path], wrapColumn: 80, autoReload: false),
            dependencies: EditorDependencies(
                fileIOStrategy: fileIO,
                terminal: TestEditorTerminal.shared
            )
        )
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        // Initially in doc.txt with wrapColumn 80
        #expect(editor.buffer.isDirectoryBuffer == false)
        #expect(editor.layoutEngine.wrapColumn == 80)

        // Open directory buffer
        editor.openDirectoryBuffer(path: workDir.path)
        #expect(editor.buffer.isDirectoryBuffer == true)
        #expect(editor.buffer.viewWrapColumn == nil)
        #expect(editor.layoutEngine.wrapColumn == nil)

        // Switch back to doc.txt
        editor.switchToBuffer(index: 0)
        #expect(editor.buffer.isDirectoryBuffer == false)
        #expect(editor.layoutEngine.wrapColumn == 80)
    }
}
