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
        #expect(dirBuffer.lineIndex == 3)
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
        #expect(dirBuffer.directoryPath == editor.fileIOStrategy.normalizePath(workDir.path, isDirectory: true))

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
        #expect((editor.buffer as? DirectoryBuffer)?.directoryPath == editor.fileIOStrategy.normalizePath(workDir.path, isDirectory: true))
    }

    @Test func testDirCommandExpandsHomeDirectory() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let editor = Editor()
        defer { editor.stopFileWatcherForCurrentBuffer() }
        let res = editor.commandBarRegistry.dispatch("dir ~", editor: editor)

        #expect(res == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect((editor.buffer as? DirectoryBuffer)?.directoryPath == editor.fileIOStrategy.normalizePath(home.path, isDirectory: true))
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

        #expect(editor.buffer.filePath == editor.fileIOStrategy.normalizePath(nonExistentFile.path, isDirectory: false))

        // Invoke :dir
        editor.openDirectoryBuffer(path: nil)

        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.isDirectoryBuffer == true)
        let dirBuf = try #require(editor.buffer as? DirectoryBuffer)
        #expect(dirBuf.directoryPath == editor.fileIOStrategy.normalizePath(baseDir.path, isDirectory: true))
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

    @Test func testDirectoryBufferDoubleClickOpensFolderAndFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_dblclick_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("docs")
        let fileURL = workDir.appendingPathComponent("hello.txt")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "Hello World".write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)

        let editor = Editor(filePath: workDir.path)
        editor.displayConfig.enableMouse = true
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        #expect(editor.buffer is DirectoryBuffer)
        let dirBuf = try #require(editor.buffer as? DirectoryBuffer)

        // Find docs folder row
        guard let docsIdx = dirBuf.lines.firstIndex(where: { $0.contains("docs") }) else {
            Issue.record("Expected docs folder in directory buffer")
            return
        }

        // 1. Single click on docs row: updates lineIndex
        let docsMouseRow = 2 + docsIdx // topMargin (1) + 1 + docsIdx
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: docsMouseRow))
        #expect(editor.buffer.lineIndex == docsIdx)
        #expect(editor.buffer is DirectoryBuffer)

        // 2. Second click immediately (double click): enters docs folder
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: docsMouseRow))
        #expect(editor.buffer is DirectoryBuffer)
        let newDirBuf = try #require(editor.buffer as? DirectoryBuffer)
        #expect(newDirBuf.directoryPath == editor.fileIOStrategy.normalizePath(subDir.path, isDirectory: true))

        // 3. Double click on '.. (up a dir)' at index 3 (row 5)
        let upDirMouseRow = 2 + 3
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: upDirMouseRow))
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: upDirMouseRow))
        #expect(editor.buffer is DirectoryBuffer)
        let rootDirBuf = try #require(editor.buffer as? DirectoryBuffer)
        #expect(rootDirBuf.directoryPath == editor.fileIOStrategy.normalizePath(workDir.path, isDirectory: true))

        // 4. Double click on hello.txt to open file
        guard let fileIdx = rootDirBuf.lines.firstIndex(where: { $0.contains("hello.txt") }) else {
            Issue.record("Expected hello.txt in root directory buffer")
            return
        }
        let fileMouseRow = 2 + fileIdx
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: fileMouseRow))
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: fileMouseRow))

        // Buffer should now be the opened file
        #expect(editor.buffer.isDirectoryBuffer == false)
        #expect(editor.buffer.filePath == editor.fileIOStrategy.normalizePath(fileURL.path, isDirectory: false))
        #expect(editor.buffer.lines.joined(separator: "\n") == "Hello World")
    }

    @Test func testDirectoryBufferClickIntervalExpiresDoesNotActivate() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_dblclick_timeout_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("docs")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        let editor = Editor(filePath: workDir.path)
        editor.displayConfig.enableMouse = true
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        let dirBuf = try #require(editor.buffer as? DirectoryBuffer)
        guard let docsIdx = dirBuf.lines.firstIndex(where: { $0.contains("docs") }) else {
            Issue.record("Expected docs folder in directory buffer")
            return
        }

        let docsMouseRow = 2 + docsIdx
        // First click
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: docsMouseRow))
        #expect(editor.buffer is DirectoryBuffer)

        // Mock lastClickTime to simulate timeout (> 0.4s ago)
        editor.mouseClickTracker.lastClickTime = Date().addingTimeInterval(-1.0)

        // Second click after timeout: should register as a new single click, not activating the folder
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: docsMouseRow))
        #expect(editor.buffer is DirectoryBuffer)
        let sameDirBuf = try #require(editor.buffer as? DirectoryBuffer)
        #expect(sameDirBuf.directoryPath == editor.fileIOStrategy.normalizePath(workDir.path, isDirectory: true))
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

    @Test func testDirectoryBufferCursorNeverLessThanLineThree() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_clamp_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("folder1")
        let fileURL = workDir.appendingPathComponent("file1.txt")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "Content".write(to: fileURL, atomically: testAtomicallyOption, encoding: .utf8)

        let editor = Editor(filePath: workDir.path)
        editor.displayConfig.enableMouse = true
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        #expect(editor.buffer is DirectoryBuffer)
        // 1. Initial lineIndex must be 3 ('.. (up a dir)')
        #expect(editor.buffer.lineIndex == 3)
        #expect(editor.buffer.columnIndex == 0)

        // 2. Pressing Up Arrow should not move cursor above line 3
        editor.processKey(.arrowUp)
        #expect(editor.buffer.lineIndex == 3)

        // 3. Pressing Home or PageUp should remain at or above line 3
        editor.processKey(.home)
        #expect(editor.buffer.lineIndex == 3)
        editor.processKey(.pageUp)
        #expect(editor.buffer.lineIndex == 3)

        // 4. Clicking on top header lines (rows 2, 3, 4 which correspond to lines 0, 1, 2) should NOT select them
        let topHeaderMouseRow = 2 // line 0
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: topHeaderMouseRow))
        #expect(editor.buffer.lineIndex == 3)

        // 5. Down arrow moves down
        editor.processKey(.arrowDown)
        #expect(editor.buffer.lineIndex == 4)

        // 6. Up arrow moves back to 3
        editor.processKey(.arrowUp)
        #expect(editor.buffer.lineIndex == 3)

        // 7. Another up arrow is clamped to 3
        editor.processKey(.arrowUp)
        #expect(editor.buffer.lineIndex == 3)
    }

    @Test func testJournalDirectoryBufferOpening() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let journalDir = tempDir.appendingPathComponent("test_journal_dir_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: journalDir, withIntermediateDirectories: true)
        let note1 = journalDir.appendingPathComponent("2026_09_01.md")
        let note2 = journalDir.appendingPathComponent("2026_09_02.md")
        try "# 2026/09/01".write(to: note1, atomically: testAtomicallyOption, encoding: .utf8)
        try "# 2026/09/02".write(to: note2, atomically: testAtomicallyOption, encoding: .utf8)

        let editor = Editor(
            options: EditorOptions(journalFolder: journalDir.path),
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: journalDir)
        }

        let normalizedJournalPath = TestLocalEditorFileIOStrategy.shared.normalizePath(journalDir.path, isDirectory: true)

        // 1. Direct API call
        editor.openJournalDirectory()
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.filePath == normalizedJournalPath)
        let dirBuf = try #require(editor.buffer as? DirectoryBuffer)
        #expect(dirBuf.lines.contains("  2026_09_01.md"))
        #expect(dirBuf.lines.contains("  2026_09_02.md"))

        // 2. CommandBar: :journal dir
        editor.closeCurrentBuffer()
        submitCommandBar("journal dir", editor: editor)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.filePath == normalizedJournalPath)

        // 3. CommandBar: :dir journal
        editor.closeCurrentBuffer()
        submitCommandBar("dir journal", editor: editor)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.filePath == normalizedJournalPath)

        // 4. CommandBar: :journals
        editor.closeCurrentBuffer()
        submitCommandBar("journals", editor: editor)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.filePath == normalizedJournalPath)
    }

    @Test func testDirectoryBufferSortingByNameAndDates() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_sort_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

        let fileA = workDir.appendingPathComponent("a_first.txt")
        let fileB = workDir.appendingPathComponent("b_middle.txt")
        let fileC = workDir.appendingPathComponent("c_last.txt")

        try "A".write(to: fileA, atomically: testAtomicallyOption, encoding: .utf8)
        Thread.sleep(forTimeInterval: 0.05)
        try "B".write(to: fileB, atomically: testAtomicallyOption, encoding: .utf8)
        Thread.sleep(forTimeInterval: 0.05)
        try "C".write(to: fileC, atomically: testAtomicallyOption, encoding: .utf8)

        let editor = Editor(filePath: workDir.path)
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        let dirBuf = try #require(editor.buffer as? DirectoryBuffer)

        // Default: Name ASC
        #expect(dirBuf.sortOption.field == .name)
        #expect(dirBuf.sortOption.order == .ascending)
        let entriesNameAsc = dirBuf.lines.filter { $0.hasSuffix(".txt") }
        #expect(entriesNameAsc == ["  a_first.txt", "  b_middle.txt", "  c_last.txt"])

        // Set Name DESC
        dirBuf.setSortOption(DirectorySortOption(field: .name, order: .descending), editor: editor)
        let entriesNameDesc = dirBuf.lines.filter { $0.hasSuffix(".txt") }
        #expect(entriesNameDesc == ["  c_last.txt", "  b_middle.txt", "  a_first.txt"])

        // Set Modified DESC
        dirBuf.setSortOption(DirectorySortOption(field: .modificationDate, order: .descending), editor: editor)
        let entriesModDesc = dirBuf.lines.filter { $0.hasSuffix(".txt") }
        #expect(entriesModDesc == ["  c_last.txt", "  b_middle.txt", "  a_first.txt"])

        // Set Modified ASC
        dirBuf.setSortOption(DirectorySortOption(field: .modificationDate, order: .ascending), editor: editor)
        let entriesModAsc = dirBuf.lines.filter { $0.hasSuffix(".txt") }
        #expect(entriesModAsc == ["  a_first.txt", "  b_middle.txt", "  c_last.txt"])
    }

    @Test func testDirectoryBufferInteractiveSortKeysAndCommandBar() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_sort_keys_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        try "1".write(to: workDir.appendingPathComponent("apple.txt"), atomically: testAtomicallyOption, encoding: .utf8)
        try "2".write(to: workDir.appendingPathComponent("banana.txt"), atomically: testAtomicallyOption, encoding: .utf8)

        let editor = Editor(filePath: workDir.path)
        defer {
            editor.stopFileWatcherForCurrentBuffer()
            try? FileManager.default.removeItem(at: workDir)
        }

        let dirBuf = try #require(editor.buffer as? DirectoryBuffer)
        #expect(dirBuf.sortOption.field == .name && dirBuf.sortOption.order == .ascending)

        // Press 's' to cycle sort
        editor.processKey(.char("s"))
        #expect(dirBuf.sortOption.field == .name && dirBuf.sortOption.order == .descending)

        // Press 'o' to toggle order
        editor.processKey(.char("o"))
        #expect(dirBuf.sortOption.field == .name && dirBuf.sortOption.order == .ascending)

        // Command bar :sort modified desc
        submitCommandBar("sort modified desc", editor: editor)
        #expect(dirBuf.sortOption.field == .modificationDate && dirBuf.sortOption.order == .descending)

        // Command bar :sort created asc
        submitCommandBar("sort created asc", editor: editor)
        #expect(dirBuf.sortOption.field == .creationDate && dirBuf.sortOption.order == .ascending)
    }

    @Test func testDirectoryBufferSortModeVisibilityInTitleBarAndStatus() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let editor = Editor(filePath: tempDir.path)
        defer { editor.stopFileWatcherForCurrentBuffer() }

        #expect(editor.buffer.isDirectoryBuffer == true)
        let modeIndicator = editor.modeIndicatorText()
        #expect(modeIndicator.contains("Sort") || modeIndicator.contains("排序"))

        let titleLine = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
        #expect(titleLine.contains("Sort") || titleLine.contains("排序"))
    }

    private func submitCommandBar(_ text: String, editor: Editor) {
        editor.promptLogoMacro()
        for ch in text {
            editor.processKey(.char(ch))
        }
        editor.processKey(.enter)
    }
}


