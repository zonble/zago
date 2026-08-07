import Foundation

// MARK: - Editor Smart Tab, Indent & Outdent Extension

extension Editor {
    /// Detects whether line at index is a markup list item (Markdown, Org-Mode, reST, AsciiDoc).
    public func isListItemLine(at lineIndex: Int) -> Bool {
        guard lineIndex >= 0 && lineIndex < buffer.lines.count else { return false }
        let trimmed = buffer.lines[lineIndex].trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return false }

        // Markdown / Org / reST / AsciiDoc list prefixes:
        // - item, * item, + item, . item, .. item
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") ||
            trimmed.hasPrefix(". ") || trimmed.hasPrefix(".. ") {
            return true
        }

        if let firstWord = trimmed.components(separatedBy: .whitespaces).first {
            if firstWord.range(of: #"^(\d+[\.\)]|[a-zA-Z][\.\)]|#\.|::)$"#, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    /// Indents the currently selected text block by injecting spaces at line starts.
    public func indentSelectedBlock(spaces: Int) {
        guard let mark = buffer.selectionMark else { return }
        let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
        let startLine = start.line
        let endLine = end.line

        for lineIdx in startLine...endLine {
            let padding = String(repeating: " ", count: spaces)
            buffer.lines[lineIdx] = padding + buffer.lines[lineIdx]
        }

        buffer.selectionMark = (line: mark.line, column: mark.column + spaces)
        buffer.columnIndex += spaces
    }

    /// Outdents the currently selected text block by removing up to `spaces` leading spaces from line starts.
    public func outdentSelectedBlock(spaces: Int) {
        guard let mark = buffer.selectionMark else { return }
        let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
        let startLine = start.line
        let endLine = end.line

        var startLineRemoved = 0
        var endLineRemoved = 0

        for lineIdx in startLine...endLine {
            let line = buffer.lines[lineIdx]
            var removed = 0
            while removed < spaces && line.hasPrefix(String(repeating: " ", count: removed + 1)) {
                removed += 1
            }
            if removed > 0 {
                buffer.lines[lineIdx] = String(line.dropFirst(removed))
            }
            if lineIdx == startLine { startLineRemoved = removed }
            if lineIdx == endLine { endLineRemoved = removed }
        }

        let removedMark = (mark.line == startLine) ? startLineRemoved : endLineRemoved
        buffer.selectionMark = (line: mark.line, column: max(0, mark.column - removedMark))

        let currentLineRemoved = (buffer.lineIndex == startLine) ? startLineRemoved : endLineRemoved
        buffer.columnIndex = max(0, buffer.columnIndex - currentLineRemoved)
    }

    /// Indents the line at lineIndex at the very beginning of the line.
    public func indentLine(at lineIndex: Int, spaces: Int) {
        guard lineIndex >= 0 && lineIndex < buffer.lines.count else { return }
        let padding = String(repeating: " ", count: spaces)
        buffer.lines[lineIndex] = padding + buffer.lines[lineIndex]
        if buffer.lineIndex == lineIndex {
            buffer.columnIndex += spaces
        }
    }

    /// Outdents the line at lineIndex by removing up to `spaces` leading spaces from line start.
    public func outdentLine(at lineIndex: Int, spaces: Int) {
        guard lineIndex >= 0 && lineIndex < buffer.lines.count else { return }
        let line = buffer.lines[lineIndex]
        var removed = 0
        while removed < spaces && line.hasPrefix(String(repeating: " ", count: removed + 1)) {
            removed += 1
        }
        if removed > 0 {
            buffer.lines[lineIndex] = String(line.dropFirst(removed))
            if buffer.lineIndex == lineIndex {
                buffer.columnIndex = max(0, buffer.columnIndex - removed)
            }
        }
    }
}
