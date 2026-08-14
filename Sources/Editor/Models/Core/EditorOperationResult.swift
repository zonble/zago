import Foundation

public struct EditorOperationResult: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case succeeded
        case failed(String)
        case cancelled
        case prompting
        case noOp
    }

    public let kind: Kind
    public let statusMessage: String?

    public static let succeeded = EditorOperationResult(kind: .succeeded)
    public static let cancelled = EditorOperationResult(kind: .cancelled)
    public static let prompting = EditorOperationResult(kind: .prompting)
    public static let noOp = EditorOperationResult(kind: .noOp)

    public static func succeeded(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .succeeded, statusMessage: message)
    }

    public static func failed(_ reason: String, message: String? = nil) -> EditorOperationResult {
        EditorOperationResult(kind: .failed(reason), statusMessage: message)
    }

    public static func cancelled(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .cancelled, statusMessage: message)
    }

    public static func prompting(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .prompting, statusMessage: message)
    }

    public static func noOp(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .noOp, statusMessage: message)
    }

    public init(kind: Kind, statusMessage: String? = nil) {
        self.kind = kind
        self.statusMessage = statusMessage
    }

    public var isSucceeded: Bool {
        kind == .succeeded
    }
}
