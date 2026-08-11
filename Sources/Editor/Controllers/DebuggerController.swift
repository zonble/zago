import Foundation

public final class DebuggerController {
    private var breakpointsByBufferID: [String: Set<Int>] = [:]
    public private(set) var activeSourceBufferID: String?
    public private(set) var activeSourceStartLine = 0
    public private(set) var activeScript = ""
    public private(set) var executionTargetBufferID: String?
    public var lastEvaluation: String?

    public init() {}

    @discardableResult
    public func toggleBreakpoint(in buffer: TextBuffer) -> Bool {
        var lines = breakpointsByBufferID[buffer.id, default: []]
        if lines.remove(buffer.lineIndex) != nil {
            breakpointsByBufferID[buffer.id] = lines
            return false
        }
        lines.insert(buffer.lineIndex)
        breakpointsByBufferID[buffer.id] = lines
        return true
    }

    public func breakpoints(in buffer: TextBuffer) -> [Int] {
        breakpointsByBufferID[buffer.id, default: []].sorted()
    }

    public func hasBreakpoint(in buffer: TextBuffer, line: Int) -> Bool {
        breakpointsByBufferID[buffer.id, default: []].contains(line)
    }

    public func beginExecution(in buffer: TextBuffer, targetBuffer: TextBuffer, startLine: Int, script: String) {
        activeSourceBufferID = buffer.id
        activeSourceStartLine = startLine
        activeScript = script
        executionTargetBufferID = targetBuffer.id
        lastEvaluation = nil
    }
}
