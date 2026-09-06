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
/// writes output to VFS, and emits ANSI OSC sequences for browser file download
/// and real-time Web Audio MIDI playback.
public final class WasiTMDExporter: TMDExportDelegate, @unchecked Sendable {
    private var lastEmittedBufferPath: String? = nil

    public init() {}

    public var shouldPromptForPath: Bool {
        false
    }

    public var isWAVExportSupported: Bool {
        false
    }

    public var isPlaybackSupported: Bool {
        true
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

    /// Compiles current TMD source to MIDI in-memory and emits OSC sequence for web playback.
    /// Format: ESC ] zago:play;<title>;<base64> BEL
    public func playTMD(sourceText: String, title: String) throws {
        let sheet = try TmdParser.parseThrowing(string: sourceText)
        let midiData = TMDMIDIGenerator.generateMIDI(from: sheet)
        let base64 = midiData.base64EncodedString()
        let osc = "\u{001B}]zago:play;\(title);\(base64)\u{0007}"
        if let oscData = osc.data(using: .utf8) {
            emitStdout(oscData)
        }
    }

    /// Emits active buffer change notification to host web UI.
    /// Format: ESC ] zago:active-buffer;<isTMD:1|0>;<filename> BEL
    public func notifyActiveBuffer(filePath: String?) {
        let isTMD = filePath?.lowercased().hasSuffix(".tmd") == true ? "1" : "0"
        let filename = filePath.map { ($0 as NSString).lastPathComponent } ?? ""
        let currentKey = "\(isTMD):\(filename)"
        guard currentKey != lastEmittedBufferPath else { return }
        lastEmittedBufferPath = currentKey

        let osc = "\u{001B}]zago:active-buffer;\(isTMD);\(filename)\u{0007}"
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
