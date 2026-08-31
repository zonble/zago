import Foundation

/// Advanced Foundation-powered Date and Time Formatter for LogoEngine.
public struct LogoDateTimeFormatter {
    public typealias Mode = LogoDateTimeMode
    public typealias StylePreset = LogoDateTimeStylePreset

    public static func resolveArguments(
        _ args: [String],
        mode: Mode,
        registry: LogoPluginRegistry? = nil
    ) -> (format: String?, locale: String?, tz: String?, cal: String?) {
        var format: String? = nil
        var locale: String? = nil
        var tz: String? = nil
        var cal: String? = nil

        for arg in args {
            let clean = arg.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if let parsedCal = registry?.parseCalendarIdentifier(clean) ?? registry?.parseCalendarIdentifier(lower)
                ?? Calendar.Identifier(logoCalendarName: lower)
            {
                if cal == nil {
                    cal = parsedCal.logoCalendarName
                }
            } else if Locale.isLogoLocaleSpec(clean) && locale == nil {
                locale = clean
            } else if TimeZone.isLogoTimeZoneSpec(clean) && tz == nil {
                tz = clean
            } else if (registry?.parseDateTimeStylePreset(clean) != nil
                || registry?.parseDateTimeStylePreset(lower) != nil || StylePreset.isPresetName(lower)) && format == nil
            {
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

        // If calendar is specified without explicit locale, pick natural matching locale
        if locale == nil, let cal, let identifier = Calendar.Identifier(logoCalendarName: cal) {
            locale = identifier.defaultLocaleIdentifier
        }

        // If non-gregorian calendar is specified without explicit format, default to long localized date
        if format == nil, let cal, let identifier = Calendar.Identifier(logoCalendarName: cal), identifier != .gregorian
        {
            format = "long"
        }

        return (format, locale, tz, cal)
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
        let locale = Locale(logoLocaleSpec: localeSpec)
        let timeZone = TimeZone(logoTimeZoneSpec: timeZoneSpec)
        var calendar = Calendar(identifier: Calendar.Identifier(logoCalendarName: calendarSpec) ?? .gregorian)
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

        if let style = preset.dateStyle {
            switch mode {
            case .date:
                formatter.dateStyle = style
                formatter.timeStyle = .none
            case .time:
                formatter.dateStyle = .none
                formatter.timeStyle = style
            case .dateTime:
                formatter.dateStyle = style
                formatter.timeStyle = style
            }
        } else if case .custom(let pattern) = preset {
            formatter.dateFormat = pattern
        }

        return formatter.string(from: date)
    }

    public static func formatDateValue(_ date: Date, calendar: Calendar.Identifier, timeZone: TimeZone) -> String {
        let calName = calendar.logoCalendarName
        let locale = calendar.defaultLocaleIdentifier
        if calendar == .gregorian {
            let cal = Calendar(identifier: .gregorian)
            let comps = cal.dateComponents(in: timeZone, from: date)
            if (comps.hour ?? 0) != 0 || (comps.minute ?? 0) != 0 || (comps.second ?? 0) != 0 {
                return format(
                    date: date, mode: .dateTime, formatSpec: "yyyy-MM-dd HH:mm:ss", localeSpec: locale,
                    timeZoneSpec: timeZone.identifier, calendarSpec: calName)
            } else {
                return format(
                    date: date, mode: .date, formatSpec: "yyyy-MM-dd", localeSpec: locale,
                    timeZoneSpec: timeZone.identifier, calendarSpec: calName)
            }
        }
        return format(
            date: date, mode: .date, formatSpec: "long", localeSpec: locale, timeZoneSpec: timeZone.identifier,
            calendarSpec: calName)
    }

    public static func parseDate(
        _ raw: String,
        defaultCalendar: Calendar = Calendar(identifier: .gregorian),
        defaultTimeZone: TimeZone = TimeZone.current
    ) -> Date? {
        LogoDateTimeParser.parseDate(raw, defaultCalendar: defaultCalendar, defaultTimeZone: defaultTimeZone)
    }

    public static func add(
        to date: Date,
        amount: Int,
        unit: String,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Date {
        let component = Calendar.Component(unit)
        return calendar.date(byAdding: component, value: amount, to: date) ?? date
    }

    public static func diff(
        between d1: Date,
        and d2: Date,
        unit: String,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Int {
        let component = Calendar.Component(unit)
        let comps = calendar.dateComponents([component], from: d2, to: d1)
        return switch component {
        case .second: comps.second ?? 0
        case .minute: comps.minute ?? 0
        case .hour: comps.hour ?? 0
        case .day: comps.day ?? 0
        case .weekOfYear: comps.weekOfYear ?? 0
        case .month: comps.month ?? 0
        case .year: comps.year ?? 0
        default: comps.day ?? 0
        }
    }
}
