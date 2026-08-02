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
            index += 1
            if index < tokens.count {
                let val = evaluateExpression(tokens, index: &index)
                frameReturn = val
            }
            return true

        case .ifCondition:
            index += 1
            var condTokens: [String] = []
            while index < tokens.count && tokens[index] != "[" {
                condTokens.append(tokens[index])
                index += 1
            }

            let isTrue = evaluateCondition(condTokens)

            if index < tokens.count && tokens[index] == "[" {
                index += 1
                if isTrue {
                    executeTokens(tokens, index: &index, frameReturn: &frameReturn)
                } else {
                    var depth = 1
                    while index < tokens.count && depth > 0 {
                        if tokens[index] == "[" { depth += 1 }
                        else if tokens[index] == "]" { depth -= 1 }
                        if depth == 0 { break }
                        index += 1
                    }
                }
            }
            return true

        case .ifElseCondition:
            index += 1
            var condTokens: [String] = []
            while index < tokens.count && tokens[index] != "[" {
                condTokens.append(tokens[index])
                index += 1
            }

            let isTrue = evaluateCondition(condTokens)

            if index < tokens.count && tokens[index] == "[" {
                if isTrue {
                    index += 1 // Advance past first "["
                    executeTokens(tokens, index: &index, frameReturn: &frameReturn)
                    if frameReturn != nil { return true }
                    index += 1 // Advance past first "]"
                    if index < tokens.count && tokens[index] == "[" {
                        var depth = 1
                        index += 1
                        while index < tokens.count && depth > 0 {
                            if tokens[index] == "[" { depth += 1 }
                            else if tokens[index] == "]" { depth -= 1 }
                            if depth == 0 { break }
                            index += 1
                        }
                    }
                } else {
                    var depth = 1
                    index += 1 // Advance past first "["
                    while index < tokens.count && depth > 0 {
                        if tokens[index] == "[" { depth += 1 }
                        else if tokens[index] == "]" { depth -= 1 }
                        if depth == 0 { break }
                        index += 1
                    }
                    index += 1 // Advance past first "]"
                    if index < tokens.count && tokens[index] == "[" {
                        index += 1 // Advance past second "["
                        executeTokens(tokens, index: &index, frameReturn: &frameReturn)
                    }
                }
            }
            return true

        case .run:
            index += 1
            if index < tokens.count {
                if tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                } else {
                    let scriptStr = evaluateExpression(tokens, index: &index)
                    let block = tokenize(scriptStr)
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            return true

        case .runResult:
            index += 1
            if index < tokens.count {
                var block: [String] = []
                if tokens[index] == "[" {
                    block = extractBlockTokens(tokens: tokens, index: &index)
                } else {
                    let scriptStr = evaluateExpression(tokens, index: &index)
                    block = tokenize(scriptStr)
                }
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
            index += 1
            let countStr = evaluateExpression(tokens, index: &index)
            let count = Int(countStr) ?? 1
            index += 1 // Advance to "["
            if index < tokens.count && tokens[index] == "[" {
                let block = extractBlockTokens(tokens: tokens, index: &index)
                guard count > 0 else { return true }
                for r in 1...count {
                    guard guardLoopIteration("REPEAT", iteration: r) else { break }
                    repCount = r
                    variables["#"] = "\(r)"
                    variables["repcount"] = "\(r)"
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    if frameReturn != nil || byeFlag || currentThrowTag != nil { break }
                }
            }
            return true

        case .stop:
            frameReturn = ""
            return true

        case .bye:
            byeFlag = true
            return true

        case .wait:
            index += 1
            if index < tokens.count {
                let timeStr = evaluateExpression(tokens, index: &index)
                if let val = Double(timeStr), val > 0 {
                    delegate?.logoEngine(self, performAction: .refreshScreen)
                    let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || ProcessInfo.processInfo.processName.contains("XCTest") || ProcessInfo.processInfo.processName.contains("swiftpm-testing-helper")
                    let delay = isTesting ? min(val / 60000.0, 0.001) : val / 60.0
                    Thread.sleep(forTimeInterval: delay)
                }
            }
            return true

        case .testCondition:
            index += 1
            var condTokens: [String] = []
            while index < tokens.count {
                let upperNext = tokens[index].uppercased()
                if upperNext == "IFTRUE" || upperNext == "IFT" || upperNext == "IFFALSE" || upperNext == "IFF" || upperNext == "[" || upperNext == "]" {
                    break
                }
                condTokens.append(tokens[index])
                index += 1
            }
            testResult = evaluateCondition(condTokens)
            index -= 1
            return true

        case .ifTrue:
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let block = extractBlockTokens(tokens: tokens, index: &index)
                if testResult == true {
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            return true

        case .ifFalse:
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let block = extractBlockTokens(tokens: tokens, index: &index)
                if testResult == false {
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            return true

        case .ignore:
            index += 1
            if index < tokens.count {
                _ = evaluateExpression(tokens, index: &index)
            }
            return true

        case .catchTag:
            index += 1
            if index < tokens.count {
                let tag = unquote(evaluateExpression(tokens, index: &index)).lowercased()
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    var bIdx = 0
                    executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    if let throwTag = currentThrowTag, throwTag == tag || tag == "error" {
                        let thrownVal = currentThrowValue ?? ""
                        currentThrowTag = nil
                        currentThrowValue = nil
                        if !thrownVal.isEmpty {
                            lastResult = thrownVal
                        }
                    }
                }
            }
            return true

        case .throwTag:
            index += 1
            if index < tokens.count {
                let tag = unquote(evaluateExpression(tokens, index: &index)).lowercased()
                var thrownVal = ""
                if index + 1 < tokens.count && !tokens[index + 1].hasPrefix("]") {
                    index += 1
                    thrownVal = evaluateExpression(tokens, index: &index)
                }
                currentThrowTag = tag
                currentThrowValue = thrownVal
            }
            return true

        case .forLoop:
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let ctrlBlock = extractBlockTokens(tokens: tokens, index: &index)
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
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
                        while (stepVal > 0 ? cur <= limitVal : cur >= limitVal) && !byeFlag && frameReturn == nil && currentThrowTag == nil {
                            iteration += 1
                            guard guardLoopIteration("FOR", iteration: iteration) else { break }
                            variables[varName] = "\(cur)"
                            var bIdx = 0
                            executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                            cur += stepVal
                        }
                    }
                }
            }
            return true

        case .dotimesLoop:
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let ctrlBlock = extractBlockTokens(tokens: tokens, index: &index)
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                    if ctrlBlock.count >= 2 {
                        let varName = ctrlBlock[0].lowercased()
                        var cIdx = 1
                        let countVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? 0
                        for i in 0..<countVal {
                            guard guardLoopIteration("DOTIMES", iteration: i + 1) else { break }
                            variables[varName] = "\(i)"
                            var bIdx = 0
                            executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                            if byeFlag || frameReturn != nil || currentThrowTag != nil { break }
                        }
                    }
                }
            }
            return true

        case .whileLoop:
            index += 1
            if let (condTokens, bodyBlock) = extractLoopConditionAndBody(tokens: tokens, index: &index) {
                var iteration = 0
                while evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil {
                    iteration += 1
                    guard guardLoopIteration("WHILE", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            return true

        case .untilLoop:
            index += 1
            if let (condTokens, bodyBlock) = extractLoopConditionAndBody(tokens: tokens, index: &index) {
                var iteration = 0
                while !evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil {
                    iteration += 1
                    guard guardLoopIteration("UNTIL", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                }
            }
            return true

        case .doWhileLoop:
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                index += 1
                var condTokens: [String] = []
                while index < tokens.count && tokens[index] != "]" {
                    condTokens.append(tokens[index])
                    index += 1
                }
                var iteration = 0
                repeat {
                    iteration += 1
                    guard guardLoopIteration("DO.WHILE", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                } while evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
            }
            return true

        case .doUntilLoop:
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                index += 1
                var condTokens: [String] = []
                while index < tokens.count && tokens[index] != "]" {
                    condTokens.append(tokens[index])
                    index += 1
                }
                var iteration = 0
                repeat {
                    iteration += 1
                    guard guardLoopIteration("DO.UNTIL", iteration: iteration) else { break }
                    var bIdx = 0
                    executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                } while !evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
            }
            return true

        case .caseSwitch:
            index += 1
            let targetVal = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let clausesBlock = extractBlockTokens(tokens: tokens, index: &index)
                let result = evaluateCaseClauses(targetVal: targetVal, clausesBlock: clausesBlock)
                if let res = result {
                    lastResult = res
                }
            }
            return true

        case .condSwitch:
            index += 1
            if index < tokens.count && tokens[index] == "[" {
                let clausesBlock = extractBlockTokens(tokens: tokens, index: &index)
                let result = evaluateCondClauses(clausesBlock: clausesBlock)
                if let res = result {
                    lastResult = res
                }
            }
            return true

        case .to:
            index += 1
            if index < tokens.count {
                let procName = tokens[index].uppercased()
                index += 1
                var params: [String] = []
                while index < tokens.count && tokens[index].hasPrefix(":") {
                    let paramName = String(tokens[index].dropFirst()).lowercased()
                    params.append(paramName)
                    index += 1
                }
                var procTokens: [String] = []
                while index < tokens.count && tokens[index].uppercased() != "END" {
                    procTokens.append(tokens[index])
                    index += 1
                }
                customProcedures[procName] = LogoProcedure(name: procName, parameters: params, bodyTokens: procTokens)
            }
            return true

        case .exec:
            index += 1
            if index < tokens.count {
                let procName = tokens[index].uppercased()
                if let proc = customProcedures[procName] {
                    let ret = invokeProcedure(proc, tokens: tokens, index: &index)
                    if let r = ret, !r.isEmpty {
                        lastResult = r
                    }
                }
            }
            return true

        case .end:
            return true

        default:
            return false
        }
    }

    private func extractLoopConditionAndBody(tokens: [String], index: inout Int) -> (condition: [String], body: [String])? {
        guard index < tokens.count else { return nil }

        if tokens[index] == "[" {
            let condition = extractBlockTokens(tokens: tokens, index: &index)
            index += 1
            guard index < tokens.count, tokens[index] == "[" else { return nil }
            let body = extractBlockTokens(tokens: tokens, index: &index)
            return (condition, body)
        }

        var condition: [String] = []
        while index < tokens.count && tokens[index] != "[" {
            condition.append(tokens[index])
            index += 1
        }
        guard index < tokens.count, tokens[index] == "[" else { return nil }
        let body = extractBlockTokens(tokens: tokens, index: &index)
        return (condition, body)
    }
}
