import Foundation

struct EditorOperationResult: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case succeeded
        case failed(String)
        case cancelled
        case prompting
        case noOp
    }

    let kind: Kind
    let statusMessage: String?

    static let succeeded = EditorOperationResult(kind: .succeeded)
    static let cancelled = EditorOperationResult(kind: .cancelled)
    static let prompting = EditorOperationResult(kind: .prompting)
    static let noOp = EditorOperationResult(kind: .noOp)

    static func succeeded(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .succeeded, statusMessage: message)
    }

    static func failed(_ reason: String, message: String? = nil) -> EditorOperationResult {
        EditorOperationResult(kind: .failed(reason), statusMessage: message)
    }

    static func cancelled(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .cancelled, statusMessage: message)
    }

    static func prompting(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .prompting, statusMessage: message)
    }

    static func noOp(message: String?) -> EditorOperationResult {
        EditorOperationResult(kind: .noOp, statusMessage: message)
    }

    init(kind: Kind, statusMessage: String? = nil) {
        self.kind = kind
        self.statusMessage = statusMessage
    }

    var isSucceeded: Bool {
        kind == .succeeded
    }

    var isFailed: Bool {
        if case .failed = kind {
            return true
        }
        return false
    }

    static func == (lhs: EditorOperationResult, rhs: EditorOperationResult) -> Bool {
        lhs.kind == rhs.kind
    }
}
