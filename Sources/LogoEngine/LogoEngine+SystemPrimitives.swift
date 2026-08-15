import Foundation
import TextTransform

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

        case .count:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            let res: String
            switch p {
            case .list(let items), .array(let items): res = "\(items.count)"
            case .string(let s): res = "\(s.count)"
            }
            setLastExpressionString(res)
            return res

        case .ascii:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let cleanStr = unquote(v)
            if let firstScalar = cleanStr.unicodeScalars.first {
                return "\(firstScalar.value)"
            }
            return "0"

        case .char:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            if let code = Int(v), let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""

        case .standout:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return "**\(v)**"

        case .translit:
            index += 1
            let transformId = unquote(evaluateExpression(tokens, index: &index))
            if index + 1 < tokens.count {
                index += 1
            }
            let inputText = unquote(evaluateExpression(tokens, index: &index))
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
            return "\(heading)"

        case .readWord:
            index += 1
            var prompt = ""
            if index < tokens.count && !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]"
                && tokens[index] != ")"
            {
                prompt = unquote(evaluateExpression(tokens, index: &index))
            } else {
                index -= 1
            }
            guard let value = delegate?.logoEngine(self, readWordWithPrompt: prompt) else {
                reportError(LogoError(code: 1, message: "[LOGO Error: Stopped by user]"), token: "READWORD")
                return ""
            }
            return value

        case .readChar:
            index += 1
            var prompt = ""
            if index < tokens.count && !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]"
                && tokens[index] != ")"
            {
                prompt = unquote(evaluateExpression(tokens, index: &index))
            } else {
                index -= 1
            }
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
        index += 1
        let inputText = unquote(evaluateExpression(tokens, index: &index))
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
        index += 1
        let inputText = unquote(evaluateExpression(tokens, index: &index))
        return "\(count(inputText))"
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

        if index + 1 < tokens.count && tokens[index + 1] == "[" {
            index += 1
            let rawList = evaluateExpression(tokens, index: &index)
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
                    let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(items.map { $0.stringValue }, mode: mode)
                    formatSpec = f
                    localeSpec = l
                    timeZoneSpec = tz
                    calendarSpec = cal
                }
            }
        } else {
            var positional: [String] = []
            while positional.count < 4 && index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if LogoEngine.isStatementCommand(nextToken) || nextToken == "]" || nextToken == ")" {
                    break
                }
                index += 1
                let val = evaluateExpression(tokens, index: &index)
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
        index += 1
        guard index < tokens.count else { return "" }
        let dateVal = evaluateExpression(tokens, index: &index)

        var formatSpec: String? = nil
        var localeSpec: String? = nil
        var timeZoneSpec: String? = nil
        var calendarSpec: String? = nil

        if index + 1 < tokens.count && tokens[index + 1] == "[" {
            index += 1
            let rawList = evaluateExpression(tokens, index: &index)
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
                    let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(items.map { $0.stringValue }, mode: .dateTime)
                    formatSpec = f
                    localeSpec = l
                    timeZoneSpec = tz
                    calendarSpec = cal
                }
            }
        } else {
            var positional: [String] = []
            while positional.count < 4 && index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if LogoEngine.isStatementCommand(nextToken) || nextToken == "]" || nextToken == ")" {
                    break
                }
                index += 1
                let val = evaluateExpression(tokens, index: &index)
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

        let parsedCal = LogoDateTimeFormatter.parseCalendar(calendarSpec)
        let parsedTz = LogoDateTimeFormatter.parseTimeZone(timeZoneSpec)
        let parsedDate = LogoDateTimeFormatter.parseDate(dateVal, defaultCalendar: parsedCal, defaultTimeZone: parsedTz) ?? Date()

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

    private func evaluateDateAddPrimitive(tokens: [String], index: inout Int) -> String {
        index += 1
        guard index < tokens.count else { return "" }
        let dateVal = evaluateExpression(tokens, index: &index)
        guard index + 1 < tokens.count else { return dateVal }
        index += 1
        let amountVal = Int(evaluateExpression(tokens, index: &index)) ?? 0

        var unitVal = "days"
        if index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if !LogoEngine.isStatementCommand(nextToken) && nextToken != "]" && nextToken != ")" {
                index += 1
                unitVal = unquote(evaluateExpression(tokens, index: &index))
            }
        }

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
        index += 1
        guard index < tokens.count else { return "0" }
        let dateVal1 = evaluateExpression(tokens, index: &index)
        guard index + 1 < tokens.count else { return "0" }
        index += 1
        let dateVal2 = evaluateExpression(tokens, index: &index)

        var unitVal = "days"
        if index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if !LogoEngine.isStatementCommand(nextToken) && nextToken != "]" && nextToken != ")" {
                index += 1
                unitVal = unquote(evaluateExpression(tokens, index: &index))
            }
        }

        let d1 = LogoDateTimeFormatter.parseDate(dateVal1) ?? Date()
        let d2 = LogoDateTimeFormatter.parseDate(dateVal2) ?? Date()
        let diff = LogoDateTimeFormatter.diff(between: d1, and: d2, unit: unitVal)
        let result = "\(diff)"
        setLastExpressionString(result)
        return result
    }

    private func evaluateFormatNumberPrimitive(tokens: [String], index: inout Int) -> String {
        index += 1
        guard index < tokens.count else { return "" }
        let numStr = evaluateExpression(tokens, index: &index)
        let num = Double(unquote(numStr)) ?? 0

        var style: LogoFormatters.NumberStyle = .decimal
        var localeSpec: String? = nil
        var currencyCode: String? = nil
        var precision: Int? = nil

        if index + 1 < tokens.count && tokens[index + 1] == "[" {
            index += 1
            let rawList = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(rawList)
            if case .list(let items) = parsed {
                var isDict = false
                var i = 0
                while i < items.count {
                    let key = items[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                    if ["style", "fmt", "locale", "lang", "currency", "curr", "precision", "digits"].contains(cleanKey) && i + 1 < items.count {
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
                    if items.count > 0 { style = LogoFormatters.NumberStyle.parse(items[0].stringValue) }
                    if items.count > 1 { localeSpec = items[1].stringValue }
                }
            }
        } else {
            var positional: [String] = []
            while positional.count < 3 && index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if LogoEngine.isStatementCommand(nextToken) || nextToken == "]" || nextToken == ")" {
                    break
                }
                index += 1
                let val = evaluateExpression(tokens, index: &index)
                positional.append(unquote(val))
            }
            if positional.count > 0 { style = LogoFormatters.NumberStyle.parse(positional[0]) }
            if positional.count > 1 { localeSpec = positional[1] }
            if positional.count > 2 { currencyCode = positional[2] }
        }

        let res = LogoFormatters.formatNumber(num, style: style, locale: localeSpec, currencyCode: currencyCode, precision: precision)
        setLastExpressionString(res)
        return res
    }

    private func evaluateFormatListPrimitive(tokens: [String], index: inout Int) -> String {
        index += 1
        guard index < tokens.count else { return "" }
        let listStr = evaluateExpression(tokens, index: &index)
        let parsed = LogoValue.parse(listStr)

        var items: [String] = []
        switch parsed {
        case .list(let l), .array(let l):
            items = l.map { $0.stringValue }
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

        var positional: [String] = []
        while positional.count < 2 && index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if LogoEngine.isStatementCommand(nextToken) || nextToken == "]" || nextToken == ")" {
                break
            }
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            positional.append(unquote(val))
        }

        if positional.count > 0 { type = LogoFormatters.ListType.parse(positional[0]) }
        if positional.count > 1 { localeSpec = positional[1] }

        let res = LogoFormatters.formatList(items, type: type, locale: localeSpec)
        setLastExpressionString(res)
        return res
    }

    private func evaluateFormatRelativeTimePrimitive(tokens: [String], index: inout Int) -> String {
        index += 1
        guard index < tokens.count else { return "" }
        let arg1 = evaluateExpression(tokens, index: &index)
        let clean1 = unquote(arg1)

        var positional: [String] = []
        while positional.count < 2 && index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if LogoEngine.isStatementCommand(nextToken) || nextToken == "]" || nextToken == ")" {
                break
            }
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            positional.append(unquote(val))
        }

        let res: String
        if let val = Double(clean1) {
            let unit = positional.count > 0 ? positional[0] : "days"
            let locale = positional.count > 1 ? positional[1] : nil
            res = LogoFormatters.formatRelativeTime(value: val, unit: unit, locale: locale)
        } else if let targetDate = LogoDateTimeFormatter.parseDate(clean1) {
            let locale = positional.count > 0 ? positional[0] : nil
            res = LogoFormatters.formatRelativeDate(target: targetDate, locale: locale)
        } else {
            res = clean1
        }

        setLastExpressionString(res)
        return res
    }

    private func evaluateFormatBytesPrimitive(tokens: [String], index: inout Int) -> String {
        index += 1
        guard index < tokens.count else { return "0 bytes" }
        let byteStr = evaluateExpression(tokens, index: &index)
        let bytes = Int64(Double(unquote(byteStr)) ?? 0)

        var style: LogoFormatters.ByteCountStyle = .file
        var localeSpec: String? = nil

        var positional: [String] = []
        while positional.count < 2 && index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if LogoEngine.isStatementCommand(nextToken) || nextToken == "]" || nextToken == ")" {
                break
            }
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            positional.append(unquote(val))
        }

        if positional.count > 0 { style = LogoFormatters.ByteCountStyle.parse(positional[0]) }
        if positional.count > 1 { localeSpec = positional[1] }

        let res = LogoFormatters.formatBytes(bytes, style: style, locale: localeSpec)
        setLastExpressionString(res)
        return res
    }
}
