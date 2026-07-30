import Foundation

public enum VisualColumnSnapDirection: Sendable, Equatable {
    case backward
    case forward
}

public enum VisualColumnWritePolicy: Sendable, Equatable {
    case replace
    case clear
}

public struct VisualColumnWriteResult: Sendable, Equatable {
    public let text: String
    public let characterOffsetAfterWrite: Int
    public let visualColumnAfterWrite: Int

    public init(text: String, characterOffsetAfterWrite: Int, visualColumnAfterWrite: Int) {
        self.text = text
        self.characterOffsetAfterWrite = characterOffsetAfterWrite
        self.visualColumnAfterWrite = visualColumnAfterWrite
    }
}

extension String {
    public func visualColumn(forCharacterOffset characterOffset: Int) -> Int {
        let chars = Array(self)
        let limit = max(0, min(characterOffset, chars.count))
        return chars[..<limit].reduce(0) { $0 + $1.displayWidth }
    }

    public func characterOffset(forVisualColumn visualColumn: Int) -> Int {
        let target = max(0, visualColumn)
        var currentVisualColumn = 0

        for (idx, ch) in self.enumerated() {
            let nextVisualColumn = currentVisualColumn + ch.displayWidth
            if nextVisualColumn > target {
                return idx
            }
            currentVisualColumn = nextVisualColumn
        }

        return count
    }

    public func snappedVisualColumn(
        _ visualColumn: Int,
        direction: VisualColumnSnapDirection = .backward
    ) -> Int {
        let target = max(0, visualColumn)
        var currentVisualColumn = 0

        for ch in self {
            let nextVisualColumn = currentVisualColumn + ch.displayWidth
            if target == currentVisualColumn {
                return currentVisualColumn
            }
            if target > currentVisualColumn && target < nextVisualColumn {
                return direction == .backward ? currentVisualColumn : nextVisualColumn
            }
            currentVisualColumn = nextVisualColumn
        }

        return min(target, currentVisualColumn)
    }

    public func writingAtVisualColumn(
        _ visualColumn: Int,
        character: Character,
        policy: VisualColumnWritePolicy = .replace,
        snapDirection: VisualColumnSnapDirection = .backward
    ) -> VisualColumnWriteResult {
        let targetVisualColumn = max(0, visualColumn)
        var chars = Array(self)
        let currentWidth = displayWidth

        if targetVisualColumn > currentWidth {
            chars.append(contentsOf: String(repeating: " ", count: targetVisualColumn - currentWidth))
        }

        let paddedLine = String(chars)
        let startVisualColumn =
            targetVisualColumn > paddedLine.displayWidth
            ? targetVisualColumn : paddedLine.snappedVisualColumn(targetVisualColumn, direction: snapDirection)

        let startOffset = paddedLine.characterOffset(forVisualColumn: startVisualColumn)
        chars = Array(paddedLine)

        switch policy {
        case .clear:
            guard startOffset < chars.count else {
                return VisualColumnWriteResult(
                    text: String(chars),
                    characterOffsetAfterWrite: startOffset,
                    visualColumnAfterWrite: startVisualColumn)
            }

            let clearedWidth = chars[startOffset].displayWidth
            chars.remove(at: startOffset)
            chars.insert(contentsOf: String(repeating: " ", count: clearedWidth), at: startOffset)

            return VisualColumnWriteResult(
                text: String(chars),
                characterOffsetAfterWrite: startOffset + clearedWidth,
                visualColumnAfterWrite: startVisualColumn + clearedWidth)

        case .replace:
            let replacementWidth = character.displayWidth
            let endVisualColumn = startVisualColumn + replacementWidth

            var removeEndOffset = startOffset
            var removedWidth = 0
            var scanVisualColumn = startVisualColumn

            while removeEndOffset < chars.count && scanVisualColumn < endVisualColumn {
                let width = chars[removeEndOffset].displayWidth
                removedWidth += width
                scanVisualColumn += width
                removeEndOffset += 1
            }

            if removeEndOffset > startOffset {
                chars.removeSubrange(startOffset..<removeEndOffset)
            }

            var inserted = [character]
            if removedWidth > replacementWidth {
                inserted.append(contentsOf: String(repeating: " ", count: removedWidth - replacementWidth))
            }
            chars.insert(contentsOf: inserted, at: startOffset)

            return VisualColumnWriteResult(
                text: String(chars),
                characterOffsetAfterWrite: startOffset + inserted.count,
                visualColumnAfterWrite: startVisualColumn + max(replacementWidth, removedWidth))
        }
    }

    public func clearingAtVisualColumn(
        _ visualColumn: Int,
        snapDirection: VisualColumnSnapDirection = .backward
    ) -> VisualColumnWriteResult {
        writingAtVisualColumn(
            visualColumn,
            character: " ",
            policy: .clear,
            snapDirection: snapDirection)
    }
}
