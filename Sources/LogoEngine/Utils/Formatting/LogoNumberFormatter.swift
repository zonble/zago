import Foundation
import NumberHelpers

/// Advanced Number formatter for LogoEngine backed by Foundation and NumberHelpers.
public enum LogoNumberFormatter {
    public static func isCurrencyCode(_ raw: String) -> Bool {
        let clean = raw.trimmingCharacters(in: CharacterSet(charactersIn: ":\"' ")).uppercased()
        if clean.count == 3 && clean.allSatisfy({ $0.isLetter }) {
            return true
        }
        return ["NT$", "$", "€", "¥", "£", "NTD"].contains(clean)
    }

    public static func disambiguateOptions(
        _ args: [String],
        style: inout LogoNumberStyle,
        locale: inout String?,
        currencyCode: inout String?,
        precision: inout Int?,
        parseStyle: ((String) -> LogoNumberStyle?)? = nil
    ) {
        for arg in args {
            let clean = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; ")).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if let parsedStyle = parseStyle?(clean) ?? parseStyle?(lower)
                ?? (LogoNumberStyle.isStyleKeyword(lower) ? LogoNumberStyle.parse(lower) : nil)
            {
                style = parsedStyle
            } else if let intVal = Int(lower), precision == nil {
                precision = intVal
            } else if isCurrencyCode(clean) && currencyCode == nil && !Locale.isLogoLocaleSpec(clean) {
                currencyCode = clean
            } else if Locale.isLogoLocaleSpec(clean) && locale == nil {
                locale = clean
            } else if locale == nil {
                locale = clean
            } else if currencyCode == nil {
                currencyCode = clean
            }
        }
    }

    public static func format(
        _ number: Double,
        style: LogoNumberStyle = .decimal,
        locale: String? = nil,
        currencyCode: String? = nil,
        precision: Int? = nil
    ) -> String {
        #if canImport(Darwin)
            let loc = Locale(logoLocaleSpec: locale)

            if let numStyle = style.numberFormatterStyle {
                let formatter = NumberFormatter()
                formatter.locale = loc
                formatter.numberStyle = numStyle
                if style == .currency, let code = currencyCode, !code.isEmpty {
                    formatter.currencyCode = code.uppercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\""))
                }
                if let precision = precision {
                    formatter.minimumFractionDigits = precision
                    formatter.maximumFractionDigits = precision
                }
                if let str = formatter.string(from: NSNumber(value: number)) {
                    return str
                }
                return style == .percent ? "\(number * 100)%" : "\(number)"
            }

            switch style {
            case .roman:
                return formatRoman(Int(number))
            case .financial:
                return formatFinancialChinese(Int(number))
            case .suzhou:
                return formatSuzhou(number)
            default:
                return "\(number)"
            }
        #else
            // Non-Darwin (Linux & Windows) portable pure-Swift implementation backed by NumberHelpers
            switch style {
            case .roman:
                return formatRoman(Int(number))
            case .financial:
                return formatFinancialChinese(Int(number))
            case .suzhou:
                return formatSuzhou(number)
            case .percent:
                let pct = number * 100
                if let precision = precision {
                    return String(format: "%.\(precision)f%%", pct)
                }
                return "\(pct)%"
            case .currency:
                let sym = currencyCode ?? "$"
                let numStr = formatWithGrouping(number, precision: precision ?? 2)
                return "\(sym)\(numStr)"
            case .decimal:
                return formatWithGrouping(number, precision: precision)
            case .ordinal:
                let intVal = Int(number)
                let suffix: String
                switch intVal % 100 {
                case 11, 12, 13: suffix = "th"
                default:
                    switch intVal % 10 {
                    case 1: suffix = "st"
                    case 2: suffix = "nd"
                    case 3: suffix = "rd"
                    default: suffix = "th"
                    }
                }
                return "\(intVal)\(suffix)"
            case .spellout:
                let isChinese = locale?.lowercased().contains("zh") == true
                if isChinese {
                    return formatChineseNumber(Int(number), uppercase: false)
                }
                return "\(Int(number))"
            }
        #endif
    }

    private static func formatWithGrouping(_ number: Double, precision: Int?) -> String {
        NumberFormatHelper.formatWithGrouping(number, precision: precision)
    }

    /// Converts an integer to Roman Numerals (1...3999).
    public static func formatRoman(_ num: Int) -> String {
        NumberFormatHelper.formatRoman(num)
    }

    /// Converts an integer to traditional Chinese financial uppercase (大寫金額/數字: 零壹貳參肆伍陸柒捌玖拾佰仟萬億).
    public static func formatFinancialChinese(_ num: Int) -> String {
        NumberFormatHelper.formatFinancialChinese(num)
    }

    /// Converts an integer to Chinese numbers (lowercase or uppercase).
    public static func formatChineseNumber(_ num: Int, uppercase: Bool = false) -> String {
        NumberFormatHelper.formatChineseNumber(num, uppercase: uppercase)
    }

    /// Converts a number to ancient Chinese Suzhou numerals (蘇州碼 / 花碼).
    public static func formatSuzhou(_ number: Double) -> String {
        NumberFormatHelper.formatSuzhou(number)
    }
}
