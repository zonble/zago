import Foundation

extension LogoEngine {
    /// Executes Logo control flow statement commands (.output, .if, .repeat, .for, .while, .catch, .to, etc.).
    /// Returns `true` if the primitive was handled by this module, `false` otherwise.
    internal func executeControlCommand(
        _ prim: LogoPrimitive,
        tokens: [String],
        index: inout Int,
        frameReturn: inout String?
    ) -> Bool {
        switch prim {
        case .output:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if reader.peekToken() != nil {
                frameReturn = reader.nextExpression()
                reader.commit(to: &index)
            }
            return true

        case .ifCondition:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            let condTokens = reader.nextBlock() ?? reader.tokensUntil { $0 == "[" }

            let isTrue = evaluateCondition(condTokens)

            if let trueBlock = reader.nextBlock() {
                if isTrue {
                    var bIdx = 0
                    executeTokens(trueBlock, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            reader.commit(to: &index)
            return true

        case .ifElseCondition:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            let condTokens = reader.nextBlock() ?? reader.tokensUntil { $0 == "[" }

            let isTrue = evaluateCondition(condTokens)

            if let trueBlock = reader.nextBlock() {
                let falseBlock = reader.nextBlock() ?? []
                var bIdx = 0
                if isTrue {
                    executeTokens(trueBlock, index: &bIdx, frameReturn: &frameReturn)
                } else if !falseBlock.isEmpty {
                    executeTokens(falseBlock, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            reader.commit(to: &index)
            return true

        case .run:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if reader.peekToken() != nil {
                if let block = reader.nextBlock() {
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                } else {
                    let scriptStr = reader.nextExpression() ?? ""
                    let block = LogoTokenizer.tokenize(scriptStr)
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            reader.commit(to: &index)
            return true

        case .runResult:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if reader.peekToken() != nil {
                var block: [String] = []
                if let rawBlock = reader.nextBlock() {
                    block = rawBlock
                } else {
                    let scriptStr = reader.nextExpression() ?? ""
                    block = LogoTokenizer.tokenize(scriptStr)
                }
                reader.commit(to: &index)
                var bIdx = 0
                var subReturn: String? = nil
                executeTokens(block, index: &bIdx, frameReturn: &subReturn)
                if let r = subReturn, !r.isEmpty {
                    lastResult = "[\(r)]"
                } else {
                    lastResult = "[]"
                }
            }
            return true

        case .repeatLoop:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            let countStr = reader.nextExpression() ?? ""
            let count = Int(countStr) ?? 1
            if let block = reader.nextBlock() {
                reader.commit(to: &index)
                guard count > 0 else { return true }
                for r in 1...count {
                    guard guardLoopIteration("REPEAT", iteration: r) else { break }
                    repCount = r
                    variables["#"] = "\(r)"
                    variables["repcount"] = "\(r)"
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    if frameReturn != nil || byeFlag || currentThrowTag != nil || hasUncaughtError { break }
                }
            }
            reader.commit(to: &index)
            return true

        case .stop:
            frameReturn = ""
            return true

        case .bye:
            byeFlag = true
            return true

        case .wait:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if reader.peekToken() != nil {
                let timeStr = reader.nextExpression()
                reader.commit(to: &index)
                if let val = Double(timeStr), val > 0 {
                    delegate?.logoEngine(self, performAction: .refreshScreen)
                    let isTesting =
                        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
                        || ProcessInfo.processInfo.processName.contains("XCTest")
                        || ProcessInfo.processInfo.processName.contains("swiftpm-testing-helper")
                    let delay = isTesting ? min(val / 60000.0, 0.001) : val / 60.0
                    Thread.sleep(forTimeInterval: delay)
                }
            }
            return true

        case .testCondition:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            let condTokens = reader.tokensUntil { token in
                let upper = token.uppercased()
                return upper == "IFTRUE" || upper == "IFT" || upper == "IFFALSE" || upper == "IFF"
                    || token == "[" || token == "]"
            }
            testResult = evaluateCondition(condTokens)
            reader.commit(to: &index)
            return true

        case .assertCondition:
            executeAssertCommand(tokens, index: &index)
            return true

        case .ifTrue:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let block = reader.nextBlock() {
                if testResult == true {
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            reader.commit(to: &index)
            return true

        case .ifFalse:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let block = reader.nextBlock() {
                if testResult == false {
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            reader.commit(to: &index)
            return true

        case .ignore:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if reader.peekToken() != nil {
                _ = reader.nextExpression()
                reader.commit(to: &index)
            }
            return true

        case .catchTag:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let rawTag = reader.nextExpression(), let block = reader.nextBlock() {
                let tag = unquote(rawTag).lowercased()
                var bIdx = 0
                executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                if let throwTag = currentThrowTag, throwTag == tag || tag == "error" {
                    let thrownVal = currentThrowValue ?? ""
                    currentThrowTag = nil
                    currentThrowValue = nil
                    lastError = LogoError(code: 1, message: thrownVal.isEmpty ? "Error" : thrownVal)
                    hasUncaughtError = false
                    if !thrownVal.isEmpty {
                        lastResult = thrownVal
                    }
                }
            }
            reader.commit(to: &index)
            return true

        case .throwTag:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let rawTag = reader.nextExpression() {
                let tag = unquote(rawTag).lowercased()
                let thrownVal = reader.nextOptionalExpression(isBoundary: { $0 == "]" }) ?? ""
                currentThrowTag = tag
                currentThrowValue = thrownVal
            }
            reader.commit(to: &index)
            return true

        case .forLoop:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let ctrlBlock = reader.nextBlock(), let bodyBlock = reader.nextBlock() {
                reader.commit(to: &index)
                if !ctrlBlock.isEmpty {
                    let varName = ctrlBlock[0].lowercased()
                    var cIdx = 1
                    let startVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? 1
                    cIdx += 1
                    let limitVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? startVal
                    cIdx += 1
                    var stepVal = 1
                    if cIdx < ctrlBlock.count {
                        stepVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? 1
                    }
                    var cur = startVal
                    var iteration = 0
                    while (stepVal > 0 ? cur <= limitVal : cur >= limitVal) && !byeFlag && frameReturn == nil
                        && currentThrowTag == nil && !hasUncaughtError
                    {
                        iteration += 1
                        guard guardLoopIteration("FOR", iteration: iteration) else { break }
                        variables[varName] = "\(cur)"
                        var bIdx = 0
                        executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                        cur += stepVal
                    }
                }
            }
            reader.commit(to: &index)
            return true

        case .dotimesLoop:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let ctrlBlock = reader.nextBlock(), let bodyBlock = reader.nextBlock() {
                reader.commit(to: &index)
                if ctrlBlock.count >= 2 {
                    let varName = ctrlBlock[0].lowercased()
                    var cIdx = 1
                    let countVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? 0
                    for i in 0..<countVal {
                        guard guardLoopIteration("DOTIMES", iteration: i + 1) else { break }
                        variables[varName] = "\(i)"
                        var bIdx = 0
                        executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                        if byeFlag || frameReturn != nil || currentThrowTag != nil || hasUncaughtError { break }
                    }
                }
            }
            reader.commit(to: &index)
            return true

        case .whileLoop:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            let condTokens = reader.nextBlock() ?? reader.tokensUntil { $0 == "[" }
            if let bodyBlock = reader.nextBlock() {
                reader.commit(to: &index)
                var iteration = 0
                while evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
                    && !hasUncaughtError
                {
                    iteration += 1
                    guard guardLoopIteration("WHILE", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            reader.commit(to: &index)
            return true

        case .untilLoop:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            let condTokens = reader.nextBlock() ?? reader.tokensUntil { $0 == "[" }
            if let bodyBlock = reader.nextBlock() {
                reader.commit(to: &index)
                var iteration = 0
                while !evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
                    && !hasUncaughtError
                {
                    iteration += 1
                    guard guardLoopIteration("UNTIL", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            reader.commit(to: &index)
            return true

        case .doWhileLoop:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let bodyBlock = reader.nextBlock() {
                let condTokens = reader.nextBlock() ?? reader.tokensUntil { $0 == "]" }
                reader.commit(to: &index)
                var iteration = 0
                repeat {
                    iteration += 1
                    guard guardLoopIteration("DO.WHILE", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                } while evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
                    && !hasUncaughtError
            }
            reader.commit(to: &index)
            return true

        case .doUntilLoop:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let bodyBlock = reader.nextBlock() {
                let condTokens = reader.nextBlock() ?? reader.tokensUntil { $0 == "]" }
                reader.commit(to: &index)
                var iteration = 0
                repeat {
                    iteration += 1
                    guard guardLoopIteration("DO.UNTIL", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                } while !evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
                    && !hasUncaughtError
            }
            reader.commit(to: &index)
            return true

        case .caseSwitch:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            guard let rawTarget = reader.nextExpression(), let clausesBlock = reader.nextBlock() else {
                reader.commit(to: &index)
                return true
            }
            let targetVal = unquote(rawTarget)
            reader.commit(to: &index)
            let result = evaluateCaseClauses(targetVal: targetVal, clausesBlock: clausesBlock)
            if let res = result {
                lastResult = res
            }
            return true

        case .condSwitch:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            if let clausesBlock = reader.nextBlock() {
                let result = evaluateCondClauses(clausesBlock: clausesBlock)
                if let res = result { lastResult = res }
            }
            reader.commit(to: &index)
            return true

        case .to:
            var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
            guard let rawName = reader.nextRawToken() else {
                let errorMessage = "[LOGO Error: TO requires a procedure name]"
                reportError(LogoError(code: 1, message: errorMessage), token: "TO")
                reader.commit(to: &index)
                return true
            }

            let procName = rawName.uppercased()
            if !isValidProcedureName(rawName) {
                let errorMessage = "[LOGO Error: invalid procedure name: \(rawName)]"
                reportError(LogoError(code: 1, message: errorMessage), token: rawName)
                while let token = reader.peekToken(), token.uppercased() != "END" {
                    _ = reader.nextRawToken()
                }
                reader.commit(to: &index)
                return true
            }

            if isReservedProcedureName(procName) {
                let errorMessage = "[LOGO Error: \(procName) is a reserved word/operator and cannot be redefined]"
                reportError(LogoError(code: 1, message: errorMessage), token: procName)
                while let token = reader.peekToken(), token.uppercased() != "END" {
                    _ = reader.nextRawToken()
                }
                reader.commit(to: &index)
                return true
            }

            var params: [String] = []
            while let token = reader.peekToken(), token.hasPrefix(":") {
                let paramName = String(token.dropFirst()).lowercased()
                if params.contains(paramName) {
                    break
                }
                params.append(paramName)
                _ = reader.nextRawToken()
            }
            var docstring: String? = nil
            if let token = reader.peekToken(), token.hasPrefix("\"") || token.hasPrefix("'"),
                reader.peekToken(offset: 2)?.uppercased() != "END"
            {
                docstring = unquote(token)
                _ = reader.nextRawToken()
            }
            var procSourceTokens: [LogoToken] = []
            let hasRootSourceTokens = tokens.count == rootSourceTokens.count
            while let token = reader.peekToken(), token.uppercased() != "END" {
                _ = reader.nextRawToken()
                if hasRootSourceTokens {
                    procSourceTokens.append(rootSourceTokens[reader.position])
                } else {
                    procSourceTokens.append(LogoToken(text: token, sourceRange: 0..<0))
                }
            }
            customProcedures[procName] = LogoProcedure(
                name: procName,
                parameters: params,
                docstring: docstring,
                bodyTokens: procSourceTokens
            )
            reader.commit(to: &index)
            return true

        case .exec:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if let rawName = reader.nextRawToken() {
                let procName = rawName.uppercased()
                reader.commit(to: &index)
                if let proc = customProcedures[procName] {
                    let ret = invokeProcedure(proc, tokens: tokens, index: &index)
                    if let r = ret, !r.isEmpty { lastResult = r }
                }
            }
            return true

        case .end:
            return true

        default:
            return false
        }
    }

    private func executeAssertCommand(_ tokens: [String], index: inout Int) {
        guard index + 1 < tokens.count else {
            reportError(LogoError(code: 1, message: "[LOGO Error: Not enough inputs to ASSERT]"), token: "ASSERT")
            return
        }
        var reader = LogoControlTokenReader(engine: self, tokens: tokens, index: index)
        let condTokens =
            reader.nextBlock()
            ?? reader.tokensUntil { token in
                token == "[" || isQuotedWordToken(token) || token == "]" || token == ")"
                    || LogoEngine.isStatementCommand(token)
            }

        let isTrue = evaluateCondition(condTokens)
        var customMsg: String? = nil

        if let msgBlock = reader.nextBlock() {
            customMsg = msgBlock.map { unquote($0) }.joined(separator: " ")
        } else if let token = reader.peekToken(), isQuotedWordToken(token) || token.hasPrefix(":") {
            let msgTokens = reader.tokensUntil {
                LogoEngine.isStatementCommand($0) || $0 == "]" || $0 == ")"
            }
            customMsg = msgTokens.map { unquote($0) }.joined(separator: " ")
        }
        reader.commit(to: &index)

        if !isTrue {
            let msg = customMsg ?? "Assertion failed: (\(condTokens.joined(separator: " ")))"
            reportError(LogoError(code: 1, message: "[LOGO Assertion Failed: \(msg)]"), token: "ASSERT")
        }
    }
}
