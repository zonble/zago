import Foundation
import TextMetrics

public struct BoxDrawer: Sendable {
    public init() {}

    /// Draws a box frame onto a `DrawingBuffer`.
    public func drawBox(
        buffer: DrawingBuffer,
        startLine: Int,
        startCol: Int,
        width: Int,
        height: Int,
        style: BoxStyle = .single,
        blendJunctions: Bool = true
    ) {
        guard width >= 2 && height >= 2 else { return }

        let borderStyle: BorderStyle
        if style.topChar == "=" {
            borderStyle = .double
        } else if style.topLeft == "+" {
            borderStyle = .ascii
        } else if style.topLeft == "/" {
            borderStyle = .asciiRound
        } else if style.topLeft == "╭" {
            borderStyle = style.topChar == "=" ? .doubleRound : .round
        } else {
            borderStyle = .single
        }

        for r in 0..<height {
            let currentLine = startLine + r
            let isTop = (r == 0)
            let isBottom = (r == height - 1)

            for c in 0..<width {
                let isLeft = (c == 0)
                let isRight = (c == width - 1)
                let currentCol = startCol + c

                var ch: Character = " "

                if isTop && isLeft {
                    ch = style.topLeft
                } else if isTop && isRight {
                    ch = style.topRight
                } else if isBottom && isLeft {
                    ch = style.bottomLeft
                } else if isBottom && isRight {
                    ch = style.bottomRight
                } else if isTop {
                    ch = style.topChar
                } else if isBottom {
                    ch = style.bottomChar
                } else if isLeft || isRight {
                    ch = style.sideChar
                } else {
                    continue
                }

                if blendJunctions, let existing = buffer.getCharacter(line: currentLine, visualColumn: currentCol) {
                    let existingMask = canvasMask(for: existing, style: borderStyle)
                    let newMask = canvasMask(for: ch, style: borderStyle)
                    if existingMask != 0 && newMask != 0 {
                        let blendedMask = existingMask | newMask
                        ch = lineCharacter(forMask: blendedMask, style: borderStyle)
                    }
                }

                buffer.setCharacter(line: currentLine, visualColumn: currentCol, character: ch)
            }
        }
    }
}
