import Foundation
import Editor
import TmdSwift
import TmdMIDI
import TmdMusicXML
import TmdLilyPond
import TmdABC

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
        }
    }
}
