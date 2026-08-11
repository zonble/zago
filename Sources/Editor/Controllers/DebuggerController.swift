import Foundation

public final class DebuggerController {
    private var breakpointsByBufferID: [String: Set<Int>] = [:]

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
}
