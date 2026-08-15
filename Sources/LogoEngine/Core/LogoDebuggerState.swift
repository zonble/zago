import Foundation

public enum LogoExecutionState: Equatable, Sendable {
    case idle
    case running
    case paused(LogoExecutionFrame)
    case completed
}
