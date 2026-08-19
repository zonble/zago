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
        let resBool = logoIsTrue(leftValStr, registry: pluginRegistry)

        if idx >= tokensToEval.count - 1 {
            return resBool
        }

        if idx + 1 < tokensToEval.count {
            let opToken = tokensToEval[idx + 1]
            if let op = parseOperator(opToken), op.isComparison {
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
}
