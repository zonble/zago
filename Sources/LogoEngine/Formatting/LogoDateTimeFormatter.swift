import Foundation

/// Advanced Foundation-powered Date and Time Formatter for LogoEngine.
public struct LogoDateTimeFormatter {
    public typealias Mode = LogoDateTimeMode
    public typealias StylePreset = LogoDateTimeStylePreset

    public static func isCalendarName(_ name: String) -> Bool {
        Calendar.Identifier(logoCalendarName: name) != nil
    }

    public static func isStylePresetName(_ name: String) -> Bool {
        LogoDateTimeStylePreset.isPresetName(name)
    }

    public static func isLocaleName(_ name: String) -> Bool {
        Locale.isLogoLocaleSpec(name)
    }

    public static func isTimeZoneName(_ name: String) -> Bool {
        TimeZone.isLogoTimeZoneSpec(name)
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

        // If calendar is specified without explicit locale, pick natural matching locale
        if locale == nil, let cal, let identifier = Calendar.Identifier(logoCalendarName: cal) {
            locale = identifier.defaultLocaleIdentifier
        }

        // If non-gregorian calendar is specified without explicit format, default to long localized date
        if format == nil, let cal, let identifier = Calendar.Identifier(logoCalendarName: cal), identifier != .gregorian {
            format = "long"
        }

        return (format, locale, tz, cal)
    }

    public static func parseCalendar(_ raw: String?) -> Calendar {
        Calendar(identifier: Calendar.Identifier(logoCalendarName: raw) ?? .gregorian)
    }

    public static func parseTimeZone(_ raw: String?) -> TimeZone {
        TimeZone(logoTimeZoneSpec: raw)
    }

    public static func parseLocale(_ raw: String?) -> Locale {
        Locale(logoLocaleSpec: raw)
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

    public static func calendarIdentifier(for name: String?) -> Calendar.Identifier {
        Calendar.Identifier(logoCalendarName: name) ?? .gregorian
    }

    public static func defaultLocaleForCalendar(_ identifier: Calendar.Identifier) -> String? {
        identifier.defaultLocaleIdentifier
    }

    public static func calendarName(for identifier: Calendar.Identifier) -> String {
        identifier.logoCalendarName
    }

    public static func formatDateValue(_ date: Date, calendar: Calendar.Identifier, timeZone: TimeZone) -> String {
        let calName = calendarName(for: calendar)
        let locale = defaultLocaleForCalendar(calendar)
        if calendar == .gregorian {
            let cal = Calendar(identifier: .gregorian)
            let comps = cal.dateComponents(in: timeZone, from: date)
            if (comps.hour ?? 0) != 0 || (comps.minute ?? 0) != 0 || (comps.second ?? 0) != 0 {
                return format(date: date, mode: .dateTime, formatSpec: "yyyy-MM-dd HH:mm:ss", localeSpec: locale, timeZoneSpec: timeZone.identifier, calendarSpec: calName)
            } else {
                return format(date: date, mode: .date, formatSpec: "yyyy-MM-dd", localeSpec: locale, timeZoneSpec: timeZone.identifier, calendarSpec: calName)
            }
        }
        return format(date: date, mode: .date, formatSpec: "long", localeSpec: locale, timeZoneSpec: timeZone.identifier, calendarSpec: calName)
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
