import Foundation

extension LogoEngine {
    /// Evaluates condition expressions for IF, WHILE, UNTIL, etc.
    internal func evaluateCondition(_ conditionTokens: [String]) -> Bool {
        var tokensToEval = conditionTokens
        if tokensToEval.first == "[" && tokensToEval.last == "]" && tokensToEval.count >= 2 {
            tokensToEval.removeFirst()
            tokensToEval.removeLast()
        }
        guard !tokensToEval.isEmpty else { return false }
        let savedLastResult = lastResult
        defer { lastResult = savedLastResult }

        var idx = 0
        let leftValStr = evaluateExpression(tokensToEval, index: &idx)
        let resBool = logoIsTrue(leftValStr)

        if idx >= tokensToEval.count - 1 {
            return resBool
        }

        if idx + 1 < tokensToEval.count {
            let opToken = tokensToEval[idx + 1]
            if let op = LogoOperator.from(opToken), op.isComparison {
                idx += 2
                let rightValStr = evaluateExpression(tokensToEval, index: &idx)

                if let num1 = Double(leftValStr), let num2 = Double(rightValStr) {
                    switch op {
                    case .equal, .aliasEqual: return num1 == num2
                    case .notEqual, .aliasNotEqual: return num1 != num2
                    case .lessThan: return num1 < num2
                    case .greaterThan: return num1 > num2
                    case .lessOrEqual: return num1 <= num2
                    case .greaterOrEqual: return num1 >= num2
                    default: return false
                    }
                } else {
                    switch op {
                    case .equal, .aliasEqual: return leftValStr == rightValStr
                    case .notEqual, .aliasNotEqual: return leftValStr != rightValStr
                    case .lessThan: return leftValStr < rightValStr
                    case .greaterThan: return leftValStr > rightValStr
                    case .lessOrEqual: return leftValStr <= rightValStr
                    case .greaterOrEqual: return leftValStr >= rightValStr
                    default: return false
                    }
                }
            }
        }

        return logoIsTrue(leftValStr)
    }

    /// Evaluates expression tokens, variadic function calls, and binary arithmetic expressions (+, -, *, /, %).
    internal func evaluateExpression(_ tokens: [String], index: inout Int) -> String {
        guard index < tokens.count else { return "" }
        guard !hasUncaughtError else { return "" }
        guard expressionCallDepth < maxExpressionCallDepth else {
            let message = "[LOGO Error: Expression evaluation depth limit exceeded]"
            reportError(
                LogoError(code: 1, message: message),
                token: tokens.indices.contains(index) ? tokens[index] : "EXPRESSION")
            return ""
        }
        expressionCallDepth += 1
        defer { expressionCallDepth -= 1 }

        var leftVal: String = ""
        var isParenthesized = false
        if tokens[index] == "(" {
            isParenthesized = true
            index += 1
            if index < tokens.count, LogoPrimitive.from(tokens[index]) == .ifElseCondition {
                index += 1
                var condTokens: [String] = []
                while index < tokens.count && tokens[index] != "[" {
                    condTokens.append(tokens[index])
                    index += 1
                }

                let isTrue = evaluateCondition(condTokens)
                var trueBlock: [String] = []
                var falseBlock: [String] = []
                if index < tokens.count && tokens[index] == "[" {
                    trueBlock = extractBlockTokens(tokens: tokens, index: &index)
                }
                if index + 1 < tokens.count && tokens[index + 1] == "[" {
                    index += 1
                    falseBlock = extractBlockTokens(tokens: tokens, index: &index)
                }

                let selectedBlock = isTrue ? trueBlock : falseBlock
                var blockIndex = 0
                leftVal = selectedBlock.isEmpty ? "" : evaluateExpression(selectedBlock, index: &blockIndex)
                setLastExpressionString(leftVal)
            } else if index < tokens.count, let variadicPrim = LogoPrimitive.from(tokens[index]),
                LogoEngine.isVariadicPrimitive(variadicPrim)
            {
                let args = evaluateVariadicArguments(tokens, index: &index)
                if let value = evaluateVariadicValuePrimitive(variadicPrim, arguments: args) {
                    leftVal = value
                    setLastExpressionString(leftVal)
                } else {
                    switch variadicPrim {
                    case .date, .time, .datetime:
                        let mode: LogoDateTimeFormatter.Mode
                        switch variadicPrim {
                        case .date: mode = .date
                        case .time: mode = .time
                        case .datetime: mode = .dateTime
                        default: mode = .date
                        }
                        let cleanArgs = args.map { unquote($0) }
                        let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(cleanArgs, mode: mode)
                        leftVal = LogoDateTimeFormatter.format(
                            mode: mode,
                            formatSpec: f,
                            localeSpec: l,
                            timeZoneSpec: tz,
                            calendarSpec: cal
                        )
                        setLastExpressionDateTime(leftVal)

                    case .dateformat:
                        let cleanArgs = args.map { unquote($0) }
                        guard !cleanArgs.isEmpty else {
                            leftVal = ""
                            break
                        }
                        let dateVal = cleanArgs[0]
                        let restArgs = Array(cleanArgs.dropFirst())
                        let (f, l, tz, cal) = LogoDateTimeFormatter.resolveArguments(restArgs, mode: .dateTime)
                        let parsedCal = LogoDateTimeFormatter.parseCalendar(cal)
                        let parsedTz = LogoDateTimeFormatter.parseTimeZone(tz)
                        let parsedDate =
                            LogoDateTimeFormatter.parseDate(
                                dateVal, defaultCalendar: parsedCal, defaultTimeZone: parsedTz)
                            ?? Date()
                        let hasTime = dateVal.contains(":") || (dateVal.contains("T") && dateVal.contains(":"))
                        let mode: LogoDateTimeFormatter.Mode = hasTime ? .dateTime : .date
                        leftVal = LogoDateTimeFormatter.format(
                            date: parsedDate,
                            mode: mode,
                            formatSpec: f,
                            localeSpec: l,
                            timeZoneSpec: tz,
                            calendarSpec: cal
                        )
                        setLastExpressionDateTime(leftVal)

                    case .dateadd:
                        let cleanArgs = args.map { unquote($0) }
                        guard !cleanArgs.isEmpty else {
                            leftVal = ""
                            break
                        }
                        let dateVal = cleanArgs[0]
                        let amountVal = cleanArgs.count > 1 ? (Int(cleanArgs[1]) ?? 0) : 0
                        let unitVal = cleanArgs.count > 2 ? cleanArgs[2] : "days"
                        let parsedDate = LogoDateTimeFormatter.parseDate(dateVal) ?? Date()
                        let newDate = LogoDateTimeFormatter.add(to: parsedDate, amount: amountVal, unit: unitVal)
                        leftVal = LogoDateTimeFormatter.format(
                            date: newDate,
                            mode: (dateVal.contains(":") || dateVal.contains("T")) ? .dateTime : .date
                        )
                        setLastExpressionDateTime(leftVal)

                    case .datediff:
                        let cleanArgs = args.map { unquote($0) }
                        guard cleanArgs.count >= 2 else {
                            leftVal = "0"
                            break
                        }
                        let dateVal1 = cleanArgs[0]
                        let dateVal2 = cleanArgs[1]
                        let unitVal = cleanArgs.count > 2 ? cleanArgs[2] : "days"
                        let d1 = LogoDateTimeFormatter.parseDate(dateVal1) ?? Date()
                        let d2 = LogoDateTimeFormatter.parseDate(dateVal2) ?? Date()
                        let diff = LogoDateTimeFormatter.diff(between: d1, and: d2, unit: unitVal)
                        leftVal = "\(diff)"
                        setLastExpressionString(leftVal)

                    case .formatNumber:
                        let cleanArgs = args.map { unquote($0) }
                        guard !cleanArgs.isEmpty else {
                            leftVal = ""
                            break
                        }
                        let num = Double(cleanArgs[0]) ?? 0
                        var style: LogoFormatters.NumberStyle = .decimal
                        var locale: String? = nil
                        var curr: String? = nil
                        var precision: Int? = nil
                        if cleanArgs.count > 1 {
                            LogoFormatters.disambiguateNumberOptions(
                                Array(cleanArgs.dropFirst()), style: &style, locale: &locale, currencyCode: &curr,
                                precision: &precision)
                        }
                        leftVal = LogoFormatters.formatNumber(
                            num, style: style, locale: locale, currencyCode: curr, precision: precision)
                        setLastExpressionString(leftVal)

                    case .formatList:
                        #if os(Linux) || os(Windows)
                            leftVal = ""
                            reportError(
                                LogoError(
                                    code: 1, message: "[LOGO Error: FORMAT.LIST is not supported on this platform]"),
                                token: "FORMAT.LIST"
                            )
                        #else
                            let cleanArgs = args.map { unquote($0) }
                            guard !cleanArgs.isEmpty else {
                                leftVal = ""
                                break
                            }
                            let parsed = LogoValue.parse(cleanArgs[0])
                            let items: [String]
                            switch parsed {
                            case .list(let l), .array(let l): items = l.map { $0.stringValue }
                            case .measurement(let val, let unit, _):
                                items = [LogoMeasurementConverter.formatResult(val), unit]
                            case .string(let s):
                                items = s.contains(" ") ? s.split(separator: " ").map { String($0) } : [s]
                            }
                            var type: LogoFormatters.ListType = .and
                            var locale: String? = nil
                            if cleanArgs.count > 1 {
                                LogoFormatters.disambiguateListOptions(
                                    Array(cleanArgs.dropFirst()), type: &type, locale: &locale)
                            }
                            leftVal = LogoFormatters.formatList(items, type: type, locale: locale)
                            setLastExpressionString(leftVal)
                        #endif

                    case .formatRelativeTime:
                        #if os(Linux) || os(Windows)
                            leftVal = ""
                            reportError(
                                LogoError(
                                    code: 1,
                                    message: "[LOGO Error: FORMAT.RELATIVETIME is not supported on this platform]"),
                                token: "FORMAT.RELATIVETIME"
                            )
                        #else
                            let cleanArgs = args.map { unquote($0) }
                            guard !cleanArgs.isEmpty else {
                                leftVal = ""
                                break
                            }
                            let arg1 = cleanArgs[0]
                            if let val = Double(arg1) {
                                var unit = "days"
                                var locale: String? = nil
                                if cleanArgs.count > 1 {
                                    LogoFormatters.disambiguateRelativeTimeOptions(
                                        Array(cleanArgs.dropFirst()), unit: &unit, locale: &locale)
                                }
                                leftVal = LogoFormatters.formatRelativeTime(value: val, unit: unit, locale: locale)
                            } else if let targetDate = LogoDateTimeFormatter.parseDate(arg1) {
                                let locale = cleanArgs.count > 1 ? cleanArgs[1] : nil
                                leftVal = LogoFormatters.formatRelativeDate(target: targetDate, locale: locale)
                            } else {
                                leftVal = arg1
                            }
                            setLastExpressionString(leftVal)
                        #endif

                    case .formatBytes:
                        let cleanArgs = args.map { unquote($0) }
                        guard !cleanArgs.isEmpty, let bytes = Int64(cleanArgs[0]) else {
                            leftVal = ""
                            break
                        }
                        var style: LogoFormatters.ByteCountStyle = .file
                        var locale: String? = nil
                        if cleanArgs.count > 1 {
                            LogoFormatters.disambiguateBytesOptions(
                                Array(cleanArgs.dropFirst()), style: &style, locale: &locale)
                        }
                        leftVal = LogoFormatters.formatBytes(bytes, style: style, locale: locale)
                        setLastExpressionString(leftVal)

                    case .formatName:
                        #if os(Linux) || os(Windows)
                            leftVal = ""
                            reportError(
                                LogoError(
                                    code: 1,
                                    message: "[LOGO Error: FORMAT.NAME is not supported on this platform]"),
                                token: "FORMAT.NAME"
                            )
                        #else
                            let cleanArgs = args.map { unquote($0) }
                            guard !cleanArgs.isEmpty else {
                                leftVal = ""
                                break
                            }
                            var style: LogoFormatters.PersonNameStyle = .default
                            var locale: String? = nil
                            var given: String? = nil
                            var family: String? = nil
                            var middle: String? = nil
                            var pfx: String? = nil
                            var sfx: String? = nil
                            var nick: String? = nil
                            var fullName: String? = nil

                            let firstArg = cleanArgs[0]
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
                                        case "locale", "loc": locale = val
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
                                            LogoFormatters.disambiguatePersonNameOptions(
                                                extra, style: &style, locale: &locale)
                                        }
                                    } else {
                                        given = itemStrings[0]
                                        family = itemStrings[1]
                                        let extra = Array(itemStrings.dropFirst(2))
                                        LogoFormatters.disambiguatePersonNameOptions(
                                            extra, style: &style, locale: &locale)
                                    }
                                }
                            } else if cleanArgs.count >= 3
                                && !LogoFormatters.PersonNameStyle.isStyleKeyword(cleanArgs[1])
                                && !LogoDateTimeFormatter.isLocaleName(cleanArgs[1])
                                && !LogoFormatters.PersonNameStyle.isStyleKeyword(cleanArgs[2])
                                && !LogoDateTimeFormatter.isLocaleName(cleanArgs[2])
                            {
                                // Three positional arguments: givenName middleName familyName [style] [locale]
                                given = cleanArgs[0]
                                middle = cleanArgs[1]
                                family = cleanArgs[2]
                                if cleanArgs.count > 3 {
                                    let extra = Array(cleanArgs.dropFirst(3))
                                    LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &locale)
                                }
                            } else if cleanArgs.count >= 2
                                && !LogoFormatters.PersonNameStyle.isStyleKeyword(cleanArgs[1])
                                && !LogoDateTimeFormatter.isLocaleName(cleanArgs[1])
                            {
                                // Two positional arguments: givenName familyName [style] [locale]
                                given = cleanArgs[0]
                                family = cleanArgs[1]
                                if cleanArgs.count > 2 {
                                    let extra = Array(cleanArgs.dropFirst(2))
                                    LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &locale)
                                }
                            } else {
                                // Single full name or given name: name [style] [locale]
                                fullName = cleanArgs[0]
                                if cleanArgs.count > 1 {
                                    let extra = Array(cleanArgs.dropFirst(1))
                                    LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &locale)
                                }
                            }

                            leftVal = LogoFormatters.formatPersonName(
                                givenName: given,
                                familyName: family,
                                middleName: middle,
                                prefix: pfx,
                                suffix: sfx,
                                nickname: nick,
                                fullName: fullName,
                                style: style,
                                locale: locale
                            )
                            setLastExpressionString(leftVal)
                        #endif

                    case .measureScale:
                        let cleanArgs = args.map { unquote($0) }
                        let val: Double
                        let unit: String
                        let factor: Double

                        if !args.isEmpty, case .measurement(let mVal, let mUnit, _) = LogoValue.parse(args[0]) {
                            val = mVal
                            unit = mUnit
                            factor = args.count > 1 ? (Double(unquote(args[1])) ?? 1) : 1
                        } else {
                            guard cleanArgs.count >= 3,
                                let v = Double(cleanArgs[0]),
                                let f = Double(cleanArgs[2])
                            else {
                                leftVal = ""
                                break
                            }
                            val = v
                            unit = cleanArgs[1]
                            factor = f
                        }
                        guard let res = LogoMeasurementConverter.scale(value: val, unit: unit, factor: factor) else {
                            leftVal = ""
                            break
                        }
                        let resStr = "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"
                        leftVal = resStr
                        setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)

                    case .measureAdd, .measureSub, .measureEqual, .measureLess, .measureGreater, .measureMin,
                        .measureMax:
                        let val1: Double
                        let unit1: String
                        let val2: Double
                        let unit2: String
                        let targetUnit: String?

                        if !args.isEmpty, case .measurement(let mVal1, let mUnit1, _) = LogoValue.parse(args[0]) {
                            val1 = mVal1
                            unit1 = mUnit1
                            if args.count > 1, case .measurement(let mVal2, let mUnit2, _) = LogoValue.parse(args[1]) {
                                val2 = mVal2
                                unit2 = mUnit2
                                if args.count > 2,
                                    let dim1 = LogoMeasurementConverter.findDimension(for: unit1),
                                    let dimT = LogoMeasurementConverter.findDimension(for: unquote(args[2])),
                                    dimT == dim1
                                {
                                    targetUnit = unquote(args[2])
                                } else {
                                    targetUnit = nil
                                }
                            } else if args.count > 2 {
                                val2 = Double(unquote(args[1])) ?? 0
                                unit2 = unquote(args[2])
                                if args.count > 3,
                                    let dim1 = LogoMeasurementConverter.findDimension(for: unit1),
                                    let dimT = LogoMeasurementConverter.findDimension(for: unquote(args[3])),
                                    dimT == dim1
                                {
                                    targetUnit = unquote(args[3])
                                } else {
                                    targetUnit = nil
                                }
                            } else {
                                leftVal = ""
                                break
                            }
                        } else {
                            let cleanArgs = args.map { unquote($0) }
                            guard cleanArgs.count >= 4,
                                let v1 = Double(cleanArgs[0]),
                                let v2 = Double(cleanArgs[2])
                            else {
                                leftVal = ""
                                break
                            }
                            val1 = v1
                            unit1 = cleanArgs[1]
                            val2 = v2
                            unit2 = cleanArgs[3]
                            if cleanArgs.count > 4,
                                let dim1 = LogoMeasurementConverter.findDimension(for: unit1),
                                let dimT = LogoMeasurementConverter.findDimension(for: cleanArgs[4]),
                                dimT == dim1
                            {
                                targetUnit = cleanArgs[4]
                            } else {
                                targetUnit = nil
                            }
                        }

                        switch variadicPrim {
                        case .measureAdd:
                            guard
                                let res = LogoMeasurementConverter.add(
                                    val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                            else {
                                let msg =
                                    "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                                reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                leftVal = ""
                                break
                            }
                            let str = "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"
                            leftVal = str
                            setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)

                        case .measureSub:
                            guard
                                let res = LogoMeasurementConverter.subtract(
                                    val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                            else {
                                let msg =
                                    "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                                reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                leftVal = ""
                                break
                            }
                            let str = "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"
                            leftVal = str
                            setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)

                        case .measureEqual:
                            guard
                                let (v1, v2) = LogoMeasurementConverter.compare(
                                    val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                            else {
                                let msg =
                                    "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                                reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                leftVal = "false"
                                break
                            }
                            let tolerance = targetUnit.flatMap(Double.init) ?? 1e-6
                            let res = abs(v1 - v2) <= tolerance
                            leftVal = res ? "true" : "false"
                            setLastExpressionBoolean(res)

                        case .measureLess:
                            guard
                                let (v1, v2) = LogoMeasurementConverter.compare(
                                    val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                            else {
                                let msg =
                                    "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                                reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                leftVal = "false"
                                break
                            }
                            let res = v1 < v2
                            leftVal = res ? "true" : "false"
                            setLastExpressionBoolean(res)

                        case .measureGreater:
                            guard
                                let (v1, v2) = LogoMeasurementConverter.compare(
                                    val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                            else {
                                let msg =
                                    "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                                reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                leftVal = "false"
                                break
                            }
                            let res = v1 > v2
                            leftVal = res ? "true" : "false"
                            setLastExpressionBoolean(res)

                        case .measureMin:
                            guard
                                let res = LogoMeasurementConverter.min(
                                    val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                            else {
                                let msg =
                                    "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                                reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                leftVal = ""
                                break
                            }
                            let str = "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"
                            leftVal = str
                            setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)

                        case .measureMax:
                            guard
                                let res = LogoMeasurementConverter.max(
                                    val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                            else {
                                let msg =
                                    "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                                reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                leftVal = ""
                                break
                            }
                            let str = "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"
                            leftVal = str
                            setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)

                        default:
                            break
                        }

                    case .detectURL, .detectEmail, .detectPhone, .detectDate, .detectAddress:
                        let text = args.first.map(unquote) ?? ""
                        leftVal = evaluateDetectPrimitive(variadicPrim, text: text)

                    case .convertMeasure:
                        var val: Double = 0
                        var fromUnit: String = ""
                        var toUnit: String = ""

                        if !args.isEmpty, case .measurement(let mVal, let mUnit, _) = LogoValue.parse(args[0]) {
                            val = mVal
                            fromUnit = mUnit
                            guard args.count >= 2 else {
                                leftVal = ""
                                break
                            }
                            toUnit = unquote(args[1])
                        } else {
                            let cleanArgs = args.map { unquote($0) }
                            guard cleanArgs.count >= 3, let v = Double(cleanArgs[0]) else {
                                leftVal = ""
                                break
                            }
                            val = v
                            fromUnit = cleanArgs[1]
                            toUnit = cleanArgs[2]
                        }

                        guard let dimFrom = LogoMeasurementConverter.findDimension(for: fromUnit) else {
                            let msg =
                                "[LOGO Error: \(variadicPrim.meta.name) invalid or unknown source unit '\(fromUnit)']"
                            reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                            leftVal = ""
                            break
                        }
                        guard let dimTo = LogoMeasurementConverter.findDimension(for: toUnit) else {
                            let msg =
                                "[LOGO Error: \(variadicPrim.meta.name) invalid or unknown target unit '\(toUnit)']"
                            reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                            leftVal = ""
                            break
                        }
                        guard dimFrom == dimTo else {
                            let msg =
                                "[LOGO Error: \(variadicPrim.meta.name) cannot convert '\(fromUnit)' (\(dimFrom)) to '\(toUnit)' (\(dimTo))]"
                            reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                            leftVal = ""
                            break
                        }

                        if let converted = LogoMeasurementConverter.convert(
                            value: val, from: fromUnit, to: toUnit, kind: dimFrom)
                        {
                            leftVal = LogoMeasurementConverter.formatResult(converted)
                            setLastExpressionString(leftVal)
                        } else {
                            leftVal = ""
                        }

                    case .formatMeasure:
                        #if os(Linux) || os(Windows)
                            let name = variadicPrim.meta.name
                            let message = "[LOGO Error: \(name) is not supported on this platform]"
                            reportError(LogoError(code: 1, message: message), token: name)
                            leftVal = ""
                        #else
                            var val: Double = 0
                            var unitStr: String = ""
                            var remainingArgs: [String] = []
                            let kind: LogoMeasurementConverter.DimensionKind

                            if !args.isEmpty,
                                case .measurement(let mVal, let mUnit, let mDim) = LogoValue.parse(args[0])
                            {
                                val = mVal
                                unitStr = mUnit
                                kind = mDim
                                remainingArgs = Array(args.dropFirst().map { unquote($0) })
                            } else {
                                let cleanArgs = args.map { unquote($0) }
                                guard cleanArgs.count >= 2, let v = Double(cleanArgs[0]) else {
                                    leftVal = ""
                                    break
                                }
                                val = v
                                unitStr = cleanArgs[1]
                                guard let inferredDim = LogoMeasurementConverter.findDimension(for: unitStr) else {
                                    let msg =
                                        "[LOGO Error: \(variadicPrim.meta.name) invalid or unknown unit '\(unitStr)']"
                                    reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                    leftVal = ""
                                    break
                                }
                                kind = inferredDim
                                remainingArgs = Array(cleanArgs.dropFirst(2))
                            }

                            var style: String? = nil
                            var locale: String? = nil
                            var naturalScale = false
                            var targetConversionUnit: String? = nil

                            var positional: [String] = []
                            var hasInvalidUnit = false
                            for arg in remainingArgs {
                                if let dim = LogoMeasurementConverter.findDimension(for: arg) {
                                    if dim == kind {
                                        targetConversionUnit = arg
                                    } else {
                                        let msg =
                                            "[LOGO Error: \(variadicPrim.meta.name) invalid unit '\(arg)' (expected \(kind) unit, got \(dim))]"
                                        reportError(LogoError(code: 1, message: msg), token: variadicPrim.meta.name)
                                        leftVal = ""
                                        hasInvalidUnit = true
                                        break
                                    }
                                } else {
                                    positional.append(arg)
                                }
                            }
                            if hasInvalidUnit { break }
                            LogoMeasurementConverter.disambiguateFormatOptions(
                                positional, style: &style, locale: &locale, naturalScale: &naturalScale)

                            if let targetUnit = targetConversionUnit,
                                let convertedVal = LogoMeasurementConverter.convert(
                                    value: val, from: unitStr, to: targetUnit, kind: kind)
                            {
                                val = convertedVal
                                unitStr = targetUnit
                            }

                            if let formatted = LogoMeasurementConverter.format(
                                value: val, unit: unitStr, kind: kind, style: style, locale: locale,
                                naturalScale: naturalScale)
                            {
                                leftVal = formatted
                                setLastExpressionString(leftVal)
                            } else {
                                leftVal = ""
                            }
                        #endif

                    default:
                        leftVal = ""
                        setLastExpressionString(leftVal)
                    }
                }
            } else {
                leftVal = evaluateExpression(tokens, index: &index)
                if index + 1 < tokens.count && tokens[index + 1] == ")" {
                    index += 1
                }
            }
        } else {
            leftVal = evaluateTokenOrCommand(tokens, index: &index)
        }

        // Peek next operator if present
        while index + 1 < tokens.count {
            guard !hasUncaughtError else { return "" }
            let nextToken = tokens[index + 1]
            if nextToken == ")" || nextToken == "]" {
                break
            }
            if let op = LogoOperator.from(nextToken) {
                if op.isArithmetic {
                    index += 2
                    guard index < tokens.count else { break }
                    let rightVal = evaluateExpression(tokens, index: &index)

                    if let num1 = Double(leftVal), let num2 = Double(rightVal) {
                        if let n1 = Int(leftVal), let n2 = Int(rightVal), op != .power && op != .divide {
                            let resNum: Int
                            switch op {
                            case .add: resNum = n1 + n2
                            case .subtract: resNum = n1 - n2
                            case .multiply: resNum = n1 * n2
                            case .modulo: resNum = (n2 != 0) ? n1 % n2 : 0
                            default: resNum = 0
                            }
                            leftVal = "\(resNum)"
                        } else {
                            let resDouble: Double
                            switch op {
                            case .add: resDouble = num1 + num2
                            case .subtract: resDouble = num1 - num2
                            case .multiply: resDouble = num1 * num2
                            case .divide: resDouble = (num2 != 0) ? num1 / num2 : 0.0
                            case .modulo: resDouble = (num2 != 0) ? num1.truncatingRemainder(dividingBy: num2) : 0.0
                            case .power: resDouble = pow(num1, num2)
                            default: resDouble = 0.0
                            }
                            if resDouble.truncatingRemainder(dividingBy: 1) == 0 && resDouble >= Double(Int.min)
                                && resDouble <= Double(Int.max)
                            {
                                leftVal = "\(Int(resDouble))"
                            } else {
                                leftVal = "\(resDouble)"
                            }
                        }
                    } else if op == .add {
                        leftVal = leftVal + rightVal
                    }
                } else if op.isComparison && isParenthesized {
                    index += 2
                    guard index < tokens.count else { break }
                    let rightVal = evaluateExpression(tokens, index: &index)
                    if let num1 = Double(leftVal), let num2 = Double(rightVal) {
                        switch op {
                        case .equal, .aliasEqual:
                            leftVal = (num1 == num2).logoString
                        case .notEqual, .aliasNotEqual:
                            leftVal = (num1 != num2).logoString
                        case .lessThan:
                            leftVal = (num1 < num2).logoString
                        case .greaterThan:
                            leftVal = (num1 > num2).logoString
                        case .lessOrEqual:
                            leftVal = (num1 <= num2).logoString
                        case .greaterOrEqual:
                            leftVal = (num1 >= num2).logoString
                        default:
                            leftVal = "false"
                        }
                    } else {
                        switch op {
                        case .equal, .aliasEqual:
                            leftVal = (leftVal == rightVal).logoString
                        case .notEqual, .aliasNotEqual:
                            leftVal = (leftVal != rightVal).logoString
                        case .lessThan:
                            leftVal = (leftVal < rightVal).logoString
                        case .greaterThan:
                            leftVal = (leftVal > rightVal).logoString
                        case .lessOrEqual:
                            leftVal = (leftVal <= rightVal).logoString
                        case .greaterOrEqual:
                            leftVal = (leftVal >= rightVal).logoString
                        default:
                            leftVal = "false"
                        }
                    }
                } else {
                    break
                }
            } else {
                break
            }
        }

        if isParenthesized && index + 1 < tokens.count && tokens[index + 1] == ")" {
            index += 1
        }

        setLastExpressionString(leftVal)
        return leftVal
    }

    /// Evaluates a single token, list block [...], array block {...}, custom procedure reporter, or built-in expression primitive.
    internal func evaluateTokenOrCommand(_ tokens: [String], index: inout Int) -> String {
        guard index < tokens.count else { return "" }
        let token = tokens[index]
        let upper = token.uppercased()

        if token.hasPrefix("[") || token.hasPrefix("{") {
            let closingChar: Character = token.hasPrefix("[") ? "]" : "}"
            var depth = 0
            var listTokens: [String] = []
            var currIndex = index
            while currIndex < tokens.count {
                let t = tokens[currIndex]
                for ch in t {
                    if ch == token.first! { depth += 1 } else if ch == closingChar { depth -= 1 }
                }
                listTokens.append(t)
                if depth <= 0 { break }
                currIndex += 1
            }
            index = currIndex
            setLastExpressionString(listTokens.joined(separator: " "))
            return listTokens.joined(separator: " ")
        }

        if let proc = customProcedures[upper] {
            let result = invokeProcedure(proc, tokens: tokens, index: &index) ?? ""
            setLastExpressionString(result)
            return result
        }

        return evaluateExpressionPrimitive(tokens, index: &index) ?? resolveTokenValue(token)
    }

    internal func resolveTokenValue(_ token: String) -> String {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        let lower = clean.lowercased()
        if clean.hasPrefix(":") {
            let varName = normalizeVariableName(clean)
            let value = variables[varName] ?? ""
            lastExpressionValue = variables.value(for: varName)
            return value
        }
        if clean.hasPrefix("?") || clean == "#" || variables[lower] != nil {
            if let val = variables[lower] {
                lastExpressionValue = variables.value(for: lower)
                return val
            }
        }
        let value = unquote(clean)
        setLastExpressionString(value)
        return value
    }

    internal func invokeProcedure(_ proc: LogoProcedure, tokens: [String], index: inout Int) -> String? {
        guard procedureCallDepth < maxProcedureCallDepth else {
            let message = "[Procedure recursion limit exceeded: \(proc.name)]"
            reportError(LogoError(code: 1, message: message, procedureName: proc.name), token: proc.name)
            return nil
        }
        procedureCallDepth += 1
        defer {
            procedureCallDepth -= 1
        }

        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        var args: [String] = []
        for _ in proc.parameters {
            guard !hasUncaughtError else { return nil }
            args.append(reader.nextExpression())
        }
        reader.commit(to: &index)

        guard !hasUncaughtError else { return nil }

        let initialScope = Dictionary(zip(proc.parameters, args), uniquingKeysWith: { _, last in last })
        variables.pushScope(initialValues: initialScope)
        executionFrames.append(
            LogoExecutionFrame(procedureName: proc.name, token: nil, scopeDepth: variables.scopeDepth))
        defer {
            variables.popScope()
            executionFrames.removeLast()
        }

        var procIndex = 0
        var procReturn: String? = nil
        let savedLastResult = lastResult
        lastResult = nil
        executeTokens(
            proc.bodyTokens.map(\.text), sourceTokens: proc.bodyTokens, index: &procIndex, frameReturn: &procReturn)
        if currentThrowTag != nil {
            return currentThrowValue ?? ""
        }
        let finalResult = procReturn ?? (proc.isSingleExpression ? lastResult : nil)
        lastResult = savedLastResult
        return finalResult
    }

    internal func extractBlockTokens(tokens: [String], index: inout Int) -> [String] {
        guard index < tokens.count && tokens[index] == "[" else { return [] }
        index += 1
        var depth = 1
        var block: [String] = []
        while index < tokens.count && depth > 0 {
            let t = tokens[index]
            if t == "[" {
                depth += 1
            } else if t == "]" {
                depth -= 1
                if depth == 0 { break }
            }
            block.append(t)
            index += 1
        }
        return block
    }

    internal func evaluateCaseClauses(targetVal: String, clausesBlock: [String]) -> String? {
        var idx = 0
        while idx < clausesBlock.count {
            if clausesBlock[idx] == "[" {
                let clause = extractBlockTokens(tokens: clausesBlock, index: &idx)
                if !clause.isEmpty {
                    var cIdx = 0
                    if clause[cIdx].uppercased() == "ELSE" {
                        cIdx += 1
                        var dummyFrameReturn: String? = nil
                        executeTokens(clause, index: &cIdx, frameReturn: &dummyFrameReturn)
                        return dummyFrameReturn ?? lastResult ?? ""
                    } else if clause[cIdx] == "[" {
                        let matches = extractBlockTokens(tokens: clause, index: &cIdx)
                        cIdx += 1
                        let isMatch = matches.contains { unquote($0) == targetVal }
                        if isMatch {
                            var dummyFrameReturn: String? = nil
                            executeTokens(clause, index: &cIdx, frameReturn: &dummyFrameReturn)
                            return dummyFrameReturn ?? lastResult ?? ""
                        }
                    }
                }
            }
            idx += 1
        }
        return nil
    }

    internal func evaluateCondClauses(clausesBlock: [String]) -> String? {
        var idx = 0
        while idx < clausesBlock.count {
            if clausesBlock[idx] == "[" {
                let clause = extractBlockTokens(tokens: clausesBlock, index: &idx)
                if !clause.isEmpty {
                    var cIdx = 0
                    if clause[cIdx].uppercased() == "ELSE" {
                        cIdx += 1
                        var dummyFrameReturn: String? = nil
                        executeTokens(clause, index: &cIdx, frameReturn: &dummyFrameReturn)
                        return dummyFrameReturn ?? lastResult ?? ""
                    } else if clause[cIdx] == "[" {
                        let condTokens = extractBlockTokens(tokens: clause, index: &cIdx)
                        cIdx += 1
                        if evaluateCondition(condTokens) {
                            var dummyFrameReturn: String? = nil
                            executeTokens(clause, index: &cIdx, frameReturn: &dummyFrameReturn)
                            return dummyFrameReturn ?? lastResult ?? ""
                        }
                    }
                }
            }
            idx += 1
        }
        return nil
    }

    internal func applyTemplate(templateStr: String, args: [String], indexInLoop: Int = 1, restList: [String] = [])
        -> String
    {
        let clean = templateStr.trimmingCharacters(in: .whitespacesAndNewlines)

        let prevHash = variables["#"]
        let prevRest = variables["?rest"]
        let prevQuestion = variables["?"]
        defer {
            if let v = prevHash { variables["#"] = v } else { variables.removeValue(forKey: "#") }
            if let v = prevRest { variables["?rest"] = v } else { variables.removeValue(forKey: "?rest") }
            if let v = prevQuestion { variables["?"] = v } else { variables.removeValue(forKey: "?") }
        }

        variables["#"] = "\(indexInLoop)"
        variables["?rest"] = restList.joined(separator: " ")

        if clean.hasPrefix("[") && clean.hasSuffix("]") {
            let tTokens = LogoTokenizer.tokenize(clean)
            var idx = 0
            if !tTokens.isEmpty && tTokens[0] == "[" {
                let inner = extractBlockTokens(tokens: tTokens, index: &idx)
                if !inner.isEmpty && inner[0] == "[" {
                    var iIdx = 0
                    let params = extractBlockTokens(tokens: inner, index: &iIdx)
                    iIdx += 1
                    for (i, p) in params.enumerated() {
                        let pName = unquote(p).lowercased()
                        variables[pName] = i < args.count ? args[i] : ""
                    }
                    let bodyTokens = Array(inner[iIdx...])
                    if !bodyTokens.isEmpty {
                        if bodyTokens[0] == "[" {
                            var bIdx = 0
                            let stmtBlock = extractBlockTokens(tokens: bodyTokens, index: &bIdx)
                            var subReturn: String? = nil
                            var sIdx = 0
                            executeTokens(stmtBlock, index: &sIdx, frameReturn: &subReturn)
                            return subReturn ?? lastResult ?? ""
                        } else if LogoEngine.isStatementCommand(bodyTokens[0]) {
                            var subReturn: String? = nil
                            var sIdx = 0
                            executeTokens(bodyTokens, index: &sIdx, frameReturn: &subReturn)
                            return subReturn ?? lastResult ?? ""
                        } else {
                            var bIdx = 0
                            return evaluateExpression(bodyTokens, index: &bIdx)
                        }
                    }
                } else {
                    variables["?"] = args.first ?? ""
                    for (i, arg) in args.enumerated() {
                        variables["?\(i + 1)"] = arg
                    }
                    if !inner.isEmpty {
                        if LogoEngine.isStatementCommand(inner[0]) {
                            var subReturn: String? = nil
                            var sIdx = 0
                            executeTokens(inner, index: &sIdx, frameReturn: &subReturn)
                            return subReturn ?? lastResult ?? ""
                        } else {
                            let hasComparison = inner.contains {
                                $0 == "=" || $0 == "==" || $0 == "!=" || $0 == "<" || $0 == ">" || $0 == "<="
                                    || $0 == ">=" || $0 == "EQUAL?" || $0 == "NOTEQUAL?"
                            }
                            if hasComparison {
                                return evaluateCondition(inner) ? "1" : "0"
                            } else {
                                var bIdx = 0
                                return evaluateExpression(inner, index: &bIdx)
                            }
                        }
                    }
                    return ""
                }
            }
        }

        let procName = unquote(clean).uppercased()
        if let proc = customProcedures[procName] {
            let callTokens = [procName] + args
            var cIdx = 0
            return invokeProcedure(proc, tokens: callTokens, index: &cIdx) ?? ""
        } else {
            let callTokens = [procName] + args
            var cIdx = 0
            return evaluateTokenOrCommand(callTokens, index: &cIdx)
        }
    }
}
