import Foundation

/// Represents a user-defined LOGO procedure defined via `TO procName :param1
/// ... body ... END`. Procedures can act as Statement Commands (non-returning)
/// or Reporters/Operations (returning a value via `OUTPUT`).
public struct LogoProcedure: Sendable {
    public let name: String
    public let parameters: [String]
    public let docstring: String?
    public let bodyTokens: [LogoToken]

    public init(name: String, parameters: [String], docstring: String? = nil, bodyTokens: [LogoToken]) {
        self.name = name
        self.parameters = parameters
        self.docstring = docstring
        self.bodyTokens = bodyTokens
    }

    public init(name: String, parameters: [String], docstring: String? = nil, bodyTokenTexts: [String]) {
        self.init(
            name: name, parameters: parameters, docstring: docstring,
            bodyTokens: bodyTokenTexts.map { LogoToken(text: $0, sourceRange: 0..<0) })
    }

    /// Returns true if this procedure is a Reporter (returns a value via `OUTPUT`/`OP`/`RETURN`
    /// or consists of a single evaluated expression).
    public var isReporter: Bool {
        let bodyTexts = bodyTokens.map(\.text)
        guard !bodyTexts.isEmpty else { return false }
        for t in bodyTexts {
            if let prim = LogoPrimitive.from(t), prim == .output {
                return true
            }
        }
        return isSingleExpression
    }

    /// Returns true if the procedure body does not contain statement commands (like MAKE, FORWARD, BOX, etc.),
    /// enabling implicit return of its single evaluated expression.
    var isSingleExpression: Bool {
        let bodyTexts = bodyTokens.map(\.text)
        guard !bodyTexts.isEmpty else { return false }
        for t in bodyTexts {
            if let prim = LogoPrimitive.from(t) {
                if LogoPrimitive.statementCommands.contains(prim) && prim != .output && prim != .stop {
                    return false
                }
            }
        }
        return true
    }
}
