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
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.uppercased()

        case .lowercase:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.lowercased()

        case .apply:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let args = LogoValue.parse(listStr).toListItems().map { $0.description }
            return applyTemplate(templateStr: templateStr, args: args)

        case .invoke:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            var args: [String] = []
            while index + 1 < tokens.count {
                if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                    break
                }
                index += 1
                let arg = evaluateExpression(tokens, index: &index)
                args.append(arg)
            }
            return applyTemplate(templateStr: templateStr, args: args)

        case .foreach:
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                _ = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
            }
            return ""

        case .map:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var results: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                results.append(res)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .mapSe:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var results: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                let parsed = LogoValue.parse(res)
                switch parsed {
                case .list(let listItems), .array(let listItems):
                    results.append(contentsOf: listItems.map { $0.description })
                case .string(let s):
                    if !s.isEmpty {
                        results.append(s)
                    }
                }
            }
            return "[" + results.joined(separator: " ") + "]"

        case .filter:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
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
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
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
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            guard !items.isEmpty else { return "" }
            var accum = items[0]
            for i in 1..<items.count {
                let rest = Array(items[(i + 1)...])
                accum = applyTemplate(templateStr: templateStr, args: [accum, items[i]], indexInLoop: i, restList: rest)
            }
            return accum

        case .crossmap:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listsArgStr = evaluateExpression(tokens, index: &index)
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
            index += 1
            var descending = false
            if index < tokens.count {
                let nextToken = tokens[index]
                let modifier = unquote(nextToken).lowercased()
                if modifier == "desc" || modifier == "descending" || modifier == "greaterp" || modifier == "greater?" {
                    descending = true
                    index += 1
                }
            }
            guard index < tokens.count else { return nil }
            let dataStr = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(dataStr)
            var customTemplate: String? = nil

            if index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if nextToken.hasPrefix("[") || customProcedures[nextToken.uppercased()] != nil {
                    index += 1
                    customTemplate = evaluateExpression(tokens, index: &index)
                }
            }

            let isLessThan: (String, String) -> Bool = { a, b in
                if let t = customTemplate {
                    let res = self.applyTemplate(templateStr: t, args: [a, b])
                    return self.logoIsTrue(res)
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

            case .string(let s):
                if customTemplate == nil {
                    let sortedChars = descending ? Array(s).sorted(by: >) : Array(s).sorted(by: <)
                    return String(sortedChars)
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

extension LogoValue {
    internal func toListItems() -> [LogoValue] {
        switch self {
        case .list(let items), .array(let items): return items
        case .string(let s): return [.string(s)]
        }
    }
}
