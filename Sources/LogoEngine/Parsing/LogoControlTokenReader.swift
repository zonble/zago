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

    mutating func skipFillerTokens() {
        while index + 1 < tokens.count {
            let nextTok = tokens[index + 1]
            if !nextTok.hasPrefix("\"") && !nextTok.hasPrefix(":") && !nextTok.hasPrefix("[") && !nextTok.hasPrefix("(") && engine.isFillerToken(nextTok) {
                index += 1
            } else {
                break
            }
        }
    }

    func peekToken(offset: Int = 1) -> String? {
        var position = index + 1
        var skipped = 0
        while position < tokens.count && skipped < offset - 1 {
            let t = tokens[position]
            if !t.hasPrefix("\"") && !t.hasPrefix(":") && !t.hasPrefix("[") && !t.hasPrefix("(") && engine.isFillerToken(t) {
                position += 1
            } else {
                skipped += 1
                position += 1
            }
        }
        while position < tokens.count {
            let t = tokens[position]
            if !t.hasPrefix("\"") && !t.hasPrefix(":") && !t.hasPrefix("[") && !t.hasPrefix("(") && engine.isFillerToken(t) {
                position += 1
            } else {
                return t
            }
        }
        return nil
    }

    var position: Int { index }

    var hasArgumentToken: Bool {
        guard let peek = peekToken() else { return false }
        return !engine.isArgumentBoundary(peek)
    }

    mutating func nextRawToken() -> String? {
        skipFillerTokens()
        guard index + 1 < tokens.count else { return nil }
        index += 1
        return tokens[index]
    }

    mutating func nextExpression() -> String? {
        skipFillerTokens()
        guard index + 1 < tokens.count else { return nil }
        index += 1
        return engine.evaluateExpression(tokens, index: &index)
    }

    mutating func nextOptionalExpression(
        isBoundary: ((String) -> Bool)? = nil
    ) -> String? {
        skipFillerTokens()
        let engine = self.engine
        let boundary = isBoundary ?? { engine.isArgumentBoundary($0) }
        guard let token = peekToken(), !boundary(token) else { return nil }
        return nextExpression()
    }

    /// Consumes a block whose opening bracket is the next token. The cursor
    /// ends on the matching closing bracket, matching extractBlockTokens.
    mutating func nextBlock() -> [String]? {
        skipFillerTokens()
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
        skipFillerTokens()
        guard peekToken() == token else { return false }
        _ = nextRawToken()
        return true
    }

    func commit(to index: inout Int) {
        index = self.index
    }
}
