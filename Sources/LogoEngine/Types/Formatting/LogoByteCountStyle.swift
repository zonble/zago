import Foundation

/// Supported byte count styles for LogoEngine byte count formatting.
public enum LogoByteCountStyle: Sendable, Equatable {
    case file
    case memory
    case binary
    case decimal
    case bytes

    public init?(keyword raw: String) {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
        switch clean {
        case "memory", "mem":
            self = .memory
        case "binary", "bin":
            self = .binary
        case "decimal", "dec":
            self = .decimal
        case "bytes", "exact", "raw":
            self = .bytes
        case "file", "auto":
            self = .file
        default:
            return nil
        }
    }

    public static func parse(_ raw: String) -> LogoByteCountStyle {
        LogoByteCountStyle(keyword: raw) ?? .file
    }

    public static func isStyleKeyword(_ raw: String) -> Bool {
        LogoByteCountStyle(keyword: raw) != nil
    }
}
