import Foundation
import TextMetrics

public struct WhereIsCommand: Command {
    public let id: CommandID = .searchWhereIs
    public let name = "Where Is"
    public let description = "Search text"
    public let keys: [Key] = [.ctrl("W"), .f6]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptSearch()
        return .prompting
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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptSearch()
        return .prompting
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        let query = String(input.text.dropFirst())
        if !query.isEmpty {
            editor.lastSearchQuery = query
        }
        let targetQuery = !query.isEmpty ? query : editor.lastSearchQuery
        if targetQuery.isEmpty {
            return .succeeded(message: editor.l10n["status.cancelled_search"])
        }

        editor.searchController.performSearch(query: targetQuery, useRegex: editor.isRegexSearchEnabled)
        return .succeeded
    }
}

public struct SearchNextCommand: Command {
    public let id: CommandID = .searchNext
    public let name = "Find Next"
    public let description = "Find next active search match"
    public let keys: [Key] = [.alt("n"), .alt("N")]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.searchController.findNextSearchMatch()
        return .succeeded
    }
}

public struct SearchPreviousCommand: Command {
    public let id: CommandID = .searchPrevious
    public let name = "Find Previous"
    public let description = "Find previous active search match"
    public let keys: [Key] = [.alt("p"), .alt("P")]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.searchController.findPreviousSearchMatch()
        return .succeeded
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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        let message = editor.l10n["status.path_required"]
        return .failed(message, message: message)
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard let parsed = parse(input.text) else {
            return .succeeded(message: editor.l10n["status.path_required"])
        }

        let isGlobal = parsed.flags.contains("g")
        let isCaseInsensitive = parsed.flags.contains("i")
        let useRegex = parsed.flags.contains("r") || editor.isRegexSearchEnabled

        if editor.isTableModeActive, editor.currentTableCell != nil {
            let result = substituteCurrentTableCell(
                parsed: parsed,
                editor: editor,
                isGlobal: isGlobal,
                isCaseInsensitive: isCaseInsensitive,
                useRegex: useRegex)
            if result.replacements > 0 {
                editor.saveUndoSnapshot()
                editor.buffer.lines = result.lines
                editor.buffer.isModified = true
                return .succeeded(message: editor.l10n.replacedOccurrences(result.replacements))
            } else {
                return .succeeded(message: editor.l10n.notFound(query: parsed.search))
            }
        }

        let targetRange: ClosedRange<Int>
        if parsed.isPercent {
            targetRange = 0...(max(0, editor.buffer.lines.count - 1))
        } else if let mark = editor.buffer.selectionMark {
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
            return .succeeded(message: editor.l10n.replacedOccurrences(totalReplacements))
        } else {
            return .succeeded(message: editor.l10n.notFound(query: parsed.search))
        }
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

    private func substituteCurrentTableCell(
        parsed: ParsedSubstitute,
        editor: Editor,
        isGlobal: Bool,
        isCaseInsensitive: Bool,
        useRegex: Bool
    ) -> (lines: [String], replacements: Int) {
        var totalReplacements = 0
        var newLines = editor.buffer.lines

        for lineIndex in newLines.indices {
            guard let bounds = editor.tableModeController.currentCellInnerBounds(on: lineIndex) else { continue }
            let line = newLines[lineIndex]
            let chars = Array(line)
            guard bounds.start <= bounds.end, bounds.end <= chars.count else { continue }
            let innerText = String(chars[bounds.start..<bounds.end])
            let innerWidth = innerText.displayWidth
            let replaced: String
            let replacements: Int

            if useRegex,
                let regex = try? NSRegularExpression(
                    pattern: parsed.search,
                    options: isCaseInsensitive ? [.caseInsensitive] : []
                )
            {
                let nsRange = NSRange(innerText.startIndex..<innerText.endIndex, in: innerText)
                let matches = regex.matches(in: innerText, options: [], range: nsRange)
                if matches.isEmpty { continue }
                if isGlobal {
                    replacements = matches.count
                    replaced = regex.stringByReplacingMatches(
                        in: innerText, options: [], range: nsRange, withTemplate: parsed.replace)
                } else if let firstMatch = matches.first {
                    replacements = 1
                    replaced = regex.stringByReplacingMatches(
                        in: innerText, options: [], range: firstMatch.range, withTemplate: parsed.replace)
                } else {
                    continue
                }
            } else {
                let compareOptions: String.CompareOptions = isCaseInsensitive ? [.caseInsensitive] : []
                if isGlobal {
                    var working = innerText
                    var searchStart = working.startIndex
                    var countOnLine = 0
                    while searchStart < working.endIndex,
                        let range = working.range(
                            of: parsed.search,
                            options: compareOptions,
                            range: searchStart..<working.endIndex)
                    {
                        countOnLine += 1
                        working.replaceSubrange(range, with: parsed.replace)
                        searchStart =
                            working.index(range.lowerBound, offsetBy: parsed.replace.count, limitedBy: working.endIndex)
                            ?? working.endIndex
                    }
                    guard countOnLine > 0 else { continue }
                    replacements = countOnLine
                    replaced = working
                } else {
                    guard let range = innerText.range(of: parsed.search, options: compareOptions) else { continue }
                    var working = innerText
                    working.replaceSubrange(range, with: parsed.replace)
                    replacements = 1
                    replaced = working
                }
            }

            let prefix = String(chars[..<bounds.start])
            let suffix = String(chars[bounds.end...])
            newLines[lineIndex] = prefix + replaced.paddedToDisplayWidth(innerWidth) + suffix
            totalReplacements += replacements
        }

        return (lines: newLines, replacements: totalReplacements)
    }
}

public struct OpenDocumentLinkCommand: Command {
    public let id: CommandID = .documentOpenLink
    public let name = "Open Link"
    public let description = "Open document link at cursor"
    public let keys: [Key] = [.alt("o"), .alt("O")]
    public let commandBarAliases = ["openlink", "open-link", "follow"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.openDocumentLinkAtCursor()
    }
}

public struct NextHeadingCommand: Command {
    public let id: CommandID = .documentHeadingNext
    public let name = "Next Heading"
    public let description = "Jump to next document heading"
    public let keys: [Key] = [.alt("]")]
    public let commandBarAliases = ["nextheading", "next-heading"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.documentOutlineController.goToNextHeading()
        return .succeeded
    }
}

public struct PreviousHeadingCommand: Command {
    public let id: CommandID = .documentHeadingPrevious
    public let name = "Previous Heading"
    public let description = "Jump to previous document heading"
    public let keys: [Key] = [.alt("[")]
    public let commandBarAliases = ["prevheading", "prev-heading"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.documentOutlineController.goToPreviousHeading()
        return .succeeded
    }
}

public struct DocumentOutlineCommand: Command {
    public let id: CommandID = .documentOutline
    public let name = "Outline"
    public let description = "Open document outline"
    public let keys: [Key] = [.alt("\\")]
    public let commandBarAliases = ["outline", "toc", "headings"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.documentOutlineController.showDocumentOutline()
        return .succeeded
    }
}

public struct GotoLineCommand: Command {
    public let id: CommandID = .cursorGotoLine
    public let name = "Go To Line"
    public let description = "Jump to line and column number"
    public let keys: [Key] = [.alt("g"), .alt("G"), .alt("/")]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptGotoLine()
        return .prompting
    }
}

public struct NumericGotoCommand: Command {
    public let id: CommandID = .cursorGotoLine
    public let name = "Goto Line"
    public let description = "Jump to line or line/column"
    public let commandBarAliases: [String] = ["goto"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        input.text.range(of: #"^-?\d+([:,]-?\d+)?$|^:-?\d+$"#, options: .regularExpression) != nil
            || input.lowerFirstToken == "goto"
    }

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptGotoLine()
        return .prompting
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        let locationText: String
        if input.lowerFirstToken == "goto" {
            locationText = input.rest
        } else if input.text.hasPrefix(":") {
            locationText = String(input.text.dropFirst())
        } else {
            locationText = input.text
        }
        let parts = locationText.split(whereSeparator: { $0.isWhitespace || $0 == ":" || $0 == "," }).map(String.init)
        guard let first = parts.first, let line = Int(first), line > 0 else {
            return .succeeded(message: editor.l10n["status.invalid_line"])
        }
        guard parts.count <= 2 else {
            return .succeeded(message: editor.l10n["status.invalid_column"])
        }

        if parts.count == 2 {
            guard let col = Int(parts[1]), col > 0 else {
                return .succeeded(message: editor.l10n["status.invalid_column"])
            }
            return editor.goToLocation(line: line, column: col)
        } else {
            return editor.goToLocation(line: line)
        }
    }
}

public struct RefreshScreenCommand: Command {
    public let id: CommandID = .screenRefresh
    public let name = "Refresh"
    public let description = "Refresh screen"
    public let keys: [Key] = [.ctrl("L")]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.renderer.invalidateScreenCache()
        return .succeeded
    }
}

public struct ShowCursorPosCommand: Command {
    public let id: CommandID = .cursorPos
    public let name = "Cur Pos"
    public let description = "Display cursor position"
    public let keys: [Key] = [.ctrl("C"), .f11]
    public let commandBarAliases = ["pos", "cursorpos", "where"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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
        return .succeeded(
            message: editor.l10n.cursorInfo(
                currentLine: currentLine, totalLines: totalLines, percent: percent, currentCol: currentCol,
                totalCol: totalCol, visualCol: visualCol, totalVisualCol: totalVisualCol))
    }
}
