import Foundation
import TextMetrics

public struct ArrowDrawer: Sendable {
    public init() {}

    /// Draws a straight line or arrow onto a `DrawingBuffer`.
    public func drawLine(
        buffer: DrawingBuffer,
        startLine: Int,
        startCol: Int,
        direction: CanvasDrawDirection,
        length: Int,
        hasArrow: Bool = false,
        style: BorderStyle = .single
    ) {
        guard length > 0 else { return }

        var currentLine = startLine
        var currentCol = startCol

        for i in 0..<length {
            let isEnd = (i == length - 1)
            var ch: Character

            if isEnd && hasArrow {
                ch = arrowHead(for: direction, style: style)
            } else {
                let mask: UInt8
                switch direction {
                case .up, .down:
                    mask = CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask
                case .left, .right:
                    mask = CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask
                }
                ch = lineCharacter(forMask: mask, style: style)
            }

            if let existing = buffer.getCharacter(line: currentLine, visualColumn: currentCol) {
                let existingMask = canvasMask(for: existing, style: style)
                let newMask = canvasMask(for: ch, style: style)
                if existingMask != 0 && newMask != 0 {
                    let blendedMask = existingMask | newMask
                    ch = lineCharacter(forMask: blendedMask, style: style)
                }
            }

            buffer.setCharacter(line: currentLine, visualColumn: currentCol, character: ch)

            let delta = direction.delta
            currentLine += delta.line
            currentCol += delta.column
        }
    }
}
