import Foundation

extension LogoEngine {
    /// Evaluates condition expressions for IF, WHILE, UNTIL, etc.
    internal func evaluateCondition(_ conditionTokens: [String]) -> Bool {
        guard !conditionTokens.isEmpty else { return false }
        let savedLastResult = lastResult
        defer { lastResult = savedLastResult }

        var idx = 0
        let leftValStr = evaluateExpression(conditionTokens, index: &idx)
        let resBool = logoIsTrue(leftValStr)

        if idx >= conditionTokens.count - 1 {
            return resBool
        }

        if idx + 1 < conditionTokens.count {
            let opToken = conditionTokens[idx + 1]
            if let op = LogoOperator.from(opToken), op.isComparison {
                idx += 2
                let rightValStr = evaluateExpression(conditionTokens, index: &idx)

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
        guard lastError == "[]" else { return "" }

        var leftVal: String
        var isParenthesized = false
        if tokens[index] == "(" {
            isParenthesized = true
            index += 1
            if index < tokens.count, let variadicPrim = LogoPrimitive.from(tokens[index]),
                LogoEngine.isVariadicPrimitive(variadicPrim)
            {
                index += 1
                var args: [String] = []
                while index < tokens.count && tokens[index] != ")" && tokens[index] != "]" {
                    let arg = evaluateExpression(tokens, index: &index)
                    args.append(arg)
                    if index + 1 < tokens.count && tokens[index + 1] != ")" && tokens[index + 1] != "]" {
                        index += 1
                    } else {
                        break
                    }
                }
                if index + 1 < tokens.count && tokens[index + 1] == ")" {
                    index += 1
                }
                switch variadicPrim {
                case .word:
                    leftVal = args.joined()
                    setLastExpressionString(leftVal)

                case .list:
                    leftVal = "[" + args.joined(separator: " ") + "]"
                    setLastExpressionString(leftVal)

                case .sentence:
                    var items: [LogoValue] = []
                    for arg in args {
                        let parsed = LogoValue.parse(arg)
                        switch parsed {
                        case .list(let listItems), .array(let listItems): items.append(contentsOf: listItems)
                        case .string(let s): items.append(.string(s))
                        }
                    }
                    leftVal = LogoValue.list(items).description
                    setLastExpressionString(leftVal)

                case .sum:
                    let nums = args.flatMap { numericValues(in: LogoValue.parse($0)) }
                    leftVal = formatNum(nums.reduce(0, +))
                    setLastExpressionString(leftVal)

                case .product:
                    let nums = args.flatMap { numericValues(in: LogoValue.parse($0)) }
                    leftVal = formatNum(nums.reduce(1, *))
                    setLastExpressionString(leftVal)

                case .min:
                    let nums = args.flatMap { numericValues(in: LogoValue.parse($0)) }
                    leftVal = formatNum(nums.min() ?? 0)
                    setLastExpressionString(leftVal)

                case .max:
                    let nums = args.flatMap { numericValues(in: LogoValue.parse($0)) }
                    leftVal = formatNum(nums.max() ?? 0)
                    setLastExpressionString(leftVal)

                case .andLogic:
                    let allTrue = args.allSatisfy { logoIsTrue($0) }
                    leftVal = allTrue ? "1" : "0"
                    setLastExpressionString(leftVal)

                case .orLogic:
                    let anyTrue = args.contains { logoIsTrue($0) }
                    leftVal = anyTrue ? "1" : "0"
                    setLastExpressionString(leftVal)

                default:
                    leftVal = ""
                    setLastExpressionString(leftVal)
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
            guard lastError == "[]" else { return "" }
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
            lastExpressionValue = runtimeValueForVariable(varName, value: value)
            return value
        }
        if clean.hasPrefix("?") || clean == "#" || variables[lower] != nil {
            if let val = variables[lower] {
                lastExpressionValue = runtimeValueForVariable(lower, value: val)
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
            lastError = message
            delegate?.logoEngine(self, performAction: .setStatusMessage(message))
            hasSetStatusMessage = true
            return nil
        }

        var args: [String] = []
        for _ in 0..<proc.parameters.count {
            guard lastError == "[]" else { return nil }
            index += 1
            let arg = evaluateExpression(tokens, index: &index)
            args.append(arg)
        }

        var previousParamValues: [String: String?] = [:]
        for (i, param) in proc.parameters.enumerated() {
            previousParamValues[param] = variables[param]
            variables[param] = args[i]
        }
        procedureCallDepth += 1
        defer {
            procedureCallDepth -= 1
            for (param, prev) in previousParamValues {
                if let old = prev {
                    variables[param] = old
                } else {
                    variables.removeValue(forKey: param)
                }
            }
        }

        var procIndex = 0
        var procReturn: String? = nil
        executeTokens(proc.bodyTokens, index: &procIndex, frameReturn: &procReturn)
        if currentThrowTag != nil {
            return currentThrowValue ?? ""
        }
        if let ret = procReturn, !ret.isEmpty {
            lastResult = ret
        }
        return procReturn
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

    public func applyTemplate(templateStr: String, args: [String], indexInLoop: Int = 1, restList: [String] = [])
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
            let tTokens = tokenize(clean)
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
                    if !bodyTokens.isEmpty && bodyTokens[0] == "[" {
                        var bIdx = 0
                        let stmtBlock = extractBlockTokens(tokens: bodyTokens, index: &bIdx)
                        var subReturn: String? = nil
                        var sIdx = 0
                        executeTokens(stmtBlock, index: &sIdx, frameReturn: &subReturn)
                        return subReturn ?? lastResult ?? ""
                    } else {
                        var bIdx = 0
                        return evaluateExpression(bodyTokens, index: &bIdx)
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
                                $0 == "=" || $0 == "==" || $0 == "!=" || $0 == "<" || $0 == ">" || $0 == "<=" || $0 == ">=" || $0 == "EQUAL?" || $0 == "NOTEQUAL?"
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
