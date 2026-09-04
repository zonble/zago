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
