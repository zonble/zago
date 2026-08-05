import Foundation

/// Git diff modification status for a line in the editor buffer.
public enum GitLineStatus: Sendable, Equatable {
    case unmodified
    case added
    case modified
    case deletedBefore
}
