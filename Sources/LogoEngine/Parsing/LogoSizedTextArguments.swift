import Foundation

internal struct LogoSizedTextArguments {
    let width: Int?
    let height: Int?
    let text: String
}

extension LogoEngine {
    /// Parses the shared `[width] [height] text` shape used by FILL and INSET.
    /// The caller's index points at the first argument and advances to the last
    /// consumed token, matching the command dispatcher contract.
    internal func consumeSizedTextArguments(
        _ tokens: [String],
        index: inout Int
    ) -> LogoSizedTextArguments {
        let boundary: (String) -> Bool = { token in
            LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
        }

        // FILL and INSET are dispatched after their command token has already
        // been consumed, while LogoArgumentReader starts at the command token.
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: max(0, index - 1))
        let width = reader.nextOptionalInteger(isBoundary: boundary)
        let height = width == nil ? nil : reader.nextOptionalInteger(isBoundary: boundary)
        let text = unquote(reader.nextExpression())
        reader.commit(to: &index)

        return LogoSizedTextArguments(width: width, height: height, text: text)
    }
}
