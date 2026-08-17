import ANSIStyle
import Foundation
import LogoEngine
import TextMetrics

/// Interactive modal dialog for querying and describing Editor commands and LOGO procedures.
final class DescribeCommandDialogView {
    private let terminal: EditorTerminal
    private weak var editor: Editor?
    private let language: Language
    private var symbol: String
    private var isInputMode: Bool
    private var inputText: String = ""
    private var scrollOffset: Int = 0
    private var cachedLines: [String] = []
    private var cachedBodyHeight: Int = 10

    private var tabCandidates: [String] = []
    private var tabCandidateIndex: Int = 0

    init(
        terminal: EditorTerminal,
        editor: Editor? = nil,
        symbol: String? = nil,
        language: Language = .detectSystemLanguage()
    ) {
        self.terminal = terminal
        self.editor = editor
        self.language = language
        if let sym = symbol?.trimmingCharacters(in: .whitespaces), !sym.isEmpty {
            self.symbol = sym
            self.isInputMode = false
        } else {
            self.symbol = ""
            self.isInputMode = true
        }
    }

    func show() {
        scrollOffset = 0
        render()
        while true {
            let key = terminal.readKey()
            if key == .unknown {
                continue
            }
            if key == .resize {
                render()
                continue
            }

            if isInputMode {
                switch key {
                case .enter:
                    let trimmed = inputText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        symbol = trimmed
                        isInputMode = false
                        scrollOffset = 0
                        tabCandidates = []
                        tabCandidateIndex = 0
                        render()
                    } else {
                        return
                    }
                case .esc, .ctrl("c"), .ctrl("g"):
                    return
                case .tab:
                    handleTabCompletion()
                case .backspace:
                    tabCandidates = []
                    tabCandidateIndex = 0
                    if !inputText.isEmpty {
                        inputText.removeLast()
                        render()
                    }
                case .char(let ch):
                    tabCandidates = []
                    tabCandidateIndex = 0
                    inputText.append(ch)
                    render()
                default:
                    break
                }
            } else {
                // Showing details with scroll support
                switch key {
                case .esc, .enter, .char("q"), .char("Q"), .ctrl("c"), .ctrl("g"):
                    return

                case .arrowUp, .char("k"), .char("K"):
                    if scrollOffset > 0 {
                        scrollOffset -= 1
                        render()
                    }

                case .arrowDown, .char("j"), .char("J"):
                    let maxOffset = max(0, cachedLines.count - cachedBodyHeight)
                    if scrollOffset < maxOffset {
                        scrollOffset += 1
                        render()
                    }

                case .pageUp, .ctrl("u"):
                    scrollOffset = max(0, scrollOffset - max(1, cachedBodyHeight - 1))
                    render()

                case .pageDown, .ctrl("d"), .char(" "):
                    let maxOffset = max(0, cachedLines.count - cachedBodyHeight)
                    scrollOffset = min(maxOffset, scrollOffset + max(1, cachedBodyHeight - 1))
                    render()

                case .home, .char("g"):
                    scrollOffset = 0
                    render()

                case .end, .char("G"):
                    let maxOffset = max(0, cachedLines.count - cachedBodyHeight)
                    scrollOffset = maxOffset
                    render()

                default:
                    break
                }
            }
        }
    }

    private func handleTabCompletion() {
        let candidates = allCandidates()
        let query = inputText.trimmingCharacters(in: .whitespaces)

        if tabCandidates.isEmpty {
            if query.isEmpty {
                tabCandidates = candidates
                tabCandidateIndex = 0
            } else {
                let queryLower = query.lowercased()
                tabCandidates = candidates.filter { $0.lowercased().hasPrefix(queryLower) }
                tabCandidateIndex = 0
            }
        }

        guard !tabCandidates.isEmpty else { return }

        if tabCandidates.count == 1 {
            inputText = tabCandidates[0]
            tabCandidates = []
            tabCandidateIndex = 0
        } else {
            let commonPrefix = longestCommonPrefix(strings: tabCandidates)
            if !query.isEmpty && commonPrefix.count > query.count && tabCandidateIndex == 0 {
                inputText = commonPrefix
            } else {
                inputText = tabCandidates[tabCandidateIndex % tabCandidates.count]
                tabCandidateIndex += 1
            }
        }
        render()
    }

    private func longestCommonPrefix(strings: [String]) -> String {
        guard let first = strings.first, !strings.isEmpty else { return "" }
        var prefix = first
        for str in strings.dropFirst() {
            while !str.lowercased().hasPrefix(prefix.lowercased()) && !prefix.isEmpty {
                prefix = String(prefix.dropLast())
            }
            if prefix.isEmpty { break }
        }
        return prefix
    }

    private func allCandidates() -> [String] {
        var set = Set<String>()

        // 1. Built-in LOGO Primitives
        for alias in LogoPrimitive.keywordAliases {
            set.insert(alias)
        }

        // 2. Editor Commands
        if let editor = editor {
            for cmd in editor.commandRegistry.commands {
                for alias in cmd.commandBarAliases {
                    set.insert(alias)
                }
                set.insert(cmd.id.rawValue)
            }
        }

        // 3. User-defined procedures
        if let editor = editor {
            for procName in editor.logoEngine.customProcedures.keys {
                set.insert(procName)
            }
        }

        return Array(set).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        guard rows > 6 && cols > 20 else { return }

        let l10n = editor?.l10n ?? L10n(language: language)

        let title: String
        let footer: String
        let lines: [String]

        let dialogWidth = min(cols - 4, max(76, min(100, Int(Double(cols) * 0.90))))
        let maxDialogHeight = min(rows - 4, max(18, Int(Double(rows) * 0.85)))

        let contentWidth = max(20, dialogWidth - 6)

        if isInputMode {
            title = l10n["describe_command.title_input"]
            footer = l10n["describe_command.footer_input"]
            let promptLabel = l10n["describe_command.prompt_input"]
            var inputLines = [
                "",
                promptLabel,
                "> " + inputText + "█",
                "",
            ]
            if !tabCandidates.isEmpty {
                let preview = tabCandidates.prefix(6).joined(separator: ", ")
                let more = tabCandidates.count > 6 ? ", ..." : ""
                let candidateHint = "  [\(tabCandidates.count)] " + preview + more
                let wrappedHint = wrapText(candidateHint, maxLineWidth: contentWidth, indent: "  ")
                inputLines.append(contentsOf: wrappedHint.map { $0.ansiStyled(style: ANSIStyle.dimGray) })
            }
            lines = inputLines
        } else {
            title = String(format: l10n["describe_command.title_help"], symbol)
            lines = buildSymbolDetails(for: symbol, l10n: l10n, maxLineWidth: contentWidth)
            let hasOverflow = lines.count > (maxDialogHeight - 2)
            if hasOverflow {
                footer = l10n["describe_command.footer_scroll"]
            } else {
                footer = l10n["describe_command.footer_close"]
            }
        }

        cachedLines = lines

        let dialogHeight = isInputMode
            ? min(maxDialogHeight, lines.count + 2)
            : min(maxDialogHeight, max(12, lines.count + 2))

        let bodyHeight = max(1, dialogHeight - 2)
        cachedBodyHeight = bodyHeight

        // Clamp scrollOffset
        let maxOffset = max(0, lines.count - bodyHeight)
        scrollOffset = min(maxOffset, max(0, scrollOffset))

        let startRow = max(1, (rows - dialogHeight) / 2)
        let startCol = max(1, (cols - dialogWidth) / 2)

        var output = ""
        if let editor = editor {
            editor.menuBarController.isActive = false
            let geometry = ScreenGeometry(rows: rows, cols: cols, editor: editor)
            editor.adjustViewport(mainAreaHeight: geometry.mainAreaHeight, textWidth: geometry.textWidth)
            output += editor.renderer.render(editor: editor, geometry: geometry)
        } else {
            output += "\u{001B}[H"
        }

        // Top border with scroll up indicator
        let topBar = "╔" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╗"
        output += "\u{001B}[\(startRow);\(startCol)H\(topBar)"
        let styledTitle = title.ansiStyled(style: ANSIStyle.bold)
        output += "\u{001B}[\(startRow);\(startCol + 2)H\(styledTitle)"
        if scrollOffset > 0 {
            let indicator = " ▲ ".ansiStyled(style: ANSIStyle.boldYellow)
            output += "\u{001B}[\(startRow);\(startCol + dialogWidth - 6)H\(indicator)"
        }

        // Body rows
        for r in 0..<bodyHeight {
            let currentRow = startRow + 1 + r
            output += "\u{001B}[\(currentRow);\(startCol)H║"
            output += String(repeating: " ", count: max(0, dialogWidth - 2))
            output += "\u{001B}[\(currentRow);\(startCol + dialogWidth - 1)H║"

            let lineIndex = scrollOffset + r
            if lineIndex < lines.count {
                let rawText = lines[lineIndex]
                let lineText = rawText.displayWidth > contentWidth
                    ? rawText.visualSlice(startVisualColumn: 0, width: contentWidth).text
                    : rawText
                output += "\u{001B}[\(currentRow);\(startCol + 3)H\(lineText)\(ANSIStyle.reset)"
            }
        }

        // Bottom border with scroll down indicator
        let bottomBar = "╚" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╝"
        let bottomRow = startRow + dialogHeight - 1
        output += "\u{001B}[\(bottomRow);\(startCol)H\(bottomBar)"
        if scrollOffset + bodyHeight < lines.count {
            let indicator = " ▼ ".ansiStyled(style: ANSIStyle.boldYellow)
            output += "\u{001B}[\(bottomRow);\(startCol + dialogWidth - 6)H\(indicator)"
        }
        if !footer.isEmpty {
            let styledFooter = footer.ansiStyled(style: ANSIStyle.dimGray)
            let footerPos = max(startCol + 2, startCol + (dialogWidth - footer.displayWidth) / 2)
            output += "\u{001B}[\(bottomRow);\(footerPos)H\(styledFooter)"
        }

        // Position cursor at bottom-right corner
        output += "\u{001B}[\(rows);\(cols)H"
        terminal.write(output)
        fflush(nil)
    }

    func buildSymbolDetails(for sym: String, l10n: L10n, maxLineWidth: Int = 68) -> [String] {
        let symUpper = sym.uppercased()
        let symLower = sym.lowercased()

        var sections: [[String]] = []

        // 1. User-Defined LOGO Procedure
        if let proc = editor?.logoEngine.customProcedures[symUpper] {
            var procSection: [String] = []
            procSection.append("• " + l10n["describe_command.user_procedure"].ansiStyled(style: ANSIStyle.boldYellow))
            let paramsStr = proc.parameters.isEmpty
                ? l10n["describe_command.no_parameters"]
                : proc.parameters.map { ":" + $0 }.joined(separator: " ")
            procSection.append("    " + l10n["describe_command.syntax"] + "\(proc.name) \(paramsStr)".ansiStyled(style: ANSIStyle.bold))
            procSection.append("")

            procSection.append("• " + l10n["describe_command.docstring"].ansiStyled(style: ANSIStyle.boldCyan))
            if let doc = proc.docstring, !doc.isEmpty {
                let wrapped = wrapText(doc, maxLineWidth: maxLineWidth, indent: "    ")
                procSection.append(contentsOf: wrapped)
            } else {
                procSection.append("    " + l10n["describe_command.no_docstring"].ansiStyled(style: ANSIStyle.dimGray))
            }
            procSection.append("")

            procSection.append("• " + l10n["describe_command.definition"].ansiStyled(style: ANSIStyle.boldCyan))
            let bodyText = proc.bodyTokens.map(\.text).joined(separator: " ")
            let wrappedBody = formatScriptLines(bodyText, maxLineWidth: maxLineWidth, maxLines: 5)
            for line in wrappedBody {
                procSection.append("    \(line)")
            }
            sections.append(procSection)
        }

        // 2. Editor Command
        if let cmd = editor?.commandRegistry.commands.first(where: {
            $0.id.rawValue.lowercased() == symLower || $0.commandBarAliases.contains(where: { $0.lowercased() == symLower })
        }) {
            var cmdSection: [String] = []
            let catTitle = editor?.menuBar.categories.first(where: { cat in
                cat.items.contains(where: { $0.commandId == cmd.id })
            })?.titleKey
            let categoryName = catTitle != nil ? l10n[catTitle!] : l10n["describe_command.general_category"]

            let titleTemplate = l10n["describe_command.editor_command"]
            let titleStr = "• " + String(format: titleTemplate, categoryName)
            cmdSection.append(contentsOf: wrapText(titleStr, maxLineWidth: maxLineWidth, indent: "").map { $0.ansiStyled(style: ANSIStyle.boldYellow) })

            let syntaxStr = cmd.commandBarAliases.first ?? cmd.id.rawValue
            let syntaxHeader = l10n["describe_command.syntax"]
            let subIndent = "        "
            let wrappedWords = wrapText(
                syntaxStr,
                maxLineWidth: max(20, maxLineWidth - (4 + syntaxHeader.displayWidth)),
                indent: ""
            )
            for (idx, line) in wrappedWords.enumerated() {
                if idx == 0 {
                    cmdSection.append("    " + syntaxHeader + line.ansiStyled(style: ANSIStyle.bold))
                } else {
                    cmdSection.append(subIndent + line.ansiStyled(style: ANSIStyle.bold))
                }
            }

            if cmd.commandBarAliases.count > 1 {
                cmdSection.append("")
                cmdSection.append("• " + l10n["describe_command.aliases"].ansiStyled(style: ANSIStyle.boldCyan))
                let aliasStr = cmd.commandBarAliases.joined(separator: ", ")
                cmdSection.append(contentsOf: wrapText(aliasStr, maxLineWidth: maxLineWidth, indent: "    "))
            }
            cmdSection.append("")

            cmdSection.append("• " + l10n["describe_command.description"].ansiStyled(style: ANSIStyle.boldCyan))
            let locKey = "command.\(cmd.id.rawValue).description"
            let locDesc = l10n[locKey]
            let desc = (locDesc != locKey && !locDesc.isEmpty) ? locDesc : cmd.description
            let wrappedDesc = wrapText(desc, maxLineWidth: maxLineWidth, indent: "    ")
            cmdSection.append(contentsOf: wrappedDesc)
            sections.append(cmdSection)
        }

        // 3. Built-in LOGO Primitive
        if let prim = LogoPrimitive.from(sym) {
            var primSection: [String] = []
            let meta = prim.meta
            let sourceStr = (meta.source == .ucbLogo)
                ? l10n["describe_command.source_ucb_logo"]
                : l10n["describe_command.source_zago"]

            let titleTemplate = l10n["describe_command.builtin_primitive"]
            let titleStr = "• " + String(format: titleTemplate, sourceStr)
            primSection.append(contentsOf: wrapText(titleStr, maxLineWidth: maxLineWidth, indent: "").map { $0.ansiStyled(style: ANSIStyle.boldYellow) })

            let paramsStr = meta.parameters?.map { param in
                param.required ? param.name : "[\(param.name)]"
            }.joined(separator: " ") ?? ""
            let syntaxRaw = paramsStr.isEmpty ? meta.name : "\(meta.name) \(paramsStr)"
            let syntaxHeader = l10n["describe_command.syntax"]
            let subIndent = "        "
            let wrappedWords = wrapText(
                syntaxRaw,
                maxLineWidth: max(20, maxLineWidth - (4 + syntaxHeader.displayWidth)),
                indent: ""
            )
            for (idx, line) in wrappedWords.enumerated() {
                if idx == 0 {
                    primSection.append("    " + syntaxHeader + line.ansiStyled(style: ANSIStyle.bold))
                } else {
                    primSection.append(subIndent + line.ansiStyled(style: ANSIStyle.bold))
                }
            }

            let aliases = LogoPrimitive.keywordAliases.filter {
                $0 != meta.name && LogoPrimitive.from($0) == prim
            }
            if !aliases.isEmpty {
                primSection.append("")
                primSection.append("• " + l10n["describe_command.aliases"].ansiStyled(style: ANSIStyle.boldCyan))
                let aliasStr = aliases.joined(separator: ", ")
                primSection.append(contentsOf: wrapText(aliasStr, maxLineWidth: maxLineWidth, indent: "    "))
            }
            primSection.append("")

            primSection.append("• " + l10n["describe_command.description"].ansiStyled(style: ANSIStyle.boldCyan))
            let locKey = meta.localizedDescriptionKey
            let locDesc = l10n[locKey]
            let desc = (locDesc != locKey && !locDesc.isEmpty) ? locDesc : meta.description
            let wrappedDesc = wrapText(desc, maxLineWidth: maxLineWidth, indent: "    ")
            primSection.append(contentsOf: wrappedDesc)

            if let notes = meta.notes, !notes.isEmpty {
                primSection.append("")
                primSection.append("• " + l10n["describe_command.notes"].ansiStyled(style: ANSIStyle.boldCyan))
                primSection.append(contentsOf: wrapText(notes, maxLineWidth: maxLineWidth, indent: "    "))
            }

            if let params = meta.parameters, !params.isEmpty {
                primSection.append("")
                primSection.append("• " + l10n["describe_command.parameters"].ansiStyled(style: ANSIStyle.boldCyan))
                for param in params {
                    let paramLines = formatParameterLines(param: param, l10n: l10n, maxLineWidth: maxLineWidth)
                    primSection.append(contentsOf: paramLines)
                }
            }

            if let examples = meta.examples, !examples.isEmpty {
                primSection.append("")
                primSection.append("• " + l10n["describe_command.examples"].ansiStyled(style: ANSIStyle.boldCyan))
                for example in examples {
                    var exStr = example.input
                    if !example.output.isEmpty {
                        exStr += "  ->  " + example.output
                    }
                    primSection.append(contentsOf: wrapText(exStr, maxLineWidth: maxLineWidth, indent: "    "))
                }
            }
            sections.append(primSection)
        }

        // 4. Combine results
        if sections.isEmpty {
            var result: [String] = []
            result.append("• " + l10n["describe_command.not_found"].ansiStyled(style: ANSIStyle.boldYellow))
            let notFoundDesc = String(format: l10n["describe_command.not_found_desc"], sym)
            result.append(contentsOf: wrapText(notFoundDesc, maxLineWidth: maxLineWidth, indent: "    "))
            return result
        }

        var result: [String] = []
        if sections.count > 1 {
            let matchesHeader = String(format: l10n["describe_command.found_matches"], sections.count)
            result.append("💡 " + matchesHeader.ansiStyled(style: ANSIStyle.dimGray))
            result.append("")
        }

        let divider = String(repeating: "─", count: maxLineWidth).ansiStyled(style: ANSIStyle.dimGray)
        for (idx, section) in sections.enumerated() {
            if idx > 0 {
                result.append("")
                result.append(divider)
                result.append("")
            }
            result.append(contentsOf: section)
        }

        return result.map { line in
            if line.displayWidth > maxLineWidth {
                return line.visualSlice(startVisualColumn: 0, width: maxLineWidth).text
            }
            return line
        }
    }

    private func wrapText(
        _ text: String,
        maxLineWidth: Int,
        indent: String
    ) -> [String] {
        let rawLines = text.components(separatedBy: .newlines)
        var result: [String] = []

        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                result.append("")
                continue
            }
            let words = rawLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            var currentLine = ""

            for word in words {
                let candidate = currentLine.isEmpty ? (indent + word) : (currentLine + " " + word)
                if candidate.displayWidth <= maxLineWidth {
                    currentLine = candidate
                } else {
                    if !currentLine.isEmpty {
                        result.append(currentLine)
                        currentLine = ""
                    }
                    if (indent + word).displayWidth <= maxLineWidth {
                        currentLine = indent + word
                    } else {
                        // Word itself is wider than maxLineWidth (e.g. continuous CJK)
                        var remaining = word
                        while !remaining.isEmpty {
                            var chunk = ""
                            var chunkWidth = 0
                            let targetWidth = max(4, maxLineWidth - indent.displayWidth)
                            for ch in remaining {
                                if chunkWidth + ch.displayWidth > targetWidth { break }
                                chunk.append(ch)
                                chunkWidth += ch.displayWidth
                            }
                            if chunk.isEmpty {
                                if let first = remaining.first {
                                    chunk.append(first)
                                }
                            }
                            result.append(indent + chunk)
                            remaining = String(remaining.dropFirst(chunk.count))
                        }
                    }
                }
            }
            if !currentLine.isEmpty {
                result.append(currentLine)
            }
        }
        return result
    }

    private func formatParameterLines(
        param: LogoPrimitiveParameter,
        l10n: L10n,
        maxLineWidth: Int
    ) -> [String] {
        let reqBadge = param.required
            ? l10n["describe_command.param_required"]
            : l10n["describe_command.param_optional"]
        let headerRaw = "    • \(param.name) \(reqBadge)"
        let detailIndent = "      "
        var result: [String] = []
        let wrappedHeader = wrapText(headerRaw, maxLineWidth: maxLineWidth, indent: "    ")
        for line in wrappedHeader {
            if line.contains(reqBadge) {
                let parts = line.components(separatedBy: reqBadge)
                let styled = parts[0] + reqBadge.ansiStyled(style: ANSIStyle.dimGray) + parts.dropFirst().joined(separator: reqBadge)
                result.append(styled)
            } else {
                result.append(line)
            }
        }

        if let description = param.description, !description.isEmpty {
            result.append(contentsOf: wrapText(
                l10n["describe_command.parameter_description"] + description,
                maxLineWidth: maxLineWidth,
                indent: detailIndent))
        }

        if !param.allowedValues.isEmpty {
            let allowedLabel = l10n["describe_command.allowed_values"]
            let allowedValues = allowedLabel + param.allowedValues.joined(separator: ", ") + ")"
            result.append(contentsOf: wrapText(allowedValues, maxLineWidth: maxLineWidth, indent: detailIndent))
        }

        if let example = param.example, !example.isEmpty {
            result.append(contentsOf: wrapText(
                l10n["describe_command.parameter_example"] + example,
                maxLineWidth: maxLineWidth,
                indent: detailIndent))
        }

        return result.map { $0.displayWidth > maxLineWidth ? $0.visualSlice(startVisualColumn: 0, width: maxLineWidth).text : $0 }
    }

    private func formatScriptLines(_ text: String, maxLineWidth: Int, maxLines: Int = 5) -> [String] {
        let rawLines = text.components(separatedBy: .newlines)
        var wrapped: [String] = []

        for rawLine in rawLines {
            var remaining = rawLine.trimmingCharacters(in: .whitespaces)
            if remaining.isEmpty { continue }

            while !remaining.isEmpty {
                if wrapped.count >= maxLines {
                    if let last = wrapped.last {
                        let truncated = last.count > 3 ? String(last.dropLast(3)) + "..." : last + "..."
                        wrapped[wrapped.count - 1] = truncated
                    }
                    return wrapped
                }

                if remaining.displayWidth <= maxLineWidth {
                    wrapped.append(remaining)
                    break
                } else {
                    let slice = remaining.visualSlice(startVisualColumn: 0, width: maxLineWidth - 1)
                    wrapped.append(slice.text)
                    remaining = String(remaining.dropFirst(slice.endCharacterOffset)).trimmingCharacters(in: .whitespaces)
                }
            }
        }

        return wrapped
    }
}
