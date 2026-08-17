import Foundation

/// Determines whether a procedure name conflicts with built-in LOGO keywords, operators, or syntax delimiters.
///
/// In the LOGO engine, procedure names are case-insensitive. User-defined procedures (`TO <name> ... END`)
/// cannot shadow or override core engine keywords to ensure unambiguous parsing and token dispatch:
///
/// 1. **Built-in Primitives**: Names matching any `LogoPrimitive` keyword or alias
///    (e.g., `FORWARD`, `FD`, `REPEAT`, `MAKE`, `IF`, `PRINT`, `FORMAT.DATE`, `CONVERT.AREA`).
/// 2. **Infix Operators**: Names matching any `LogoOperator` symbol or word (e.g., `+`, `-`, `*`, `/`, `=`, `<>`).
/// 3. **Structural Delimiters & Keywords**: Special syntax tokens including `END` (procedure terminator),
///    brackets `[` `]` `{` `}`, parentheses `(` `)`, and comment prefixes `;`, `#`, `//`.
///
/// - Parameter name: The candidate procedure name to test.
/// - Returns: `true` if the name is reserved and cannot be defined by user scripts; otherwise `false`.
internal func isReservedProcedureName(_ name: String) -> Bool {
    let upper = name.uppercased()
    if LogoPrimitive.from(upper) != nil || LogoOperator.from(upper) != nil {
        return true
    }
    let reservedTokens: Set<String> = ["END", "]", "[", "}", "{", "(", ")", ";", "#", "//"]
    return reservedTokens.contains(upper)
}

/// Validates the syntactic structure of a candidate LOGO procedure name.
///
/// The LOGO engine requires custom procedure identifiers to follow standard UCBLogo naming rules:
///
/// 1. **Non-Empty**: The identifier must contain at least one character.
/// 2. **No Variable Prefix (`:`)**: Names cannot begin with `:` (reserved for variable value dereferencing).
/// 3. **No Literal Quote Prefixes (`"`, `'`)**: Names cannot begin with double or single quotes (reserved for literal words/strings).
/// 4. **Not a Numeric Literal**: The identifier cannot be parsed as a numeric literal (e.g., `123`, `3.14`),
///    ensuring numeric tokens are always evaluated as numbers rather than procedure invocations.
///
/// - Parameter name: The candidate procedure name string to inspect.
/// - Returns: `true` if the name is syntactically valid for procedure declaration; otherwise `false`.
internal func isValidProcedureName(_ name: String) -> Bool {
    guard !name.isEmpty,
        !name.hasPrefix(":"),
        !name.hasPrefix("\""),
        !name.hasPrefix("'")
    else { return false }
    return Double(name) == nil
}
