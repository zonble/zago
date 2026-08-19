import Foundation

/// Represents a structured Logo runtime error.
public struct LogoError: Sendable, Equatable {
    public let code: Int
    public let message: String
    public let procedureName: String?

    public init(code: Int = 1, message: String, procedureName: String? = nil) {
        self.code = code
        self.message = message
        self.procedureName = procedureName
    }

    /// Formats error as a Logo list `[code "message" "procedureName"]`.
    internal var toLogoListString: String {
        let procStr = procedureName ?? ""
        return "[\(code) \"\(message)\" \"\(procStr)\"]"
    }
}
