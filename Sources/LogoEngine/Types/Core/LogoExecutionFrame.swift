import Foundation

/// Represents a snapshot of the execution call stack in the LOGO interpreter.
public struct LogoExecutionFrame: Equatable, Sendable {
    /// The name of the active procedure being executed, or `nil` if executing top-level commands.
    public let procedureName: String?

    /// The current token being evaluated within this stack frame, if available.
    public let token: LogoToken?

    /// The lexical scope nesting depth for variable resolution.
    public let scopeDepth: Int

    public init(procedureName: String?, token: LogoToken?, scopeDepth: Int) {
        self.procedureName = procedureName
        self.token = token
        self.scopeDepth = scopeDepth
    }
}
