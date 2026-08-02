import Foundation
import TextMetrics

public struct WhereIsCommand: Command {
    public let id: CommandID = .searchWhereIs
    public let name = "Where Is"
    public let description = "Search text"
    public let keys: [Key] = [.ctrl("W"), .f6]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptSearch()
    }
}

public struct SearchCommand: Command {
    public let id: CommandID = .searchWhereIs
    public let name = "Search"
    public let description = "Search text with /<query>"
    public let commandBarAliases: [String] = ["/"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        input.text.hasPrefix("/")
    }

    public func execute(on editor: Editor) {
        editor.promptSearch()
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        let query = String(input.text.dropFirst())
        if !query.isEmpty {
            editor.lastSearchQuery = query
        }
        let targetQuery = !query.isEmpty ? query : editor.lastSearchQuery
        if targetQuery.isEmpty {
            editor.setStatusMessage(L10n["status.cancelled_search"])
            return .handled
        }

        editor.performSearch(query: targetQuery, useRegex: editor.isRegexSearchEnabled)
        return .handled
    }
}

public struct SubstituteCommand: Command {
    public let id: CommandID = .editJustify
    public let name = "Substitute"
    public let description = "Vim-style regex substitute s/search/replace/g"
    public let commandBarAliases: [String] = ["s", "%s"]

    public init() {}

    public func isAvailable(in editor: Editor) -> Bool {
        !editor.buffer.isReadOnly
    }

    public func match(_ input: CommandBarInput) -> Bool {
        let text = input.text
        if text.hasPrefix("%s") {
            let rest = text.dropFirst(2)
            return rest.hasPrefix("/") || rest.hasPrefix(",")
        } else if text.hasPrefix("s") {
            let rest = text.dropFirst(1)
            return rest.hasPrefix("/") || rest.hasPrefix(",")
        }
        return false
    }

    public func execute(on editor: Editor) {
        editor.setStatusMessage(L10n["status.path_required"])
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        guard let parsed = parse(input.text) else {
            editor.setStatusMessage(L10n["status.path_required"])
            return .handled
        }

        let isGlobal = parsed.flags.contains("g")
        let isCaseInsensitive = parsed.flags.contains("i")
        let useRegex = parsed.flags.contains("r") || editor.isRegexSearchEnabled

        let targetRange: ClosedRange<Int>
        if parsed.isPercent {
            targetRange = 0...(max(0, editor.buffer.lines.count - 1))
        } else if let mark = editor.selectionMark {
            let cursorLine = editor.buffer.lineIndex
            let startL = min(mark.line, cursorLine)
            let endL = max(mark.line, cursorLine)
            targetRange = max(0, startL)...min(endL, max(0, editor.buffer.lines.count - 1))
        } else {
            let cur = editor.buffer.lineIndex
            targetRange = cur...cur
        }

        var totalReplacements = 0
        var newLines = editor.buffer.lines

        if useRegex,
            let regex = try? NSRegularExpression(
                pattern: parsed.search,
                options: isCaseInsensitive ? [.caseInsensitive] : []
            )
        {
            for lIdx in targetRange {
                guard lIdx < newLines.count else { continue }
                let line = newLines[lIdx]
                let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
                let matches = regex.matches(in: line, options: [], range: nsRange)
                if matches.isEmpty { continue }

                if isGlobal {
                    totalReplacements += matches.count
                    let replaced = regex.stringByReplacingMatches(
                        in: line, options: [], range: nsRange, withTemplate: parsed.replace
                    )
                    newLines[lIdx] = replaced
                } else if let firstMatch = matches.first {
                    totalReplacements += 1
                    let replaced = regex.stringByReplacingMatches(
                        in: line, options: [], range: firstMatch.range, withTemplate: parsed.replace
                    )
                    newLines[lIdx] = replaced
                }
            }
        } else {
            let searchStr = parsed.search
            let replaceStr = parsed.replace
            let compareOptions: String.CompareOptions = isCaseInsensitive ? [.caseInsensitive] : []

            for lIdx in targetRange {
                guard lIdx < newLines.count else { continue }
                var line = newLines[lIdx]

                if isGlobal {
                    var searchStart = line.startIndex
                    var countOnLine = 0
                    while searchStart < line.endIndex,
                        let range = line.range(
                            of: searchStr, options: compareOptions, range: searchStart..<line.endIndex)
                    {
                        countOnLine += 1
                        line.replaceSubrange(range, with: replaceStr)
                        let newAdvance =
                            line.index(range.lowerBound, offsetBy: replaceStr.count, limitedBy: line.endIndex)
                            ?? line.endIndex
                        searchStart = newAdvance
                    }
                    if countOnLine > 0 {
                        totalReplacements += countOnLine
                        newLines[lIdx] = line
                    }
                } else {
                    if let range = line.range(of: searchStr, options: compareOptions) {
                        totalReplacements += 1
                        line.replaceSubrange(range, with: replaceStr)
                        newLines[lIdx] = line
                    }
                }
            }
        }

        if totalReplacements > 0 {
            editor.saveUndoSnapshot()
            editor.buffer.lines = newLines
            editor.buffer.isModified = true
            editor.setStatusMessage(L10n.replacedOccurrences(totalReplacements))
        } else {
            editor.setStatusMessage(L10n.notFound(query: parsed.search))
        }

        return .handled
    }

    private struct ParsedSubstitute {
        let isPercent: Bool
        let delimiter: Character
        let search: String
        let replace: String
        let flags: String
    }

    private func parse(_ raw: String) -> ParsedSubstitute? {
        var isPercent = false
        var restStr = raw

        if restStr.hasPrefix("%s") {
            isPercent = true
            restStr = String(restStr.dropFirst(2))
        } else if restStr.hasPrefix("s") {
            isPercent = false
            restStr = String(restStr.dropFirst(1))
        } else {
            return nil
        }

        guard let delim = restStr.first, delim == "/" || delim == "," else { return nil }
        restStr = String(restStr.dropFirst(1))

        let parts = restStr.split(separator: delim, omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2 else { return nil }

        let search = parts[0]
        let replace = parts[1]
        let flags = parts.count > 2 ? parts[2].lowercased() : ""

        guard !search.isEmpty else { return nil }
        return ParsedSubstitute(
            isPercent: isPercent, delimiter: delim, search: search, replace: replace, flags: flags
        )
    }
}

public struct OpenDocumentLinkCommand: Command {
    public let id: CommandID = .documentOpenLink
    public let name = "Open Link"
    public let description = "Open document link at cursor"
    public let keys: [Key] = [.alt("o"), .alt("O")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.openDocumentLinkAtCursor()
    }
}

public struct GotoLineCommand: Command {
    public let id: CommandID = .cursorGotoLine
    public let name = "Go To Line"
    public let description = "Jump to line and column number"
    public let keys: [Key] = [.ctrl("/"), .ctrl("_"), .alt("g"), .alt("G"), .alt("/")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptGotoLine()
    }
}

public struct NumericGotoCommand: Command {
    public let id: CommandID = .cursorGotoLine
    public let name = "Goto Line"
    public let description = "Jump to line or line:column"
    public let commandBarAliases: [String] = ["goto"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        input.text.range(of: #"^-?\d+([:,]-?\d+)?$"#, options: .regularExpression) != nil
    }

    public func execute(on editor: Editor) {
        editor.promptGotoLine()
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        let parts = input.text.split(whereSeparator: { $0 == ":" || $0 == "," }).map(String.init)
        guard let first = parts.first, let line = Int(first), line > 0 else {
            editor.setStatusMessage(L10n["status.invalid_line"])
            return .handled
        }

        if parts.count == 2 {
            guard let col = Int(parts[1]), col > 0 else {
                editor.setStatusMessage(L10n["status.invalid_column"])
                return .handled
            }
            editor.goToLocation(line: line, column: col)
        } else {
            editor.goToLocation(line: line)
        }

        return .handled
    }
}

public struct RefreshScreenCommand: Command {
    public let id: CommandID = .screenRefresh
    public let name = "Refresh"
    public let description = "Refresh screen"
    public let keys: [Key] = [.ctrl("L")]

    public init() {}

    public func execute(on editor: Editor) {}
}

public struct ShowCursorPosCommand: Command {
    public let id: CommandID = .cursorPos
    public let name = "Cur Pos"
    public let description = "Display cursor position"
    public let keys: [Key] = [.ctrl("C"), .f11]

    public init() {}

    public func execute(on editor: Editor) {
        let currentLine = editor.buffer.lineIndex + 1
        let totalLines = editor.buffer.lines.count
        let percent = totalLines > 0 ? Int(Double(currentLine) / Double(totalLines) * 100) : 100
        let currentCol = editor.buffer.columnIndex + 1
        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let totalCol = line.count + 1
        let visualCol =
            editor.isCanvasModeActive
            ? editor.canvasVisualColumn + 1
            : line.visualColumn(forCharacterOffset: editor.buffer.columnIndex) + 1
        let totalVisualCol = line.displayWidth + 1
        editor.setStatusMessage(
            L10n.cursorInfo(
                currentLine: currentLine, totalLines: totalLines, percent: percent, currentCol: currentCol,
                totalCol: totalCol, visualCol: visualCol, totalVisualCol: totalVisualCol))
    }
}
