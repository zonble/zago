import Foundation
import Testing

@testable import Config
@testable import Editor

private final class MockTMDExportDelegate: TMDExportDelegate, @unchecked Sendable {
    var lastSourceText: String?
    var lastFormat: TMDExportFormat?
    var lastTargetPath: String?
    var shouldFail: Bool = false
    var isWAVExportSupported: Bool = true

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
}
