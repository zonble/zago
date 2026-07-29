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
