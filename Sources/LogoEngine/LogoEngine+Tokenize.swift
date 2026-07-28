import Foundation

extension LogoEngine {
    /// Tokenizes macro script handling string literals in quotes, comparison operators (==, !=, <=, >=), math operators (+, -, *, /, %), and brackets.
    public func tokenize(_ script: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuote = false

        let delims: Set<Character> = ["[", "]", "{", "}", "(", ")", "+", "-", "*", "/", "%"]

        var i = script.startIndex
        while i < script.endIndex {
            let ch = script[i]
            if ch == "\"" {
                inQuote.toggle()
                current.append(ch)
            } else if delims.contains(ch) && !inQuote {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(String(ch))
            } else if !inQuote && (ch == "=" || ch == "!" || ch == ">" || ch == "<") {
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
            } else if ch.isWhitespace && !inQuote {
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

    internal func evaluateCondition(_ conditionTokens: [String]) -> Bool {
        guard !conditionTokens.isEmpty else { return false }

        // Find comparison operator if present
        let opIndex = conditionTokens.firstIndex { $0 == "==" || $0 == "=" || $0 == "!=" || $0 == "<>" || $0 == "<" || $0 == "<=" || $0 == ">" || $0 == ">=" }

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
        } else {
            var exprIdx = 0
            let val = evaluateExpression(conditionTokens, index: &exprIdx).lowercased()
            if val == "true" || val == "1" {
                return true
            }
            return false
        }
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
            if nextOp == "+" || nextOp == "-" || nextOp == "*" || nextOp == "/" || nextOp == "%" {
                let op = nextOp
                index += 2
                guard index < tokens.count else { break }
                let rightVal = evaluateExpression(tokens, index: &index)

                if let num1 = Double(leftVal), let num2 = Double(rightVal) {
                    if let n1 = Int(leftVal), let n2 = Int(rightVal) {
                        let resNum: Int
                        switch op {
                        case "+": resNum = n1 + n2
                        case "-": resNum = n1 - n2
                        case "*": resNum = n1 * n2
                        case "/": resNum = (n2 != 0) ? n1 / n2 : 0
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
                        default: resDouble = 0.0
                        }
                        if resDouble.truncatingRemainder(dividingBy: 1) == 0 {
                            leftVal = "\(Int(resDouble))"
                        } else {
                            leftVal = "\(resDouble)"
                        }
                    }
                } else if op == "+" {
                    // String concatenation
                    leftVal = leftVal + rightVal
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

        if upper == "DATE" {
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
        }

        if upper == "TIME" {
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
        }

        if let proc = customProcedures[upper] {
            return invokeProcedure(proc, tokens: tokens, index: &index) ?? ""
        }

        return evaluateDataPrimitives(tokens, index: &index) ?? resolveTokenValue(token)
    }

    internal func resolveTokenValue(_ token: String) -> String {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        if clean.hasPrefix(":") {
            let varName = String(clean.dropFirst()).lowercased()
            return variables[varName] ?? ""
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
