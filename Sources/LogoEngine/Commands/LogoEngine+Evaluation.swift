import Foundation

extension LogoEngine {
    /// Evaluates condition expressions for IF, WHILE, UNTIL, etc.
    internal func evaluateCondition(_ conditionTokens: [String]) -> Bool {
        var tokensToEval = conditionTokens
        if tokensToEval.first == "[" && tokensToEval.last == "]" && tokensToEval.count >= 2 {
            tokensToEval.removeFirst()
            tokensToEval.removeLast()
        }
        guard !tokensToEval.isEmpty else { return false }
        let savedLastResult = lastResult
        defer { lastResult = savedLastResult }

        var idx = 0
        let leftValStr = evaluateExpression(tokensToEval, index: &idx)
        let resBool = logoIsTrue(leftValStr)

        if idx >= tokensToEval.count - 1 {
            return resBool
        }

        if idx + 1 < tokensToEval.count {
            let opToken = tokensToEval[idx + 1]
            if let op = LogoOperator.from(opToken), op.isComparison {
                idx += 2
                let rightValStr = evaluateExpression(tokensToEval, index: &idx)

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
        guard !hasUncaughtError else { return "" }

        var leftVal: String
        var isParenthesized = false
        if tokens[index] == "(" {
            isParenthesized = true
            index += 1
            if index < tokens.count, LogoPrimitive.from(tokens[index]) == .ifElseCondition {
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
                if index + 1 < tokens.count && tokens[index + 1] == "[" {
                    index += 1
                    falseBlock = extractBlockTokens(tokens: tokens, index: &index)
                }

                let selectedBlock = isTrue ? trueBlock : falseBlock
                var blockIndex = 0
                leftVal = selectedBlock.isEmpty ? "" : evaluateExpression(selectedBlock, index: &blockIndex)
                setLastExpressionString(leftVal)
            } else if index < tokens.count, let variadicPrim = LogoPrimitive.from(tokens[index]),
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
                    let parsedCal = LogoDateTimeFormatter.parseCalendar(cal)
                    let parsedTz = LogoDateTimeFormatter.parseTimeZone(tz)
                    let parsedDate =
                        LogoDateTimeFormatter.parseDate(dateVal, defaultCalendar: parsedCal, defaultTimeZone: parsedTz)
                        ?? Date()
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
                    let style = cleanArgs.count > 1 ? LogoFormatters.NumberStyle.parse(cleanArgs[1]) : .decimal
                    let locale = cleanArgs.count > 2 ? cleanArgs[2] : nil
                    let curr = cleanArgs.count > 3 ? cleanArgs[3] : nil
                    leftVal = LogoFormatters.formatNumber(num, style: style, locale: locale, currencyCode: curr)
                    setLastExpressionString(leftVal)

                    case .formatList:
                    let cleanArgs = args.map { unquote($0) }
                    guard !cleanArgs.isEmpty else {
                        leftVal = ""
                        break
                    }
                    let parsed = LogoValue.parse(cleanArgs[0])
                    let items: [String]
                    switch parsed {
                    case .list(let l), .array(let l): items = l.map { $0.stringValue }
                    case .string(let s): items = s.contains(" ") ? s.split(separator: " ").map { String($0) } : [s]
                    }
                    let type = cleanArgs.count > 1 ? LogoFormatters.ListType.parse(cleanArgs[1]) : .and
                    let locale = cleanArgs.count > 2 ? cleanArgs[2] : nil
                    leftVal = LogoFormatters.formatList(items, type: type, locale: locale)
                    setLastExpressionString(leftVal)

                    case .formatRelativeTime:
#if os(Linux) || os(Windows)
                    leftVal = ""
                    reportError(
                        LogoError(code: 1, message: "[LOGO Error: FORMAT.RELATIVETIME is not supported on this platform]"),
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
                        let unit = cleanArgs.count > 1 ? cleanArgs[1] : "days"
                        let locale = cleanArgs.count > 2 ? cleanArgs[2] : nil
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
                    guard !cleanArgs.isEmpty else {
                        leftVal = "0 bytes"
                        break
                    }
                    let bytes = Int64(Double(cleanArgs[0]) ?? 0)
                    let style = cleanArgs.count > 1 ? LogoFormatters.ByteCountStyle.parse(cleanArgs[1]) : .file
                    let locale = cleanArgs.count > 2 ? cleanArgs[2] : nil
                    leftVal = LogoFormatters.formatBytes(bytes, style: style, locale: locale)
                    setLastExpressionString(leftVal)

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

    internal func invokeProcedure(_ proc: LogoProcedure, tokens: [String], index: inout Int) -> String? {
        guard procedureCallDepth < maxProcedureCallDepth else {
            let message = "[Procedure recursion limit exceeded: \(proc.name)]"
            lastError = LogoError(code: 1, message: message, procedureName: proc.name)
            delegate?.logoEngine(self, performAction: .setStatusMessage(message))
            hasSetStatusMessage = true
            return nil
        }

        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        var args: [String] = []
        for _ in proc.parameters {
            guard !hasUncaughtError else { return nil }
            args.append(reader.nextExpression())
        }
        reader.commit(to: &index)

        let initialScope = Dictionary(zip(proc.parameters, args), uniquingKeysWith: { _, last in last })
        variables.pushScope(initialValues: initialScope)
        procedureCallDepth += 1
        executionFrames.append(
            LogoExecutionFrame(procedureName: proc.name, token: nil, scopeDepth: variables.scopeDepth))
        defer {
            procedureCallDepth -= 1
            variables.popScope()
            executionFrames.removeLast()
        }

        var procIndex = 0
        var procReturn: String? = nil
        let savedLastResult = lastResult
        lastResult = nil
        executeTokens(
            proc.bodyTokens.map(\.text), sourceTokens: proc.bodyTokens, index: &procIndex, frameReturn: &procReturn)
        if currentThrowTag != nil {
            return currentThrowValue ?? ""
        }
        let finalResult = procReturn ?? (proc.isSingleExpression ? lastResult : nil)
        lastResult = savedLastResult
        return finalResult
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

    internal func applyTemplate(templateStr: String, args: [String], indexInLoop: Int = 1, restList: [String] = [])
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
            let tTokens = LogoTokenizer.tokenize(clean)
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
                    if !bodyTokens.isEmpty {
                        if bodyTokens[0] == "[" {
                            var bIdx = 0
                            let stmtBlock = extractBlockTokens(tokens: bodyTokens, index: &bIdx)
                            var subReturn: String? = nil
                            var sIdx = 0
                            executeTokens(stmtBlock, index: &sIdx, frameReturn: &subReturn)
                            return subReturn ?? lastResult ?? ""
                        } else if LogoEngine.isStatementCommand(bodyTokens[0]) {
                            var subReturn: String? = nil
                            var sIdx = 0
                            executeTokens(bodyTokens, index: &sIdx, frameReturn: &subReturn)
                            return subReturn ?? lastResult ?? ""
                        } else {
                            var bIdx = 0
                            return evaluateExpression(bodyTokens, index: &bIdx)
                        }
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
                                $0 == "=" || $0 == "==" || $0 == "!=" || $0 == "<" || $0 == ">" || $0 == "<="
                                    || $0 == ">=" || $0 == "EQUAL?" || $0 == "NOTEQUAL?"
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
