import Foundation
import TextMetrics

public struct TextFillSpan: Sendable {
    public let line: Int
    public let startColumn: Int
    public let endColumn: Int

    public init(line: Int, startColumn: Int, endColumn: Int) {
        self.line = line
        self.startColumn = startColumn
        self.endColumn = endColumn
    }
}

public struct TextFloodFillResult: Sendable {
    public let spans: [TextFillSpan]
    public let escaped: Bool
    public let reachedLimit: Bool

    public init(spans: [TextFillSpan], escaped: Bool, reachedLimit: Bool) {
        self.spans = spans
        self.escaped = escaped
        self.reachedLimit = reachedLimit
    }
}

/// Pure text generation and flood-fill operations for box drawing commands.
public enum TextFillRenderer {
    public static func tiled(_ pattern: String, toDisplayWidth width: Int) -> String {
        pattern.tiledToDisplayWidth(width)
    }

    public static func floodFill(
        lines: [String],
        startLine: Int,
        startColumn: Int,
        maxCells: Int = 10_000
    ) -> TextFloodFillResult {
        guard startLine >= 0, startColumn >= 0 else {
            return TextFloodFillResult(spans: [], escaped: true, reachedLimit: false)
        }

        struct Cell: Hashable {
            let line: Int
            let column: Int
        }

        let maxRows = lines.count
        let maxColumns = 200
        var visited: Set<Cell> = [Cell(line: startLine, column: startColumn)]
        var queue: [Cell] = [Cell(line: startLine, column: startColumn)]
        var cells: [Cell] = []
        var escaped = false

        func character(at cell: Cell) -> Character {
            guard cell.line >= 0, cell.line < lines.count else { return " " }
            return DisplayText.character(atVisualColumn: cell.column, in: lines[cell.line])
        }

        while !queue.isEmpty && cells.count < maxCells {
            let cell = queue.removeFirst()
            guard !BoxBorderCharacters.isBorder(character(at: cell)) else { continue }
            cells.append(cell)

            let neighbors = [
                Cell(line: cell.line - 1, column: cell.column),
                Cell(line: cell.line + 1, column: cell.column),
                Cell(line: cell.line, column: cell.column - 1),
                Cell(line: cell.line, column: cell.column + 1),
            ]
            for neighbor in neighbors {
                if neighbor.line < 0 || neighbor.line >= maxRows
                    || neighbor.column < 0 || neighbor.column >= maxColumns
                {
                    escaped = true
                    continue
                }
                if visited.insert(neighbor).inserted {
                    queue.append(neighbor)
                }
            }
        }

        let grouped = Dictionary(grouping: cells, by: \.line)
        let spans = grouped.keys.sorted().flatMap { line in
            let columns = grouped[line, default: []].map(\.column).sorted()
            var result: [TextFillSpan] = []
            for column in columns {
                if let last = result.last, last.endColumn + 1 == column {
                    result[result.count - 1] = TextFillSpan(
                        line: line, startColumn: last.startColumn, endColumn: column)
                } else {
                    result.append(TextFillSpan(line: line, startColumn: column, endColumn: column))
                }
            }
            return result
        }

        return TextFloodFillResult(
            spans: spans,
            escaped: escaped,
            reachedLimit: cells.count >= maxCells)
    }
}
