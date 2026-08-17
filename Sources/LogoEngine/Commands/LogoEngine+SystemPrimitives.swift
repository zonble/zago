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

        case .convertArea, .convertLength, .convertVolume, .convertAngle, .convertMass,
            .convertPressure, .convertAcceleration, .convertDuration, .convertFrequency,
            .convertSpeed, .convertEnergy, .convertPower, .convertTemperature, .convertIlluminance,
            .convertElectricCharge, .convertElectricCurrent, .convertElectricPotentialDifference,
            .convertElectricResistance, .convertConcentrationMass, .convertDispersion,
            .convertFuelEfficiency, .convertInformationStorage:
            return evaluateMeasurementConvertPrimitive(prim, tokens: tokens, index: &index)

        case .formatArea, .formatLength, .formatVolume, .formatAngle, .formatMass,
            .formatPressure, .formatAcceleration, .formatDuration, .formatFrequency,
            .formatSpeed, .formatEnergy, .formatPower, .formatTemperature, .formatIlluminance,
            .formatElectricCharge, .formatElectricCurrent, .formatElectricPotentialDifference,
            .formatElectricResistance, .formatConcentrationMass, .formatDispersion,
            .formatFuelEfficiency, .formatInformationStorage:
            return evaluateMeasurementFormatPrimitive(prim, tokens: tokens, index: &index)

        case .detectURL, .detectEmail, .detectPhone, .detectDate, .detectAddress:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let text = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return evaluateDetectPrimitive(prim, text: text)

        case .count:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            let res: String
            switch p {
            case .list(let items), .array(let items): res = "\(items.count)"
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

        let parsedCal = LogoDateTimeFormatter.parseCalendar(calendarSpec)
        let parsedTz = LogoDateTimeFormatter.parseTimeZone(timeZoneSpec)
        let parsedDate =
            LogoDateTimeFormatter.parseDate(dateVal, defaultCalendar: parsedCal, defaultTimeZone: parsedTz) ?? Date()

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

    internal func evaluateDetectPrimitive(_ primitive: LogoPrimitive, text: String) -> String {
        #if os(Linux) || os(Windows)
            let name = primitive.meta.name
            let message = "[LOGO Error: \(name) is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: name)
            return ""
        #else
            let kind: LogoDetectorKind
            switch primitive {
            case .detectURL: kind = .url
            case .detectEmail: kind = .email
            case .detectPhone: kind = .phone
            case .detectDate: kind = .date
            case .detectAddress: kind = .address
            default: return ""
            }
            let matches = LogoDetectors.detect(text, kind: kind)
            let result = LogoValue.list(matches.map(LogoValue.string)).description
            setLastExpressionString(result)
            return result
        #endif
    }

    private func evaluateMeasurementConvertPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        let valStr = unquote(reader.nextExpression())
        let fromUnitStr = unquote(reader.nextExpression())
        let toUnitStr = unquote(reader.nextExpression())
        reader.commit(to: &index)

        guard let val = Double(valStr) else {
            return ""
        }

        let kind: LogoMeasurementConverter.DimensionKind
        switch prim {
        case .convertArea: kind = .area
        case .convertLength: kind = .length
        case .convertVolume: kind = .volume
        case .convertAngle: kind = .angle
        case .convertMass: kind = .mass
        case .convertPressure: kind = .pressure
        case .convertAcceleration: kind = .acceleration
        case .convertDuration: kind = .duration
        case .convertFrequency: kind = .frequency
        case .convertSpeed: kind = .speed
        case .convertEnergy: kind = .energy
        case .convertPower: kind = .power
        case .convertTemperature: kind = .temperature
        case .convertIlluminance: kind = .illuminance
        case .convertElectricCharge: kind = .electricCharge
        case .convertElectricCurrent: kind = .electricCurrent
        case .convertElectricPotentialDifference: kind = .electricPotentialDifference
        case .convertElectricResistance: kind = .electricResistance
        case .convertConcentrationMass: kind = .concentrationMass
        case .convertDispersion: kind = .dispersion
        case .convertFuelEfficiency: kind = .fuelEfficiency
        case .convertInformationStorage: kind = .informationStorage
        default: return ""
        }

        if let converted = LogoMeasurementConverter.convert(value: val, from: fromUnitStr, to: toUnitStr, kind: kind) {
            let res = LogoMeasurementConverter.formatResult(converted)
            setLastExpressionString(res)
            return res
        }
        return ""
    }

    private func evaluateMeasurementFormatPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> String {
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
            guard let valStr = reader.nextOptionalExpression(),
                let unitStr = reader.nextOptionalExpression()
            else { return "" }

            let val = Double(unquote(valStr)) ?? 0
            let cleanUnit = unquote(unitStr)

            var style: String? = nil
            var localeSpec: String? = nil
            var naturalScale = false

            if reader.peekToken() == "[" {
                let rawList = reader.nextExpression()
                let parsed = LogoValue.parse(rawList)
                if case .list(let items) = parsed {
                    var isDict = false
                    var i = 0
                    while i < items.count {
                        let key = items[i].stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanKey = key.hasPrefix(":") ? String(key.dropFirst()) : key
                        if ["style", "fmt", "locale", "lang", "natural", "scale"].contains(cleanKey)
                            && i + 1 < items.count
                        {
                            isDict = true
                            let v = items[i + 1].stringValue
                            switch cleanKey {
                            case "style", "fmt": style = v
                            case "locale", "lang": localeSpec = v
                            case "natural", "scale": naturalScale = (v.lowercased() == "true" || v == "1" || v.lowercased() == "yes")
                            default: break
                            }
                            i += 2
                        } else {
                            i += 1
                        }
                    }
                    if !isDict {
                        let strings = items.map { $0.stringValue }
                        LogoMeasurementConverter.disambiguateFormatOptions(
                            strings, style: &style, locale: &localeSpec, naturalScale: &naturalScale)
                    }
                }
            } else {
                var positional: [String] = []
                while positional.count < 3,
                    let arg = reader.nextOptionalExpression()
                {
                    positional.append(unquote(arg))
                }
                LogoMeasurementConverter.disambiguateFormatOptions(
                    positional, style: &style, locale: &localeSpec, naturalScale: &naturalScale)
            }

            reader.commit(to: &index)

            let kind: LogoMeasurementConverter.DimensionKind
            switch prim {
            case .formatArea: kind = .area
            case .formatLength: kind = .length
            case .formatVolume: kind = .volume
            case .formatAngle: kind = .angle
            case .formatMass: kind = .mass
            case .formatPressure: kind = .pressure
            case .formatAcceleration: kind = .acceleration
            case .formatDuration: kind = .duration
            case .formatFrequency: kind = .frequency
            case .formatSpeed: kind = .speed
            case .formatEnergy: kind = .energy
            case .formatPower: kind = .power
            case .formatTemperature: kind = .temperature
            case .formatIlluminance: kind = .illuminance
            case .formatElectricCharge: kind = .electricCharge
            case .formatElectricCurrent: kind = .electricCurrent
            case .formatElectricPotentialDifference: kind = .electricPotentialDifference
            case .formatElectricResistance: kind = .electricResistance
            case .formatConcentrationMass: kind = .concentrationMass
            case .formatDispersion: kind = .dispersion
            case .formatFuelEfficiency: kind = .fuelEfficiency
            case .formatInformationStorage: kind = .informationStorage
            default: return ""
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
}
