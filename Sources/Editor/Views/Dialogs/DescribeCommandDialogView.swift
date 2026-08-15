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
                        render()
                    } else {
                        return
                    }
                case .esc, .ctrl("c"), .ctrl("g"):
                    return
                case .backspace:
                    if !inputText.isEmpty {
                        inputText.removeLast()
                        render()
                    }
                case .char(let ch):
                    inputText.append(ch)
                    render()
                default:
                    break
                }
            } else {
                // Showing details: dismiss on any key
                return
            }
        }
    }

    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        guard rows > 6 && cols > 20 else { return }

        let dialogWidth = min(cols - 4, 76)
        let dialogHeight = min(rows - 4, 18)
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

        let l10n = editor?.l10n ?? L10n(language: language)

        let title: String
        let footer: String
        let lines: [String]

        if isInputMode {
            title = language == .zh_TW ? "查詢指令與程序 (Describe Command)" : "Describe Command & Procedure"
            footer = language == .zh_TW ? "[ Enter: 查詢  |  Esc: 關閉 ]" : "[ Enter: Search  |  Esc: Close ]"
            let promptLabel = language == .zh_TW
                ? "請輸入指令名稱、自訂 Procedure 或 Primitive："
                : "Enter command, procedure or primitive name:"
            lines = [
                "",
                promptLabel,
                "> " + inputText + "█",
                "",
            ]
        } else {
            title = String(format: language == .zh_TW ? "說明：%@" : "Help: %@", symbol)
            footer = language == .zh_TW ? "[ 按任意鍵關閉 ]" : "[ Press any key to close ]"
            lines = buildSymbolDetails(for: symbol, l10n: l10n)
        }

        // Top border
        let topBar = "╔" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╗"
        output += "\u{001B}[\(startRow);\(startCol)H\(topBar)"
        let styledTitle = title.ansiStyled(style: ANSIStyle.bold)
        output += "\u{001B}[\(startRow);\(startCol + 2)H\(styledTitle)"

        // Body rows
        let bodyHeight = max(1, dialogHeight - 2)
        for r in 0..<bodyHeight {
            let currentRow = startRow + 1 + r
            output += "\u{001B}[\(currentRow);\(startCol)H║"
            output += String(repeating: " ", count: max(0, dialogWidth - 2))
            output += "\u{001B}[\(currentRow);\(startCol + dialogWidth - 1)H║"

            if r < lines.count {
                let lineText = lines[r]
                let maxLineWidth = max(1, dialogWidth - 6)
                let visibleText = lineText.displayWidth > maxLineWidth
                    ? lineText.visualSlice(startVisualColumn: 0, width: maxLineWidth).text
                    : lineText
                output += "\u{001B}[\(currentRow);\(startCol + 3)H\(visibleText)"
            }
        }

        // Bottom border
        let bottomBar = "╚" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╝"
        let bottomRow = startRow + dialogHeight - 1
        output += "\u{001B}[\(bottomRow);\(startCol)H\(bottomBar)"
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

    private func buildSymbolDetails(for sym: String, l10n: L10n) -> [String] {
        let symUpper = sym.uppercased()
        let symLower = sym.lowercased()
        var result: [String] = []

        let isZh = language == .zh_TW

        // 1. User-Defined LOGO Procedure
        if let proc = editor?.logoEngine.customProcedures[symUpper] {
            result.append("• " + (isZh ? "自訂程序 (LOGO Procedure)" : "User-Defined Procedure").ansiStyled(style: ANSIStyle.boldYellow))
            let paramsStr = proc.parameters.isEmpty ? (isZh ? "(無參數)" : "(none)") : proc.parameters.map { ":" + $0 }.joined(separator: " ")
            result.append("    " + (isZh ? "語法：" : "Syntax: ") + "\(proc.name) \(paramsStr)".ansiStyled(style: ANSIStyle.bold))
            result.append("")

            result.append("• " + (isZh ? "說明文件 (Docstring)" : "Docstring").ansiStyled(style: ANSIStyle.boldCyan))
            if let doc = proc.docstring, !doc.isEmpty {
                result.append("    \(doc)")
            } else {
                result.append("    " + (isZh ? "(未提供 docstring)" : "(No docstring provided)").ansiStyled(style: ANSIStyle.dimGray))
            }
            result.append("")

            result.append("• " + (isZh ? "定義 (Definition)" : "Definition").ansiStyled(style: ANSIStyle.boldCyan))
            let bodyText = proc.bodyTokens.map(\.text).joined(separator: " ")
            let wrappedBody = formatScriptLines(bodyText, maxLineWidth: 66, maxLines: 3)
            for line in wrappedBody {
                result.append("    \(line)")
            }
            return result
        }

        // 2. Editor Command
        if let editor = editor {
            let foundCmd = editor.commandRegistry.commands.first(where: {
                $0.commandBarAliases.contains(symLower)
                    || $0.id.rawValue.lowercased() == symLower
                    || $0.name.lowercased() == symLower
            })

            if let cmd = foundCmd {
                result.append("• " + (isZh ? "編輯器指令 (Editor Command)" : "Editor Command").ansiStyled(style: ANSIStyle.boldYellow))
                result.append("    " + (isZh ? "名稱：" : "Name: ") + "\(cmd.name) [\(cmd.id.rawValue)]".ansiStyled(style: ANSIStyle.bold))
                result.append("")

                result.append("• " + (isZh ? "說明：" : "Description:").ansiStyled(style: ANSIStyle.boldCyan))
                let locKey = "command.\(cmd.id.rawValue).description"
                let locDesc = l10n[locKey]
                let desc = (locDesc != locKey && !locDesc.isEmpty) ? locDesc : cmd.description
                result.append("    \(desc)")
                result.append("")

                if !cmd.commandBarAliases.isEmpty {
                    result.append("• " + (isZh ? "別名 (Aliases)：" : "Aliases:").ansiStyled(style: ANSIStyle.boldCyan))
                    result.append("    " + cmd.commandBarAliases.joined(separator: ", "))
                }
                return result
            }
        }

        // 3. Built-in LOGO Primitive
        if let prim = LogoPrimitive.from(sym) {
            result.append("• " + (isZh ? "內建 LOGO 指令 (Primitive)" : "Built-in LOGO Primitive").ansiStyled(style: ANSIStyle.boldYellow))
            result.append("    " + (isZh ? "指令名：" : "Name: ") + "\(prim)".uppercased().ansiStyled(style: ANSIStyle.bold))
            result.append("")
            result.append("• " + (isZh ? "說明：" : "Description:").ansiStyled(style: ANSIStyle.boldCyan))
            result.append("    " + (isZh ? "內建直譯器指令 / Primitive。" : "Built-in interpreter command or reporter."))
            return result
        }

        // 4. Not Found
        result.append("• " + (isZh ? "找不到符合項目" : "Not Found").ansiStyled(style: ANSIStyle.boldYellow))
        result.append("    " + String(format: isZh ? "找不到名為 '%@' 的指令、程序或 Primitive。" : "No command, procedure or primitive found matching '%@'.", sym))
        return result
    }

    private func formatScriptLines(_ text: String, maxLineWidth: Int, maxLines: Int = 3) -> [String] {
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
