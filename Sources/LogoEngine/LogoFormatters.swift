import Foundation

/// Advanced Foundation-powered Number, List, RelativeDateTime, and ByteCount formatters for LogoEngine.
struct LogoFormatters {

    // MARK: - Number Formatter

    enum NumberStyle {
        case decimal
        case percent
        case currency
        case spellout
        case financial
        case roman
        case ordinal

        static func parse(_ raw: String) -> NumberStyle {
            let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
            return switch clean {
            case "spellout", "words", "word", "text", "chinese", "cjk", "spoken": .spellout
            case "financial", "capital", "caps", "cap", "upper", "check", "cheque", "bank", "invoice", "traditional",
                "daxie":
                .financial
            case "currency", "money", "curr", "cash": .currency
            case "percent", "percentage", "pct": .percent
            case "roman", "romannumeral": .roman
            case "ordinal", "ord": .ordinal
            case "decimal", "number", "num", "grouping": .decimal
            default: .decimal
            }
        }
    }

    static func formatNumber(
        _ number: Double,
        style: NumberStyle = .decimal,
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
    static func formatRoman(_ num: Int) -> String {
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
    static func formatFinancialChinese(_ num: Int) -> String {
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

    // MARK: - List Formatter

    enum ListType {
        case and
        case or
        case unit

        static func parse(_ raw: String) -> ListType {
            let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
            return switch clean {
            case "or", "disjunction": .or
            case "unit", "narrow", "comma": .unit
            case "and", "standard", "conjunction": .and
            default: .and
            }
        }
    }

    static func formatList(
        _ items: [String],
        type: ListType = .and,
        locale: String? = nil
    ) -> String {
        guard !items.isEmpty else { return "" }
        if items.count == 1 { return items[0] }

        let loc = LogoDateTimeFormatter.parseLocale(locale)
        let isChinese = loc.identifier.lowercased().hasPrefix("zh")

        switch type {
        case .and:
            let formatter = ListFormatter()
            formatter.locale = loc
            return formatter.string(from: items) ?? items.joined(separator: ", ")

        case .or:
            if isChinese {
                if items.count == 2 {
                    return "\(items[0])或\(items[1])"
                }
                let head = items.dropLast().joined(separator: "、")
                return "\(head)或\(items.last ?? "")"
            } else {
                if items.count == 2 {
                    return "\(items[0]) or \(items[1])"
                }
                let head = items.dropLast().joined(separator: ", ")
                return "\(head), or \(items.last ?? "")"
            }

        case .unit:
            if isChinese {
                return items.joined(separator: "、")
            } else {
                return items.joined(separator: ", ")
            }
        }
    }

    // MARK: - Relative Date Time Formatter

    static func formatRelativeTime(
        value: Double,
        unit: String,
        locale: String? = nil
    ) -> String {
        let loc = LogoDateTimeFormatter.parseLocale(locale)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = loc
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named

        let cleanUnit = unit.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\""))
        var comps = DateComponents()
        switch cleanUnit {
        case "second", "seconds", "sec", "s": comps.second = Int(value)
        case "minute", "minutes", "min": comps.minute = Int(value)
        case "hour", "hours", "h": comps.hour = Int(value)
        case "day", "days", "d": comps.day = Int(value)
        case "week", "weeks", "w": comps.weekOfYear = Int(value)
        case "month", "months", "m": comps.month = Int(value)
        case "year", "years", "y": comps.year = Int(value)
        default: comps.day = Int(value)
        }

        return formatter.localizedString(from: comps)
    }

    static func formatRelativeDate(
        target: Date,
        reference: Date = Date(),
        locale: String? = nil
    ) -> String {
        let loc = LogoDateTimeFormatter.parseLocale(locale)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = loc
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: target, relativeTo: reference)
    }

    // MARK: - Byte Count Formatter

    enum ByteCountStyle {
        case file
        case memory
        case binary
        case decimal
        case bytes

        static func parse(_ raw: String) -> ByteCountStyle {
            let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
            return switch clean {
            case "memory", "mem": .memory
            case "binary", "bin": .binary
            case "decimal", "dec": .decimal
            case "bytes", "exact", "raw": .bytes
            case "file", "auto": .file
            default: .file
            }
        }
    }

    static func formatBytes(
        _ bytes: Int64,
        style: ByteCountStyle = .file,
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
