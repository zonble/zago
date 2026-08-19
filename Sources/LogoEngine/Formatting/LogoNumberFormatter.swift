import Foundation

/// Defines formatting styles for numbers in LogoEngine.
public enum LogoNumberStyle: Sendable, Equatable {
    case decimal
    case percent
    case currency
    case spellout
    case financial
    case roman
    case ordinal

    public init?(keyword raw: String) {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
        switch clean {
        case "spellout", "words", "word", "text", "chinese", "cjk", "spoken":
            self = .spellout
        case "financial", "capital", "caps", "cap", "upper", "check", "cheque", "bank", "invoice", "traditional", "daxie":
            self = .financial
        case "currency", "money", "curr", "cash":
            self = .currency
        case "percent", "percentage", "pct":
            self = .percent
        case "roman", "romannumeral":
            self = .roman
        case "ordinal", "ord":
            self = .ordinal
        case "decimal", "number", "num", "grouping":
            self = .decimal
        default:
            return nil
        }
    }

    public static func parse(_ raw: String) -> LogoNumberStyle {
        LogoNumberStyle(keyword: raw) ?? .decimal
    }

    public static func isStyleKeyword(_ raw: String) -> Bool {
        LogoNumberStyle(keyword: raw) != nil
    }
}

/// Advanced Foundation-powered Number formatter for LogoEngine.
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
        precision: inout Int?
    ) {
        for arg in args {
            let clean = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; ")).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if let intVal = Int(lower), precision == nil, !LogoNumberStyle.isStyleKeyword(lower) {
                precision = intVal
            } else if LogoNumberStyle.isStyleKeyword(lower) {
                style = LogoNumberStyle.parse(lower)
            } else if isCurrencyCode(clean) && currencyCode == nil && !LogoDateTimeFormatter.isLocaleName(clean) {
                currencyCode = clean
            } else if LogoDateTimeFormatter.isLocaleName(clean) && locale == nil {
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
        let loc = LogoDateTimeFormatter.parseLocale(locale)

        switch style {
        case .roman:
            return formatRoman(Int(number))

        case .financial:
            return formatFinancialChinese(Int(number))

        case .ordinal:
            let formatter = NumberFormatter()
            formatter.locale = loc
            formatter.numberStyle = .ordinal
            if let precision = precision {
                formatter.minimumFractionDigits = precision
                formatter.maximumFractionDigits = precision
            }
            return formatter.string(from: NSNumber(value: number)) ?? "\(Int(number))"

        case .spellout:
            let formatter = NumberFormatter()
            formatter.locale = loc
            formatter.numberStyle = .spellOut
            return formatter.string(from: NSNumber(value: number)) ?? "\(number)"

        case .currency:
            let formatter = NumberFormatter()
            formatter.locale = loc
            formatter.numberStyle = .currency
            if let code = currencyCode, !code.isEmpty {
                formatter.currencyCode = code.uppercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\""))
            }
            if let precision = precision {
                formatter.minimumFractionDigits = precision
                formatter.maximumFractionDigits = precision
            }
            return formatter.string(from: NSNumber(value: number)) ?? "\(number)"

        case .percent:
            let formatter = NumberFormatter()
            formatter.locale = loc
            formatter.numberStyle = .percent
            if let precision = precision {
                formatter.minimumFractionDigits = precision
                formatter.maximumFractionDigits = precision
            }
            return formatter.string(from: NSNumber(value: number)) ?? "\(number * 100)%"

        case .decimal:
            let formatter = NumberFormatter()
            formatter.locale = loc
            formatter.numberStyle = .decimal
            if let precision = precision {
                formatter.minimumFractionDigits = precision
                formatter.maximumFractionDigits = precision
            }
            return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        }
    }

    /// Converts an integer to Roman Numerals (1...3999).
    public static func formatRoman(_ num: Int) -> String {
        guard num > 0, num < 4000 else { return "\(num)" }
        let mappings: [(int: Int, roman: String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
        ]
        var res = ""
        var n = num
        for m in mappings {
            while n >= m.int {
                res += m.roman
                n -= m.int
            }
        }
        return res
    }

    /// Converts an integer to traditional Chinese financial uppercase (大寫金額/數字: 零壹貳參肆伍陸柒捌玖拾佰仟萬億).
    public static func formatFinancialChinese(_ num: Int) -> String {
        if num == 0 { return "零" }
        if num < 0 { return "負" + formatFinancialChinese(-num) }

        let digits = ["零", "壹", "貳", "參", "肆", "伍", "陸", "柒", "捌", "玖"]
        let units = ["", "拾", "佰", "仟"]
        let bigUnits = ["", "萬", "億", "兆"]

        var res = ""
        var n = num
        var sectionIndex = 0

        while n > 0 {
            let section = n % 10000
            if section > 0 {
                var sectionStr = ""
                var temp = section
                var zeroFlag = false

                for unitIndex in 0..<4 {
                    let d = temp % 10
                    if d == 0 {
                        if !zeroFlag && !sectionStr.isEmpty {
                            zeroFlag = true
                            sectionStr = digits[0] + sectionStr
                        }
                    } else {
                        zeroFlag = false
                        sectionStr = digits[d] + units[unitIndex] + sectionStr
                    }
                    temp /= 10
                }
                res = sectionStr + bigUnits[sectionIndex] + res
            } else if !res.isEmpty && !res.hasPrefix("零") {
                res = "零" + res
            }
            n /= 10000
            sectionIndex += 1
        }

        // Clean up redundant leading zeros
        while res.hasPrefix("零") && res.count > 1 {
            res.removeFirst()
        }
        return res
    }
}
