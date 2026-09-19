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
    var mockIsPlaybackSupported: Bool = false
    var lastPlayedSourceText: String?
    var lastPlayedTitle: String?
    var lastNotifiedBufferPath: String?

    var shouldPromptForPath: Bool {
        mockShouldPromptForPath
    }

    var isPlaybackSupported: Bool {
        mockIsPlaybackSupported
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

    func playTMD(sourceText: String, title: String) throws {
        if shouldFail {
            throw TMDExportError.custom("Simulated playback error")
        }
        lastPlayedSourceText = sourceText
        lastPlayedTitle = title
    }

    func notifyActiveBuffer(filePath: String?) {
        lastNotifiedBufferPath = filePath
    }

    var lastFormattedSourceText: String?
    var lastCheckedSourceText: String?
    var lastInspectedSourceText: String?
    var mockIssues: [String] = []

    func formatTMD(sourceText: String) throws -> String {
        lastFormattedSourceText = sourceText
        return "// formatted\n" + sourceText
    }

    func checkTMD(sourceText: String) -> [String] {
        lastCheckedSourceText = sourceText
        return mockIssues
    }

    func inspectTMD(sourceText: String) throws -> String {
        lastInspectedSourceText = sourceText
        return "TMD Song Profile Report\n======================"
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

        // 7. Trigger export ChordPro
        _ = editor.commandRegistry.dispatch(id: .tmdExportChordPro, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .chordpro)

        // 8. Trigger export REAPER
        _ = editor.commandRegistry.dispatch(id: .tmdExportReaper, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .reaper)

        // 9. Trigger export UTAU
        _ = editor.commandRegistry.dispatch(id: .tmdExportUTAU, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .utau)

        // 10. Trigger export VSQX
        _ = editor.commandRegistry.dispatch(id: .tmdExportVSQX, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .vsqx)

        // 11. Trigger export VSQ
        _ = editor.commandRegistry.dispatch(id: .tmdExportVSQ, editor: editor)
        _ = editor.promptController.handleKey(.enter)
        #expect(mockDelegate.lastFormat == .vsq)
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

    @Test func testTMDPlayScoreCommandAndMenuVisibility() {
        let mockDelegate = MockTMDExportDelegate()
        mockDelegate.mockIsPlaybackSupported = false
        let editor = makeEditor(filePath: "/workspace/song.tmd", delegate: mockDelegate)

        // 1. When playback is not supported, menu.tmd.play should NOT appear
        editor.menuBar.updateCategories(for: editor)
        let tmdCat = editor.menuBar.categories.first { $0.titleKey == "menu.tmd" }
        #expect(tmdCat?.items.contains { $0.commandId == .tmdPlay } == false)

        // 2. When playback is supported (Web environment), menu.tmd.play should appear
        mockDelegate.mockIsPlaybackSupported = true
        editor.menuBar.updateCategories(for: editor)
        let tmdCatWeb = editor.menuBar.categories.first { $0.titleKey == "menu.tmd" }
        #expect(tmdCatWeb?.items.contains { $0.commandId == .tmdPlay } == true)

        // 3. Dispatch TMD Play command
        editor.buffer.lines = [
            "::SCORE::",
            "** Live Play **",
            "!= 120",
            "?= C",
            "<4/4>",
            "Intro:Piano@{ <4*> 1 2 3 4 }",
            "-> Intro ->#",
        ]
        _ = editor.commandRegistry.dispatch(id: .tmdPlay, editor: editor)
        #expect(mockDelegate.lastPlayedTitle == "song.tmd")
        #expect(mockDelegate.lastPlayedSourceText?.contains("::SCORE::") == true)
        #expect(editor.statusMessage.contains("song.tmd"))

        // 4. Buffer notification check
        #expect(
            mockDelegate.lastNotifiedBufferPath == "/workspace/song.tmd"
                || mockDelegate.lastNotifiedBufferPath == "\\workspace\\song.tmd"
        )
    }

    @Test func testWasiTMDExporterPlayAndNotifyBuffer() throws {
        let exporter = WasiTMDExporter()
        #expect(exporter.isPlaybackSupported)

        let sourceText = TMDSnippets.fullScoreTemplate.templateText
        try exporter.playTMD(sourceText: sourceText, title: "mysong.tmd")

        exporter.notifyActiveBuffer(filePath: "/workspace/mysong.tmd")
        exporter.notifyActiveBuffer(filePath: "/workspace/notes.txt")
    }

    @Test func testTMDCheckFormatAndInspectCommands() {
        let mockDelegate = MockTMDExportDelegate()
        let editor = makeEditor(filePath: "/workspace/test_score.tmd", delegate: mockDelegate)
        editor.buffer.lines = [
            "::SCORE::",
            "** Check Me **",
            "!= 120",
            "?= C",
            "<4/4>",
            "Intro:Piano@{ <4*> 1 2 3 4 }",
            "-> Intro ->#",
        ]

        // 1. TMD Check clean
        _ = editor.commandRegistry.dispatch(id: .tmdCheck, editor: editor)
        #expect(mockDelegate.lastCheckedSourceText != nil)
        #expect(editor.statusMessage == editor.l10n["status.tmd_check_passed"])

        // 2. TMD Check with issues
        mockDelegate.mockIssues = ["Intro:Piano (line 6, measure 1): Expected 4 units, found 3"]
        _ = editor.commandRegistry.dispatch(id: .tmdCheck, editor: editor)
        #expect(editor.statusMessage.contains("1"))

        // 3. TMD Format
        _ = editor.commandRegistry.dispatch(id: .tmdFormat, editor: editor)
        #expect(mockDelegate.lastFormattedSourceText != nil)
        #expect(editor.buffer.lines[0] == "// formatted")
        #expect(editor.statusMessage == editor.l10n["status.tmd_formatted"])

        // 4. TMD Inspect
        _ = editor.commandRegistry.dispatch(id: .tmdInspect, editor: editor)
        #expect(mockDelegate.lastInspectedSourceText != nil)
    }

    @Test func testRealZagoTMDExporterExtendedFormatsAndOperations() throws {
        let exporter = ZagoTMDExporter()
        let sourceText = TMDSnippets.fullScoreTemplate.templateText

        let tempDir = FileManager.default.temporaryDirectory
        let choURL = tempDir.appendingPathComponent("test_export.cho")
        let rppURL = tempDir.appendingPathComponent("test_export.rpp")
        let ustURL = tempDir.appendingPathComponent("test_export.ust")
        let vsqxURL = tempDir.appendingPathComponent("test_export.vsqx")
        let vsqURL = tempDir.appendingPathComponent("test_export.vsq")

        defer {
            try? FileManager.default.removeItem(at: choURL)
            try? FileManager.default.removeItem(at: rppURL)
            try? FileManager.default.removeItem(at: ustURL)
            try? FileManager.default.removeItem(at: vsqxURL)
            try? FileManager.default.removeItem(at: vsqURL)
        }

        try exporter.exportTMD(sourceText: sourceText, format: .chordpro, toPath: choURL.path)
        #expect(FileManager.default.fileExists(atPath: choURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .reaper, toPath: rppURL.path)
        #expect(FileManager.default.fileExists(atPath: rppURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .utau, toPath: ustURL.path)
        #expect(FileManager.default.fileExists(atPath: ustURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .vsqx, toPath: vsqxURL.path)
        #expect(FileManager.default.fileExists(atPath: vsqxURL.path))

        try exporter.exportTMD(sourceText: sourceText, format: .vsq, toPath: vsqURL.path)
        #expect(FileManager.default.fileExists(atPath: vsqURL.path))

        let formatted = try exporter.formatTMD(sourceText: sourceText)
        #expect(formatted.contains("::SCORE::"))

        let issues = exporter.checkTMD(sourceText: sourceText)
        #expect(issues.isEmpty)

        let report = try exporter.inspectTMD(sourceText: sourceText)
        #expect(report.contains("Untitled Score") || report.contains("Piano"))
    }
}
