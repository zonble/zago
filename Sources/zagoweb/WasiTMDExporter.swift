import Foundation
import Editor
import TmdSwift
import TmdMIDI
import TmdMusicXML
import TmdLilyPond
import TmdABC

#if canImport(WASILibc)
    import WASILibc
#endif

/// WebAssembly implementation of `TMDExportDelegate` that compiles TMD text using `TmdSwift`,
/// writes output to VFS, and emits an ANSI OSC sequence (`\u{001B}]zago:download;<filename>;<base64>\u{0007}`)
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
        let filename = (targetPath as NSString).lastPathComponent
        let rel = targetPath.hasPrefix("/workspace/")
            ? String(targetPath.dropFirst("/workspace/".count))
            : (targetPath.hasPrefix("/") ? String(targetPath.dropFirst()) : targetPath)
        let safeRel = rel.isEmpty ? filename : rel

        #if canImport(WASILibc)
            let oCreat: Int32 = 0x1000  // __WASI_OFLAGS_CREAT << 12
            let oTrunc: Int32 = 0x8000  // __WASI_OFLAGS_TRUNC << 12
            let fd = WASILibc.open(safeRel, O_WRONLY | oCreat | oTrunc, 0o644)
            if fd >= 0 {
                defer { WASILibc.close(fd) }
                targetData.withUnsafeBytes { ptr in
                    if let base = ptr.baseAddress {
                        _ = WASILibc.write(fd, base, ptr.count)
                    }
                }
            } else {
                try? targetData.write(to: URL(fileURLWithPath: safeRel))
            }
        #else
            try? targetData.write(to: URL(fileURLWithPath: targetPath))
        #endif

        // 2. Trigger browser download via OSC sequence with inline base64 payload
        // Format: ESC ] zago:download;<filename>;<base64> BEL
        let base64 = targetData.base64EncodedString()
        let osc = "\u{001B}]zago:download;\(filename);\(base64)\u{0007}"
        if let oscData = osc.data(using: .utf8) {
            emitStdout(oscData)
        }
    }

    private func emitStdout(_ data: Data) {
        data.withUnsafeBytes { ptr in
            if let base = ptr.baseAddress {
                #if canImport(WASILibc)
                    _ = WASILibc.write(1, base, ptr.count)
                #else
                    Foundation.FileHandle.standardOutput.write(data)
                #endif
            }
        }
    }
}
