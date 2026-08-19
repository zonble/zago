import Foundation
import TextMetrics

/// The way a rendered box row is merged into existing text.
public enum TextBoxRenderMode: Sendable {
    case insert
    case overlay
}

/// Pure text layout and row-merging operations shared by drawing clients.
public struct TextBoxRenderer: Sendable {
    public init() {}

    public func insetRows(
        text: String,
        width: Int,
        height: Int
    ) -> (rows: [String], targetRow: Int, targetColumn: Int) {
        let textLines = text.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        let startRow = max(0, (height - textLines.count) / 2)
        let rows = (0..<height).map { row in
            guard row >= startRow, row - startRow < textLines.count else {
                return String(repeating: " ", count: width)
            }

            let line = textLines[row - startRow]
            let textWidth = line.displayWidth
            let offset = max(0, (width - textWidth) / 2)
            return String(repeating: " ", count: offset)
                + line
                + String(repeating: " ", count: max(0, width - offset - textWidth))
        }

        let targetTextWidth = textLines.first?.displayWidth ?? text.displayWidth
        let targetColumn = max(0, (width - targetTextWidth) / 2) + targetTextWidth
        return (rows, startRow, targetColumn)
    }

    public func frameRows(width: Int, height: Int, style: BoxStyle) -> [String] {
        guard width > 0, height > 0 else { return [] }

        return (0..<height).map { row in
            let isTop = row == 0
            let isBottom = row == height - 1
            return (0..<width).map { column -> Character in
                let isLeft = column == 0
                let isRight = column == width - 1
                if isTop && isLeft { return style.topLeft }
                if isTop && isRight { return style.topRight }
                if isBottom && isLeft { return style.bottomLeft }
                if isBottom && isRight { return style.bottomRight }
                if isTop { return style.topChar }
                if isBottom { return style.bottomChar }
                if isLeft || isRight { return style.sideChar }
                return " "
            }
            .reduce(into: "") { $0.append($1) }
        }
    }

    public func textBoxRows(
        text: String,
        targetWidth: Int?,
        targetHeight: Int?,
        alignment: BoxAlignment = .left,
        style: BoxStyle
    ) -> (rows: [String], width: Int, height: Int) {
        let rawLines = text.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        let maxVisualWidth = rawLines.map(\.displayWidth).max() ?? 0
        let width = targetWidth ?? (maxVisualWidth + 4)
        let innerWidth = max(1, width - 2)
        var textLines: [String] = []
        for rawLine in rawLines {
            textLines.append(contentsOf: wrapTextLine(rawLine, maxWidth: innerWidth))
        }

        let height = max(targetHeight ?? 0, textLines.count + 2)
        let rows = (0..<height).map { row -> String in
            if row == 0 {
                return String(style.topLeft)
                    + String(repeating: style.topChar, count: innerWidth)
                    + String(style.topRight)
            }
            if row == height - 1 {
                return String(style.bottomLeft)
                    + String(repeating: style.bottomChar, count: innerWidth)
                    + String(style.bottomRight)
            }

            let line = row - 1 < textLines.count ? textLines[row - 1] : ""
            let textWidth = line.displayWidth
            let offset: Int
            switch alignment {
            case .center:
                offset = max(0, (innerWidth - textWidth) / 2)
            case .right:
                offset = max(0, innerWidth - textWidth)
            case .left:
                offset = innerWidth > textWidth ? 1 : 0
            }

            return String(style.sideChar)
                + String(repeating: " ", count: offset)
                + line
                + String(repeating: " ", count: max(0, innerWidth - offset - textWidth))
                + String(style.sideChar)
        }
        return (rows, width, height)
    }

    public func mergeRow(
        existingLine: String,
        startCol: Int,
        row: String,
        isTop: Bool,
        isBottom: Bool,
        mode: TextBoxRenderMode
    ) -> String {
        switch mode {
        case .insert:
            return mergeInsertedRow(
                existingLine: existingLine, startCol: startCol, row: row, isTop: isTop, isBottom: isBottom)
        case .overlay:
            return mergeOverlayRow(
                existingLine: existingLine, startCol: startCol, row: row, isTop: isTop, isBottom: isBottom)
        }
    }

    private func mergeInsertedRow(existingLine: String, startCol: Int, row: String, isTop: Bool, isBottom: Bool)
        -> String
    {
        var prefix = ""
        var suffix = ""
        var firstOverlap: Character?
        var currentWidth = 0

        for (offset, character) in existingLine.enumerated() {
            let width = character.displayWidth
            if currentWidth + width <= startCol {
                prefix.append(character)
            } else {
                firstOverlap = character
                suffix = String(existingLine.dropFirst(offset))
                break
            }
            currentWidth += width
        }

        if prefix.displayWidth < startCol {
            prefix += String(repeating: " ", count: startCol - prefix.displayWidth)
        }

        return prefix
            + mergeRenderedRow(
                row: row, isTop: isTop, isBottom: isBottom,
                existing: { position in
                    position == 0 ? firstOverlap : nil
                }) + suffix
    }

    private func mergeOverlayRow(existingLine: String, startCol: Int, row: String, isTop: Bool, isBottom: Bool)
        -> String
    {
        var prefix = ""
        var suffix = ""
        var existingRegion: [Character] = []
        var currentWidth = 0
        let rowWidth = row.displayWidth

        for character in existingLine {
            let width = character.displayWidth
            if currentWidth + width <= startCol {
                prefix.append(character)
            } else if currentWidth < startCol + rowWidth {
                existingRegion.append(character)
            } else {
                suffix.append(character)
            }
            currentWidth += width
        }

        if prefix.displayWidth < startCol {
            prefix += String(repeating: " ", count: startCol - prefix.displayWidth)
        }

        return prefix
            + mergeRenderedRow(
                row: row, isTop: isTop, isBottom: isBottom,
                existing: { position in
                    var width = 0
                    for character in existingRegion {
                        if width == position { return character }
                        width += character.displayWidth
                    }
                    return nil
                }) + suffix
    }

    private func mergeRenderedRow(
        row: String,
        isTop: Bool,
        isBottom: Bool,
        existing: (Int) -> Character?
    ) -> String {
        var result = ""
        var position = 0
        for character in row {
            let isLeft = position == 0
            let isRight = position + character.displayWidth == row.displayWidth
            let mask: UInt8
            if isTop && isLeft {
                mask = 6
            } else if isTop && isRight {
                mask = 12
            } else if isBottom && isLeft {
                mask = 3
            } else if isBottom && isRight {
                mask = 9
            } else if isTop || isBottom {
                mask = 10
            } else if isLeft || isRight {
                mask = 5
            } else {
                mask = 0
            }

            if mask != 0, let existingCharacter = existing(position) {
                result.append(
                    fuseLineCharacter(
                        existing: existingCharacter,
                        defaultNewCharacter: character,
                        addingMask: mask
                    ))
            } else {
                result.append(character)
            }
            position += character.displayWidth
        }
        return result
    }

    private func wrapTextLine(_ text: String, maxWidth: Int) -> [String] {
        guard text.displayWidth > maxWidth, maxWidth > 0 else { return [text] }
        var result: [String] = []
        var currentLine = ""

        for word in text.components(separatedBy: " ") {
            let wordWidth = word.displayWidth
            if wordWidth > maxWidth {
                if !currentLine.isEmpty {
                    result.append(currentLine)
                    currentLine = ""
                }
                var chunk = ""
                for character in word {
                    if chunk.displayWidth + character.displayWidth > maxWidth, !chunk.isEmpty {
                        result.append(chunk)
                        chunk = String(character)
                    } else {
                        chunk.append(character)
                    }
                }
                currentLine = chunk
            } else if currentLine.isEmpty {
                currentLine = word
            } else if currentLine.displayWidth + 1 + wordWidth <= maxWidth {
                currentLine += " " + word
            } else {
                result.append(currentLine)
                currentLine = word
            }
        }
        if !currentLine.isEmpty { result.append(currentLine) }
        return result
    }
}
