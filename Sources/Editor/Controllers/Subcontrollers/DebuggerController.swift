import Foundation

final class DebuggerController {
    private var breakpointsByBufferID: [String: Set<Int>] = [:]
    private(set) var activeSourceBufferID: String?
    private(set) var activeSourceStartLine = 0
    private(set) var activeScript = ""
    private(set) var executionTargetBufferID: String?
    var lastEvaluation: String?

    init() {}

    @discardableResult
    func toggleBreakpoint(in buffer: TextBuffer) -> Bool {
        var lines = breakpointsByBufferID[buffer.id, default: []]
        if lines.remove(buffer.lineIndex) != nil {
            breakpointsByBufferID[buffer.id] = lines
            return false
        }
        lines.insert(buffer.lineIndex)
        breakpointsByBufferID[buffer.id] = lines
        return true
    }

    func breakpoints(in buffer: TextBuffer) -> [Int] {
        breakpointsByBufferID[buffer.id, default: []].sorted()
    }

    func hasBreakpoint(in buffer: TextBuffer, line: Int) -> Bool {
        breakpointsByBufferID[buffer.id, default: []].contains(line)
    }

    func beginExecution(in buffer: TextBuffer, targetBuffer: TextBuffer, startLine: Int, script: String) {
        activeSourceBufferID = buffer.id
        activeSourceStartLine = startLine
        activeScript = script
        executionTargetBufferID = targetBuffer.id
        lastEvaluation = nil
    }
}
