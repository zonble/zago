import Foundation
import Editor
import TmdSwift
import TmdMIDI
import TmdMusicXML
import TmdLilyPond
import TmdABC

#if os(WASI) && canImport(WASILibc)
    import WASILibc
#endif

/// WebAssembly implementation of `TMDExportDelegate` that compiles TMD text using `TmdSwift`,
/// writes output to VFS, and emits an ANSI OSC sequence (`\u{001B}]zago:download;<filename>\u{0007}`)
/// so the host browser can immediately trigger a file download.
public final class WasiTMDExporter: TMDExportDelegate, @unchecked Sendable {
    public init() {}

    public var shouldPromptForPath: Bool {
        false
    }

    public var isWAVExportSupported: Bool {
        false
    }

    public func exportTMD(
        sourceText: String,
        format: TMDExportFormat,
        toPath targetPath: String
    ) throws {
        let sheet = try TmdParser.parseThrowing(string: sourceText)
        let outURL = URL(fileURLWithPath: targetPath)

        let targetData: Data
        switch format {
        case .midi:
            targetData = TMDMIDIGenerator.generateMIDI(from: sheet)

        case .musicxml:
            let xmlString = TMDMusicXMLGenerator.generateMusicXML(from: sheet)
            guard let xmlData = xmlString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode MusicXML into UTF-8 data.")
            }
            targetData = xmlData

        case .lilypond:
            let lyString = TMDLilyPondGenerator.generateLilyPond(from: sheet)
            guard let lyData = lyString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode LilyPond into UTF-8 data.")
            }
            targetData = lyData

        case .abc:
            let abcString = TMDABCGenerator.generateABC(from: sheet)
            guard let abcData = abcString.data(using: .utf8) else {
                throw TMDExportError.custom("Failed to encode ABC into UTF-8 data.")
            }
            targetData = abcData

        case .wav:
            throw TMDExportError.notSupported
        }

        // 1. Write file to virtual file system (VFS)
        try targetData.write(to: outURL)

        // 2. Trigger browser download via OSC sequence on standard output
        // Format: ESC ] zago:download;<filename> BEL
        let filename = (targetPath as NSString).lastPathComponent
        let osc = "\u{001B}]zago:download;\(filename)\u{0007}"
        if let oscData = osc.data(using: .utf8) {
            emitStdout(oscData)
        }
    }

    private func emitStdout(_ data: Data) {
        data.withUnsafeBytes { ptr in
            if let base = ptr.baseAddress {
                #if os(WASI) && canImport(WASILibc)
                    _ = WASILibc.write(1, base, ptr.count)
                #else
                    Foundation.FileHandle.standardOutput.write(data)
                #endif
            }
        }
    }
}
