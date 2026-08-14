import Foundation

public enum EditorOperationResult: Equatable, Sendable {
    case succeeded
    case failed(String)
    case cancelled
    case prompting
    case noOp

    public var isSucceeded: Bool {
        self == .succeeded
    }
}
