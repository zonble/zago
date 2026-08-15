import Foundation

/// Advanced Foundation-powered Date and Time Formatter for LogoEngine.
public struct LogoDateTimeFormatter {
    public enum Mode {
        case date
        case time
        case dateTime
    }

    public enum StylePreset {
        case short
        case medium
        case long
        case full
        case iso8601
        case custom(String)

        public static func parse(_ raw: String, mode: Mode) -> StylePreset {
            let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
            return switch clean {
            case "short": .short
            case "medium", "med": .medium
            case "long": .long
            case "full": .full
            case "iso8601", "iso": .iso8601
            default:
                if clean.isEmpty {
                    switch mode {
                    case .date: .custom("yyyy-MM-dd")
                    case .time: .custom("HH:mm:ss")
                    case .dateTime: .custom("yyyy-MM-dd HH:mm:ss")
                    }
                } else {
                    .custom(raw)
                }
            }
        }
    }

    public static func isCalendarName(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        return switch stripped {
        case "roc", "republicofchina", "minguo", "taiwan",
            "japanese", "japan", "wareki", "jp",
            "buddhist", "thai",
            "chinese", "lunar",
            "islamic", "islamiccivil", "islamicrural", "islamicummalqura", "ummalqura", "muslim",
            "hebrew", "jewish",
            "persian", "iran",
            "indian", "coptic", "ethiopic", "ethiopicametemihret",
            "gregorian", "western":
            true
        default:
            false
        }
    }

    public static func isStylePresetName(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        return switch stripped {
        case "short", "medium", "med", "long", "full", "iso8601", "iso": true
        default: false
        }
    }

    public static func isLocaleName(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        let lower = stripped.lowercased()
        if lower == "system" || lower == "current" { return true }
        if stripped.contains("_") || stripped.contains("-") {
            let prefix = stripped.split(separator: "_").first ?? stripped.split(separator: "-").first ?? ""
            if prefix.count == 2 || prefix.count == 3 {
                return true
            }
        }
        if stripped.count == 4 || stripped.count == 5 {
            let lang = String(lower.prefix(2))
            if ["zh", "en", "ja", "fr", "de", "es", "it", "ko", "th", "ru", "pt"].contains(lang) {
                return true
            }
        }
        if ["zh", "en", "ja", "fr", "de", "es", "it", "ko", "th", "ru", "pt"].contains(lower) {
            return true
        }
        return false
    }

    public static func isTimeZoneName(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        if stripped.hasPrefix("+") || stripped.hasPrefix("-") { return true }
        let upper = stripped.uppercased()
        if upper.hasPrefix("UTC") || upper.hasPrefix("GMT") || upper == "Z" { return true }
        if TimeZone(identifier: stripped) != nil || TimeZone(abbreviation: stripped) != nil {
            return true
        }
        return false
    }

    public static func resolveArguments(
        _ args: [String],
        mode: Mode
    ) -> (format: String?, locale: String?, tz: String?, cal: String?) {
        var format: String? = nil
        var locale: String? = nil
        var tz: String? = nil
        var cal: String? = nil

        for arg in args {
            let clean = arg.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if isCalendarName(lower) && cal == nil {
                cal = clean
            } else if isLocaleName(clean) && locale == nil {
                locale = clean
            } else if isTimeZoneName(clean) && tz == nil {
                tz = clean
            } else if isStylePresetName(lower) && format == nil {
                format = clean
            } else if format == nil {
                format = clean
            } else if locale == nil {
                locale = clean
            } else if tz == nil {
                tz = clean
            } else if cal == nil {
                cal = clean
            }
        }

        // If calendar is specified without explicit locale, pick the natural matching locale
        if locale == nil && cal != nil {
            let lowerCal = (cal ?? "").lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            switch lowerCal {
            case "roc", "republicofchina", "minguo", "taiwan":
                locale = "zh_TW"
            case "chinese", "lunar":
                locale = "zh_TW"
            case "japanese", "japan", "wareki", "jp":
                locale = "ja_JP"
            case "buddhist", "thai":
                locale = "th_TH"
            default:
                break
            }
        }

        // If calendar is specified (e.g. roc, japanese) without explicit format, default to long localized date
        if format == nil && cal != nil && isCalendarName(cal ?? "") {
            let lowerCal = (cal ?? "").lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            if lowerCal != "gregorian" && lowerCal != "western" {
                format = "long"
            }
        }

        return (format, locale, tz, cal)
    }

    public static func parseCalendar(_ raw: String?) -> Calendar {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else {
            return Calendar(identifier: .gregorian)
        }
        let clean = raw.hasPrefix(":") ? String(raw.dropFirst()) : raw

        let identifier: Calendar.Identifier = switch clean {
        case "roc", "republicofchina", "minguo", "taiwan": .republicOfChina
        case "japanese", "japan", "wareki", "jp": .japanese
        case "buddhist", "thai": .buddhist
        case "chinese", "lunar": .chinese
        case "islamic", "islamiccivil", "islamicrural", "muslim": .islamic
        case "islamicummalqura", "ummalqura": .islamicUmmAlQura
        case "hebrew", "jewish": .hebrew
        case "persian", "iran": .persian
        case "indian": .indian
        case "coptic": .coptic
        case "ethiopic", "ethiopicametemihret": .ethiopicAmeteMihret
        case "gregorian", "western", "iso": .gregorian
        default: .gregorian
        }

        return Calendar(identifier: identifier)
    }

    public static func parseTimeZone(_ raw: String?) -> TimeZone {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return TimeZone.current
        }
        let clean = raw.hasPrefix(":") ? String(raw.dropFirst()) : raw

        // 1. Check IANA / Identifier (e.g. "Asia/Taipei", "UTC", "America/New_York")
        if let tz = TimeZone(identifier: clean) {
            return tz
        }

        // 2. Check standard Abbreviation (e.g. "JST", "PST", "EST", "CST", "UTC")
        if let tz = TimeZone(abbreviation: clean) {
            return tz
        }

        // 3. Numeric offset parser (e.g. "+08:00", "+8", "-0500", "UTC+8", "GMT-5")
        var s = clean.uppercased()
        if s.hasPrefix("UTC") { s = String(s.dropFirst(3)) }
        if s.hasPrefix("GMT") { s = String(s.dropFirst(3)) }

        if let offsetTz = parseOffset(s) {
            return offsetTz
        }

        return TimeZone.current
    }

    private static func parseOffset(_ str: String) -> TimeZone? {
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first, first == "+" || first == "-" else {
            if let num = Int(trimmed) {
                return TimeZone(secondsFromGMT: num * 3600)
            }
            return nil
        }
        let sign = (first == "-") ? -1 : 1
        let rest = String(trimmed.dropFirst())

        if rest.contains(":") {
            let parts = rest.split(separator: ":")
            if let h = Int(parts[0]), let m = Int(parts.count > 1 ? parts[1] : "0") {
                return TimeZone(secondsFromGMT: sign * (h * 3600 + m * 60))
            }
        } else if rest.count == 4, let h = Int(rest.prefix(2)), let m = Int(rest.suffix(2)) {
            return TimeZone(secondsFromGMT: sign * (h * 3600 + m * 60))
        } else if let h = Int(rest) {
            return TimeZone(secondsFromGMT: sign * (h * 3600))
        }
        return nil
    }

    public static func parseLocale(_ raw: String?) -> Locale {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return Locale.autoupdatingCurrent
        }
        let clean = raw.hasPrefix(":") ? String(raw.dropFirst()) : raw
        let lower = clean.lowercased()
        if lower == "system" || lower == "current" {
            return Locale.autoupdatingCurrent
        }
        if clean.count == 4 && !clean.contains("_") && !clean.contains("-") {
            let lang = String(clean.prefix(2)).lowercased()
            let region = String(clean.suffix(2)).uppercased()
            return Locale(identifier: "\(lang)_\(region)")
        }
        return Locale(identifier: clean)
    }

    public static func format(
        date: Date = Date(),
        mode: Mode,
        formatSpec: String? = nil,
        localeSpec: String? = nil,
        timeZoneSpec: String? = nil,
        calendarSpec: String? = nil
    ) -> String {
        let preset = StylePreset.parse(formatSpec ?? "", mode: mode)
        let locale = parseLocale(localeSpec)
        let timeZone = parseTimeZone(timeZoneSpec)
        var calendar = parseCalendar(calendarSpec)
        calendar.locale = locale
        calendar.timeZone = timeZone

        if case .iso8601 = preset {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.timeZone = timeZone
            return isoFormatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.calendar = calendar

        switch preset {
        case .short:
            switch mode {
            case .date:
                formatter.dateStyle = .short
                formatter.timeStyle = .none
            case .time:
                formatter.dateStyle = .none
                formatter.timeStyle = .short
            case .dateTime:
                formatter.dateStyle = .short
                formatter.timeStyle = .short
            }

        case .medium:
            switch mode {
            case .date:
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
            case .time:
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
            case .dateTime:
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
            }

        case .long:
            switch mode {
            case .date:
                formatter.dateStyle = .long
                formatter.timeStyle = .none
            case .time:
                formatter.dateStyle = .none
                formatter.timeStyle = .long
            case .dateTime:
                formatter.dateStyle = .long
                formatter.timeStyle = .long
            }

        case .full:
            switch mode {
            case .date:
                formatter.dateStyle = .full
                formatter.timeStyle = .none
            case .time:
                formatter.dateStyle = .none
                formatter.timeStyle = .full
            case .dateTime:
                formatter.dateStyle = .full
                formatter.timeStyle = .full
            }

        case .iso8601:
            break

        case .custom(let pattern):
            formatter.dateFormat = pattern
        }

        return formatter.string(from: date)
    }
}
