import Foundation
import TextMetrics

/// Abstract 2D text buffer protocol for drawing lines, boxes, and shapes with CJK visual column support.
public protocol DrawingBuffer: AnyObject {
    var lineCount: Int { get }
    func lineString(at line: Int) -> String
    func getCharacter(line: Int, visualColumn: Int) -> Character?
    func setCharacter(line: Int, visualColumn: Int, character: Character)
}

/// Helper adapter wrapping an `inout [String]` or `[String]` array into a `DrawingBuffer`.
public final class StringArrayDrawingBuffer: DrawingBuffer, @unchecked Sendable {
    public var lines: [String]

    public init(lines: [String] = []) {
        self.lines = lines
    }

    public var lineCount: Int {
        lines.count
    }

    public func lineString(at line: Int) -> String {
        guard line >= 0 && line < lines.count else { return "" }
        return lines[line]
    }

    public func getCharacter(line: Int, visualColumn: Int) -> Character? {
        guard line >= 0 && line < lines.count else { return nil }
        let currentLine = lines[line]
        var currentVisCol = 0

        for ch in currentLine {
            let width = ch.displayWidth
            if currentVisCol == visualColumn {
                return ch
            }
            if currentVisCol < visualColumn && currentVisCol + width > visualColumn {
                return nil
            }
            currentVisCol += width
            if currentVisCol > visualColumn {
                break
            }
        }
        return nil
    }

    public func setCharacter(line: Int, visualColumn: Int, character: Character) {
        while lines.count <= line {
            lines.append("")
        }

        var currentLine = lines[line]
        var charArray: [Character] = []
        var visCols: [Int] = []
        var charWidths: [Int] = []

        var curCol = 0
        for ch in currentLine {
            let w = ch.displayWidth
            charArray.append(ch)
            visCols.append(curCol)
            charWidths.append(w)
            curCol += w
        }

        let maxVisCol = curCol
        if visualColumn >= maxVisCol {
            let spacesNeeded = visualColumn - maxVisCol
            if spacesNeeded > 0 {
                currentLine.append(String(repeating: " ", count: spacesNeeded))
            }
            currentLine.append(character)
            lines[line] = currentLine
            return
        }

        var newChars: [Character] = []
        var i = 0
        while i < charArray.count {
            let startV = visCols[i]
            let w = charWidths[i]
            let endV = startV + w

            if visualColumn >= startV && visualColumn < endV {
                newChars.append(character)
                let newW = character.displayWidth
                let diff = endV - (startV + newW)
                if diff > 0 {
                    for _ in 0..<diff {
                        newChars.append(" ")
                    }
                }
            } else {
                newChars.append(charArray[i])
            }
            i += 1
        }
        lines[line] = String(newChars)
    }
}
