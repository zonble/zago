import Foundation

/// Pure-Swift high performance cross-platform number and byte formatting helper.
public enum NumberFormatHelper {

    /// Formats a number with comma grouping and optional fractional precision (e.g. `1,234,567.89`).
    public static func formatWithGrouping(_ number: Double, precision: Int? = nil) -> String {
        let formattedStr: String
        if let precision = precision {
            formattedStr = String(format: "%.\(precision)f", number)
        } else {
            if number.rounded() == number && !number.isInfinite && !number.isNaN && abs(number) < 1e12 {
                formattedStr = String(Int(number))
            } else {
                formattedStr = "\(number)"
            }
        }
        let parts = formattedStr.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = parts[0]
        let isNegative = integerPart.hasPrefix("-")
        let digitsOnly = isNegative ? integerPart.dropFirst() : integerPart[...]
        var groupedDigits = ""
        let count = digitsOnly.count
        for (i, char) in digitsOnly.enumerated() {
            if i > 0 && (count - i) % 3 == 0 {
                groupedDigits.append(",")
            }
            groupedDigits.append(char)
        }
        let finalInt = (isNegative ? "-" : "") + groupedDigits
        if parts.count > 1 {
            return "\(finalInt).\(parts[1])"
        }
        return finalInt
    }

    /// Formats a percentage value (e.g. `0.75` -> `75%` or `75.0%`).
    public static func formatPercent(_ number: Double, precision: Int? = nil) -> String {
        let pct = number * 100
        if let precision = precision {
            return String(format: "%.\(precision)f%%", pct)
        }
        return "\(pct)%"
    }

    /// Formats currency with currency symbol / code and precision.
    public static func formatCurrency(_ number: Double, currencyCode: String? = nil, precision: Int? = 2) -> String {
        let sym = currencyCode ?? "$"
        let numStr = formatWithGrouping(number, precision: precision)
        return "\(sym)\(numStr)"
    }

    /// Formats an integer as ordinal (e.g. 1st, 2nd, 3rd, 4th, 11th, 21st, 102nd).
    public static func formatOrdinal(_ number: Int) -> String {
        let suffix: String
        switch abs(number) % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch abs(number) % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(number)\(suffix)"
    }

    /// Converts an integer to Roman Numerals (1...3999).
    public static func formatRoman(_ num: Int, style: RomanNumbersStyle = .alphabets) -> String {
        (try? RomanNumbers.convert(input: num, style: style)) ?? "\(num)"
    }

    /// Converts an integer to traditional Chinese financial uppercase (大寫金額/數字: 零壹貳參肆伍陸柒捌玖拾佰仟萬億).
    public static func formatFinancialChinese(_ num: Int) -> String {
        let isNegative = num < 0
        let absNum = abs(num)
        let res = ChineseNumbers.generate(intPart: "\(absNum)", decPart: "", digitCase: .uppercase)
        return isNegative ? "負\(res)" : res
    }

    /// Converts an integer to Chinese numbers (lowercase 一二三 or uppercase 壹貳參).
    public static func formatChineseNumber(_ num: Int, uppercase: Bool = false) -> String {
        let isNegative = num < 0
        let absNum = abs(num)
        let res = ChineseNumbers.generate(
            intPart: "\(absNum)",
            decPart: "",
            digitCase: uppercase ? .uppercase : .lowercase
        )
        return isNegative ? "負\(res)" : res
    }

    /// Converts a number to ancient Chinese Suzhou numerals (蘇州碼 / 花碼).
    public static func formatSuzhou(_ number: Double, unit: String = "") -> String {
        let isNegative = number < 0
        let absNum = abs(number)
        let strVal = "\(absNum)"
        let parts = strVal.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = String(parts[0])
        let decPart = parts.count > 1 ? String(parts[1]) : ""
        let res = SuzhouNumbers.generate(intPart: intPart, decPart: decPart, unit: unit)
        return isNegative ? "負\(res)" : res
    }

    /// Formats bytes into human-readable representation (e.g. 1.5 KB, 2.3 MB, 1024 bytes).
    public static func formatBytes(_ bytes: Int64, isBinary: Bool = false) -> String {
        if bytes == 0 { return "0 bytes" }
        let isNegative = bytes < 0
        let absBytes = Double(abs(bytes))
        let base: Double = isBinary ? 1024.0 : 1000.0
        let units = isBinary
            ? ["bytes", "KiB", "MiB", "GiB", "TiB", "PiB"]
            : ["bytes", "kB", "MB", "GB", "TB", "PB"]

        var val = absBytes
        var unitIdx = 0
        while val >= base && unitIdx < units.count - 1 {
            val /= base
            unitIdx += 1
        }

        let prefix = isNegative ? "-" : ""
        if unitIdx == 0 {
            return "\(prefix)\(Int64(val)) \(units[0])"
        }
        if val.rounded() == val {
            return "\(prefix)\(Int(val)) \(units[unitIdx])"
        }
        return "\(prefix)" + String(format: "%.1f", val) + " \(units[unitIdx])"
    }
}
