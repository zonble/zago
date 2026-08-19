import Foundation

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
