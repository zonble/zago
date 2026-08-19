import Foundation
import TextTransform

private func systemOptionalArgumentBoundary(_ token: String) -> Bool {
    LogoEngine.isKeyword(token) || token == "]" || token == ")"
}

extension LogoEngine {
    /// System & Environment Primitives Evaluator (`evaluateSystemPrimitives`)
    ///
    /// ### Role & Architecture:
    /// - **Role**: Evaluates system state, environment queries, date/time formatting, and character code primitives.
    /// - **Primitives**: `DATE`, `TIME`, `ASCII`, `CHAR`, `STANDOUT`, `COUNT`, `SORT`
    /// - **Return Type**: `String?` (evaluated result string or `nil`).
    internal func evaluateSystemPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

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

        case .formatNumber:
            return evaluateFormatNumberPrimitive(tokens: tokens, index: &index)

        case .formatList:
            return evaluateFormatListPrimitive(tokens: tokens, index: &index)

        case .formatRelativeTime:
            return evaluateFormatRelativeTimePrimitive(tokens: tokens, index: &index)

        case .formatBytes:
            return evaluateFormatBytesPrimitive(tokens: tokens, index: &index)

        case .formatName:
            return evaluateFormatNamePrimitive(tokens: tokens, index: &index)

        case .convertCalendar:
            return evaluateConvertCalendarPrimitive(tokens: tokens, index: &index)

        case .convertMeasure:
            return evaluateMeasurementConvertPrimitive(prim, tokens: tokens, index: &index)

        case .formatMeasure:
            return evaluateMeasurementFormatPrimitive(prim, tokens: tokens, index: &index)

        case .measureAdd, .measureSub, .measureScale, .measureEqual, .measureLess, .measureGreater, .measureMin,
            .measureMax:
            return evaluateMeasureOperationPrimitive(prim, tokens: tokens, index: &index)

        case .detectURL, .detectEmail, .detectPhone, .detectDate, .detectAddress:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let text = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return evaluateDetectPrimitive(prim, text: text)

        case .uuid:
            return evaluateUUIDPrimitive(tokens: tokens, index: &index)

        case .isUUID:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let valid = LogoUUIDGenerator.isValidUUID(input)
            setLastExpressionBoolean(valid)
            return valid ? "true" : "false"

        case .uuidTime:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            guard let date = LogoUUIDGenerator.extractV7Date(from: input) else {
                let msg = "[LOGO Error: UUID '\(input)' is not a valid UUID v7 with extractable timestamp]"
                reportError(LogoError(code: 1, message: msg), token: "UUID.TIME")
                return ""
            }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateStr = formatter.string(from: date)
            setLastExpressionString(dateStr)
            return dateStr

        case .base64Encode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let encoded = LogoDataCodec.base64Encode(input)
            setLastExpressionString(encoded)
            return encoded

        case .base64Decode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            guard let decoded = LogoDataCodec.base64Decode(input) else {
                let msg = "[LOGO Error: Invalid Base64 input string '\(input)']"
                reportError(LogoError(code: 1, message: msg), token: "BASE64.DECODE")
                return ""
            }
            setLastExpressionString(decoded)
            return decoded

        case .isBase64:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let valid = LogoDataCodec.isValidBase64(input)
            setLastExpressionBoolean(valid)
            return valid ? "true" : "false"

        case .urlEncode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let encoded = LogoDataCodec.urlEncode(input)
            setLastExpressionString(encoded)
            return encoded

        case .urlDecode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let decoded = LogoDataCodec.urlDecode(input)
            setLastExpressionString(decoded)
            return decoded

        case .hexEncode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let encoded = LogoDataCodec.hexEncode(input)
            setLastExpressionString(encoded)
            return encoded

        case .hexDecode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            guard let decoded = LogoDataCodec.hexDecode(input) else {
                let msg = "[LOGO Error: Invalid Hex input string '\(input)']"
                reportError(LogoError(code: 1, message: msg), token: "HEX.DECODE")
                return ""
            }
            setLastExpressionString(decoded)
            return decoded

        case .hashSha256:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let hash = LogoDataCodec.sha256(input)
            setLastExpressionString(hash)
            return hash

        case .hashSha1:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let hash = LogoDataCodec.sha1(input)
            setLastExpressionString(hash)
            return hash

        case .hashMd5:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let hash = LogoDataCodec.md5(input)
            setLastExpressionString(hash)
            return hash

        case .count:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            let res: String
            switch p {
            case .list(let items), .array(let items): res = "\(items.count)"
            case .measurement: res = "2"
            case .date: res = "\(p.stringValue.count)"
            case .string(let s): res = "\(s.count)"
            }
            setLastExpressionString(res)
            return res

        case .ascii:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let cleanStr = unquote(v)
            if let firstScalar = cleanStr.unicodeScalars.first {
                return "\(firstScalar.value)"
            }
            return "0"

        case .char:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            if let code = Int(v), let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""

        case .standout:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            return "**\(v)**"

        case .translit:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let transformId = unquote(reader.nextExpression())
            let inputText = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return applyTextTransform(transformId, to: inputText)

        case .transformToHans:
            return applyFixedTextTransform("Hant-Hans", tokens, index: &index)

        case .transformToHant:
            return applyFixedTextTransform("Hans-Hant", tokens, index: &index)

        case .transformToLatin:
            return applyFixedTextTransform("Any-Latin", tokens, index: &index)

        case .transformToHiragana:
            return applyFixedTextTransform("Any-Hiragana", tokens, index: &index)

        case .transformToKatakana:
            return applyFixedTextTransform("Any-Katakana", tokens, index: &index)

        case .transformToRomaji:
            return applyFixedTextTransform("Any-Latin", tokens, index: &index)

        case .spacingCJK:
            return applyFixedTextTransform("Zago-CJK-Spacing", tokens, index: &index)

        case .charCount:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.characterCount(in: $0) }

        case .charCountCJK:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.cjkCharacterCount(in: $0) }

        case .charCountWords:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.wordCount(in: $0) }

        case .charCountEmoji:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.emojiCount(in: $0) }

        case .charCountLines:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.lineCount(in: $0) }

        case .headingPrimitive:
            return heading.rawValue

        case .readWord:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            var prompt = ""
            if let value = reader.nextOptionalExpression(isBoundary: systemOptionalArgumentBoundary) {
                prompt = unquote(value)
            }
            reader.commit(to: &index)
            guard let value = delegate?.logoEngine(self, readWordWithPrompt: prompt) else {
                reportError(LogoError(code: 1, message: "[LOGO Error: Stopped by user]"), token: "READWORD")
                return ""
            }
            return value

        case .readChar:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            var prompt = ""
            if let value = reader.nextOptionalExpression(isBoundary: systemOptionalArgumentBoundary) {
                prompt = unquote(value)
            }
            reader.commit(to: &index)
            guard let value = delegate?.logoEngine(self, readCharWithPrompt: prompt) else {
                reportError(LogoError(code: 1, message: "[LOGO Error: Stopped by user]"), token: "READCHAR")
                return ""
            }
            return value

        default:
            return nil
        }
    }

    private func applyFixedTextTransform(_ transformId: String, _ tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        let inputText = unquote(reader.nextExpression())
        reader.commit(to: &index)
        return applyTextTransform(transformId, to: inputText)
    }

    private func applyTextTransform(_ transformId: String, to inputText: String) -> String {
        do {
            return try TextTransformer.apply(transformId, to: inputText)
        } catch {
            let message = "[\(error)]"
            lastError = LogoError(code: 1, message: message)
            delegate?.logoEngine(self, performAction: .setStatusMessage(message))
            hasSetStatusMessage = true
            return ""
        }
    }

    private func applyTextCount(_ tokens: [String], index: inout Int, count: (String) -> Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        let inputText = unquote(reader.nextExpression())
        reader.commit(to: &index)
        return "\(count(inputText))"
    }

    private func evaluateUUIDPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        var flavor = "v4"
        if let arg = reader.nextOptionalExpression(isBoundary: systemOptionalArgumentBoundary) {
            flavor = unquote(arg)
        }
        reader.commit(to: &index)
        let generated = LogoUUIDGenerator.generate(flavor: flavor)
        setLastExpressionString(generated)
        return generated
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
                        items.map { $0.stringValue }, mode: mode)
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
                let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(positional, mode: mode)
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

        let parsedTz = LogoDateTimeFormatter.parseTimeZone(timeZoneSpec)
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
            if LogoDateTimeFormatter.isCalendarName(clean) && sourceCalToken == nil {
                sourceCalToken = clean
            } else if formatToken == nil {
                formatToken = clean
            }
        }
        reader.commit(to: &index)

        let targetCalName = unquote(targetCalToken)
        let targetCalId = LogoDateTimeFormatter.calendarIdentifier(for: targetCalName)
        let sourceCal = sourceCalToken.map { LogoDateTimeFormatter.parseCalendar($0) } ?? Calendar(identifier: .gregorian)

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
                localeSpec: LogoDateTimeFormatter.defaultLocaleForCalendar(targetCalId),
                calendarSpec: targetCalName
            )
            setLastExpressionDateTime(res)
            return res
        }

        let dateValue = LogoValue.date(date: parsedDate, calendar: targetCalId, timeZone: TimeZone.current)
        let res = dateValue.stringValue
        setLastExpressionDateTime(res)
        return res
    }

    private func evaluateDateAddPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let dateVal = reader.nextOptionalExpression() else { return "" }
        guard let amount = reader.nextOptionalExpression() else {
            reader.commit(to: &index)
            return dateVal
        }
        let amountVal = Int(amount) ?? 0
        let unitVal = reader.nextOptionalExpression().map(unquote) ?? "days"
        reader.commit(to: &index)

        let parsedDate = LogoDateTimeFormatter.parseDate(dateVal) ?? Date()
        let newDate = LogoDateTimeFormatter.add(to: parsedDate, amount: amountVal, unit: unitVal)
        let result = LogoDateTimeFormatter.format(
            date: newDate,
            mode: (dateVal.contains(":") || dateVal.contains("T")) ? .dateTime : .date
        )
        setLastExpressionDateTime(result)
        return result
    }

    private func evaluateDateDiffPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let dateVal1 = reader.nextOptionalExpression(),
            let dateVal2 = reader.nextOptionalExpression()
        else { return "0" }
        let unitVal = reader.nextOptionalExpression().map(unquote) ?? "days"
        reader.commit(to: &index)

        let d1 = LogoDateTimeFormatter.parseDate(dateVal1) ?? Date()
        let d2 = LogoDateTimeFormatter.parseDate(dateVal2) ?? Date()
        let diff = LogoDateTimeFormatter.diff(between: d1, and: d2, unit: unitVal)
        let result = "\(diff)"
        setLastExpressionString(result)
        return result
    }

    private func evaluateFormatNumberPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let numStr = reader.nextOptionalExpression() else { return "" }
        let num = Double(unquote(numStr)) ?? 0

        var style: LogoFormatters.NumberStyle = .decimal
        var localeSpec: String? = nil
        var currencyCode: String? = nil
        var precision: Int? = nil

        if reader.peekToken() == "[" {
            let rawList = reader.nextExpression()
            let parsed = LogoValue.parse(rawList)
            if case .list(let items) = parsed {
                var isDict = false
                var i = 0
                while i < items.count {
                    let key = items[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                    if ["style", "fmt", "locale", "lang", "currency", "curr", "precision", "digits"].contains(cleanKey)
                        && i + 1 < items.count
                    {
                        isDict = true
                        let val = items[i + 1].stringValue
                        switch cleanKey {
                        case "style", "fmt": style = LogoFormatters.NumberStyle.parse(val)
                        case "locale", "lang": localeSpec = val
                        case "currency", "curr": currencyCode = val
                        case "precision", "digits": precision = Int(val)
                        default: break
                        }
                        i += 2
                    } else {
                        i += 1
                    }
                }
                if !isDict {
                    let strings = items.map { $0.stringValue }
                    LogoFormatters.disambiguateNumberOptions(
                        strings, style: &style, locale: &localeSpec, currencyCode: &currencyCode, precision: &precision)
                }
            }
        } else {
            var positional: [String] = []
            while positional.count < 4,
                let val = reader.nextOptionalExpression()
            {
                positional.append(unquote(val))
            }
            LogoFormatters.disambiguateNumberOptions(
                positional, style: &style, locale: &localeSpec, currencyCode: &currencyCode, precision: &precision)
        }

        reader.commit(to: &index)

        let res = LogoFormatters.formatNumber(
            num, style: style, locale: localeSpec, currencyCode: currencyCode, precision: precision)
        setLastExpressionString(res)
        return res
    }

    private func evaluateFormatListPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        #if os(Linux) || os(Windows)
            while reader.nextOptionalExpression() != nil {}
            reader.commit(to: &index)
            let message = "[LOGO Error: FORMAT.LIST is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: "FORMAT.LIST")
            return ""
        #else
            guard let listStr = reader.nextOptionalExpression() else { return "" }
            let parsed = LogoValue.parse(listStr)

            var items: [String] = []
            switch parsed {
            case .list(let l), .array(let l):
                items = l.map { $0.stringValue }
            case .measurement(let val, let unit, _):
                items = [LogoMeasurementConverter.formatResult(val), unit]
            case .date:
                items = [parsed.stringValue]
            case .string(let s):
                let clean = unquote(s)
                if clean.contains(" ") {
                    items = clean.split(separator: " ").map { String($0) }
                } else {
                    items = [clean]
                }
            }

            var type: LogoFormatters.ListType = .and
            var localeSpec: String? = nil

            if reader.peekToken() == "[" {
                let rawList = reader.nextExpression()
                let parsedOpts = LogoValue.parse(rawList)
                if case .list(let optItems) = parsedOpts {
                    var isDict = false
                    var i = 0
                    while i < optItems.count {
                        let key = optItems[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                        if ["type", "kind", "style", "locale", "lang"].contains(cleanKey) && i + 1 < optItems.count {
                            isDict = true
                            let val = optItems[i + 1].stringValue
                            switch cleanKey {
                            case "type", "kind", "style": type = LogoFormatters.ListType.parse(val)
                            case "locale", "lang": localeSpec = val
                            default: break
                            }
                            i += 2
                        } else {
                            i += 1
                        }
                    }
                    if !isDict {
                        let strings = optItems.map { $0.stringValue }
                        LogoFormatters.disambiguateListOptions(strings, type: &type, locale: &localeSpec)
                    }
                }
            } else {
                var positional: [String] = []
                while positional.count < 2,
                    let val = reader.nextOptionalExpression()
                {
                    positional.append(unquote(val))
                }
                LogoFormatters.disambiguateListOptions(positional, type: &type, locale: &localeSpec)
            }

            reader.commit(to: &index)

            let res = LogoFormatters.formatList(items, type: type, locale: localeSpec)
            setLastExpressionString(res)
            return res
        #endif
    }

    private func evaluateFormatRelativeTimePrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        #if os(Linux) || os(Windows)
            while reader.nextOptionalExpression() != nil {}
            reader.commit(to: &index)
            let message = "[LOGO Error: FORMAT.RELATIVETIME is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: "FORMAT.RELATIVETIME")
            return ""
        #else
            guard let arg1 = reader.nextOptionalExpression() else { return "" }
            let clean1 = unquote(arg1)

            var positional: [String] = []
            while positional.count < 2,
                let val = reader.nextOptionalExpression()
            {
                positional.append(unquote(val))
            }
            reader.commit(to: &index)

            let res: String
            if let val = Double(clean1) {
                var unit = "days"
                var locale: String? = nil
                LogoFormatters.disambiguateRelativeTimeOptions(positional, unit: &unit, locale: &locale)
                res = LogoFormatters.formatRelativeTime(value: val, unit: unit, locale: locale)
            } else if let targetDate = LogoDateTimeFormatter.parseDate(clean1) {
                let locale = positional.count > 0 ? positional[0] : nil
                res = LogoFormatters.formatRelativeDate(target: targetDate, locale: locale)
            } else {
                res = clean1
            }

            setLastExpressionString(res)
            return res
        #endif
    }

    private func evaluateFormatBytesPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let byteStr = reader.nextOptionalExpression() else { return "0 bytes" }
        let bytes = Int64(Double(unquote(byteStr)) ?? 0)

        var style: LogoFormatters.ByteCountStyle = .file
        var localeSpec: String? = nil

        if reader.peekToken() == "[" {
            let rawList = reader.nextExpression()
            let parsedOpts = LogoValue.parse(rawList)
            if case .list(let optItems) = parsedOpts {
                var isDict = false
                var i = 0
                while i < optItems.count {
                    let key = optItems[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                    if ["style", "fmt", "locale", "lang"].contains(cleanKey) && i + 1 < optItems.count {
                        isDict = true
                        let val = optItems[i + 1].stringValue
                        switch cleanKey {
                        case "style", "fmt": style = LogoFormatters.ByteCountStyle.parse(val)
                        case "locale", "lang": localeSpec = val
                        default: break
                        }
                        i += 2
                    } else {
                        i += 1
                    }
                }
                if !isDict {
                    let strings = optItems.map { $0.stringValue }
                    LogoFormatters.disambiguateBytesOptions(strings, style: &style, locale: &localeSpec)
                }
            }
        } else {
            var positional: [String] = []
            while positional.count < 2,
                let val = reader.nextOptionalExpression()
            {
                positional.append(unquote(val))
            }
            LogoFormatters.disambiguateBytesOptions(positional, style: &style, locale: &localeSpec)
        }

        reader.commit(to: &index)

        let res = LogoFormatters.formatBytes(bytes, style: style, locale: localeSpec)
        setLastExpressionString(res)
        return res
    }

    private func evaluateFormatNamePrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        #if os(Linux) || os(Windows)
            while reader.nextOptionalExpression() != nil {}
            reader.commit(to: &index)
            let message = "[LOGO Error: FORMAT.NAME is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: "FORMAT.NAME")
            return ""
        #else
            guard let firstArg = reader.nextOptionalExpression() else { return "" }

            var style: LogoFormatters.PersonNameStyle = .default
            var localeSpec: String? = nil
            var given: String? = nil
            var family: String? = nil
            var middle: String? = nil
            var pfx: String? = nil
            var sfx: String? = nil
            var nick: String? = nil
            var fullName: String? = nil

            let parsed = LogoValue.parse(firstArg)
            if case .list(let items) = parsed {
                let itemStrings = items.map { $0.stringValue }
                if itemStrings.count % 2 == 0 {
                    var i = 0
                    while i < itemStrings.count {
                        let key = itemStrings[i].lowercased().trimmingCharacters(
                            in: CharacterSet(charactersIn: ":\"' "))
                        let val = itemStrings[i + 1]
                        switch key {
                        case "given", "first", "firstname", "givenname": given = val
                        case "family", "last", "lastname", "familyname", "surname": family = val
                        case "middle", "middlename": middle = val
                        case "prefix", "title": pfx = val
                        case "suffix": sfx = val
                        case "nickname", "nick": nick = val
                        case "style": style = LogoFormatters.PersonNameStyle.parse(val)
                        case "locale", "loc": localeSpec = val
                        case "name", "full", "fullname": fullName = val
                        default: break
                        }
                        i += 2
                    }
                } else if itemStrings.count == 1 {
                    fullName = itemStrings[0]
                } else if itemStrings.count == 2 {
                    given = itemStrings[0]
                    family = itemStrings[1]
                } else if itemStrings.count >= 3 {
                    if !LogoFormatters.PersonNameStyle.isStyleKeyword(itemStrings[2])
                        && !LogoDateTimeFormatter.isLocaleName(itemStrings[2])
                    {
                        given = itemStrings[0]
                        middle = itemStrings[1]
                        family = itemStrings[2]
                        if itemStrings.count > 3 {
                            let extra = Array(itemStrings.dropFirst(3))
                            LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &localeSpec)
                        }
                    } else {
                        given = itemStrings[0]
                        family = itemStrings[1]
                        let extra = Array(itemStrings.dropFirst(2))
                        LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &localeSpec)
                    }
                }
            } else {
                var positional: [String] = [unquote(firstArg)]
                while positional.count < 5,
                    let val = reader.nextOptionalExpression()
                {
                    positional.append(unquote(val))
                }
                if positional.count >= 3 && !LogoFormatters.PersonNameStyle.isStyleKeyword(positional[1])
                    && !LogoDateTimeFormatter.isLocaleName(positional[1])
                    && !LogoFormatters.PersonNameStyle.isStyleKeyword(positional[2])
                    && !LogoDateTimeFormatter.isLocaleName(positional[2])
                {
                    given = positional[0]
                    middle = positional[1]
                    family = positional[2]
                    if positional.count > 3 {
                        let extra = Array(positional.dropFirst(3))
                        LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &localeSpec)
                    }
                } else if positional.count >= 2 && !LogoFormatters.PersonNameStyle.isStyleKeyword(positional[1])
                    && !LogoDateTimeFormatter.isLocaleName(positional[1])
                {
                    given = positional[0]
                    family = positional[1]
                    if positional.count > 2 {
                        let extra = Array(positional.dropFirst(2))
                        LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &localeSpec)
                    }
                } else {
                    fullName = positional[0]
                    if positional.count > 1 {
                        let extra = Array(positional.dropFirst(1))
                        LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &localeSpec)
                    }
                }
            }

            reader.commit(to: &index)

            let res = LogoFormatters.formatPersonName(
                givenName: given,
                familyName: family,
                middleName: middle,
                prefix: pfx,
                suffix: sfx,
                nickname: nick,
                fullName: fullName,
                style: style,
                locale: localeSpec
            )
            setLastExpressionString(res)
            return res
        #endif
    }

    internal func evaluateDetectPrimitive(_ primitive: LogoPrimitive, text: String) -> String {
        #if os(Linux) || os(Windows)
            let name = primitive.meta.name
            let message = "[LOGO Error: \(name) is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: name)
            return ""
        #else
            guard let kind = LogoDetectorKind(primitive) else { return "" }
            let matches = LogoDetectors.detect(text, kind: kind)
            let result = LogoValue.list(matches.map(LogoValue.string)).description
            setLastExpressionString(result)
            return result
        #endif
    }

    private func evaluateMeasurementConvertPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int)
        -> String
    {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        let firstArg = reader.nextExpression()

        var val: Double = 0
        var fromUnit: String = ""
        var toUnit: String = ""

        let parsedFirst = LogoValue.parse(firstArg)
        if case .measurement(let mVal, let mUnit, _) = parsedFirst {
            val = mVal
            fromUnit = mUnit
            toUnit = unquote(reader.nextExpression())
        } else {
            val = Double(unquote(firstArg)) ?? 0
            fromUnit = unquote(reader.nextExpression())
            toUnit = unquote(reader.nextExpression())
        }
        reader.commit(to: &index)

        guard let dimFrom = LogoMeasurementConverter.findDimension(for: fromUnit) else {
            let msg = "[LOGO Error: \(prim.meta.name) invalid or unknown source unit '\(fromUnit)']"
            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
            return ""
        }
        guard let dimTo = LogoMeasurementConverter.findDimension(for: toUnit) else {
            let msg = "[LOGO Error: \(prim.meta.name) invalid or unknown target unit '\(toUnit)']"
            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
            return ""
        }
        guard dimFrom == dimTo else {
            let msg =
                "[LOGO Error: \(prim.meta.name) cannot convert '\(fromUnit)' (\(dimFrom)) to '\(toUnit)' (\(dimTo))]"
            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
            return ""
        }

        if let converted = LogoMeasurementConverter.convert(value: val, from: fromUnit, to: toUnit, kind: dimFrom) {
            let res = LogoMeasurementConverter.formatResult(converted)
            setLastExpressionString(res)
            return res
        }
        return ""
    }

    private func evaluateMeasurementFormatPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> String
    {
        #if os(Linux) || os(Windows)
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            _ = reader.nextOptionalExpression()
            _ = reader.nextOptionalExpression()
            reader.commit(to: &index)
            let name = prim.meta.name
            let message = "[LOGO Error: \(name) is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: name)
            return ""
        #else
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let firstArg = reader.nextOptionalExpression() else { return "" }

            var val: Double = 0
            var cleanUnit: String = ""
            let kind: LogoMeasurementConverter.DimensionKind

            let parsedFirst = LogoValue.parse(firstArg)
            if case .measurement(let mVal, let mUnit, let mDim) = parsedFirst {
                val = mVal
                cleanUnit = mUnit
                kind = mDim
            } else {
                guard let unitStr = reader.nextOptionalExpression() else {
                    reader.commit(to: &index)
                    return ""
                }
                val = Double(unquote(firstArg)) ?? 0
                cleanUnit = unquote(unitStr)
                guard let inferredDim = LogoMeasurementConverter.findDimension(for: cleanUnit) else {
                    let msg = "[LOGO Error: \(prim.meta.name) invalid or unknown unit '\(cleanUnit)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    reader.commit(to: &index)
                    return ""
                }
                kind = inferredDim
            }

            var style: String? = nil
            var localeSpec: String? = nil
            var naturalScale = false
            var targetConversionUnit: String? = nil

            if reader.peekToken() == "[" {
                let rawList = reader.nextExpression()
                let parsed = LogoValue.parse(rawList)
                if case .list(let items) = parsed {
                    var isDict = false
                    var i = 0
                    while i < items.count {
                        let key = items[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                        if ["style", "fmt", "locale", "lang", "natural", "scale", "unit", "to"].contains(cleanKey)
                            && i + 1 < items.count
                        {
                            isDict = true
                            let v = items[i + 1].stringValue
                            switch cleanKey {
                            case "style", "fmt": style = v
                            case "locale", "lang": localeSpec = v
                            case "natural", "scale":
                                naturalScale = (v.lowercased() == "true" || v == "1" || v.lowercased() == "yes")
                            case "unit", "to": targetConversionUnit = v
                            default: break
                            }
                            i += 2
                        } else {
                            i += 1
                        }
                    }
                    if !isDict {
                        let strings = items.map { $0.stringValue }
                        for s in strings {
                            let unq = unquote(s)
                            if let dim = LogoMeasurementConverter.findDimension(for: unq) {
                                if dim == kind {
                                    targetConversionUnit = unq
                                } else {
                                    let msg =
                                        "[LOGO Error: \(prim.meta.name) invalid unit '\(unq)' (expected \(kind) unit, got \(dim))]"
                                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                                    reader.commit(to: &index)
                                    return ""
                                }
                            }
                        }
                        LogoMeasurementConverter.disambiguateFormatOptions(
                            strings, style: &style, locale: &localeSpec, naturalScale: &naturalScale)
                    }
                }
            } else {
                var positional: [String] = []
                while positional.count < 3,
                    let arg = reader.nextOptionalExpression()
                {
                    let unq = unquote(arg)
                    if let dim = LogoMeasurementConverter.findDimension(for: unq) {
                        if dim == kind {
                            targetConversionUnit = unq
                        } else {
                            let msg =
                                "[LOGO Error: \(prim.meta.name) invalid unit '\(unq)' (expected \(kind) unit, got \(dim))]"
                            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                            reader.commit(to: &index)
                            return ""
                        }
                    } else {
                        positional.append(unq)
                    }
                }
                LogoMeasurementConverter.disambiguateFormatOptions(
                    positional, style: &style, locale: &localeSpec, naturalScale: &naturalScale)
            }

            reader.commit(to: &index)

            if let targetUnit = targetConversionUnit,
                let convertedVal = LogoMeasurementConverter.convert(
                    value: val, from: cleanUnit, to: targetUnit, kind: kind)
            {
                val = convertedVal
                cleanUnit = targetUnit
            }

            if let formatted = LogoMeasurementConverter.format(
                value: val,
                unit: cleanUnit,
                kind: kind,
                style: style,
                locale: localeSpec,
                naturalScale: naturalScale
            ) {
                setLastExpressionString(formatted)
                return formatted
            }
            return ""
        #endif
    }

    private func evaluateMeasureOperationPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> String
    {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let arg1 = reader.nextOptionalExpression() else { return "" }
        let clean1 = unquote(arg1)
        let parsed1 = LogoValue.parse(arg1)

        switch prim {
        case .measureScale:
            let val: Double
            let unit: String
            let factor: Double

            if case .measurement(let mVal, let mUnit, _) = parsed1 {
                guard let factorStr = reader.nextOptionalExpression() else {
                    reader.commit(to: &index)
                    return ""
                }
                val = mVal
                unit = mUnit
                factor = Double(unquote(factorStr)) ?? 1
            } else {
                guard let unitStr = reader.nextOptionalExpression(),
                    let factorStr = reader.nextOptionalExpression()
                else {
                    reader.commit(to: &index)
                    return ""
                }
                val = Double(clean1) ?? 0
                unit = unquote(unitStr)
                factor = Double(unquote(factorStr)) ?? 1
            }
            reader.commit(to: &index)

            guard let res = LogoMeasurementConverter.scale(value: val, unit: unit, factor: factor) else {
                return ""
            }
            setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
            return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

        case .measureAdd, .measureSub, .measureEqual, .measureLess, .measureGreater, .measureMin, .measureMax:
            let val1: Double
            let unit1: String
            let val2: Double
            let unit2: String
            let targetUnit: String?

            if case .measurement(let mVal1, let mUnit1, _) = parsed1 {
                guard let arg2 = reader.nextOptionalExpression() else {
                    reader.commit(to: &index)
                    return ""
                }
                let parsed2 = LogoValue.parse(arg2)
                if case .measurement(let mVal2, let mUnit2, _) = parsed2 {
                    val1 = mVal1
                    unit1 = mUnit1
                    val2 = mVal2
                    unit2 = mUnit2
                } else {
                    guard let unit2Str = reader.nextOptionalExpression() else {
                        reader.commit(to: &index)
                        return ""
                    }
                    val1 = mVal1
                    unit1 = mUnit1
                    val2 = Double(unquote(arg2)) ?? 0
                    unit2 = unquote(unit2Str)
                }
            } else {
                guard let unit1Str = reader.nextOptionalExpression(),
                    let val2Str = reader.nextOptionalExpression(),
                    let unit2Str = reader.nextOptionalExpression()
                else {
                    reader.commit(to: &index)
                    return ""
                }
                val1 = Double(clean1) ?? 0
                unit1 = unquote(unit1Str)
                let parsedVal2 = LogoValue.parse(val2Str)
                if case .measurement(let mVal2, let mUnit2, _) = parsedVal2 {
                    val2 = mVal2
                    unit2 = mUnit2
                } else {
                    val2 = Double(unquote(val2Str)) ?? 0
                    unit2 = unquote(unit2Str)
                }
            }

            if let dim1 = LogoMeasurementConverter.findDimension(for: unit1),
                let peek = reader.peekToken(),
                !isArgumentBoundary(peek),
                let peekDim = LogoMeasurementConverter.findDimension(for: unquote(peek)),
                peekDim == dim1
            {
                targetUnit = reader.nextOptionalExpression().map(unquote)
            } else {
                targetUnit = nil
            }
            reader.commit(to: &index)

            switch prim {
            case .measureAdd:
                guard
                    let res = LogoMeasurementConverter.add(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            case .measureSub:
                guard
                    let res = LogoMeasurementConverter.subtract(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            case .measureEqual:
                guard
                    let (v1, v2) = LogoMeasurementConverter.compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return "false"
                }
                let tolerance = targetUnit.flatMap(Double.init) ?? 1e-6
                let res = abs(v1 - v2) <= tolerance
                setLastExpressionBoolean(res)
                return res ? "true" : "false"

            case .measureLess:
                guard
                    let (v1, v2) = LogoMeasurementConverter.compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return "false"
                }
                let res = v1 < v2
                setLastExpressionBoolean(res)
                return res ? "true" : "false"

            case .measureGreater:
                guard
                    let (v1, v2) = LogoMeasurementConverter.compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return "false"
                }
                let res = v1 > v2
                setLastExpressionBoolean(res)
                return res ? "true" : "false"

            case .measureMin:
                guard
                    let res = LogoMeasurementConverter.min(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            case .measureMax:
                guard
                    let res = LogoMeasurementConverter.max(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            default:
                return ""
            }
        default:
            return ""
        }
    }
}
