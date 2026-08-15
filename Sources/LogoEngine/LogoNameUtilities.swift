import Foundation

internal func isReservedProcedureName(_ name: String) -> Bool {
    let upper = name.uppercased()
    if LogoPrimitive.from(upper) != nil || LogoOperator.from(upper) != nil {
        return true
    }
    let reservedTokens: Set<String> = ["END", "]", "[", "}", "{", "(", ")", ";", "#", "//"]
    return reservedTokens.contains(upper)
}
