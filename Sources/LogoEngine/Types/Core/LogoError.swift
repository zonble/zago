import Foundation

/// Represents a structured Logo runtime error.
public struct LogoError: Sendable, Equatable {
    public let code: Int
    public let message: String
    public var procedureName: String?
    public var token: LogoToken?
    public var callStack: [LogoExecutionFrame]

    public init(
        code: Int = 1,
        message: String,
        procedureName: String? = nil,
        token: LogoToken? = nil,
        callStack: [LogoExecutionFrame] = []
    ) {
        self.code = code
        self.message = message
        self.procedureName = procedureName
        self.token = token
        self.callStack = callStack
    }

    /// Formats error as a Logo list `[code "message" "procedureName"]`.
    internal var toLogoListString: String {
        let procStr = procedureName ?? ""
        return "[\(code) \"\(message)\" \"\(procStr)\"]"
    }
}
