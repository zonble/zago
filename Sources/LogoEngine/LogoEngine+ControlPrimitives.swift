import Foundation

extension LogoEngine {
    /// Evaluates Control, Higher-Order, Iteration, Procedure, and String Formatting Primitives.
    internal func evaluateControlPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        // ---------------------------------------------------------------------
        // 2.5 Queries & Misc
        // ---------------------------------------------------------------------
        case .count:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items): return "\(items.count)"
            case .string(let s): return "\(s.count)"
            }

        case .ascii:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            if let first = v.utf8.first {
                return "\(first)"
            }
            return "0"

        case .char:
            index += 1
            let code = Int(evaluateExpression(tokens, index: &index)) ?? 0
            if let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""

        case .uppercase:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.uppercased()

        case .lowercase:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.lowercased()

        case .member:
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(haystack)
            switch p {
            case .list(let items):
                if let pos = items.firstIndex(where: { $0.description == needle }) {
                    let tail = Array(items[pos...])
                    return LogoValue.list(tail).description
                }
                return "[]"
            case .array(let items):
                if let pos = items.firstIndex(where: { $0.description == needle }) {
                    let tail = Array(items[pos...])
                    return LogoValue.array(tail).description
                }
                return "{}"
            case .string(let s):
                if let range = s.range(of: needle) {
                    return String(s[range.lowerBound...])
                }
                return ""
            }

        case .standout:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            var result = ""
            for ch in v {
                if let asciiVal = ch.asciiValue {
                    if asciiVal >= 65 && asciiVal <= 90 { // A-Z
                        let boldScalar = UnicodeScalar(0x1D400 + Int(asciiVal - 65))!
                        result.append(Character(boldScalar))
                    } else if asciiVal >= 97 && asciiVal <= 122 { // a-z
                        let boldScalar = UnicodeScalar(0x1D41A + Int(asciiVal - 97))!
                        result.append(Character(boldScalar))
                    } else if asciiVal >= 48 && asciiVal <= 57 { // 0-9
                        let boldScalar = UnicodeScalar(0x1D7CE + Int(asciiVal - 48))!
                        result.append(Character(boldScalar))
                    } else {
                        result.append(ch)
                    }
                } else {
                    result.append(ch)
                }
            }
            return result

        case .parse, .runparse:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let toks = tokenize(v)
            return "[" + toks.joined(separator: " ") + "]"

        // ---------------------------------------------------------------------
        // 8.1 & 8.2 Control & Template-based Iteration Primitives
        // ---------------------------------------------------------------------
        case .apply:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            return applyTemplate(templateStr: templateStr, args: items)

        case .invoke:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            var args: [String] = []
            while index + 1 < tokens.count && !tokens[index + 1].hasPrefix("]") && tokens[index + 1] != ")" {
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
                let resItems = LogoValue.parse(res).toListItems().map { $0.description }.filter { !$0.isEmpty }
                results.append(contentsOf: resItems)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .filter:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var filtered: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let condRes = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                if logoIsTrue(condRes) {
                    filtered.append(item)
                }
            }
            return "[" + filtered.joined(separator: " ") + "]"

        case .find:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            if index + 1 < tokens.count { index += 1 }
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let condRes = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                if logoIsTrue(condRes) {
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
            guard !items.isEmpty else { return "[]" }
            var acc = items[0]
            for (i, item) in items.dropFirst().enumerated() {
                let rest = Array(items[(i + 2)...])
                acc = applyTemplate(templateStr: templateStr, args: [acc, item], indexInLoop: i + 2, restList: rest)
            }
            return acc

        case .crossmap:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listListStr = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(listListStr)
            var listsOfItems: [[String]] = []
            switch parsed {
            case .list(let subLists):
                for sub in subLists {
                    listsOfItems.append(sub.toListItems().map { $0.description })
                }
            default:
                listsOfItems.append(parsed.toListItems().map { $0.description })
            }

            func cartesianProduct(_ arrays: [[String]]) -> [[String]] {
                guard let first = arrays.first else { return [[]] }
                let subProduct = cartesianProduct(Array(arrays.dropFirst()))
                var res: [[String]] = []
                for f in first {
                    for sub in subProduct {
                        res.append([f] + sub)
                    }
                }
                return res
            }

            let combos = cartesianProduct(listsOfItems)
            var results: [String] = []
            for (i, combo) in combos.enumerated() {
                let res = applyTemplate(templateStr: templateStr, args: combo, indexInLoop: i + 1)
                results.append(res)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .sort:
            index += 1
            guard index < tokens.count else { return "[]" }
            var isDesc = false
            var customTemplate: String? = nil

            let firstToken = tokens[index]
            let firstUpper = unquote(firstToken).uppercased()

            if firstUpper == "DESC" {
                isDesc = true
                index += 1
            } else if firstUpper == "ASC" {
                isDesc = false
                index += 1
            }

            guard index < tokens.count else { return "[]" }
            let targetValStr = evaluateExpression(tokens, index: &index)

            if index + 1 < tokens.count && (tokens[index + 1].hasPrefix("[") || customProcedures[tokens[index + 1].uppercased()] != nil) {
                index += 1
                customTemplate = evaluateExpression(tokens, index: &index)
            }

            let parsed = LogoValue.parse(targetValStr)

            func isLessThan(_ aStr: String, _ bStr: String) -> Bool {
                if let t = customTemplate, !t.isEmpty {
                    let res = applyTemplate(templateStr: t, args: [aStr, bStr])
                    return logoIsTrue(res)
                }
                if let n1 = Double(aStr), let n2 = Double(bStr) {
                    return isDesc ? n1 > n2 : n1 < n2
                }
                return isDesc ? aStr > bStr : aStr < bStr
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
                    let sortedChars = isDesc ? Array(s).sorted(by: >) : Array(s).sorted(by: <)
                    return String(sortedChars)
                } else {
                    let sortedChars = Array(s).map { String($0) }.sorted { isLessThan($0, $1) }
                    return sortedChars.joined()
                }
            }

        case .date:
            var format = "yyyy-MM-dd"
            if index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if !LogoEngine.isKeyword(nextToken) && nextToken != "]" && nextToken != ")" {
                    index += 1
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: Date())

        case .time:
            var format = "HH:mm:ss"
            if index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if !LogoEngine.isKeyword(nextToken) && nextToken != "]" && nextToken != ")" {
                    index += 1
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: Date())

        default:
            return nil
        }
    }

    internal func formatNum(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 && val >= Double(Int.min) && val <= Double(Int.max) {
            return "\(Int(val))"
        }
        return "\(val)"
    }

    internal func numericSum(of value: LogoValue) -> Double {
        switch value {
        case .string(let string):
            return Double(string) ?? 0
        case .list(let items), .array(let items):
            return items.reduce(0) { $0 + numericSum(of: $1) }
        }
    }

    internal func numericValues(in value: LogoValue) -> [Double] {
        switch value {
        case .string(let string):
            return Double(string).map { [$0] } ?? []
        case .list(let items), .array(let items):
            return items.flatMap { numericValues(in: $0) }
        }
    }

    internal func numericExtremum(of value: LogoValue, preferMaximum: Bool) -> Double? {
        let values = numericValues(in: value)
        guard var result = values.first else { return nil }
        for value in values.dropFirst() {
            result = preferMaximum ? Swift.max(result, value) : Swift.min(result, value)
        }
        return result
    }

    internal func logoIsTrue(_ val: String) -> Bool {
        let clean = val.lowercased().trimmingCharacters(in: .whitespaces)
        if clean == "1" || clean == "true" { return true }
        if clean == "0" || clean == "false" || clean.isEmpty { return false }
        if let d = Double(clean) { return d != 0 }
        return true
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
