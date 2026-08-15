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

    mutating func nextExpression() -> String {
        index += 1
        return engine.evaluateExpression(tokens, index: &index)
    }

    mutating func nextRawToken() -> String? {
        guard index + 1 < tokens.count else { return nil }
        index += 1
        return tokens[index]
    }

    mutating func nextRawExpression() -> (raw: String, value: String)? {
        guard index + 1 < tokens.count else { return nil }
        index += 1
        let raw = tokens[index]
        let value = engine.evaluateExpression(tokens, index: &index)
        return (raw, value)
    }

    mutating func nextOptionalExpression() -> String? {
        nextOptionalExpression { LogoEngine.isArgumentBoundary($0) }
    }

    mutating func nextOptionalExpression(isBoundary: (String) -> Bool) -> String? {
        guard index + 1 < tokens.count, !isBoundary(tokens[index + 1]) else { return nil }
        return nextExpression()
    }

    func peekToken(offset: Int = 1) -> String? {
        let position = index + offset
        guard tokens.indices.contains(position) else { return nil }
        return tokens[position]
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
        let boundary = isBoundary ?? { LogoEngine.isArgumentBoundary($0) }
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
