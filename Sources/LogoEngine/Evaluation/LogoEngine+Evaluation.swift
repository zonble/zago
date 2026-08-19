import Foundation

extension LogoEngine {
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
            leftVal = evaluateParenthesizedExpression(tokens: tokens, index: &index)
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
}
