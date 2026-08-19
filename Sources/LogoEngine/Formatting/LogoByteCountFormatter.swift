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

/// Advanced Foundation-powered Byte Count formatter for LogoEngine.
public enum LogoByteCountFormatter {
    public static func disambiguateOptions(
        _ args: [String],
        style: inout LogoByteCountStyle,
        locale: inout String?
    ) {
        for arg in args {
            let clean = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; ")).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if LogoByteCountStyle.isStyleKeyword(lower) {
                style = LogoByteCountStyle.parse(lower)
            } else {
                locale = clean
            }
        }
    }

    public static func format(
        _ bytes: Int64,
        style: LogoByteCountStyle = .file,
        locale: String? = nil
    ) -> String {
        if style == .bytes {
            let numFormatter = NumberFormatter()
            numFormatter.locale = LogoDateTimeFormatter.parseLocale(locale)
            numFormatter.numberStyle = .decimal
            let numStr = numFormatter.string(from: NSNumber(value: bytes)) ?? "\(bytes)"
            return "\(numStr) bytes"
        }

        let formatter = ByteCountFormatter()
        formatter.includesUnit = true
        formatter.isAdaptive = true

        switch style {
        case .file:
            formatter.countStyle = .file
        case .memory:
            formatter.countStyle = .memory
        case .binary:
            formatter.countStyle = .binary
        case .decimal:
            formatter.countStyle = .decimal
        case .bytes:
            break
        }

        return formatter.string(fromByteCount: bytes)
    }
}
