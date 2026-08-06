import Foundation

enum SearchDirection {
    case forward
    case backward
}

extension Editor {
    @discardableResult
    func clearActiveSearch(setStatus: Bool = true) -> Bool {
        guard buffer.activeSearchMatch != nil else { return false }
        buffer.activeSearchMatch = nil
        if setStatus {
            setStatusMessage(l10n["status.search_cleared"])
        }
        return true
    }

    func isSearchMatchCharacter(line: Int, col: Int) -> Bool {
        guard let match = buffer.activeSearchMatch else { return false }
        return line == match.line && col >= match.column && col < match.column + match.length
    }

    func findNextSearchMatch() {
        repeatSearch(direction: .forward)
    }

    func findPreviousSearchMatch() {
        repeatSearch(direction: .backward)
    }

    /// Performs search operation for target query string.
    func performSearch(query: String, useRegex: Bool = false, direction: SearchDirection = .forward) {
        let activeRegex = useRegex || isRegexSearchEnabled
        search(
            query: query,
            useRegex: activeRegex,
            direction: direction,
            anchor: (line: buffer.lineIndex, column: buffer.columnIndex),
            includeAnchor: true
        )
    }

    private func repeatSearch(direction: SearchDirection) {
        let query = buffer.activeSearchMatch?.query ?? lastSearchQuery
        guard !query.isEmpty else {
            setStatusMessage(l10n["status.no_active_search"])
            return
        }

        let activeRegex = buffer.activeSearchMatch?.usesRegex ?? isRegexSearchEnabled
        let anchor: (line: Int, column: Int)
        if let match = buffer.activeSearchMatch {
            switch direction {
            case .forward:
                anchor = (line: match.line, column: match.column + max(1, match.length))
            case .backward:
                anchor = (line: match.line, column: match.column)
            }
        } else {
            anchor = (line: buffer.lineIndex, column: buffer.columnIndex)
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
        guard !query.isEmpty else { return }

        let candidates: [SearchCandidate]
        if useRegex {
            do {
                let regex = try NSRegularExpression(pattern: query, options: [.caseInsensitive])
                candidates = regexSearchCandidates(regex: regex)
            } catch {
                buffer.activeSearchMatch = nil
                setStatusMessage(String(format: l10n["status.invalid_regex"], error.localizedDescription))
                return
            }
        } else {
            candidates = plainSearchCandidates(query: query)
        }

        guard !candidates.isEmpty else {
            buffer.activeSearchMatch = nil
            lastSearchQuery = query
            setStatusMessage(l10n.notFound(query: query))
            return
        }

        let clampedAnchorLine = max(0, min(anchor.line, max(0, buffer.lines.count - 1)))
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
        var candidates: [SearchCandidate] = []
        for (lineIndex, line) in buffer.lines.enumerated() {
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
        var candidates: [SearchCandidate] = []
        for (lineIndex, line) in buffer.lines.enumerated() {
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
        buffer.lineIndex = candidate.line
        buffer.columnIndex = candidate.column
        buffer.activeSearchMatch = SearchMatch(
            query: query,
            line: candidate.line,
            column: candidate.column,
            length: candidate.length,
            usesRegex: useRegex
        )
        lastSearchQuery = query
        if wrapped {
            setStatusMessage(l10n.searchWrappedFound(query: query, line: candidate.line + 1))
        } else {
            setStatusMessage(l10n.foundQueryAtLine(query: query, line: candidate.line + 1))
        }
    }
}
