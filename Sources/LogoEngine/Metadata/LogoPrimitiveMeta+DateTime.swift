import Foundation

extension LogoPrimitive {
    var dateTimeMeta: LogoPrimitiveMeta? {
        switch self {
        case .date:
            return LogoPrimitiveMeta(
                name: "DATE",
                description: "Returns formatted current date string.",
                localizedDescriptionKey: "logo.doc.date",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "format", required: false, description: "The format to use. Used by DATE.", example: "full",
                        allowedValues: ["short", "medium", "long", "full", "iso8601"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale to format the date. Used by DATE.", example: "en_US"),
                    LogoPrimitiveParameter(name: "timezone", required: false, description: "The timezone name. Used by DATE.", example: "UTC"),
                    LogoPrimitiveParameter(name: "calendar", required: false, description: "The calendar type. Used by DATE.", example: "gregorian"),
                ],
                examples: [LogoPrimitiveExample(input: "DATE")]
            )

        case .time:
            return LogoPrimitiveMeta(
                name: "TIME",
                description: "Returns formatted current time string.",
                localizedDescriptionKey: "logo.doc.time",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "format", required: false, description: "The format to use. Used by TIME.", example: "medium",
                        allowedValues: ["short", "medium", "long", "full", "iso8601"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale to format the time. Used by TIME.", example: "en_US"),
                    LogoPrimitiveParameter(name: "timezone", required: false, description: "The timezone name. Used by TIME.", example: "UTC"),
                    LogoPrimitiveParameter(name: "calendar", required: false, description: "The calendar type. Used by TIME.", example: "gregorian"),
                ],
                examples: [LogoPrimitiveExample(input: "TIME")]
            )

        case .datetime:
            return LogoPrimitiveMeta(
                name: "DATETIME",
                description: "Returns formatted current date and time string.",
                localizedDescriptionKey: "logo.doc.datetime",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "format", required: false, description: "The format to use. Used by DATETIME.", example: "iso8601",
                        allowedValues: ["short", "medium", "long", "full", "iso8601"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale to format. Used by DATETIME.", example: "en_US"),
                    LogoPrimitiveParameter(name: "timezone", required: false, description: "The timezone name. Used by DATETIME.", example: "UTC"),
                    LogoPrimitiveParameter(name: "calendar", required: false, description: "The calendar type. Used by DATETIME.", example: "gregorian"),
                ],
                examples: [LogoPrimitiveExample(input: "DATETIME")]
            )

        case .dateformat:
            return LogoPrimitiveMeta(
                name: "FORMAT.DATE",
                description: "Parses date string and reformats using locale, timezone, or custom style.",
                localizedDescriptionKey: "logo.doc.dateformat",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "dateStr", required: true, description: "The date or date-time string to parse and format.", example: "2026-12-31"),
                    LogoPrimitiveParameter(
                        name: "format", required: false, description: "The format specifier or custom date template (e.g. yyyy-MM-dd).", example: "long",
                        allowedValues: ["short", "medium", "long", "full", "iso8601"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The target locale identifier.", example: "zh_TW"),
                    LogoPrimitiveParameter(name: "timezone", required: false, description: "The target time zone (identifier or abbreviation).", example: "Asia/Taipei"),
                    LogoPrimitiveParameter(
                        name: "calendar", required: false, description: "The calendar system to use.", example: "gregorian",
                        allowedValues: ["gregorian", "japanese", "buddhist", "roc", "islamic", "hebrew", "chinese"]),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.DATE \"2026-12-31 \"full \"zh_TW")]
            )

        case .dateadd:
            return LogoPrimitiveMeta(
                name: "DATE.ADD",
                description: "Adds or subtracts date components (days, weeks, months, years) from date.",
                localizedDescriptionKey: "logo.doc.dateadd",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "dateStr", required: true, description: "The date or date-time string to change.", example: "2026-12-31"),
                    LogoPrimitiveParameter(name: "amount", required: true, description: "The number of units to add; use a negative number to subtract.", example: "7"),
                    LogoPrimitiveParameter(
                        name: "unit", required: false, description: "The unit used for the operation. Used by DATEADD.", example: "days",
                        allowedValues: ["days", "weeks", "months", "years", "hours", "minutes", "seconds"]),
                ],
                examples: [LogoPrimitiveExample(input: "DATE.ADD DATE 7 \"days")]
            )

        case .datediff:
            return LogoPrimitiveMeta(
                name: "DATE.DIFF",
                description: "Calculates time difference between two dates in specified units.",
                localizedDescriptionKey: "logo.doc.datediff",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "date1", required: true, description: "The first date or date-time string.", example: "2026-12-31"),
                    LogoPrimitiveParameter(name: "date2", required: true, description: "The second date or date-time string.", example: "2027-01-07"),
                    LogoPrimitiveParameter(
                        name: "unit", required: false, description: "The unit used for the operation. Used by DATEDIFF.", example: "days",
                        allowedValues: ["days", "weeks", "months", "years", "hours", "minutes", "seconds"]),
                ],
                examples: [LogoPrimitiveExample(input: "DATE.DIFF \"2026-12-31 DATE \"days")]
            )

        case .formatNumber:
            return LogoPrimitiveMeta(
                name: "FORMAT.NUMBER",
                description:
                    "Formats number using localized decimal, currency, percent, roman, or financial CJK uppercase.",
                localizedDescriptionKey: "logo.doc.formatnumber",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true, description: "The number to format.", example: "1234.5"),
                    LogoPrimitiveParameter(
                        name: "style", required: false, description: "The number representation to use.", example: "currency",
                        allowedValues: ["decimal", "currency", "percent", "roman", "financial", "ordinal", "spellout"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale used for decimal separators, symbols, and words.", example: "en_US"),
                    LogoPrimitiveParameter(name: "currency", required: false, description: "The ISO 4217 currency code used by the currency style.", example: "USD"),
                    LogoPrimitiveParameter(name: "precision", required: false, description: "The exact number of fraction digits for numeric styles.", example: "2"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "FORMAT.NUMBER 1234.5 \"currency \"en_US \"USD", output: "$1,234.50"),
                    LogoPrimitiveExample(input: "FORMAT.NUMBER 10050208 \"financial", output: "壹仟零伍萬零貳佰零捌"),
                ]
            )

        case .formatList:
            return LogoPrimitiveMeta(
                name: "FORMAT.LIST",
                description: "Formats list into localized natural language string (and, or, unit).",
                localizedDescriptionKey: "logo.doc.formatlist",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true, description: "The list or array to format.", example: "[A B C]"),
                    LogoPrimitiveParameter(name: "type", required: false, description: "The list conjunction style.", example: "and", allowedValues: ["and", "or", "unit"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale used for formatting.", example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.LIST [A B C] \"and \"en_US", output: "A, B, and C")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatRelativeTime:
            return LogoPrimitiveMeta(
                name: "FORMAT.RELATIVETIME",
                description: "Formats relative elapsed time description (e.g. '2 hours ago').",
                localizedDescriptionKey: "logo.doc.formatrelativetime",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "A numeric offset or target date.", example: "-2"),
                    LogoPrimitiveParameter(name: "unit", required: false, description: "The relative time unit.", example: "hour"),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale used for formatting.", example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.RELATIVETIME -2 \"hour \"en_US", output: "2 hours ago")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatBytes:
            return LogoPrimitiveMeta(
                name: "FORMAT.BYTES",
                description: "Formats byte counts into human-readable memory or file sizes (KB, MB, GB).",
                localizedDescriptionKey: "logo.doc.formatbytes",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "bytes", required: true, description: "The bytes argument. Used by FORMATBYTES.", example: "value"),
                    LogoPrimitiveParameter(
                        name: "style", required: false, description: "The formatting or border style. Used by FORMATBYTES.", example: "file", allowedValues: ["file", "memory", "binary", "decimal", "bytes"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale identifier. Used by FORMATBYTES.", example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.BYTES 1048576", output: "1 MB")]
            )

        case .formatName:
            return LogoPrimitiveMeta(
                name: "FORMAT.NAME",
                description: "Formats person name components (given, middle, family, prefix, suffix, nickname) into localized name strings.",
                localizedDescriptionKey: "logo.doc.formatname",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "givenOrFullName", required: true, description: "A full name string, given name, or property list [given family middle prefix suffix nickname ...].", example: "Arthur"),
                    LogoPrimitiveParameter(name: "middleOrFamilyOrStyle", required: false, description: "Middle name, family name, or display style.", example: "Conan"),
                    LogoPrimitiveParameter(name: "familyOrStyle", required: false, description: "Family name or display style.", example: "Doyle"),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Display style (short, medium, long, abbreviated).", example: "long", allowedValues: ["medium", "short", "long", "abbreviated"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale (e.g. en_US, zh_TW, ja_JP).", example: "en_US"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "FORMAT.NAME \"Arthur \"Conan \"Doyle \"long", output: "Arthur Conan Doyle"),
                    LogoPrimitiveExample(input: "FORMAT.NAME \"Steve \"Jobs \"abbreviated", output: "S. Jobs"),
                    LogoPrimitiveExample(input: "FORMAT.NAME [given \"Arthur middle \"Conan family \"Doyle] \"short", output: "Arthur"),
                ],
                notes: "Supports positional inputs (given family / given middle family), full name strings, and property lists ([given ... middle ... family ... prefix ... suffix ... nickname ...])."
            )

        default:
            return nil
        }
    }
}
