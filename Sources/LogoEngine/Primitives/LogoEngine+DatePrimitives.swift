import Foundation

extension LogoEngine {
    /// Date & Calendar Primitives Evaluator (`evaluateDatePrimitives`)
    ///
    /// Evaluates `DATE`, `TIME`, `DATETIME`, `DATEFORMAT`, `DATEADD`, `DATEDIFF`, `CONVERT.CALENDAR`.
    internal func evaluateDatePrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = parsePrimitive(tokens[index]) else { return nil }

        switch prim {
        case .date:
            return evaluateDateTimePrimitive(mode: .date, tokens: tokens, index: &index)

        case .time:
            return evaluateDateTimePrimitive(mode: .time, tokens: tokens, index: &index)

        case .datetime:
            return evaluateDateTimePrimitive(mode: .dateTime, tokens: tokens, index: &index)

        case .dateformat:
            return evaluateDateFormatPrimitive(tokens: tokens, index: &index)

        case .dateadd:
            return evaluateDateAddPrimitive(tokens: tokens, index: &index)

        case .datediff:
            return evaluateDateDiffPrimitive(tokens: tokens, index: &index)

        case .convertCalendar:
            return evaluateConvertCalendarPrimitive(tokens: tokens, index: &index)

        default:
            return nil
        }
    }

    private func evaluateDateTimePrimitive(
        mode: LogoDateTimeFormatter.Mode,
        tokens: [String],
        index: inout Int
    ) -> String {
        var formatSpec: String? = nil
        var localeSpec: String? = nil
        var timeZoneSpec: String? = nil
        var calendarSpec: String? = nil

        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        if reader.peekToken() == "[" {
            let rawList = reader.nextExpression()
            let parsed = LogoValue.parse(rawList)
            if case .list(let items) = parsed {
                var isDict = false
                var i = 0
                while i < items.count {
                    let key = items[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                    if (cleanKey == "format" || cleanKey == "fmt" || cleanKey == "locale" || cleanKey == "lang"
                        || cleanKey == "tz" || cleanKey == "timezone" || cleanKey == "calendar" || cleanKey == "cal")
                        && i + 1 < items.count
                    {
                        isDict = true
                        let val = items[i + 1].stringValue
                        switch cleanKey {
                        case "format", "fmt": formatSpec = val
                        case "locale", "lang": localeSpec = val
                        case "tz", "timezone": timeZoneSpec = val
                        case "calendar", "cal": calendarSpec = val
                        default: break
                        }
                        i += 2
                    } else {
                        i += 1
                    }
                }

                if !isDict {
                    let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(
                        items.map { $0.stringValue }, mode: mode, registry: pluginRegistry)
                    formatSpec = f
                    localeSpec = l
                    timeZoneSpec = tz
                    calendarSpec = cal
                }
            }
        } else {
            var positional: [String] = []
            while positional.count < 4,
                let val = reader.nextOptionalExpression()
            {
                let clean = unquote(val)
                positional.append(clean)
            }

            if !positional.isEmpty {
                let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(
                    positional, mode: mode, registry: pluginRegistry)
                formatSpec = f
                localeSpec = l
                timeZoneSpec = tz
                calendarSpec = cal
            }
        }

        reader.commit(to: &index)

        let result = LogoDateTimeFormatter.format(
            mode: mode,
            formatSpec: formatSpec,
            localeSpec: localeSpec,
            timeZoneSpec: timeZoneSpec,
            calendarSpec: calendarSpec
        )
        setLastExpressionDateTime(result)
        return result
    }

    private func evaluateDateFormatPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let dateVal = reader.nextOptionalExpression() else { return "" }

        var formatSpec: String? = nil
        var localeSpec: String? = nil
        var timeZoneSpec: String? = nil
        var calendarSpec: String? = nil

        if reader.peekToken() == "[" {
            let rawList = reader.nextExpression()
            let parsed = LogoValue.parse(rawList)
            if case .list(let items) = parsed {
                var isDict = false
                var i = 0
                while i < items.count {
                    let key = items[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                    if (cleanKey == "format" || cleanKey == "fmt" || cleanKey == "locale" || cleanKey == "lang"
                        || cleanKey == "tz" || cleanKey == "timezone" || cleanKey == "calendar" || cleanKey == "cal")
                        && i + 1 < items.count
                    {
                        isDict = true
                        let val = items[i + 1].stringValue
                        switch cleanKey {
                        case "format", "fmt": formatSpec = val
                        case "locale", "lang": localeSpec = val
                        case "tz", "timezone": timeZoneSpec = val
                        case "calendar", "cal": calendarSpec = val
                        default: break
                        }
                        i += 2
                    } else {
                        i += 1
                    }
                }

                if !isDict {
                    let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(
                        items.map { $0.stringValue }, mode: .dateTime)
                    formatSpec = f
                    localeSpec = l
                    timeZoneSpec = tz
                    calendarSpec = cal
                }
            }
        } else {
            var positional: [String] = []
            while positional.count < 4,
                let val = reader.nextOptionalExpression()
            {
                let clean = unquote(val)
                positional.append(clean)
            }

            if !positional.isEmpty {
                let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(positional, mode: .dateTime)
                formatSpec = f
                localeSpec = l
                timeZoneSpec = tz
                calendarSpec = cal
            }
        }

        reader.commit(to: &index)

        let parsedTz = TimeZone(logoTimeZoneSpec: timeZoneSpec)
        let parsedDate: Date
        let parsedVal = LogoValue.parse(dateVal)
        switch parsedVal {
        case .date(let d, _, _):
            parsedDate = d
        default:
            parsedDate = LogoDateTimeFormatter.parseDate(dateVal, defaultTimeZone: parsedTz) ?? Date()
        }

        let hasTime = dateVal.contains(":") || (dateVal.contains("T") && dateVal.contains(":"))
        let mode: LogoDateTimeFormatter.Mode = hasTime ? .dateTime : .date

        let result = LogoDateTimeFormatter.format(
            date: parsedDate,
            mode: mode,
            formatSpec: formatSpec,
            localeSpec: localeSpec,
            timeZoneSpec: timeZoneSpec,
            calendarSpec: calendarSpec
        )
        setLastExpressionDateTime(result)
        return result
    }

    private func evaluateConvertCalendarPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let dateToken = reader.nextOptionalExpression() else { return "" }
        guard let targetCalToken = reader.nextOptionalExpression() else {
            reader.commit(to: &index)
            return ""
        }

        var sourceCalToken: String? = nil
        var formatToken: String? = nil

        while let nextTok = reader.nextOptionalExpression() {
            let clean = unquote(nextTok)
            if let parsedCal = pluginRegistry.parseCalendarIdentifier(clean)
                ?? Calendar.Identifier(logoCalendarName: clean)
            {
                if sourceCalToken == nil {
                    sourceCalToken = parsedCal.logoCalendarName
                }
            } else if formatToken == nil {
                formatToken = clean
            }
        }
        reader.commit(to: &index)

        let rawTargetCalName = unquote(targetCalToken)
        let targetCalId =
            pluginRegistry.parseCalendarIdentifier(rawTargetCalName) ?? Calendar.Identifier(
                logoCalendarName: rawTargetCalName) ?? .gregorian
        let sourceCal =
            sourceCalToken.map { Calendar(identifier: Calendar.Identifier(logoCalendarName: $0) ?? .gregorian) }
            ?? Calendar(identifier: .gregorian)

        let parsedDate: Date
        let parsedVal = LogoValue.parse(dateToken)
        switch parsedVal {
        case .date(let d, _, _):
            parsedDate = d
        default:
            let cleanDateStr = unquote(dateToken)
            parsedDate = LogoDateTimeFormatter.parseDate(cleanDateStr, defaultCalendar: sourceCal) ?? Date()
        }

        if let fmt = formatToken, !fmt.isEmpty {
            let res = LogoDateTimeFormatter.format(
                date: parsedDate,
                mode: .date,
                formatSpec: fmt,
                localeSpec: targetCalId.defaultLocaleIdentifier,
                calendarSpec: targetCalId.logoCalendarName
            )
            setLastExpressionDateTime(res)
            return res
        } else {
            let dateValue = LogoValue.date(date: parsedDate, calendar: targetCalId, timeZone: TimeZone.current)
            let res = dateValue.stringValue
            setLastExpressionDateTime(res)
            return res
        }
    }

    private func evaluateDateAddPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let dateStr = reader.nextOptionalExpression() else { return "" }
        guard let amountStr = reader.nextOptionalExpression() else {
            reader.commit(to: &index)
            return ""
        }
        guard let unitStr = reader.nextOptionalExpression() else {
            reader.commit(to: &index)
            return ""
        }
        reader.commit(to: &index)

        let dateVal = unquote(dateStr)
        let amountVal = Int(Double(unquote(amountStr)) ?? 0)
        let unitVal = unquote(unitStr)

        let parsedDate = LogoDateTimeFormatter.parseDate(dateVal) ?? Date()
        let newDate = LogoDateTimeFormatter.add(to: parsedDate, amount: amountVal, unit: unitVal)
        let result = LogoDateTimeFormatter.format(
            date: newDate,
            mode: dateVal.contains(":") ? .dateTime : .date
        )
        setLastExpressionDateTime(result)
        return result
    }

    private func evaluateDateDiffPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let dateStr1 = reader.nextOptionalExpression() else { return "" }
        guard let dateStr2 = reader.nextOptionalExpression() else {
            reader.commit(to: &index)
            return ""
        }
        guard let unitStr = reader.nextOptionalExpression() else {
            reader.commit(to: &index)
            return ""
        }
        reader.commit(to: &index)

        let dateVal1 = unquote(dateStr1)
        let dateVal2 = unquote(dateStr2)
        let unitVal = unquote(unitStr)

        let d1 = LogoDateTimeFormatter.parseDate(dateVal1) ?? Date()
        let d2 = LogoDateTimeFormatter.parseDate(dateVal2) ?? Date()
        let diff = LogoDateTimeFormatter.diff(between: d1, and: d2, unit: unitVal)
        setLastExpressionString("\(diff)")
        return "\(diff)"
    }
}
