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
                }
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
        let compOps: Set<String> = ["==", "=", "!=", "<>", "<", "<=", ">", ">="]

        for (idx, tok) in conditionTokens.enumerated() {
            if compOps.contains(tok) {
                opIndex = idx
                break
            }
        }

        if let idx = opIndex {
            var leftIdx = 0
            let leftValStr = evaluateExpression(Array(conditionTokens[..<idx]), index: &leftIdx)

            var rightIdx = 0
            let rightValStr = evaluateExpression(Array(conditionTokens[(idx + 1)...]), index: &rightIdx)

            let op = conditionTokens[idx]

            if let num1 = Double(leftValStr), let num2 = Double(rightValStr) {
                switch op {
                case "==", "=": return num1 == num2
                case "!=", "<>": return num1 != num2
                case "<": return num1 < num2
                case "<=": return num1 <= num2
                case ">": return num1 > num2
                case ">=": return num1 >= num2
                default: return false
                }
            } else {
                switch op {
                case "==", "=": return leftValStr == rightValStr
                case "!=", "<>": return leftValStr != rightValStr
                case "<": return leftValStr < rightValStr
                case "<=": return leftValStr <= rightValStr
                case ">": return leftValStr > rightValStr
                case ">=": return leftValStr >= rightValStr
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

        var leftVal: String
        if tokens[index] == "(" {
            index += 1
            leftVal = evaluateExpression(tokens, index: &index)
            if index + 1 < tokens.count && tokens[index + 1] == ")" {
                index += 1
            }
        } else {
            leftVal = evaluateTokenOrCommand(tokens, index: &index)
        }

        // Peek next operator if present
        while index + 1 < tokens.count {
            let nextOp = tokens[index + 1]
            if nextOp == ")" || nextOp == "]" {
                break
            }
            if nextOp == "+" || nextOp == "-" || nextOp == "*" || nextOp == "/" || nextOp == "%" || nextOp == "^" {
                let op = nextOp
                index += 2
                guard index < tokens.count else { break }
                let rightVal = evaluateExpression(tokens, index: &index)

                if let num1 = Double(leftVal), let num2 = Double(rightVal) {
                    if let n1 = Int(leftVal), let n2 = Int(rightVal), op != "^" && op != "/" {
                        let resNum: Int
                        switch op {
                        case "+": resNum = n1 + n2
                        case "-": resNum = n1 - n2
                        case "*": resNum = n1 * n2
                        case "%": resNum = (n2 != 0) ? n1 % n2 : 0
                        default: resNum = 0
                        }
                        leftVal = "\(resNum)"
                    } else {
                        let resDouble: Double
                        switch op {
                        case "+": resDouble = num1 + num2
                        case "-": resDouble = num1 - num2
                        case "*": resDouble = num1 * num2
                        case "/": resDouble = (num2 != 0) ? num1 / num2 : 0.0
                        case "%": resDouble = (num2 != 0) ? num1.truncatingRemainder(dividingBy: num2) : 0.0
                        case "^": resDouble = pow(num1, num2)
                        default: resDouble = 0.0
                        }
                        if resDouble.truncatingRemainder(dividingBy: 1) == 0 && resDouble >= Double(Int.min) && resDouble <= Double(Int.max) {
                            leftVal = "\(Int(resDouble))"
                        } else {
                            leftVal = "\(resDouble)"
                        }
                    }
                } else if op == "+" {
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
                    let nextUpper = nextToken.uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) && nextToken != "]" && nextToken != ")" {
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
                    let nextUpper = nextToken.uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) && nextToken != "]" && nextToken != ")" {
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
