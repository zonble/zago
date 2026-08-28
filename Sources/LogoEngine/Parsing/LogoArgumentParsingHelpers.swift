import Foundation

extension LogoEngine {
    internal func isIntExpressionArgumentStart(_ token: String) -> Bool {
        let unquoted = token.unquotedLogoWord
        if BorderStyle.isStyleToken(unquoted) || BoxAlignment(unquoted) != nil || BoxExitPosition(unquoted) != nil {
            return false
        }
        guard !token.isQuotedLogoWord else { return false }
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
        while index < tokens.count && isFillerToken(tokens[index]) {
            index += 1
        }
        guard index < tokens.count else { return nil }
        let originalIndex = index
        let token = tokens[index]
        guard !isBoundary(token), isIntExpressionArgumentStart(token) else { return nil }

        var expressionIndex = index
        let value = evaluateExpression(tokens, index: &expressionIndex)
        guard expressionIndex >= originalIndex, let intValue = value.logoIntValue else {
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
