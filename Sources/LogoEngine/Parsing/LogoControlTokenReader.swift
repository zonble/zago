import Foundation

/// Cursor for control-flow syntax. Unlike LogoArgumentReader, this cursor
/// understands raw tokens and bracket blocks; it does not decide where an
/// expression argument ends beyond delegating expression evaluation to the
/// engine.
internal struct LogoControlTokenReader {
    private unowned let engine: LogoEngine
    private let tokens: [String]
    private(set) var index: Int

    init(engine: LogoEngine, tokens: [String], index: Int) {
        self.engine = engine
        self.tokens = tokens
        self.index = index
    }

    func peekToken(offset: Int = 1) -> String? {
        let position = index + offset
        guard tokens.indices.contains(position) else { return nil }
        return tokens[position]
    }

    var position: Int { index }

    mutating func nextRawToken() -> String? {
        guard index + 1 < tokens.count else { return nil }
        index += 1
        return tokens[index]
    }

    mutating func nextExpression() -> String? {
        guard index + 1 < tokens.count else { return nil }
        index += 1
        return engine.evaluateExpression(tokens, index: &index)
    }

    mutating func nextOptionalExpression(
        isBoundary: ((String) -> Bool)? = nil
    ) -> String? {
        let engine = self.engine
        let boundary = isBoundary ?? { engine.isArgumentBoundary($0) }
        guard let token = peekToken(), !boundary(token) else { return nil }
        return nextExpression()
    }

    /// Consumes a block whose opening bracket is the next token. The cursor
    /// ends on the matching closing bracket, matching extractBlockTokens.
    mutating func nextBlock() -> [String]? {
        guard peekToken() == "[" else { return nil }
        index += 1
        var depth = 1
        var block: [String] = []
        while index + 1 < tokens.count, depth > 0 {
            index += 1
            let token = tokens[index]
            if token == "[" {
                depth += 1
            } else if token == "]" {
                depth -= 1
                if depth == 0 { break }
            }
            block.append(token)
        }
        return block
    }

    /// Consumes raw tokens after the current cursor until the next token
    /// satisfies `stop`. The stop token remains unconsumed.
    mutating func tokensUntil(_ stop: (String) -> Bool) -> [String] {
        var result: [String] = []
        while let token = peekToken(), !stop(token) {
            result.append(token)
            _ = nextRawToken()
        }
        return result
    }

    mutating func skipRawTokenIfPresent(_ token: String) -> Bool {
        guard peekToken() == token else { return false }
        _ = nextRawToken()
        return true
    }

    func commit(to index: inout Int) {
        index = self.index
    }
}
