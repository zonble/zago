import Foundation

extension String {
    /// Removes surrounding quotes from string literal tokens if present.
    /// Supports standard double quotes (`"word`) and vertical bar literals (`|multi word|`).
    public var unquotedLogoWord: String {
        var result = self
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

    /// Checks whether this token represents a quoted word (starts with `"`).
    public var isQuotedLogoWord: Bool {
        hasPrefix("\"")
    }

    /// Converts a LOGO expression string result into an integer if possible (handling both Int and Double strings).
    public var logoIntValue: Int? {
        if let intValue = Int(self) {
            return intValue
        }
        if let doubleValue = Double(self) {
            return Int(doubleValue)
        }
        return nil
    }
}
