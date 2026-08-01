import Foundation

public struct SubstituteCommandBarCommand: CommandBarCommand {
    public let name = "s"
    public let help = "s/<search>/<replace>/[flags] or %s/<search>/<replace>/[flags]"
    public let completionNames = ["s", "%s"]

    public init() {}

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

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
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

        if useRegex, let regex = try? NSRegularExpression(
            pattern: parsed.search,
            options: isCaseInsensitive ? [.caseInsensitive] : []
        ) {
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
                          let range = line.range(of: searchStr, options: compareOptions, range: searchStart..<line.endIndex) {
                        countOnLine += 1
                        line.replaceSubrange(range, with: replaceStr)
                        let newAdvance = line.index(range.lowerBound, offsetBy: replaceStr.count, limitedBy: line.endIndex) ?? line.endIndex
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

        guard let delim = restStr.first, (delim == "/" || delim == ",") else { return nil }
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
