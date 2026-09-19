import Foundation

struct TMDPlayScoreCommand: Command {
    let id: CommandID = .tmdPlay
    let name = "Play TMD Score"
    let description = "Preview/play current TMD score using Web Audio synthesizer"
    let commandBarAliases = ["play", "play-tmd", "preview"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.playCurrentTMDScore()
        return .succeeded
    }
}

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

struct TMDExportChordProCommand: Command {
    let id: CommandID = .tmdExportChordPro
    let name = "Export ChordPro"
    let description = "Export current TMD score to ChordPro lead sheet"
    let commandBarAliases = ["export-chordpro", "chordpro", "cho"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .chordpro)
        return .prompting
    }
}

struct TMDExportReaperCommand: Command {
    let id: CommandID = .tmdExportReaper
    let name = "Export REAPER"
    let description = "Export current TMD score to REAPER project file (.rpp)"
    let commandBarAliases = ["export-reaper", "reaper", "rpp"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .reaper)
        return .prompting
    }
}

struct TMDExportUTAUCommand: Command {
    let id: CommandID = .tmdExportUTAU
    let name = "Export UTAU"
    let description = "Export current TMD vocal track to UTAU sequence (.ust)"
    let commandBarAliases = ["export-utau", "utau", "ust"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .utau)
        return .prompting
    }
}

struct TMDExportVSQXCommand: Command {
    let id: CommandID = .tmdExportVSQX
    let name = "Export VOCALOID4 (VSQX)"
    let description = "Export current TMD vocal track to VOCALOID3/4 sequence (.vsqx)"
    let commandBarAliases = ["export-vsqx", "vsqx"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .vsqx)
        return .prompting
    }
}

struct TMDExportVSQCommand: Command {
    let id: CommandID = .tmdExportVSQ
    let name = "Export VOCALOID2 (VSQ)"
    let description = "Export current TMD vocal track to VOCALOID2 sequence (.vsq)"
    let commandBarAliases = ["export-vsq", "vsq"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptTMDExport(format: .vsq)
        return .prompting
    }
}

struct TMDCheckCommand: Command {
    let id: CommandID = .tmdCheck
    let name = "Check TMD Score"
    let description = "Verify measure bar beat consistency and playback order completeness"
    let commandBarAliases = ["tmd-check", "check-tmd", "check-score"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.checkCurrentTMDScore()
        return .succeeded
    }
}

struct TMDFormatCommand: Command {
    let id: CommandID = .tmdFormat
    let name = "Format TMD Score"
    let description = "Format and re-indent current TMD score layout"
    let commandBarAliases = ["tmd-format", "format-tmd", "format-score"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.formatCurrentTMDScore()
        return .succeeded
    }
}

struct TMDInspectCommand: Command {
    let id: CommandID = .tmdInspect
    let name = "Inspect TMD Score"
    let description = "Generate vocal range, timing, density, and structure profile report"
    let commandBarAliases = ["tmd-inspect", "inspect-tmd", "song-profile", "song-inspect"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.inspectCurrentTMDScore()
        return .succeeded
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

