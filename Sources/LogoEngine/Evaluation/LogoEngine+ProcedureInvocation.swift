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

    private func isElseClauseToken(_ token: String) -> Bool {
        token.uppercased() == "ELSE" || isFillerToken(token)
    }

    private func executeClauseBody(_ clause: [String], reader: inout LogoControlTokenReader, frameReturn: inout String?) -> String? {
        if let bodyBlock = reader.nextBlock() {
            var bIdx = 0
            executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
            return frameReturn ?? lastResult ?? ""
        } else {
            var bIdx = reader.position + 1
            executeTokens(clause, index: &bIdx, frameReturn: &frameReturn)
            return frameReturn ?? lastResult ?? ""
        }
    }

    internal func evaluateCaseClauses(targetVal: String, clausesBlock: [String], frameReturn: inout String?) -> String? {
        var reader = LogoControlTokenReader(engine: self, tokens: clausesBlock, index: -1)
        while let clause = reader.nextBlock() {
            guard !clause.isEmpty else { continue }
            var clauseReader = LogoControlTokenReader(engine: self, tokens: clause, index: -1)
            if let firstToken = clauseReader.nextRawToken(skipFillers: false), isElseClauseToken(firstToken) {
                return executeClauseBody(clause, reader: &clauseReader, frameReturn: &frameReturn)
            } else {
                clauseReader = LogoControlTokenReader(engine: self, tokens: clause, index: -1)
                if let matches = clauseReader.nextBlock() {
                    let isMatch = matches.contains { unquote($0) == targetVal }
                    if isMatch {
                        return executeClauseBody(clause, reader: &clauseReader, frameReturn: &frameReturn)
                    }
                }
            }
        }
        return nil
    }

    internal func evaluateCaseClauses(targetVal: String, clausesBlock: [String]) -> String? {
        var dummy: String? = nil
        return evaluateCaseClauses(targetVal: targetVal, clausesBlock: clausesBlock, frameReturn: &dummy)
    }

    internal func evaluateCondClauses(clausesBlock: [String], frameReturn: inout String?) -> String? {
        var reader = LogoControlTokenReader(engine: self, tokens: clausesBlock, index: -1)
        while let clause = reader.nextBlock() {
            guard !clause.isEmpty else { continue }
            var clauseReader = LogoControlTokenReader(engine: self, tokens: clause, index: -1)
            if let firstToken = clauseReader.nextRawToken(skipFillers: false), isElseClauseToken(firstToken) {
                return executeClauseBody(clause, reader: &clauseReader, frameReturn: &frameReturn)
            } else {
                clauseReader = LogoControlTokenReader(engine: self, tokens: clause, index: -1)
                if let condTokens = clauseReader.nextBlock() {
                    if evaluateCondition(condTokens) {
                        return executeClauseBody(clause, reader: &clauseReader, frameReturn: &frameReturn)
                    }
                }
            }
        }
        return nil
    }

    internal func evaluateCondClauses(clausesBlock: [String]) -> String? {
        var dummy: String? = nil
        return evaluateCondClauses(clausesBlock: clausesBlock, frameReturn: &dummy)
    }
}
