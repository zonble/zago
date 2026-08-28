import Foundation

/// Advances through the arguments of a primitive while preserving the engine's
/// expression-evaluation rules. The primitive itself remains at `index` until
/// the reader is committed.
internal struct LogoArgumentReader {
    // The reader is created and consumed synchronously by LogoEngine.
    // It must not extend the engine's lifetime.
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
            if engine.isFillerToken(nextTok) {
                index += 1
            } else {
                break
            }
        }
    }

    mutating func nextExpression() -> String {
        skipFillerTokens()
        index += 1
        return engine.evaluateExpression(tokens, index: &index)
    }

    mutating func nextRawToken() -> String? {
        skipFillerTokens()
        guard index + 1 < tokens.count else { return nil }
        index += 1
        return tokens[index]
    }

    mutating func nextRawExpression() -> (raw: String, value: String)? {
        skipFillerTokens()
        guard index + 1 < tokens.count else { return nil }
        index += 1
        let raw = tokens[index]
        let value = engine.evaluateExpression(tokens, index: &index)
        return (raw, value)
    }

    mutating func nextOptionalExpression() -> String? {
        let engine = self.engine
        return nextOptionalExpression { engine.isArgumentBoundary($0) }
    }

    mutating func nextOptionalExpression(isBoundary: (String) -> Bool) -> String? {
        skipFillerTokens()
        guard index + 1 < tokens.count, !isBoundary(tokens[index + 1]) else { return nil }
        return nextExpression()
    }

    var hasArgumentToken: Bool {
        guard let peek = peekToken() else { return false }
        return !engine.isArgumentBoundary(peek)
    }

    func peekToken(offset: Int = 1) -> String? {
        var position = index + 1
        var skipped = 0
        while position < tokens.count && skipped < offset - 1 {
            let t = tokens[position]
            if engine.isFillerToken(t) {
                position += 1
            } else {
                skipped += 1
                position += 1
            }
        }
        while position < tokens.count {
            let t = tokens[position]
            if engine.isFillerToken(t) {
                position += 1
            } else {
                return t
            }
        }
        return nil
    }

    mutating func nextInteger(default defaultValue: Int = 0) -> Int {
        let raw = nextExpression().trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(raw) { return value }
        if let value = Double(raw) { return Int(value) }
        return defaultValue
    }

    mutating func nextOptionalInteger(
        isBoundary: ((String) -> Bool)? = nil
    ) -> Int? {
        skipFillerTokens()
        let engine = self.engine
        let boundary = isBoundary ?? { engine.isArgumentBoundary($0) }
        guard index + 1 < tokens.count else { return nil }
        var nextIndex = index + 1
        guard
            let value = engine.parseIntExpressionArgument(
                tokens, index: &nextIndex, isBoundary: boundary)
        else {
            return nil
        }
        index = nextIndex
        return value
    }

    mutating func nextDouble(default defaultValue: Double = 0) -> Double {
        Double(nextExpression().trimmingCharacters(in: .whitespacesAndNewlines)) ?? defaultValue
    }

    func commit(to index: inout Int) {
        index = self.index
    }
}
