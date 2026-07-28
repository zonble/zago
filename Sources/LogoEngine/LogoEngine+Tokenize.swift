import Foundation

extension LogoEngine {
    /// Tokenizes macro script handling string literals in quotes, comparison operators (==, !=, <=, >=), math operators (+, -, *, /, %), and brackets.
    public func tokenize(_ script: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        let delims: Set<Character> = ["[", "]", "{", "}", "(", ")", "+", "-", "*", "/", "%", "^"]

        var i = script.startIndex
        while i < script.endIndex {
            let ch = script[i]
            if ch == "\"" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                current.append(ch)

                if hasClosingQuoteOnSameLine(script: script, fromIndex: script.index(after: i)) {
                    i = script.index(after: i)
                    while i < script.endIndex {
                        let innerCh = script[i]
                        current.append(innerCh)
                        if innerCh == "\"" { break }
                        i = script.index(after: i)
                    }
                    tokens.append(current)
                    current = ""
                } else {
                    i = script.index(after: i)
                    while i < script.endIndex && !script[i].isWhitespace && !delims.contains(script[i]) {
                        current.append(script[i])
                        i = script.index(after: i)
                    }
                    tokens.append(current)
                    current = ""
                    continue
                }
            } else if ch == ";" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                i = script.index(after: i)
                while i < script.endIndex && !script[i].isNewline {
                    i = script.index(after: i)
                }
                continue
            } else if delims.contains(ch) {
                if ch == "-" && current.isEmpty {
                    let nextIdx = script.index(after: i)
                    if nextIdx < script.endIndex && script[nextIdx].isNumber {
                        current.append(ch)
                        i = script.index(after: i)
                        continue
                    }
                }
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(String(ch))
            } else if ch == "=" || ch == "!" || ch == ">" || ch == "<" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                var op = String(ch)
                let nextIdx = script.index(after: i)
                if nextIdx < script.endIndex {
                    let nextCh = script[nextIdx]
                    if nextCh == "=" || nextCh == ">" {
                        op.append(nextCh)
                        i = nextIdx
                    }
                }
                tokens.append(op)
            } else if ch.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
            i = script.index(after: i)
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }

    private func hasClosingQuoteOnSameLine(script: String, fromIndex: String.Index) -> Bool {
        var idx = fromIndex
        guard idx > script.startIndex else { return false }
        var prev: Character = script[script.index(before: fromIndex)]
        while idx < script.endIndex {
            let c = script[idx]
            if c == "\"" {
                let nextIdx = script.index(after: idx)
                let nextChar: Character = nextIdx < script.endIndex ? script[nextIdx] : "\n"
                let isNextOpeningQuote = (prev.isWhitespace || prev == "[" || prev == "(") && (nextChar.isLetter || nextChar.isNumber || nextChar == ":" || nextChar == "\"")
                if !isNextOpeningQuote {
                    return true
                }
            }
            if c == "[" || c == "]" || c.isNewline { return false }
            prev = c
            idx = script.index(after: idx)
        }
        return false
    }

    internal func evaluateCondition(_ conditionTokens: [String]) -> Bool {
        guard !conditionTokens.isEmpty else { return false }

        var opIndex: Int? = nil
        var targetOp: LogoOperator? = nil

        for (idx, tok) in conditionTokens.enumerated() {
            if let op = LogoOperator.from(tok), op.isComparison {
                opIndex = idx
                targetOp = op
                break
            }
        }

        if let idx = opIndex, let op = targetOp {
            var leftIdx = 0
            let leftValStr = evaluateExpression(Array(conditionTokens[..<idx]), index: &leftIdx)

            var rightIdx = 0
            let rightValStr = evaluateExpression(Array(conditionTokens[(idx + 1)...]), index: &rightIdx)

            if let num1 = Double(leftValStr), let num2 = Double(rightValStr) {
                switch op {
                case .equal, .aliasEqual: return num1 == num2
                case .notEqual, .aliasNotEqual: return num1 != num2
                case .lessThan: return num1 < num2
                case .lessOrEqual: return num1 <= num2
                case .greaterThan: return num1 > num2
                case .greaterOrEqual: return num1 >= num2
                default: return false
                }
            } else {
                switch op {
                case .equal, .aliasEqual: return leftValStr == rightValStr
                case .notEqual, .aliasNotEqual: return leftValStr != rightValStr
                case .lessThan: return leftValStr < rightValStr
                case .lessOrEqual: return leftValStr <= rightValStr
                case .greaterThan: return leftValStr > rightValStr
                case .greaterOrEqual: return leftValStr >= rightValStr
                default: return false
                }
            }
        }

        let valStr = conditionTokens.joined(separator: " ")
        return logoIsTrue(valStr)
    }

    /// Evaluates token value or command (DATE, TIME) or binary arithmetic expression (+, -, *, /, %) with parentheses.
    internal func evaluateExpression(_ tokens: [String], index: inout Int) -> String {
        guard index < tokens.count else { return "" }
        guard lastError == "[]" else { return "" }

        var leftVal: String
        if tokens[index] == "(" {
            index += 1
            if index < tokens.count, let variadicPrim = LogoPrimitive.from(tokens[index]),
               variadicPrim == .sum || variadicPrim == .min || variadicPrim == .max {
                index += 1
                var values: [Double] = []
                while index < tokens.count && tokens[index] != ")" {
                    let value = evaluateExpression(tokens, index: &index)
                    values.append(contentsOf: numericValues(in: LogoValue.parse(value)))
                    if index + 1 < tokens.count && tokens[index + 1] != ")" {
                        index += 1
                    } else {
                        break
                    }
                }
                if index + 1 < tokens.count && tokens[index + 1] == ")" {
                    index += 1
                }
                switch variadicPrim {
                case .sum:
                    leftVal = formatNum(values.reduce(0, +))
                case .min:
                    leftVal = formatNum(values.min() ?? 0)
                case .max:
                    leftVal = formatNum(values.max() ?? 0)
                default:
                    leftVal = "0"
                }
            } else {
                leftVal = evaluateExpression(tokens, index: &index)
            }
            if index + 1 < tokens.count && tokens[index + 1] == ")" {
                index += 1
            }
        } else {
            leftVal = evaluateTokenOrCommand(tokens, index: &index)
        }

        // Peek next operator if present
        while index + 1 < tokens.count {
            guard lastError == "[]" else { return "" }
            let nextToken = tokens[index + 1]
            if nextToken == ")" || nextToken == "]" {
                break
            }
            if let op = LogoOperator.from(nextToken), op.isArithmetic {
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
                        if resDouble.truncatingRemainder(dividingBy: 1) == 0 && resDouble >= Double(Int.min) && resDouble <= Double(Int.max) {
                            leftVal = "\(Int(resDouble))"
                        } else {
                            leftVal = "\(resDouble)"
                        }
                    }
                } else if op == .add {
                    // String concatenation
                    leftVal = leftVal + rightVal
                } else {
                    break
                }
            } else {
                break
            }
        }

        return leftVal
    }

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
                    if ch == token.first! { depth += 1 }
                    else if ch == closingChar { depth -= 1 }
                }
                listTokens.append(t)
                if depth <= 0 { break }
                currIndex += 1
            }
            index = currIndex
            return listTokens.joined(separator: " ")
        }

        if let prim = LogoPrimitive.from(token) {
            switch prim {
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
                return formatDate(format: format)

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
                return formatTime(format: format)

            default:
                break
            }
        } else if let proc = customProcedures[upper] {
            return invokeProcedure(proc, tokens: tokens, index: &index) ?? ""
        } else {
            return resolveTokenValue(token)
        }

        if let proc = customProcedures[upper] {
            return invokeProcedure(proc, tokens: tokens, index: &index) ?? ""
        }

        return evaluateDataPrimitives(tokens, index: &index) ?? resolveTokenValue(token)
    }

    internal func resolveTokenValue(_ token: String) -> String {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        let lower = clean.lowercased()
        if clean.hasPrefix(":") {
            let varName = String(clean.dropFirst()).lowercased()
            return variables[varName] ?? ""
        }
        if clean.hasPrefix("?") || clean == "#" || variables[lower] != nil {
            if let val = variables[lower] {
                return val
            }
        }
        return unquote(clean)
    }

    internal func unquote(_ str: String) -> String {
        var result = str
        if result.hasPrefix("\"") {
            result.removeFirst()
        }
        if result.hasSuffix("\"") {
            result.removeLast()
        }
        return result
    }

    internal func formatDate(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = normalizeDateFormat(format)
        return formatter.string(from: Date())
    }

    internal func formatTime(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = normalizeTimeFormat(format)
        return formatter.string(from: Date())
    }

    private func normalizeDateFormat(_ format: String) -> String {
        var fmt = format
        fmt = fmt.replacingOccurrences(of: "YYYY", with: "yyyy")
        fmt = fmt.replacingOccurrences(of: "DD", with: "dd")
        return fmt
    }

    private func normalizeTimeFormat(_ format: String) -> String {
        var fmt = format
        fmt = fmt.replacingOccurrences(of: "hh", with: "HH")
        fmt = fmt.replacingOccurrences(of: "MM", with: "mm")
        fmt = fmt.replacingOccurrences(of: "SS", with: "ss")
        return fmt
    }
}
