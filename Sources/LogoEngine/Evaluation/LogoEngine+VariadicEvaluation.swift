import Foundation

extension LogoEngine {
    /// Evaluates expressions enclosed in parentheses, including variadic primitives and (ifelse cond [t] [f]).
    internal func evaluateParenthesizedExpression(tokens: [String], index: inout Int) -> String {
        guard index < tokens.count && tokens[index] == "(" else { return "" }
        index += 1
        var leftVal: String = ""
        if index < tokens.count, parsePrimitive(tokens[index]) == .ifCondition {
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
            while index + 1 < tokens.count && isFillerToken(tokens[index + 1]) {
                index += 1
            }
            if index + 1 < tokens.count && tokens[index + 1] == "[" {
                index += 1
                falseBlock = extractBlockTokens(tokens: tokens, index: &index)
            }

            let selectedBlock = isTrue ? trueBlock : falseBlock
            var blockIndex = 0
            leftVal = selectedBlock.isEmpty ? "" : evaluateExpression(selectedBlock, index: &blockIndex)
            setLastExpressionString(leftVal)
        } else if index < tokens.count, let variadicPrim = parsePrimitive(tokens[index]),
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
                    let parsedTz = TimeZone(logoTimeZoneSpec: tz)
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
                            precision: &precision,
                            parseStyle: { [weak self] in self?.parseNumberStyle($0) })
                    }
                    leftVal = LogoFormatters.formatNumber(
                        num, style: style, locale: locale, currencyCode: curr, precision: precision)
                    setLastExpressionString(leftVal)

                case .formatList:
                    #if !canImport(Darwin)
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
                        case .date:
                            items = [parsed.stringValue]
                        case .string(let s):
                            items = s.contains(" ") ? s.split(separator: " ").map { String($0) } : [s]
                        }
                        var type: LogoFormatters.ListType = .and
                        var locale: String? = nil
                        if cleanArgs.count > 1 {
                            LogoFormatters.disambiguateListOptions(
                                Array(cleanArgs.dropFirst()), type: &type, locale: &locale,
                                parseType: { [weak self] in self?.parseListType($0) })
                        }
                        leftVal = LogoFormatters.formatList(items, type: type, locale: locale)
                        setLastExpressionString(leftVal)
                    #endif

                case .formatRelativeTime:
                    #if !canImport(Darwin)
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
                                LogoRelativeDateTimeFormatter.disambiguateOptions(
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
                            Array(cleanArgs.dropFirst()), style: &style, locale: &locale,
                            parseStyle: { [weak self] in self?.parseByteCountStyle($0) })
                    }
                    leftVal = LogoFormatters.formatBytes(bytes, style: style, locale: locale)
                    setLastExpressionString(leftVal)

                case .formatName:
                    #if !canImport(Darwin)
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
                                    let key = itemStrings[i]
                                    let val = itemStrings[i + 1]
                                    if let field = parsePersonNameField(key) {
                                        switch field {
                                        case .givenName: given = val
                                        case .familyName: family = val
                                        case .middleName: middle = val
                                        case .prefix: pfx = val
                                        case .suffix: sfx = val
                                        case .nickname: nick = val
                                        case .style:
                                            style =
                                                parsePersonNameStyle(val) ?? LogoFormatters.PersonNameStyle.parse(val)
                                        case .locale: locale = val
                                        case .fullName: fullName = val
                                        }
                                    }
                                    i += 2
                                }
                            } else if itemStrings.count == 1 {
                                fullName = itemStrings[0]
                            } else if itemStrings.count == 2 {
                                given = itemStrings[0]
                                family = itemStrings[1]
                            } else if itemStrings.count >= 3 {
                                if parsePersonNameStyle(itemStrings[2]) == nil
                                    && !LogoFormatters.PersonNameStyle.isStyleKeyword(itemStrings[2])
                                    && !Locale.isLogoLocaleSpec(itemStrings[2])
                                {
                                    given = itemStrings[0]
                                    middle = itemStrings[1]
                                    family = itemStrings[2]
                                    if itemStrings.count > 3 {
                                        let extra = Array(itemStrings.dropFirst(3))
                                        LogoFormatters.disambiguatePersonNameOptions(
                                            extra, style: &style, locale: &locale,
                                            parseStyle: { [weak self] in self?.parsePersonNameStyle($0) })
                                    }
                                } else {
                                    given = itemStrings[0]
                                    family = itemStrings[1]
                                    let extra = Array(itemStrings.dropFirst(2))
                                    LogoFormatters.disambiguatePersonNameOptions(
                                        extra, style: &style, locale: &locale,
                                        parseStyle: { [weak self] in self?.parsePersonNameStyle($0) })
                                }
                            }
                        } else if cleanArgs.count >= 3
                            && parsePersonNameStyle(cleanArgs[1]) == nil
                            && !LogoFormatters.PersonNameStyle.isStyleKeyword(cleanArgs[1])
                            && !Locale.isLogoLocaleSpec(cleanArgs[1])
                            && parsePersonNameStyle(cleanArgs[2]) == nil
                            && !LogoFormatters.PersonNameStyle.isStyleKeyword(cleanArgs[2])
                            && !Locale.isLogoLocaleSpec(cleanArgs[2])
                        {
                            // Three positional arguments: givenName middleName familyName [style] [locale]
                            given = cleanArgs[0]
                            middle = cleanArgs[1]
                            family = cleanArgs[2]
                            if cleanArgs.count > 3 {
                                let extra = Array(cleanArgs.dropFirst(3))
                                LogoFormatters.disambiguatePersonNameOptions(
                                    extra, style: &style, locale: &locale,
                                    parseStyle: { [weak self] in self?.parsePersonNameStyle($0) })
                            }
                        } else if cleanArgs.count >= 2
                            && parsePersonNameStyle(cleanArgs[1]) == nil
                            && !LogoFormatters.PersonNameStyle.isStyleKeyword(cleanArgs[1])
                            && !Locale.isLogoLocaleSpec(cleanArgs[1])
                        {
                            // Two positional arguments: givenName familyName [style] [locale]
                            given = cleanArgs[0]
                            family = cleanArgs[1]
                            if cleanArgs.count > 2 {
                                let extra = Array(cleanArgs.dropFirst(2))
                                LogoFormatters.disambiguatePersonNameOptions(
                                    extra, style: &style, locale: &locale,
                                    parseStyle: { [weak self] in self?.parsePersonNameStyle($0) })
                            }
                        } else {
                            // Single full name or given name: name [style] [locale]
                            fullName = cleanArgs[0]
                            if cleanArgs.count > 1 {
                                let extra = Array(cleanArgs.dropFirst(1))
                                LogoFormatters.disambiguatePersonNameOptions(
                                    extra, style: &style, locale: &locale,
                                    parseStyle: { [weak self] in self?.parsePersonNameStyle($0) })
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
                        leftVal = res.logoString
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
                        leftVal = res.logoString
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
                        leftVal = res.logoString
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

                case .convertCalendar:
                    let cleanArgs = args.map { unquote($0) }
                    guard cleanArgs.count >= 2 else {
                        leftVal = ""
                        break
                    }
                    let dateToken = cleanArgs[0]
                    let targetCalName = cleanArgs[1]
                    var sourceCalToken: String? = nil
                    var formatToken: String? = nil

                    for tok in cleanArgs.dropFirst(2) {
                        if Calendar.Identifier(logoCalendarName: tok) != nil && sourceCalToken == nil {
                            sourceCalToken = tok
                        } else if formatToken == nil {
                            formatToken = tok
                        }
                    }

                    let targetCalId = Calendar.Identifier(logoCalendarName: targetCalName) ?? .gregorian
                    let sourceCal =
                        sourceCalToken.map {
                            Calendar(identifier: Calendar.Identifier(logoCalendarName: $0) ?? .gregorian)
                        } ?? Calendar(identifier: .gregorian)

                    let parsedDate: Date
                    let parsedVal = LogoValue.parse(dateToken)
                    switch parsedVal {
                    case .date(let d, _, _):
                        parsedDate = d
                    default:
                        parsedDate = LogoDateTimeFormatter.parseDate(dateToken, defaultCalendar: sourceCal) ?? Date()
                    }

                    if let fmt = formatToken, !fmt.isEmpty {
                        let res = LogoDateTimeFormatter.format(
                            date: parsedDate,
                            mode: .date,
                            formatSpec: fmt,
                            localeSpec: targetCalId.defaultLocaleIdentifier,
                            calendarSpec: targetCalName
                        )
                        setLastExpressionDateTime(res)
                        leftVal = res
                    } else {
                        let dateValue = LogoValue.date(
                            date: parsedDate, calendar: targetCalId, timeZone: TimeZone.current)
                        let res = dateValue.stringValue
                        setLastExpressionDateTime(res)
                        leftVal = res
                    }

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
                    #if !canImport(Darwin)
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
                            if arg.hasPrefix("[") && arg.hasSuffix("]") {
                                let parsed = LogoValue.parse(arg)
                                if case .list(let items) = parsed {
                                    var isDict = false
                                    var i = 0
                                    while i < items.count {
                                        let key = items[i].stringValue
                                        if let field = parseFormatOptionField(key), i + 1 < items.count {
                                            isDict = true
                                            let v = unquote(items[i + 1].stringValue)
                                            switch field {
                                            case .style, .format:
                                                style = v
                                            case .locale, .language:
                                                locale = v
                                            case .naturalScale:
                                                naturalScale = parseBoolean(v) ?? (v.lowercased() == "yes")
                                            case .unit:
                                                targetConversionUnit = v
                                            default:
                                                break
                                            }
                                            i += 2
                                        } else {
                                            i += 1
                                        }
                                    }
                                    if isDict { continue }
                                }
                            }
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

        return leftVal
    }
}
