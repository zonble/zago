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
        guard let countStyle = style.countStyle else {
            let numFormatter = NumberFormatter()
            numFormatter.locale = LogoDateTimeFormatter.parseLocale(locale)
            numFormatter.numberStyle = .decimal
            let numStr = numFormatter.string(from: NSNumber(value: bytes)) ?? "\(bytes)"
            return "\(numStr) bytes"
        }

        let formatter = ByteCountFormatter()
        formatter.includesUnit = true
        formatter.isAdaptive = true
        formatter.countStyle = countStyle
        return formatter.string(fromByteCount: bytes)
    }
}
