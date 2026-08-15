import Foundation

public struct LogoExecutionFrame: Equatable, Sendable {
    public let procedureName: String?
    public let token: LogoToken?
    public let scopeDepth: Int

    public init(procedureName: String?, token: LogoToken?, scopeDepth: Int) {
        self.procedureName = procedureName
        self.token = token
        self.scopeDepth = scopeDepth
    }
}
