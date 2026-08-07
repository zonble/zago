import Foundation

public enum SearchDirection {
    case forward
    case backward
}

/// Controller managing text search state and search candidate execution.
public final class SearchController: KeyInputHandler {
    public weak var editor: Editor?

    public struct SearchMatch: Sendable, Equatable {
        public let query: String
        public let line: Int
        public let column: Int
        public let length: Int
        public let usesRegex: Bool

        public init(query: String, line: Int, column: Int, length: Int, usesRegex: Bool) {
            self.query = query
            self.line = line
            self.column = column
            self.length = length
            self.usesRegex = usesRegex
        }
    }

    public var lastSearchQuery: String = ""

    public init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// KeyInputHandler protocol implementation.
    public func handleKey(_ key: Key) -> Bool {
        switch key {
        case .ctrl("W"), .f6:
            editor?.promptSearch()
            return true
        case .alt("n"), .alt("N"):
            findNextSearchMatch()
            return true
        case .alt("p"), .alt("P"):
            findPreviousSearchMatch()
            return true
        default:
            return false
        }
    }

    @discardableResult
    public func clearActiveSearch(setStatus: Bool = true) -> Bool {
        guard let editor, editor.buffer.activeSearchMatch != nil else { return false }
        editor.buffer.activeSearchMatch = nil
        if setStatus {
            editor.setStatusMessage(editor.l10n["status.search_cleared"])
        }
        return true
    }

    public func isSearchMatchCharacter(line: Int, col: Int) -> Bool {
        guard let editor, let match = editor.buffer.activeSearchMatch else { return false }
        return line == match.line && col >= match.column && col < match.column + match.length
    }

    public func findNextSearchMatch() {
        repeatSearch(direction: .forward)
    }

    public func findPreviousSearchMatch() {
        repeatSearch(direction: .backward)
    }

    /// Performs search operation for target query string.
    public func performSearch(
        query: String,
        useRegex: Bool = false,
        direction: SearchDirection = .forward
    ) {
        guard let editor else { return }
        let activeRegex = useRegex || editor.isRegexSearchEnabled
        search(
            query: query,
            useRegex: activeRegex,
            direction: direction,
            anchor: (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex),
            includeAnchor: true
        )
    }

    private func repeatSearch(direction: SearchDirection) {
        guard let editor else { return }
        let query = editor.buffer.activeSearchMatch?.query ?? lastSearchQuery
        guard !query.isEmpty else {
            editor.setStatusMessage(editor.l10n["status.no_active_search"])
            return
        }

        let activeRegex = editor.buffer.activeSearchMatch?.usesRegex ?? editor.isRegexSearchEnabled
        let anchor: (line: Int, column: Int)
        if let match = editor.buffer.activeSearchMatch {
            switch direction {
            case .forward:
                anchor = (line: match.line, column: match.column + max(1, match.length))
            case .backward:
                anchor = (line: match.line, column: match.column)
            }
        } else {
            anchor = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
        }

        search(query: query, useRegex: activeRegex, direction: direction, anchor: anchor, includeAnchor: false)
    }

    private struct SearchCandidate: Equatable {
        let line: Int
        let column: Int
        let length: Int
    }

    private func search(
        query: String,
        useRegex: Bool,
        direction: SearchDirection,
        anchor: (line: Int, column: Int),
        includeAnchor: Bool
    ) {
        guard let editor, !query.isEmpty else { return }

        let candidates: [SearchCandidate]
        if useRegex {
            do {
                let regex = try NSRegularExpression(pattern: query, options: [.caseInsensitive])
                candidates = regexSearchCandidates(regex: regex)
            } catch {
                editor.buffer.activeSearchMatch = nil
                editor.setStatusMessage(String(format: editor.l10n["status.invalid_regex"], error.localizedDescription))
                return
            }
        } else {
            candidates = plainSearchCandidates(query: query)
        }

        guard !candidates.isEmpty else {
            editor.buffer.activeSearchMatch = nil
            lastSearchQuery = query
            editor.setStatusMessage(editor.l10n.notFound(query: query))
            return
        }

        let clampedAnchorLine = max(0, min(anchor.line, max(0, editor.buffer.lines.count - 1)))
        let clampedAnchorColumn = max(0, anchor.column)
        let selected: (candidate: SearchCandidate, wrapped: Bool)
        switch direction {
        case .forward:
            if let candidate = candidates.first(where: {
                isAtOrAfter($0, line: clampedAnchorLine, column: clampedAnchorColumn, includeEqual: includeAnchor)
            }) {
                selected = (candidate: candidate, wrapped: false)
            } else {
                selected = (candidate: candidates[0], wrapped: true)
            }
        case .backward:
            if let candidate = candidates.last(where: {
                isBefore($0, line: clampedAnchorLine, column: clampedAnchorColumn, includeEqual: includeAnchor)
            }) {
                selected = (candidate: candidate, wrapped: false)
            } else {
                selected = (candidate: candidates[candidates.count - 1], wrapped: true)
            }
        }

        applySearchCandidate(selected.candidate, query: query, useRegex: useRegex, wrapped: selected.wrapped)
    }

    private func plainSearchCandidates(query: String) -> [SearchCandidate] {
        guard let editor else { return [] }
        var candidates: [SearchCandidate] = []
        for (lineIndex, line) in editor.buffer.lines.enumerated() {
            var searchStart = line.startIndex
            while searchStart < line.endIndex,
                let range = line.range(of: query, options: [.caseInsensitive], range: searchStart..<line.endIndex)
            {
                let column = line.distance(from: line.startIndex, to: range.lowerBound)
                let length = line.distance(from: range.lowerBound, to: range.upperBound)
                if length > 0 {
                    candidates.append(SearchCandidate(line: lineIndex, column: column, length: length))
                }
                searchStart = range.upperBound
            }
        }
        return candidates
    }

    private func regexSearchCandidates(regex: NSRegularExpression) -> [SearchCandidate] {
        guard let editor else { return [] }
        var candidates: [SearchCandidate] = []
        for (lineIndex, line) in editor.buffer.lines.enumerated() {
            let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
            let matches = regex.matches(in: line, options: [], range: nsRange)
            for match in matches {
                guard match.range.length > 0, let range = Range(match.range(at: 0), in: line) else { continue }
                let column = line.distance(from: line.startIndex, to: range.lowerBound)
                let length = line.distance(from: range.lowerBound, to: range.upperBound)
                candidates.append(SearchCandidate(line: lineIndex, column: column, length: length))
            }
        }
        return candidates
    }

    private func isAtOrAfter(
        _ candidate: SearchCandidate,
        line: Int,
        column: Int,
        includeEqual: Bool
    ) -> Bool {
        if candidate.line > line { return true }
        if candidate.line < line { return false }
        return includeEqual ? candidate.column >= column : candidate.column > column
    }

    private func isBefore(
        _ candidate: SearchCandidate,
        line: Int,
        column: Int,
        includeEqual: Bool
    ) -> Bool {
        if candidate.line < line { return true }
        if candidate.line > line { return false }
        return includeEqual ? candidate.column <= column : candidate.column < column
    }

    private func applySearchCandidate(
        _ candidate: SearchCandidate,
        query: String,
        useRegex: Bool,
        wrapped: Bool
    ) {
        guard let editor else { return }
        editor.buffer.lineIndex = candidate.line
        editor.buffer.columnIndex = candidate.column
        editor.buffer.activeSearchMatch = SearchMatch(
            query: query,
            line: candidate.line,
            column: candidate.column,
            length: candidate.length,
            usesRegex: useRegex
        )
        lastSearchQuery = query
        if wrapped {
            editor.setStatusMessage(editor.l10n.searchWrappedFound(query: query, line: candidate.line + 1))
        } else {
            editor.setStatusMessage(editor.l10n.foundQueryAtLine(query: query, line: candidate.line + 1))
        }
    }
}
