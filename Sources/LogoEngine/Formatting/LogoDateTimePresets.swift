import Foundation

/// Defines formatting modes for LOGO date/time operations.
public enum LogoDateTimeMode: Sendable, Equatable {
    case date
    case time
    case dateTime

    public init?(raw: String) {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        switch stripped {
        case "date": self = .date
        case "time": self = .time
        case "datetime", "date_time", "dateTime": self = .dateTime
        default: return nil
        }
    }
}

/// Supported style presets and custom pattern specifications for date/time formatting.
public enum LogoDateTimeStylePreset: Sendable, Equatable {
    case short
    case medium
    case long
    case full
    case iso8601
    case custom(String)

    public init(raw: String, mode: LogoDateTimeMode) {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
        switch clean {
        case "short": self = .short
        case "medium", "med": self = .medium
        case "long": self = .long
        case "full": self = .full
        case "iso8601", "iso": self = .iso8601
        default:
            if clean.isEmpty {
                switch mode {
                case .date: self = .custom("yyyy-MM-dd")
                case .time: self = .custom("HH:mm:ss")
                case .dateTime: self = .custom("yyyy-MM-dd HH:mm:ss")
                }
            } else {
                self = .custom(raw)
            }
        }
    }

    public static func parse(_ raw: String, mode: LogoDateTimeMode) -> LogoDateTimeStylePreset {
        LogoDateTimeStylePreset(raw: raw, mode: mode)
    }

    public static func isPresetName(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        switch stripped {
        case "short", "medium", "med", "long", "full", "iso8601", "iso":
            return true
        default:
            return false
        }
    }

    public var dateStyle: DateFormatter.Style? {
        switch self {
        case .short: return .short
        case .medium: return .medium
        case .long: return .long
        case .full: return .full
        default: return nil
        }
    }
}

extension Locale {
    private static let commonLanguageCodes: Set<String> = [
        "zh", "en", "ja", "fr", "de", "es", "it", "ko", "th", "ru", "pt"
    ]

    public init(logoLocaleSpec raw: String?) {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            self = .autoupdatingCurrent
            return
        }
        let clean = raw.hasPrefix(":") ? String(raw.dropFirst()) : raw
        let lower = clean.lowercased()
        if lower == "system" || lower == "current" {
            self = .autoupdatingCurrent
            return
        }
        if clean.count == 4 && !clean.contains("_") && !clean.contains("-") {
            let lang = String(clean.prefix(2)).lowercased()
            let region = String(clean.suffix(2)).uppercased()
            self = Locale(identifier: "\(lang)_\(region)")
            return
        }
        self = Locale(identifier: clean)
    }

    public static func isLogoLocaleSpec(_ name: String) -> Bool {
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
            if commonLanguageCodes.contains(lang) {
                return true
            }
        }
        return commonLanguageCodes.contains(lower)
    }
}

extension TimeZone {
    public init(logoTimeZoneSpec raw: String?) {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            self = .current
            return
        }
        let clean = raw.hasPrefix(":") ? String(raw.dropFirst()) : raw

        // 1. IANA Identifier (e.g. "Asia/Taipei", "America/New_York")
        if let tz = TimeZone(identifier: clean) {
            self = tz
            return
        }

        // 2. Standard Abbreviation (e.g. "JST", "PST", "UTC")
        if let tz = TimeZone(abbreviation: clean) {
            self = tz
            return
        }

        // 3. Numeric offset parser (e.g. "+08:00", "+8", "-0500", "UTC+8", "GMT-5")
        var s = clean.uppercased()
        if s.hasPrefix("UTC") { s = String(s.dropFirst(3)) }
        if s.hasPrefix("GMT") { s = String(s.dropFirst(3)) }

        if let offsetTz = Self.parseNumericOffset(s) {
            self = offsetTz
            return
        }

        self = .current
    }

    public static func isLogoTimeZoneSpec(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        if stripped.hasPrefix("+") || stripped.hasPrefix("-") { return true }
        let upper = stripped.uppercased()
        if upper.hasPrefix("UTC") || upper.hasPrefix("GMT") || upper == "Z" { return true }
        return TimeZone(identifier: stripped) != nil || TimeZone(abbreviation: stripped) != nil
    }

    public static func parseNumericOffset(_ str: String) -> TimeZone? {
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
}

extension Calendar.Component {
    public init(_ rawUnit: String) {
        let cleanUnit = rawUnit.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\""))
        switch cleanUnit {
        case "second", "seconds", "sec", "s": self = .second
        case "minute", "minutes", "min": self = .minute
        case "hour", "hours", "h": self = .hour
        case "day", "days", "d": self = .day
        case "week", "weeks", "w": self = .weekOfYear
        case "month", "months", "m": self = .month
        case "year", "years", "y": self = .year
        default: self = .day
        }
    }
}

extension Calendar.Identifier {
    public init?(logoCalendarName: String?) {
        guard let raw = logoCalendarName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else {
            return nil
        }
        let clean = raw.hasPrefix(":") ? String(raw.dropFirst()) : raw
        switch clean {
        case "roc", "republicofchina", "minguo", "taiwan":
            self = .republicOfChina
        case "japanese", "japan", "wareki", "jp":
            self = .japanese
        case "buddhist", "thai":
            self = .buddhist
        case "chinese", "lunar":
            self = .chinese
        case "islamic", "islamiccivil", "islamicrural", "muslim":
            self = .islamic
        case "islamicummalqura", "ummalqura":
            self = .islamicUmmAlQura
        case "hebrew", "jewish":
            self = .hebrew
        case "persian", "iran":
            self = .persian
        case "indian":
            self = .indian
        case "coptic":
            self = .coptic
        case "ethiopic", "ethiopicametemihret":
            self = .ethiopicAmeteMihret
        case "gregorian", "western", "iso":
            self = .gregorian
        default:
            return nil
        }
    }

    public var logoCalendarName: String {
        switch self {
        case .republicOfChina: return "roc"
        case .japanese: return "japanese"
        case .buddhist: return "buddhist"
        case .chinese: return "chinese"
        case .islamic: return "islamic"
        case .islamicUmmAlQura: return "ummalqura"
        case .hebrew: return "hebrew"
        case .persian: return "persian"
        case .indian: return "indian"
        case .coptic: return "coptic"
        case .ethiopicAmeteMihret: return "ethiopic"
        case .gregorian: return "gregorian"
        default: return "gregorian"
        }
    }

    public var defaultLocaleIdentifier: String? {
        switch self {
        case .republicOfChina, .chinese: return "zh_TW"
        case .japanese: return "ja_JP"
        case .buddhist: return "th_TH"
        default: return nil
        }
    }
}
