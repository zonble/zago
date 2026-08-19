import Foundation

extension LogoEngine {
    /// Formatting Primitives Evaluator (`evaluateFormattingPrimitives`)
    ///
    /// Evaluates `FORMAT.NUMBER`, `FORMAT.LIST`, `FORMAT.RELATIVETIME`, `FORMAT.BYTES`, `FORMAT.NAME`.
    internal func evaluateFormattingPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = parsePrimitive(tokens[index]) else { return nil }

        switch prim {
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

        default:
            return nil
        }
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
        #if !canImport(Darwin)
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
        #if !canImport(Darwin)
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
                LogoRelativeDateTimeFormatter.disambiguateOptions(positional, unit: &unit, locale: &locale)
                res = LogoRelativeDateTimeFormatter.formatTime(value: val, unit: unit, locale: locale)
            } else if let targetDate = LogoDateTimeFormatter.parseDate(clean1) {
                let locale = positional.count > 0 ? positional[0] : nil
                res = LogoRelativeDateTimeFormatter.formatDate(target: targetDate, locale: locale)
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
        #if !canImport(Darwin)
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
                        && !Locale.isLogoLocaleSpec(itemStrings[2])
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
                    && !Locale.isLogoLocaleSpec(positional[1])
                    && !LogoFormatters.PersonNameStyle.isStyleKeyword(positional[2])
                    && !Locale.isLogoLocaleSpec(positional[2])
                {
                    given = positional[0]
                    middle = positional[1]
                    family = positional[2]
                    if positional.count > 3 {
                        let extra = Array(positional.dropFirst(3))
                        LogoFormatters.disambiguatePersonNameOptions(extra, style: &style, locale: &localeSpec)
                    }
                } else if positional.count >= 2 && !LogoFormatters.PersonNameStyle.isStyleKeyword(positional[1])
                    && !Locale.isLogoLocaleSpec(positional[1])
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
}
