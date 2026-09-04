import Foundation

struct TMDExportMIDICommand: Command {
    let id: CommandID = .tmdExportMIDI
    let name = "Export MIDI"
    let description = "Export current TMD score to Standard MIDI File"
    let commandBarAliases = ["export-midi", "midi"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .midi)
        return .prompting
    }
}

struct TMDExportMusicXMLCommand: Command {
    let id: CommandID = .tmdExportMusicXML
    let name = "Export MusicXML"
    let description = "Export current TMD score to MusicXML score"
    let commandBarAliases = ["export-musicxml", "musicxml", "xml"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .musicxml)
        return .prompting
    }
}

struct TMDExportLilyPondCommand: Command {
    let id: CommandID = .tmdExportLilyPond
    let name = "Export LilyPond"
    let description = "Export current TMD score to LilyPond (.ly) source"
    let commandBarAliases = ["export-lilypond", "lilypond", "lily"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .lilypond)
        return .prompting
    }
}

struct TMDExportABCCommand: Command {
    let id: CommandID = .tmdExportABC
    let name = "Export ABC"
    let description = "Export current TMD score to ABC notation"
    let commandBarAliases = ["export-abc", "abc"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .abc)
        return .prompting
    }
}

struct TMDExportWAVCommand: Command {
    let id: CommandID = .tmdExportWAV
    let name = "Export WAV"
    let description = "Render current TMD score to WAV audio using system synthesizer"
    let commandBarAliases = ["export-wav", "wav"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .wav)
        return .prompting
    }
}

struct TMDReferenceCommand: Command {
    let id: CommandID = .tmdReference
    let name = "TMD Reference"
    let description = "Show TMD music syntax and quick reference"
    let commandBarAliases = ["help-tmd", "tmd-reference", "tmd"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        TextDocumentView(
            terminal: editor.terminal,
            title: editor.l10n["tmdview.reference_title"],
            lines: TMDReferenceContent.lines(language: editor.language),
            footer: editor.l10n["textview.footer"]
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
        return .succeeded
    }
}

