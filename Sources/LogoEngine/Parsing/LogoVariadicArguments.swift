import Foundation

extension LogoEngine {
    /// Evaluates arguments of a parenthesized variadic primitive.
    /// The input index points at the primitive name and the returned index
    /// points at the last consumed argument or the closing parenthesis.
    internal func evaluateVariadicArguments(_ tokens: [String], index: inout Int) -> [String] {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)

        var arguments: [String] = []
        while let nextToken = reader.peekToken(), nextToken != ")", nextToken != "]" {
            arguments.append(reader.nextExpression())
        }

        if reader.peekToken() == ")" {
            _ = reader.nextRawToken()
        }
        reader.commit(to: &index)
        return arguments
    }
}
