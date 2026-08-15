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
        } else if let dashedStyle = BorderStyle.allCases.first(where: {
            $0.isDashed && $0.horizontalLineCharacter == style.topChar
        }) {
            borderStyle = dashedStyle
        } else {
            borderStyle = .single
        }

        let rows = TextBoxRenderer().frameRows(width: width, height: height, style: style)
        for (rowIndex, row) in rows.enumerated() {
            let currentLine = startLine + rowIndex
            var column = startCol
            for ch in row {
                defer { column += ch.displayWidth }
                guard ch != " " else { continue }
                var renderedCharacter = ch
                if blendJunctions, let existing = buffer.getCharacter(line: currentLine, visualColumn: column) {
                    let existingMask = canvasMask(for: existing, style: borderStyle)
                    let newMask = canvasMask(for: renderedCharacter, style: borderStyle)
                    if existingMask != 0 && newMask != 0 {
                        let blendedMask = existingMask | newMask
                        renderedCharacter = lineCharacter(forMask: blendedMask, style: borderStyle)
                    }
                }

                buffer.setCharacter(line: currentLine, visualColumn: column, character: renderedCharacter)
            }
        }
    }
}
