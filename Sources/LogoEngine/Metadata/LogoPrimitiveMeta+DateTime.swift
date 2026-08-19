import Foundation

private let presetAllowedValues = LogoDateTimeStylePreset.allowedPresetNames
private let calendarAllowedValues = Calendar.Identifier.supportedLogoCalendarNames
private let unitAllowedValues = Calendar.Component.supportedLogoUnitNames

private func currentDateTimeParameters(
    for commandName: String,
    formatExample: String,
    localeDescription: String
) -> [LogoPrimitiveParameter] {
    [
        LogoPrimitiveParameter(
            name: "format", required: false, description: "The format to use. Used by \(commandName).",
            example: formatExample,
            allowedValues: presetAllowedValues),
        LogoPrimitiveParameter(
            name: "locale", required: false, description: localeDescription,
            example: "en_US"),
        LogoPrimitiveParameter(
            name: "timezone", required: false, description: "The timezone name. Used by \(commandName).",
            example: "UTC"),
        LogoPrimitiveParameter(
            name: "calendar", required: false, description: "The calendar type. Used by \(commandName).",
            example: "gregorian",
            allowedValues: calendarAllowedValues),
    ]
}

extension LogoPrimitive {
    var dateTimeMeta: LogoPrimitiveMeta? {
        return switch self {
        case .date:
            LogoPrimitiveMeta(
                name: "DATE",
                description: "Returns formatted current date string.",
                localizedDescriptionKey: "logo.doc.date",
                source: .zago,
                parameters: currentDateTimeParameters(
                    for: "DATE", formatExample: "full",
                    localeDescription: "The locale to format the date. Used by DATE."),
                examples: [LogoPrimitiveExample(input: "DATE")]
            )

        case .time:
            LogoPrimitiveMeta(
                name: "TIME",
                description: "Returns formatted current time string.",
                localizedDescriptionKey: "logo.doc.time",
                source: .zago,
                parameters: currentDateTimeParameters(
                    for: "TIME", formatExample: "medium",
                    localeDescription: "The locale to format the time. Used by TIME."),
                examples: [LogoPrimitiveExample(input: "TIME")]
            )

        case .datetime:
            LogoPrimitiveMeta(
                name: "DATETIME",
                description: "Returns formatted current date and time string.",
                localizedDescriptionKey: "logo.doc.datetime",
                source: .zago,
                parameters: currentDateTimeParameters(
                    for: "DATETIME", formatExample: "iso8601",
                    localeDescription: "The locale to format. Used by DATETIME."),
                examples: [LogoPrimitiveExample(input: "DATETIME")]
            )

        case .dateformat:
            LogoPrimitiveMeta(
                name: "FORMAT.DATE",
                description: "Parses date string and reformats using locale, timezone, or custom style.",
                localizedDescriptionKey: "logo.doc.dateformat",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "dateStr", required: true,
                        description: "The date or date-time string to parse and format.", example: "2026-12-31"),
                    LogoPrimitiveParameter(
                        name: "format", required: false,
                        description: "The format specifier or custom date template (e.g. yyyy-MM-dd).", example: "long",
                        allowedValues: presetAllowedValues),
                    LogoPrimitiveParameter(
                        name: "locale", required: false, description: "The target locale identifier.", example: "zh_TW"),
                    LogoPrimitiveParameter(
                        name: "timezone", required: false,
                        description: "The target time zone (identifier or abbreviation).", example: "Asia/Taipei"),
                    LogoPrimitiveParameter(
                        name: "calendar", required: false, description: "The calendar system to use.",
                        example: "gregorian",
                        allowedValues: calendarAllowedValues),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.DATE \"2026-12-31 \"full \"zh_TW")]
            )

        case .dateadd:
            LogoPrimitiveMeta(
                name: "DATE.ADD",
                description: "Adds or subtracts date components (days, weeks, months, years) from date.",
                localizedDescriptionKey: "logo.doc.dateadd",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "dateStr", required: true, description: "The date or date-time string to change.",
                        example: "2026-12-31"),
                    LogoPrimitiveParameter(
                        name: "amount", required: true,
                        description: "The number of units to add; use a negative number to subtract.", example: "7"),
                    LogoPrimitiveParameter(
                        name: "unit", required: false, description: "The unit used for the operation. Used by DATEADD.",
                        example: "days",
                        allowedValues: unitAllowedValues),
                ],
                examples: [LogoPrimitiveExample(input: "DATE.ADD DATE 7 \"days")]
            )

        case .datediff:
            LogoPrimitiveMeta(
                name: "DATE.DIFF",
                description: "Calculates time difference between two dates in specified units.",
                localizedDescriptionKey: "logo.doc.datediff",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "date1", required: true, description: "The first date or date-time string.",
                        example: "2026-12-31"),
                    LogoPrimitiveParameter(
                        name: "date2", required: true, description: "The second date or date-time string.",
                        example: "2027-01-07"),
                    LogoPrimitiveParameter(
                        name: "unit", required: false,
                        description: "The unit used for the operation. Used by DATEDIFF.", example: "days",
                        allowedValues: unitAllowedValues),
                ],
                examples: [LogoPrimitiveExample(input: "DATE.DIFF \"2026-12-31 DATE \"days")]
            )

        case .formatRelativeTime:
            LogoPrimitiveMeta(
                name: "FORMAT.RELATIVETIME",
                description: "Formats relative elapsed time description (e.g. '2 hours ago').",
                localizedDescriptionKey: "logo.doc.formatrelativetime",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "A numeric offset or target date.", example: "-2"),
                    LogoPrimitiveParameter(
                        name: "unit", required: false, description: "The relative time unit.", example: "hour"),
                    LogoPrimitiveParameter(
                        name: "locale", required: false, description: "The locale used for formatting.",
                        example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.RELATIVETIME -2 \"hour \"en_US", output: "2 hours ago")],
                notes: "Not supported on Linux or Windows."
            )

        case .convertCalendar:
            LogoPrimitiveMeta(
                name: "CONVERT.CALENDAR",
                description: "Converts date between calendar systems (e.g. Gregorian, ROC, Japanese Wareki, Buddhist).",
                localizedDescriptionKey: "logo.doc.convertcalendar",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "date", required: true,
                        description: "The date string, date value, or date components list to convert.", example: "2026-08-19"),
                    LogoPrimitiveParameter(
                        name: "targetCalendar", required: true,
                        description: "The target calendar system.", example: "roc",
                        allowedValues: calendarAllowedValues),
                    LogoPrimitiveParameter(
                        name: "sourceCalendar", required: false,
                        description: "The source calendar system if input date is not in Gregorian calendar.", example: "roc",
                        allowedValues: calendarAllowedValues),
                    LogoPrimitiveParameter(
                        name: "format", required: false,
                        description: "Optional custom date format pattern for output.", example: "yyyy/MM/dd"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "CONVERT.CALENDAR \"2026-08-19 \"roc", output: "民國115年8月19日"),
                    LogoPrimitiveExample(input: "CONVERT.CALENDAR \"2026-08-19 \"japanese", output: "令和8年8月19日"),
                    LogoPrimitiveExample(input: "CONVERT.CALENDAR \"民國115年8月19日 \"gregorian", output: "2026-08-19"),
                ]
            )

        default:
            nil
        }
    }
}
