import Foundation

/// Internal date parsing engine for LOGO date/time inputs.
enum LogoDateTimeParser {
    private static let standardPatterns = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy/MM/dd",
        "yyyy.MM.dd",
        "MM/dd/yyyy",
        "dd/MM/yyyy",
        "y-MM-dd HH:mm:ss",
        "y-MM-dd",
        "y/MM/dd",
        "y.MM.dd",
        "y-M-d",
        "y/M/d",
        "HH:mm:ss",
    ]

    private static let eraPatterns = [
        "Gy年M月d日",
        "G y年M月d日",
        "G y年MM月dd日",
        "Gy年MM月dd日",
        "y年M月d日",
        "y年MM月dd日",
    ]

    private static let japaneseEraNames = ["令和", "平成", "昭和", "大正", "明治"]

    static func parseDate(
        _ raw: String,
        defaultCalendar: Calendar = Calendar(identifier: .gregorian),
        defaultTimeZone: TimeZone = TimeZone.current
    ) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lower = trimmed.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\""))
        if lower == "now" || lower == "today" {
            return Date()
        }

        if (trimmed.hasPrefix("[") && trimmed.hasSuffix("]")) || (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) {
            let parsed = LogoValue.parse(trimmed)
            if case .list(let items) = parsed {
                return parseDateFromList(items, defaultCalendar: defaultCalendar, defaultTimeZone: defaultTimeZone)
            } else if case .array(let items) = parsed {
                return parseDateFromList(items, defaultCalendar: defaultCalendar, defaultTimeZone: defaultTimeZone)
            }
        }

        if let timestamp = Double(lower), timestamp > 100000 {
            return Date(timeIntervalSince1970: timestamp)
        }

        // Check if string contains ROC era characters ("民國")
        if trimmed.contains("民國"),
           let d = parseEraDate(trimmed, calendarIdentifier: .republicOfChina, localeIdentifier: "zh_TW", timeZone: defaultTimeZone) {
            return d
        }

        // Check if string contains Japanese era names
        if japaneseEraNames.contains(where: { trimmed.contains($0) }),
           let d = parseEraDate(trimmed, calendarIdentifier: .japanese, localeIdentifier: "ja_JP", timeZone: defaultTimeZone) {
            return d
        }

        let iso = ISO8601DateFormatter()
        iso.timeZone = defaultTimeZone
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: trimmed) { return d }

        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: trimmed) { return d }

        // If year looks like a 4-digit Gregorian year (> 1000), use Gregorian calendar
        let calToUse: Calendar
        if let firstToken = trimmed.split(whereSeparator: { !$0.isNumber }).first,
           let num = Int(firstToken), num > 1000 {
            calToUse = Calendar(identifier: .gregorian)
        } else {
            calToUse = defaultCalendar
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = defaultTimeZone
        formatter.calendar = calToUse

        for pattern in standardPatterns {
            formatter.dateFormat = pattern
            if let d = formatter.date(from: trimmed) {
                return d
            }
        }

        return nil
    }

    private static func parseEraDate(
        _ text: String,
        calendarIdentifier: Calendar.Identifier,
        localeIdentifier: String,
        timeZone: TimeZone
    ) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.calendar = Calendar(identifier: calendarIdentifier)
        formatter.timeZone = timeZone
        for pattern in eraPatterns {
            formatter.dateFormat = pattern
            if let d = formatter.date(from: text) { return d }
        }
        return nil
    }

    static func parseDateFromList(
        _ items: [LogoValue],
        defaultCalendar: Calendar,
        defaultTimeZone: TimeZone
    ) -> Date? {
        guard !items.isEmpty else { return nil }

        var isPlist = false
        var year: Int? = nil
        var month: Int? = nil
        var day: Int? = nil
        var hour: Int? = nil
        var minute: Int? = nil
        var second: Int? = nil
        var tz: TimeZone = defaultTimeZone
        var cal: Calendar = defaultCalendar

        var i = 0
        while i < items.count {
            let key = items[i].stringValue.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\""))
            if isComponentKey(key) && i + 1 < items.count {
                isPlist = true
                let valStr = items[i + 1].stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                switch key {
                case "year", "y": year = Int(valStr)
                case "month", "m": month = Int(valStr)
                case "day", "d": day = Int(valStr)
                case "hour", "h": hour = Int(valStr)
                case "minute", "min": minute = Int(valStr)
                case "second", "sec", "s": second = Int(valStr)
                case "tz", "timezone": tz = TimeZone(logoTimeZoneSpec: valStr)
                case "cal", "calendar": cal = Calendar(identifier: Calendar.Identifier(logoCalendarName: valStr) ?? .gregorian)
                default: break
                }
                i += 2
            } else {
                i += 1
            }
        }

        if isPlist {
            let yearNum = year ?? cal.component(.year, from: Date())
            let inputCal = (yearNum > 1000) ? Calendar(identifier: .gregorian) : cal
            var comps = DateComponents()
            comps.calendar = inputCal
            comps.timeZone = tz
            comps.year = yearNum
            comps.month = month ?? 1
            comps.day = day ?? 1
            comps.hour = hour ?? 0
            comps.minute = minute ?? 0
            comps.second = second ?? 0
            return inputCal.date(from: comps)
        }

        var nums: [Int] = []
        for item in items {
            let s = item.stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if let n = Int(s) {
                nums.append(n)
            } else if TimeZone.isLogoTimeZoneSpec(s) {
                tz = TimeZone(logoTimeZoneSpec: s)
            } else if Calendar.Identifier(logoCalendarName: s) != nil {
                cal = Calendar(identifier: Calendar.Identifier(logoCalendarName: s) ?? .gregorian)
            }
        }

        guard !nums.isEmpty else { return nil }

        let yearNum = nums.count > 0 ? nums[0] : cal.component(.year, from: Date())
        let inputCal = (yearNum > 1000) ? Calendar(identifier: .gregorian) : cal
        var comps = DateComponents()
        comps.calendar = inputCal
        comps.timeZone = tz
        comps.year = yearNum
        comps.month = nums.count > 1 ? nums[1] : 1
        comps.day = nums.count > 2 ? nums[2] : 1
        comps.hour = nums.count > 3 ? nums[3] : 0
        comps.minute = nums.count > 4 ? nums[4] : 0
        comps.second = nums.count > 5 ? nums[5] : 0
        return inputCal.date(from: comps)
    }

    private static func isComponentKey(_ key: String) -> Bool {
        switch key {
        case "year", "y", "month", "m", "day", "d",
             "hour", "h", "min", "minute", "sec", "second", "s",
             "tz", "timezone", "cal", "calendar":
            return true
        default:
            return false
        }
    }
}
