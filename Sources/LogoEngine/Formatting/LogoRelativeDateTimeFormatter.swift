import Foundation

/// Advanced Foundation-powered Relative Date and Time formatter for LogoEngine.
public enum LogoRelativeDateTimeFormatter {
    public static func isRelativeTimeUnit(_ raw: String) -> Bool {
        let clean = raw.trimmingCharacters(in: CharacterSet(charactersIn: ":\"' ")).lowercased()
        return [
            "second", "seconds", "sec", "s",
            "minute", "minutes", "min",
            "hour", "hours", "h", "hr", "hrs",
            "day", "days", "d",
            "week", "weeks", "w",
            "month", "months", "m", "mon",
            "year", "years", "y", "yr", "yrs",
        ].contains(clean)
    }

    public static func disambiguateOptions(
        _ args: [String],
        unit: inout String,
        locale: inout String?
    ) {
        for arg in args {
            let clean = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; ")).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if isRelativeTimeUnit(lower) {
                unit = lower
            } else {
                locale = clean
            }
        }
    }

    public static func formatTime(
        value: Double,
        unit: String,
        locale: String? = nil
    ) -> String {
        #if os(Linux) || os(Windows)
            return ""
        #else
            let loc = Locale(logoLocaleSpec: locale)
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = loc
            formatter.unitsStyle = .full
            formatter.dateTimeStyle = .named

            let cleanUnit = unit.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\"' "))
            var comps = DateComponents()
            switch cleanUnit {
            case "second", "seconds", "sec", "s": comps.second = Int(value)
            case "minute", "minutes", "min": comps.minute = Int(value)
            case "hour", "hours", "h", "hr", "hrs": comps.hour = Int(value)
            case "day", "days", "d": comps.day = Int(value)
            case "week", "weeks", "w": comps.weekOfYear = Int(value)
            case "month", "months", "m", "mon": comps.month = Int(value)
            case "year", "years", "y", "yr", "yrs": comps.year = Int(value)
            default: comps.day = Int(value)
            }
            return formatter.localizedString(from: comps)
        #endif
    }

    public static func formatDate(
        target: Date,
        reference: Date = Date(),
        locale: String? = nil
    ) -> String {
        #if os(Linux) || os(Windows)
            return ""
        #else
            let loc = Locale(logoLocaleSpec: locale)
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = loc
            formatter.unitsStyle = .full
            formatter.dateTimeStyle = .named
            return formatter.localizedString(for: target, relativeTo: reference)
        #endif
    }
}
