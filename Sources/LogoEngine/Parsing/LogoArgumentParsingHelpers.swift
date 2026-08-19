import Foundation

extension LogoEngine {
    /// Removes surrounding quotes from string literal tokens if present.
    internal func unquote(_ str: String) -> String {
        var result = str
        if result.hasPrefix("\"") {
            result.removeFirst()
        }
        if result.hasSuffix("\"") {
            result.removeLast()
        }
        if result.hasPrefix("|"), result.hasSuffix("|"), result.count >= 2 {
            result.removeFirst()
            result.removeLast()
            result = result.replacingOccurrences(of: "\\|", with: "|").replacingOccurrences(of: "\\\\", with: "\\")
        }
        return result
    }

    internal func isQuotedWordToken(_ token: String) -> Bool {
        token.hasPrefix("\"")
    }

    internal func intValue(fromExpressionResult value: String) -> Int? {
        if let intValue = Int(value) {
            return intValue
        }
        if let doubleValue = Double(value) {
            return Int(doubleValue)
        }
        return nil
    }

    internal func isIntExpressionArgumentStart(_ token: String) -> Bool {
        let unquoted = unquote(token)
        if BorderStyle.isStyleToken(unquoted) || BoxAlignment(unquoted) != nil || BoxExitPosition(unquoted) != nil {
            return false
        }
        guard !isQuotedWordToken(token) else { return false }
        if token == "(" { return true }
        if Double(token) != nil { return true }
        if token.hasPrefix(":") || token.hasPrefix("?") || token == "#" { return true }
        if variables[token.lowercased()] != nil { return true }

        guard parsePrimitive(token) != nil else { return false }
        return !isStatementCommand(token) && isKeyword(token)
    }

    internal func parseIntExpressionArgument(
        _ tokens: [String],
        index: inout Int,
        isBoundary: (String) -> Bool
    ) -> Int? {
        guard index < tokens.count else { return nil }
        let originalIndex = index
        let token = tokens[index]
        guard !isBoundary(token), isIntExpressionArgumentStart(token) else { return nil }

        var expressionIndex = index
        let value = evaluateExpression(tokens, index: &expressionIndex)
        guard expressionIndex >= originalIndex, let intValue = intValue(fromExpressionResult: value) else {
            index = originalIndex
            return nil
        }

        index = expressionIndex
        return intValue
    }

    internal func consumeOptionalIntExpressionArgument(
        _ tokens: [String],
        index: inout Int,
        isBoundary: (String) -> Bool
    ) -> Int? {
        index += 1
        guard index < tokens.count else {
            index -= 1
            return nil
        }
        guard let value = parseIntExpressionArgument(tokens, index: &index, isBoundary: isBoundary) else {
            index -= 1
            return nil
        }
        return value
    }

    internal func consumeNextIntExpressionArgument(
        _ tokens: [String],
        index: inout Int,
        isBoundary: (String) -> Bool
    ) -> Int? {
        guard index + 1 < tokens.count else { return nil }
        var nextIndex = index + 1
        guard let value = parseIntExpressionArgument(tokens, index: &nextIndex, isBoundary: isBoundary) else {
            return nil
        }
        index = nextIndex
        return value
    }
}
