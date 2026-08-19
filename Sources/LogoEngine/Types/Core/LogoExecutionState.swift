import Foundation

/// Represents the execution and lifecycle state of the LOGO interpreter during
/// script evaluation.
public enum LogoExecutionState: Equatable, Sendable {
    /// The engine is currently inactive and ready to accept new commands or
    /// scripts.
    case idle

    /// The engine is actively interpreting and evaluating LOGO tokens and
    /// procedures.
    case running

    /// Execution has been paused (e.g. at a breakpoint, single-step debugger
    /// pause, or pause request). Holds the active `LogoExecutionFrame`
    /// representing the current procedure, token location, and scope depth.
    case paused(LogoExecutionFrame)

    /// Script evaluation has completed all top-level tokens or terminated
    /// normally.
    case completed
}
