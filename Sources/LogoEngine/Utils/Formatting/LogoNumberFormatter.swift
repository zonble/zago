import Foundation

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
        default:
            return "\(number)"
        }
        #else
        // Non-Darwin (Linux & Windows) portable pure-Swift implementation
        switch style {
        case .roman:
            return formatRoman(Int(number))
        case .financial:
            return formatFinancialChinese(Int(number))
        case .percent:
            let pct = number * 100
            if let precision = precision {
                return String(format: "%.\(precision)f%%", pct)
            }
            return "\(pct)%"
        case .currency:
            let sym = currencyCode ?? "$"
            if let precision = precision {
                return "\(sym)" + String(format: "%.\(precision)f", number)
            }
            return "\(sym)\(number)"
        case .decimal:
            if let precision = precision {
                return String(format: "%.\(precision)f", number)
            }
            return "\(number)"
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
            return "\(Int(number))"
        }
        #endif
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
