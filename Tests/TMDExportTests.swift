import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import zago
@testable import zagoweb

private final class MockTMDExportDelegate: TMDExportDelegate, @unchecked Sendable {
    var lastSourceText: String?
    var lastFormat: TMDExportFormat?
    var lastTargetPath: String?
    var shouldFail: Bool = false
    var isWAVExportSupported: Bool = true
    var mockShouldPromptForPath: Bool = true

    var shouldPromptForPath: Bool {
        mockShouldPromptForPath
    }

    func exportTMD(
        sourceText: String,
        format: TMDExportFormat,
        toPath targetPath: String
    ) throws {
        if shouldFail {
            throw TMDExportError.custom("Simulated export error")
        }
        lastSourceText = sourceText
        lastFormat = format
        lastTargetPath = targetPath
    }
}

@Suite(.serialized)
struct TMDExportTests {
    private func makeEditor(filePath: String?, delegate: any TMDExportDelegate = MockTMDExportDelegate()) -> Editor {
        let fileIO = TestLocalEditorFileIOStrategy.shared
        let terminal = TestEditorTerminal.shared
        let dependencies = EditorDependencies(
            fileIOStrategy: fileIO,
            terminal: terminal,
            tmdExportDelegate: delegate
        )
        let options = EditorOptions(filePaths: filePath.map { [$0] } ?? [])
        let editor = Editor(options: options, dependencies: dependencies)
        return editor
    }

    @Test func testTMDMenuVisibleOnlyForTMDFile() {
        let tmdEditor = makeEditor(filePath: "/path/to/song.tmd")
        tmdEditor.menuBar.updateCategories(for: tmdEditor)
        let hasTMD = tmdEditor.menuBar.categories.contains { $0.titleKey == "menu.tmd" }
        #expect(hasTMD)

        let nonTmdEditor = makeEditor(filePath: "/path/to/script.logo")
        nonTmdEditor.menuBar.updateCategories(for: nonTmdEditor)
        let hasTMDNonTmd = nonTmdEditor.menuBar.categories.contains { $0.titleKey == "menu.tmd" }
        #expect(!hasTMDNonTmd)
    }

    @Test func testTMDExportPromptAndExecution() {
        let mockDelegate = MockTMDExportDelegate()
        let editor = makeEditor(filePath: "/workspace/mysong.tmd", delegate: mockDelegate)
        editor.buffer.lines = [
            "::SCORE::",
            "** My Song **",
            "!= 120",
            "?= C",
            "<4/4>",
            "Intro:Piano@{ <4*> 1 2 3 4 }",
            "-> Intro ->#",
        ]

        // 1. Trigger export MIDI command
        _ = editor.commandRegistry.dispatch(id: .tmdExportMIDI, editor: editor)
        #expect(editor.promptController.isActive)
        #expect(editor.promptInputText == "/workspace/mysong.mid")

        // 2. Confirm default path by pressing Enter (^M)
        _ = editor.promptController.handleKey(.enter)
        #expect(!editor.promptController.isActive)
        #expect(mockDelegate.lastFormat == .midi)
        #expect(mockDelegate.lastTargetPath == "/workspace/mysong.mid")
        #expect(mockDelegate.lastSourceText?.contains("::SCORE::") == true)
        #expect(editor.statusMessage.contains("mysong.mid"))

        // 3. Trigger export MusicXML and edit target path
        _ = editor.commandRegistry.dispatch(id: .tmdExportMusicXML, editor: editor)
        #expect(editor.promptInputText == "/workspace/mysong.xml")
        editor.promptInputText = "/custom/path/score.xml"
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .musicxml)
        #expect(mockDelegate.lastTargetPath == "/custom/path/score.xml")

        // 4. Trigger export LilyPond
        _ = editor.commandRegistry.dispatch(id: .tmdExportLilyPond, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .lilypond)

        // 5. Trigger export ABC
        _ = editor.commandRegistry.dispatch(id: .tmdExportABC, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .abc)

        // 6. Trigger export WAV
        _ = editor.commandRegistry.dispatch(id: .tmdExportWAV, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .wav)
    }

    @Test func testTMDExportCancellation() {
        let mockDelegate = MockTMDExportDelegate()
        let editor = makeEditor(filePath: "/path/to/song.tmd", delegate: mockDelegate)

        _ = editor.commandRegistry.dispatch(id: .tmdExportMIDI, editor: editor)
        #expect(editor.promptController.isActive)

        _ = editor.promptController.handleKey(.esc)
        #expect(!editor.promptController.isActive)
        #expect(mockDelegate.lastFormat == nil)
    }

    @Test func testTMDExportErrorHandling() {
        let mockDelegate = MockTMDExportDelegate()
        mockDelegate.shouldFail = true
        let editor = makeEditor(filePath: "/path/to/song.tmd", delegate: mockDelegate)

        _ = editor.commandRegistry.dispatch(id: .tmdExportMIDI, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(editor.statusMessage.contains("Simulated export error"))
    }

    @Test func testTMDSnippetsInMenuAndInsertion() {
        let editor = makeEditor(filePath: "/path/to/song.tmd")
        editor.menuBar.updateCategories(for: editor)
        let tmdCategory = editor.menuBar.categories.first { $0.titleKey == "menu.tmd" }
        #expect(tmdCategory != nil)

        let snippetItem = tmdCategory?.items.first { $0.titleKey == "menu.tmd.snippet.score_template" }
        #expect(snippetItem != nil)

        // Test inserting snippet
        TMDSnippets.insertSnippet(TMDSnippets.fullScoreTemplate, into: editor)
        #expect(editor.buffer.isModified)
        #expect(editor.buffer.lines.joined(separator: "\n").contains("::SCORE::"))
        #expect(editor.buffer.lines.joined(separator: "\n").contains("Intro:Piano"))
        #expect(editor.statusMessage == editor.l10n["status.tmd_snippet_inserted"])
    }

    @Test func testTMDReferenceInHelpMenuAndContent() {
        let editor = makeEditor(filePath: "/path/to/song.tmd")
        editor.menuBar.updateCategories(for: editor)
        let helpCategory = editor.menuBar.categories.first { $0.titleKey == "menu.help" }
        #expect(helpCategory != nil)

        let refItem = helpCategory?.items.first { $0.commandId == .tmdReference }
        #expect(refItem != nil)

        let txtEditor = makeEditor(filePath: "/path/to/notes.txt")
        txtEditor.menuBar.updateCategories(for: txtEditor)
        let txtHelpCategory = txtEditor.menuBar.categories.first { $0.titleKey == "menu.help" }
        let txtRefItem = txtHelpCategory?.items.first { $0.commandId == .tmdReference }
        #expect(txtRefItem == nil)

        let enLines = TMDReferenceContent.lines(language: .en)
        #expect(enLines.joined(separator: "\n").contains("::SCORE::"))
        #expect(enLines.joined(separator: "\n").contains("Text Music Description"))
        #expect(enLines.joined(separator: "\n").contains("In memory of Chen, Chih-Han / aguai (阿怪, 1974–2019)."))

        let twLines = TMDReferenceContent.lines(language: .zh_TW)
        #expect(twLines.joined(separator: "\n").contains("::SCORE::"))
        #expect(twLines.joined(separator: "\n").contains("語法速查"))
        #expect(twLines.joined(separator: "\n").contains("In memory of Chen, Chih-Han / aguai (阿怪, 1974–2019)."))
    }

    @Test func testRealZagoTMDExporterWithSnippets() throws {
        let exporter = ZagoTMDExporter()
        let sourceText = TMDSnippets.fullScoreTemplate.templateText

        let tempDir = FileManager.default.temporaryDirectory
        let midiURL = tempDir.appendingPathComponent("test_export.mid")
        let xmlURL = tempDir.appendingPathComponent("test_export.xml")
        let lyURL = tempDir.appendingPathComponent("test_export.ly")
        let abcURL = tempDir.appendingPathComponent("test_export.abc")

        defer {
            try? FileManager.default.removeItem(at: midiURL)
            try? FileManager.default.removeItem(at: xmlURL)
            try? FileManager.default.removeItem(at: lyURL)
            try? FileManager.default.removeItem(at: abcURL)
        }

        try exporter.exportTMD(sourceText: sourceText, format: .midi, toPath: midiURL.path)
        #expect(FileManager.default.fileExists(atPath: midiURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .musicxml, toPath: xmlURL.path)
        #expect(FileManager.default.fileExists(atPath: xmlURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .lilypond, toPath: lyURL.path)
        #expect(FileManager.default.fileExists(atPath: lyURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .abc, toPath: abcURL.path)
        #expect(FileManager.default.fileExists(atPath: abcURL.path))
    }

    @Test func testInstantTMDExportWhenShouldPromptForPathIsFalse() {
        let mockDelegate = MockTMDExportDelegate()
        mockDelegate.mockShouldPromptForPath = false
        let editor = makeEditor(filePath: "/workspace/web_song.tmd", delegate: mockDelegate)
        editor.buffer.lines = [
            "::SCORE::",
            "** Web Song **",
            "!= 120",
            "?= C",
            "<4/4>",
            "Intro:Piano@{ <4*> 1 2 3 4 }",
            "-> Intro ->#",
        ]

        // 1. Dispatch TMD Export MIDI
        _ = editor.commandRegistry.dispatch(id: .tmdExportMIDI, editor: editor)

        // 2. Prompt controller should NOT be active since prompt was bypassed
        #expect(!editor.promptController.isActive)
        #expect(mockDelegate.lastFormat == .midi)
        #expect(mockDelegate.lastTargetPath == "/workspace/web_song.mid")
        #expect(editor.statusMessage.contains("web_song.mid"))
    }

    @Test func testWasiTMDExporterExecution() throws {
        let exporter = WasiTMDExporter()
        #expect(!exporter.shouldPromptForPath)
        #expect(!exporter.isWAVExportSupported)

        let sourceText = TMDSnippets.fullScoreTemplate.templateText
        let tempDir = FileManager.default.temporaryDirectory
        let midiURL = tempDir.appendingPathComponent("wasi_test.mid")
        let xmlURL = tempDir.appendingPathComponent("wasi_test.xml")
        let lyURL = tempDir.appendingPathComponent("wasi_test.ly")
        let abcURL = tempDir.appendingPathComponent("wasi_test.abc")

        defer {
            try? FileManager.default.removeItem(at: midiURL)
            try? FileManager.default.removeItem(at: xmlURL)
            try? FileManager.default.removeItem(at: lyURL)
            try? FileManager.default.removeItem(at: abcURL)
        }

        try exporter.exportTMD(sourceText: sourceText, format: .midi, toPath: midiURL.path)
        #expect(FileManager.default.fileExists(atPath: midiURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .musicxml, toPath: xmlURL.path)
        #expect(FileManager.default.fileExists(atPath: xmlURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .lilypond, toPath: lyURL.path)
        #expect(FileManager.default.fileExists(atPath: lyURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .abc, toPath: abcURL.path)
        #expect(FileManager.default.fileExists(atPath: abcURL.path))

        #expect(throws: TMDExportError.self) {
            try exporter.exportTMD(sourceText: sourceText, format: .wav, toPath: "/tmp/invalid.wav")
        }
    }
}
