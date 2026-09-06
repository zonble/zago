import Foundation

/// Supported TMD export target formats.
public enum TMDExportFormat: String, CaseIterable, Sendable {
    case midi = "midi"
    case musicxml = "musicxml"
    case lilypond = "lilypond"
    case abc = "abc"
    case wav = "wav"

    /// Default file extension for the export format.
    public var fileExtension: String {
        switch self {
        case .midi: return "mid"
        case .musicxml: return "xml"
        case .lilypond: return "ly"
        case .abc: return "abc"
        case .wav: return "wav"
        }
    }

    /// Display title for the format in status messages.
    public var displayName: String {
        switch self {
        case .midi: return "MIDI"
        case .musicxml: return "MusicXML"
        case .lilypond: return "LilyPond"
        case .abc: return "ABC"
        case .wav: return "WAV"
        }
    }
}

/// Abstract delegate protocol implemented by app targets (e.g. zago CLI)
/// to perform TMD parsing and compilation without coupling the Editor module to TmdSwift.
public protocol TMDExportDelegate: AnyObject, Sendable {
    /// Whether the editor should prompt the user for an export path before running export.
    /// Defaults to `true` on CLI targets; WebAssembly / browser targets can return `false` to trigger instant download.
    var shouldPromptForPath: Bool { get }

    /// Whether WAV audio export is supported in current platform environment.
    var isWAVExportSupported: Bool { get }

    /// Whether real-time score playback/preview is supported in this environment (e.g. Web edition).
    var isPlaybackSupported: Bool { get }

    /// Exports TMD source text to the specified format and writes to target path.
    func exportTMD(
        sourceText: String,
        format: TMDExportFormat,
        toPath targetPath: String
    ) throws

    /// Plays/previews TMD source text in the host environment (e.g. Web Audio synthesizer).
    func playTMD(sourceText: String, title: String) throws

    /// Notifies the host environment that the editor's active buffer changed.
    func notifyActiveBuffer(filePath: String?)
}

public extension TMDExportDelegate {
    var shouldPromptForPath: Bool { true }
    var isPlaybackSupported: Bool { false }
    func playTMD(sourceText: String, title: String) throws {}
    func notifyActiveBuffer(filePath: String?) {}
}

/// Default no-op delegate when no TMD compiler is injected (e.g. headless/test environments).
public final class DefaultTMDExportDelegate: TMDExportDelegate, @unchecked Sendable {
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
        throw TMDExportError.notSupported
    }
}

/// Errors occurring during TMD export dispatch.
public enum TMDExportError: LocalizedError, Sendable {
    case notSupported
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .notSupported:
            return "TMD exporter is not configured in this environment."
        case .custom(let message):
            return message
        }
    }
}
