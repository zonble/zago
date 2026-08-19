import Foundation

enum SearchDirection {
    case forward
    case backward
}

/// Controller managing text search state and search candidate execution.
final class SearchController: KeyInputHandler {
    weak var editor: Editor?

    struct SearchMatch: Sendable, Equatable {
        let query: String
        let line: Int
        let column: Int
        let length: Int
        let usesRegex: Bool

        init(query: String, line: Int, column: Int, length: Int, usesRegex: Bool) {
            self.query = query
            self.line = line
            self.column = column
            self.length = length
            self.usesRegex = usesRegex
        }
    }

    var lastSearchQuery: String = ""

    init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// KeyInputHandler protocol implementation.
    func handleKey(_ key: Key) -> Bool {
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
    func clearActiveSearch(setStatus: Bool = true) -> Bool {
        guard let editor, editor.buffer.activeSearchMatch != nil else { return false }
        editor.buffer.activeSearchMatch = nil
        if setStatus {
            editor.reportOperationResult(.succeeded(message: editor.l10n["status.search_cleared"]))
        }
        return true
    }

    func isSearchMatchCharacter(line: Int, col: Int) -> Bool {
        guard let editor, let match = editor.buffer.activeSearchMatch else { return false }
        return line == match.line && col >= match.column && col < match.column + match.length
    }

    func findNextSearchMatch() {
        repeatSearch(direction: .forward)
    }

    func findPreviousSearchMatch() {
        repeatSearch(direction: .backward)
    }

    /// Performs search operation for target query string.
    func performSearch(
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
            editor.reportOperationResult(.noOp(message: editor.l10n["status.no_active_search"]))
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
                editor.reportOperationResult(
                    .failed(
                        error.localizedDescription,
                        message: String(format: editor.l10n["status.invalid_regex"], error.localizedDescription)))
                return
            }
        } else {
            candidates = plainSearchCandidates(query: query)
        }

        guard !candidates.isEmpty else {
            editor.buffer.activeSearchMatch = nil
            lastSearchQuery = query
            editor.reportOperationResult(.noOp(message: editor.l10n.notFound(query: query)))
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
            let searchRange: Range<String.Index>
            let columnOffset: Int
            if editor.isTableModeActive, let bounds = editor.tableModeController.currentCellInnerBounds(on: lineIndex) {
                let start = line.index(line.startIndex, offsetBy: bounds.start)
                let end = line.index(line.startIndex, offsetBy: bounds.end)
                searchRange = start..<end
                columnOffset = bounds.start
            } else if editor.isTableModeActive {
                continue
            } else {
                searchRange = line.startIndex..<line.endIndex
                columnOffset = 0
            }

            var searchStart = searchRange.lowerBound
            while searchStart < searchRange.upperBound,
                let range = line.range(
                    of: query, options: [.caseInsensitive], range: searchStart..<searchRange.upperBound)
            {
                let column = line.distance(from: line.startIndex, to: range.lowerBound)
                let length = line.distance(from: range.lowerBound, to: range.upperBound)
                if length > 0, column >= columnOffset {
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
            let searchRange: Range<String.Index>
            if editor.isTableModeActive, let bounds = editor.tableModeController.currentCellInnerBounds(on: lineIndex) {
                let start = line.index(line.startIndex, offsetBy: bounds.start)
                let end = line.index(line.startIndex, offsetBy: bounds.end)
                searchRange = start..<end
            } else if editor.isTableModeActive {
                continue
            } else {
                searchRange = line.startIndex..<line.endIndex
            }

            let nsRange = NSRange(searchRange, in: line)
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
            editor.reportOperationResult(
                .succeeded(message: editor.l10n.searchWrappedFound(query: query, line: candidate.line + 1)))
        } else {
            editor.reportOperationResult(
                .succeeded(message: editor.l10n.foundQueryAtLine(query: query, line: candidate.line + 1)))
        }
    }

    /// Starts interactive search & replace workflow.
    func startInteractiveReplace(query: String, replacement: String) {
        guard let editor else { return }
        editor.saveUndoSnapshot()

        let candidates =
            editor.isRegexSearchEnabled
            ? (try? NSRegularExpression(pattern: query, options: [.caseInsensitive])).map {
                regexSearchCandidates(regex: $0)
            } ?? []
            : plainSearchCandidates(query: query)

        guard !candidates.isEmpty else {
            editor.buffer.activeSearchMatch = nil
            lastSearchQuery = query
            editor.reportOperationResult(.noOp(message: editor.l10n.notFound(query: query)))
            return
        }

        runInteractiveReplaceStep(query: query, replacement: replacement, candidateIndex: 0, replacedCount: 0)
    }

    private func runInteractiveReplaceStep(
        query: String,
        replacement: String,
        candidateIndex: Int,
        replacedCount: Int
    ) {
        guard let editor else { return }

        let candidates =
            editor.isRegexSearchEnabled
            ? (try? NSRegularExpression(pattern: query, options: [.caseInsensitive])).map {
                regexSearchCandidates(regex: $0)
            } ?? []
            : plainSearchCandidates(query: query)

        guard candidateIndex < candidates.count else {
            editor.buffer.activeSearchMatch = nil
            editor.reportOperationResult(
                .succeeded(message: editor.l10n.replacedOccurrences(replacedCount))
            )
            return
        }

        let candidate = candidates[candidateIndex]
        editor.buffer.lineIndex = candidate.line
        editor.buffer.columnIndex = candidate.column
        editor.buffer.activeSearchMatch = SearchMatch(
            query: query,
            line: candidate.line,
            column: candidate.column,
            length: candidate.length,
            usesRegex: editor.isRegexSearchEnabled
        )

        editor.currentPromptMode = .confirmReplace(query: query, replacement: replacement) { [weak self] choice in
            guard let self = self, let editor = self.editor else { return }
            switch choice {
            case .yes:
                self.replaceCandidate(candidate, with: replacement)
                self.runInteractiveReplaceStep(
                    query: query,
                    replacement: replacement,
                    candidateIndex: candidateIndex,
                    replacedCount: replacedCount + 1
                )

            case .no:
                self.runInteractiveReplaceStep(
                    query: query,
                    replacement: replacement,
                    candidateIndex: candidateIndex + 1,
                    replacedCount: replacedCount
                )

            case .all:
                var count = replacedCount
                while true {
                    let remaining =
                        editor.isRegexSearchEnabled
                        ? (try? NSRegularExpression(pattern: query, options: [.caseInsensitive])).map {
                            self.regexSearchCandidates(regex: $0)
                        } ?? []
                        : self.plainSearchCandidates(query: query)
                    guard
                        let first = remaining.first(where: {
                            self.isAtOrAfter($0, line: candidate.line, column: 0, includeEqual: true)
                        }) ?? remaining.first
                    else {
                        break
                    }
                    self.replaceCandidate(first, with: replacement)
                    count += 1
                }
                editor.buffer.activeSearchMatch = nil
                editor.reportOperationResult(
                    .succeeded(message: editor.l10n.replacedOccurrences(count))
                )

            case .cancel:
                editor.buffer.activeSearchMatch = nil
                editor.reportOperationResult(
                    .succeeded(message: editor.l10n.replacedOccurrences(replacedCount))
                )
            }
        }
    }

    private func replaceCandidate(_ candidate: SearchCandidate, with replacement: String) {
        guard let editor else { return }
        guard candidate.line < editor.buffer.lines.count else { return }
        var line = editor.buffer.lines[candidate.line]
        guard candidate.column + candidate.length <= line.count else { return }
        let startIdx = line.index(line.startIndex, offsetBy: candidate.column)
        let endIdx = line.index(startIdx, offsetBy: candidate.length)
        line.replaceSubrange(startIdx..<endIdx, with: replacement)
        editor.buffer.lines[candidate.line] = line
        editor.buffer.columnIndex = candidate.column + replacement.count
        editor.buffer.isModified = true
    }
}
