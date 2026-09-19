import Foundation
import Editor
import TmdSwift
import TmdMIDI
import TmdMusicXML
import TmdLilyPond
import TmdABC
import TmdChordPro
import TmdReaper
import TmdUTAU
import TmdVocaloid

#if os(macOS)
import TmdAudio
#endif

/// App-level delegate implementing `TMDExportDelegate` using `TmdSwift` libraries.
public final class ZagoTMDExporter: TMDExportDelegate, @unchecked Sendable {
    public init() {}

    public var isWAVExportSupported: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    public func exportTMD(
        sourceText: String,
        format: TMDExportFormat,
        toPath targetPath: String
    ) throws {
        // Parse source string directly using TmdParser
        let sheet = try TmdParser.parseThrowing(string: sourceText)
        let outURL = URL(fileURLWithPath: targetPath)

        switch format {
        case .midi:
            let midiData = TMDMIDIGenerator.generateMIDI(from: sheet)
            try midiData.write(to: outURL)

        case .musicxml:
            let xmlString = TMDMusicXMLGenerator.generateMusicXML(from: sheet)
            guard let xmlData = xmlString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode MusicXML into UTF-8 data.")
            }
            try xmlData.write(to: outURL)

        case .lilypond:
            let lyString = TMDLilyPondGenerator.generateLilyPond(from: sheet)
            guard let lyData = lyString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode LilyPond into UTF-8 data.")
            }
            try lyData.write(to: outURL)

        case .abc:
            let abcString = TMDABCGenerator.generateABC(from: sheet)
            guard let abcData = abcString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode ABC into UTF-8 data.")
            }
            try abcData.write(to: outURL)

        case .wav:
            #if os(macOS)
            let wavData = try TMDWAVRenderer.renderWAV(from: sheet, soundBankURL: nil)
            try wavData.write(to: outURL)
            #else
            throw TMDExportError.custom("WAV export is only supported on macOS.")
            #endif

        case .chordpro:
            let choString = TMDChordProGenerator.generateChordPro(from: sheet)
            guard let choData = choString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode ChordPro into UTF-8 data.")
            }
            try choData.write(to: outURL)

        case .reaper:
            let rppString = TMDReaperGenerator.generateRPP(from: sheet)
            guard let rppData = rppString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode REAPER project into UTF-8 data.")
            }
            try rppData.write(to: outURL)

        case .utau:
            let ustString = TMDUSTGenerator.generateUST(from: sheet)
            guard let ustData = ustString.data(using: .shiftJIS) ?? ustString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode UTAU (.ust) data.")
            }
            try ustData.write(to: outURL)

        case .vsqx:
            let vsqxString = TMDVSQXGenerator.generateVSQX(from: sheet)
            guard let vsqxData = vsqxString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode VOCALOID4 (.vsqx) into UTF-8 data.")
            }
            try vsqxData.write(to: outURL)

        case .vsq:
            let vsqData = TMDVSQGenerator.generateVSQ(from: sheet)
            try vsqData.write(to: outURL)
        }
    }

    public func formatTMD(sourceText: String) throws -> String {
        return TMDRefactor.format(sourceText)
    }

    public func checkTMD(sourceText: String) -> [String] {
        let issues = TMDMeasureChecker.check(source: sourceText)
        return issues.map(\.description)
    }

    public func inspectTMD(sourceText: String) throws -> String {
        let sheet = try TmdParser.parseThrowing(string: sourceText)
        let profile = TMDSongInspector.inspect(sheet: sheet)
        return TMDSongInspector.generateReport(profile)
    }
}
