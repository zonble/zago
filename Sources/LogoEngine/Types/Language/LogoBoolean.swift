import Foundation

extension Bool {
    public var logoString: String {
        self ? "true" : "false"
    }
}

/// Evaluates whether a raw LOGO string represents a truthy boolean value.
public func logoIsTrue(_ value: String) -> Bool {
    let clean = value.lowercased().trimmingCharacters(in: .whitespaces)
    if clean == "1" || clean == "true" { return true }
    if clean == "0" || clean == "false" || clean.isEmpty { return false }
    if let number = Double(clean) { return number != 0 }
    return true
}
