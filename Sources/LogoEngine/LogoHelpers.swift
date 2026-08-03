import Foundation

// MARK: - LogoEngine Utility & Helper Functions

extension LogoEngine {
    /// Formats a Double value to String, stripping trailing `.0` if it represents an exact integer within Int bounds.
    internal func formatNum(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 && val >= Double(Int.min) && val <= Double(Int.max) {
            return "\(Int(val))"
        }
        return "\(val)"
    }

    /// Computes the numeric sum recursively across nested strings, lists, and arrays.
    internal func numericSum(of value: LogoValue) -> Double {
        switch value {
        case .string(let string):
            return Double(string) ?? 0
        case .list(let items), .array(let items):
            return items.reduce(0) { $0 + numericSum(of: $1) }
        }
    }

    /// Extracts all numeric values recursively from nested strings, lists, and arrays.
    internal func numericValues(in value: LogoValue) -> [Double] {
        switch value {
        case .string(let string):
            return Double(string).map { [$0] } ?? []
        case .list(let items), .array(let items):
            return items.flatMap { numericValues(in: $0) }
        }
    }

    /// Computes minimum or maximum numeric value recursively from a LogoValue.
    internal func numericExtremum(of value: LogoValue, preferMaximum: Bool) -> Double? {
        let values = numericValues(in: value)
        guard var result = values.first else { return nil }
        for value in values.dropFirst() {
            result = preferMaximum ? Swift.max(result, value) : Swift.min(result, value)
        }
        return result
    }

    /// Evaluates LOGO boolean coercion semantics ("1", "true" -> true; "0", "false", "" -> false; non-zero numbers -> true).
    internal func logoIsTrue(_ val: String) -> Bool {
        let clean = val.lowercased().trimmingCharacters(in: .whitespaces)
        if clean == "1" || clean == "true" { return true }
        if clean == "0" || clean == "false" || clean.isEmpty { return false }
        if let d = Double(clean) { return d != 0 }
        return true
    }

    /// Removes surrounding quotes from string literal tokens if present.
    internal func unquote(_ str: String) -> String {
        var result = str
        if result.hasPrefix("\"") {
            result.removeFirst()
        }
        if result.hasSuffix("\"") {
            result.removeLast()
        }
        return result
    }

    internal func isQuotedWordToken(_ token: String) -> Bool {
        token.hasPrefix("\"")
    }

    internal func setLastExpressionString(_ value: String) {
        lastExpressionValue = .string(value)
    }

    internal func setLastExpressionDateTime(_ value: String) {
        lastExpressionValue = .dateTime(value)
    }

    internal func runtimeValueForLastExpression(fallback value: String) -> LogoRuntimeValue {
        if let runtimeValue = lastExpressionValue, runtimeValue.description == value {
            return runtimeValue
        }
        return .string(value)
    }

    internal func runtimeValueForVariable(_ name: String, value: String) -> LogoRuntimeValue {
        if let runtimeValue = variableValues[name], runtimeValue.description == value {
            return runtimeValue
        }
        return .string(value)
    }

    internal func parseUnquotedIntArgument(_ tokens: [String], index: inout Int) -> Int? {
        guard index < tokens.count, !isQuotedWordToken(tokens[index]) else { return nil }

        let token = tokens[index]
        if let literalValue = Int(token) {
            return literalValue
        }

        if token.hasPrefix(":") {
            let variableName = normalizeVariableName(token)
            let value = variables[variableName] ?? ""
            if !runtimeValueForVariable(variableName, value: value).isNumeric {
                return nil
            }
            return Int(resolveTokenValue(token))
        }

        let variableName = token.lowercased()
        if let value = variables[variableName] {
            if !runtimeValueForVariable(variableName, value: value).isNumeric {
                return nil
            }
            return Int(resolveTokenValue(token))
        }

        return nil
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
        guard !isQuotedWordToken(token) else { return false }
        if token == "(" { return true }
        if Double(token) != nil { return true }
        if token.hasPrefix(":") { return true }
        if variables[token.lowercased()] != nil { return true }

        guard let primitive = LogoPrimitive.from(token) else { return false }
        return !LogoEngine.isStatementCommand(token) && LogoEngine.keywords.contains(primitive)
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

    /// Normalizes variable names (removes leading colon, unquotes, lowercases).
    internal func normalizeVariableName(_ raw: String) -> String {
        var name = unquote(raw.trimmingCharacters(in: CharacterSet(charactersIn: "()")))
        if name.hasPrefix(":") {
            name.removeFirst()
        }
        return name.lowercased()
    }

    /// Formats current date string according to specified format pattern.
    internal func formatDate(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = normalizeDateFormat(format)
        return formatter.string(from: Date())
    }

    /// Formats current time string according to specified format pattern.
    internal func formatTime(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = normalizeTimeFormat(format)
        return formatter.string(from: Date())
    }

    private func normalizeDateFormat(_ format: String) -> String {
        var fmt = format
        fmt = fmt.replacingOccurrences(of: "YYYY", with: "yyyy")
        fmt = fmt.replacingOccurrences(of: "DD", with: "dd")
        return fmt
    }

    private func normalizeTimeFormat(_ format: String) -> String {
        var fmt = format
        fmt = fmt.replacingOccurrences(of: "hh", with: "HH")
        fmt = fmt.replacingOccurrences(of: "MM", with: "mm")
        fmt = fmt.replacingOccurrences(of: "SS", with: "ss")
        return fmt
    }
}
