import Foundation

extension Bool {
    public var logoString: String {
        self ? "true" : "false"
    }
}

/// Evaluates whether a raw LOGO string represents a truthy boolean value.
public func logoIsTrue(_ value: String) -> Bool {
    logoIsTrue(value, registry: nil)
}

/// Evaluates whether a raw LOGO string represents a truthy boolean value with optional plugin registry.
public func logoIsTrue(_ value: String, registry: LogoPluginRegistry?) -> Bool {
    let clean = value.lowercased().trimmingCharacters(in: .whitespaces)
    if let registry, let b = registry.parseBoolean(clean) {
        return b
    }
    if clean == "1" || clean == "true" { return true }
    if clean == "0" || clean == "false" || clean.isEmpty { return false }
    if let number = Double(clean) { return number != 0 }
    return true
}
