import Foundation

extension String {
    /// Detects whether line is a markup list item (Markdown, Org-Mode, reST, AsciiDoc).
    public var isMarkupListItem: Bool {
        let trimmed = trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return false }

        // Markdown / Org / reST / AsciiDoc list prefixes:
        // - item, * item, + item, . item, .. item
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") || trimmed.hasPrefix(". ")
            || trimmed.hasPrefix(".. ")
        {
            return true
        }

        if let firstWord = trimmed.components(separatedBy: .whitespaces).first {
            if firstWord.range(of: #"^(\d+[\.\)]|[a-zA-Z][\.\)]|#\.|::)$"#, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }
}

extension TextBuffer {
    /// Detects whether line at index is a markup list item (Markdown, Org-Mode, reST, AsciiDoc).
    public func isListItemLine(at lineIndex: Int) -> Bool {
        guard lineIndex >= 0 && lineIndex < lines.count else { return false }
        return lines[lineIndex].isMarkupListItem
    }

    /// Indents the currently selected text block by injecting spaces at line starts.
    public func indentSelectedBlock(spaces: Int) {
        guard let mark = selectionMark else { return }
        let (start, end) = TextBuffer.getOrderedRange(
            mark1: mark, mark2: (line: lineIndex, column: columnIndex))
        let startLine = start.line
        let endLine = end.line

        for lineIdx in startLine...endLine {
            let padding = String(repeating: " ", count: spaces)
            lines[lineIdx] = padding + lines[lineIdx]
        }

        selectionMark = (line: mark.line, column: mark.column + spaces)
        columnIndex += spaces
    }

    /// Outdents the currently selected text block by removing up to `spaces` leading spaces from line starts.
    public func outdentSelectedBlock(spaces: Int) {
        guard let mark = selectionMark else { return }
        let (start, end) = TextBuffer.getOrderedRange(
            mark1: mark, mark2: (line: lineIndex, column: columnIndex))
        let startLine = start.line
        let endLine = end.line

        var startLineRemoved = 0
        var endLineRemoved = 0

        for lineIdx in startLine...endLine {
            let line = lines[lineIdx]
            var removed = 0
            while removed < spaces && line.hasPrefix(String(repeating: " ", count: removed + 1)) {
                removed += 1
            }
            if removed > 0 {
                lines[lineIdx] = String(line.dropFirst(removed))
            }
            if lineIdx == startLine { startLineRemoved = removed }
            if lineIdx == endLine { endLineRemoved = removed }
        }

        let removedMark = (mark.line == startLine) ? startLineRemoved : endLineRemoved
        selectionMark = (line: mark.line, column: max(0, mark.column - removedMark))

        let currentLineRemoved = (lineIndex == startLine) ? startLineRemoved : endLineRemoved
        columnIndex = max(0, columnIndex - currentLineRemoved)
    }

    /// Indents the line at lineIndex at the very beginning of the line.
    public func indentLine(at lineIndex: Int, spaces: Int) {
        guard lineIndex >= 0 && lineIndex < lines.count else { return }
        let padding = String(repeating: " ", count: spaces)
        lines[lineIndex] = padding + lines[lineIndex]
        if self.lineIndex == lineIndex {
            columnIndex += spaces
        }
    }

    /// Outdents the line at lineIndex by removing up to `spaces` leading spaces from line start.
    public func outdentLine(at lineIndex: Int, spaces: Int) {
        guard lineIndex >= 0 && lineIndex < lines.count else { return }
        let line = lines[lineIndex]
        var removed = 0
        while removed < spaces && line.hasPrefix(String(repeating: " ", count: removed + 1)) {
            removed += 1
        }
        if removed > 0 {
            lines[lineIndex] = String(line.dropFirst(removed))
            if self.lineIndex == lineIndex {
                columnIndex = max(0, columnIndex - removed)
            }
        }
    }
}
