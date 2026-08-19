import Foundation

extension LogoEngine {
    /// Template & Higher-Order Primitives Evaluator (`evaluateTemplatePrimitives`)
    ///
    /// ### Role & Architecture:
    /// - **Role**: Evaluates higher-order functional primitives and template iterators.
    /// - **Primitives**: `APPLY`, `INVOKE`, `MAP`, `MAPSE`, `FILTER`, `FIND`, `REDUCE`, `CROSSMAP`, `SORT`
    /// - **Return Type**: `String?` (evaluated result string or `nil`).
    internal func evaluateTemplatePrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        case .uppercase:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            return v.uppercased()

        case .lowercase:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            return v.lowercased()

        case .apply:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            let listStr = reader.nextExpression()
            reader.commit(to: &index)
            let args = LogoValue.parse(listStr).toListItems().map { $0.description }
            return applyTemplate(templateStr: templateStr, args: args)

        case .invoke:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            var args: [String] = []
            while let arg = reader.nextOptionalExpression() {
                args.append(arg)
            }
            reader.commit(to: &index)
            return applyTemplate(templateStr: templateStr, args: args)

        case .foreach:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let listStr = reader.nextExpression()
            let templateStr = reader.nextExpression()
            reader.commit(to: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                _ = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
            }
            return ""

        case .map:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            let listStr = reader.nextExpression()
            reader.commit(to: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var results: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                results.append(res)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .mapSe:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            let listStr = reader.nextExpression()
            reader.commit(to: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var results: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                let parsed = LogoValue.parse(res)
                switch parsed {
                case .list(let listItems), .array(let listItems):
                    results.append(contentsOf: listItems.map { $0.description })
                case .measurement(let v, let u, _):
                    results.append(contentsOf: [LogoMeasurementConverter.formatResult(v), u])
                case .date:
                    results.append(parsed.description)
                case .string(let s):
                    if !s.isEmpty {
                        results.append(s)
                    }
                }
            }
            return "[" + results.joined(separator: " ") + "]"

        case .filter:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            let listStr = reader.nextExpression()
            reader.commit(to: &index)

            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var results: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                if logoIsTrue(res) {
                    results.append(item)
                }
            }
            return "[" + results.joined(separator: " ") + "]"

        case .find:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            let listStr = reader.nextExpression()
            reader.commit(to: &index)

            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                if logoIsTrue(res) {
                    return item
                }
            }
            return "[]"

        case .reduce:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            let listStr = reader.nextExpression()
            reader.commit(to: &index)

            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            guard !items.isEmpty else { return "" }
            guard items.count > 1 else { return items[0] }

            var accum = items[0]
            for (i, nextItem) in items.dropFirst().enumerated() {
                let rest = Array(items[(i + 2)...])
                accum = applyTemplate(
                    templateStr: templateStr, args: [accum, nextItem], indexInLoop: i + 1, restList: rest)
            }
            return accum

        case .crossmap:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let templateStr = reader.nextExpression()
            let listsArgStr = reader.nextExpression()
            reader.commit(to: &index)
            let parsedListsArg = LogoValue.parse(listsArgStr).toListItems()
            let listOfLists = parsedListsArg.map { $0.toListItems().map { item in item.description } }
            guard !listOfLists.isEmpty else { return "[]" }

            var combinations: [[String]] = [[]]
            for list in listOfLists {
                var nextCombos: [[String]] = []
                for combo in combinations {
                    for item in list {
                        nextCombos.append(combo + [item])
                    }
                }
                combinations = nextCombos
            }

            var results: [String] = []
            for (i, combo) in combinations.enumerated() {
                let res = applyTemplate(templateStr: templateStr, args: combo, indexInLoop: i + 1)
                results.append(res)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .sort:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            var descending = false
            if let nextToken = reader.peekToken() {
                let modifier = unquote(nextToken).lowercased()
                if modifier == "desc" {
                    descending = true
                    _ = reader.nextRawToken()
                } else if modifier == "asc" {
                    descending = false
                    _ = reader.nextRawToken()
                }
            }
            guard reader.peekToken() != nil else { return nil }
            let dataStr = reader.nextExpression()
            let parsed = LogoValue.parse(dataStr)
            var customTemplate: String? = nil

            if let nextToken = reader.peekToken() {
                if nextToken.hasPrefix("[") || customProcedures[nextToken.uppercased()] != nil {
                    customTemplate = reader.nextExpression()
                }
            }
            reader.commit(to: &index)

            let isLessThan: (String, String) -> Bool = { a, b in
                if let t = customTemplate {
                    let res = self.applyTemplate(templateStr: t, args: [a, b])
                    return logoIsTrue(res)
                } else {
                    if let n1 = Double(a), let n2 = Double(b) {
                        return descending ? n1 > n2 : n1 < n2
                    }
                    return descending ? a > b : a < b
                }
            }

            switch parsed {
            case .list(let items):
                let sortedItems = items.sorted { isLessThan($0.description, $1.description) }
                return LogoValue.list(sortedItems).description

            case .array(let items):
                let sortedItems = items.sorted { isLessThan($0.description, $1.description) }
                return LogoValue.array(sortedItems).description

            case .measurement, .date:
                return parsed.description

            case .string(let s):
                if customTemplate == nil {
                    let sortedChars = descending ? Array(s).sorted(by: >) : Array(s).sorted(by: <)
                    return String(sortedChars)
                } else {
                    let sortedChars = Array(s).map { String($0) }.sorted { isLessThan($0, $1) }
                    return sortedChars.joined()
                }
            }

        case .sortLocalized:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            var descending = false
            var targetLocale = Locale.autoupdatingCurrent

            while let nextToken = reader.peekToken() {
                let unquoted = unquote(nextToken)
                let lower = unquoted.lowercased()
                if lower == "desc" {
                    descending = true
                    _ = reader.nextRawToken()
                } else if lower == "asc" {
                    descending = false
                    _ = reader.nextRawToken()
                } else if LogoDateTimeFormatter.isLocaleName(unquoted) {
                    targetLocale = LogoDateTimeFormatter.parseLocale(unquoted)
                    _ = reader.nextRawToken()
                } else {
                    break
                }
            }
            guard reader.peekToken() != nil else { return nil }
            let dataStr = reader.nextExpression()
            let parsed = LogoValue.parse(dataStr)
            var customTemplate: String? = nil

            if let nextToken = reader.peekToken() {
                if nextToken.hasPrefix("[") || customProcedures[nextToken.uppercased()] != nil {
                    customTemplate = reader.nextExpression()
                }
            }
            reader.commit(to: &index)

            let isLessThan: (String, String) -> Bool = { a, b in
                if let t = customTemplate {
                    let res = self.applyTemplate(templateStr: t, args: [a, b])
                    return logoIsTrue(res)
                } else {
                    let comparison = a.compare(
                        b,
                        options: [.caseInsensitive, .numeric, .widthInsensitive, .forcedOrdering],
                        range: nil,
                        locale: targetLocale
                    )
                    return descending ? comparison == .orderedDescending : comparison == .orderedAscending
                }
            }

            switch parsed {
            case .list(let items):
                let sortedItems = items.sorted { isLessThan($0.description, $1.description) }
                return LogoValue.list(sortedItems).description

            case .array(let items):
                let sortedItems = items.sorted { isLessThan($0.description, $1.description) }
                return LogoValue.array(sortedItems).description

            case .measurement, .date:
                return parsed.description

            case .string(let s):
                if customTemplate == nil {
                    let chars = Array(s).map { String($0) }
                    let sortedChars = chars.sorted { isLessThan($0, $1) }
                    return sortedChars.joined()
                } else {
                    let sortedChars = Array(s).map { String($0) }.sorted { isLessThan($0, $1) }
                    return sortedChars.joined()
                }
            }

        default:
            return nil
        }
    }
}
