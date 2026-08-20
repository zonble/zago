import Foundation

extension LogoEngine {
    internal func invokeProcedure(_ proc: LogoProcedure, tokens: [String], index: inout Int) -> String? {
        guard procedureCallDepth < maxProcedureCallDepth else {
            let message = "[Procedure recursion limit exceeded: \(proc.name)]"
            reportError(LogoError(code: 1, message: message, procedureName: proc.name), token: proc.name)
            return nil
        }
        procedureCallDepth += 1
        defer {
            procedureCallDepth -= 1
        }

        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        var args: [String] = []
        for _ in proc.parameters {
            guard !hasUncaughtError else { return nil }
            guard reader.hasArgumentToken else {
                let message = "[LOGO Error: Not enough inputs to \(proc.name)]"
                reportError(LogoError(code: 1, message: message), token: proc.name)
                return nil
            }
            args.append(reader.nextExpression())
        }
        reader.commit(to: &index)

        guard !hasUncaughtError else { return nil }

        let initialScope = Dictionary(zip(proc.parameters, args), uniquingKeysWith: { _, last in last })
        variables.pushScope(initialValues: initialScope)
        executionFrames.append(
            LogoExecutionFrame(procedureName: proc.name, token: nil, scopeDepth: variables.scopeDepth))
        defer {
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
        let finalResult = procReturn ?? (proc.isSingleExpression(registry: pluginRegistry) ? lastResult : nil)
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
}
