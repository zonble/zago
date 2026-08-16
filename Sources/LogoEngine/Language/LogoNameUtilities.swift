import Foundation

internal func isReservedProcedureName(_ name: String) -> Bool {
    let upper = name.uppercased()
    if LogoPrimitive.from(upper) != nil || LogoOperator.from(upper) != nil {
        return true
    }
    let reservedTokens: Set<String> = ["END", "]", "[", "}", "{", "(", ")", ";", "#", "//"]
    return reservedTokens.contains(upper)
}

internal func isValidProcedureName(_ name: String) -> Bool {
    guard !name.isEmpty,
        !name.hasPrefix(":"),
        !name.hasPrefix("\""),
        !name.hasPrefix("'")
    else { return false }
    return Double(name) == nil
}
