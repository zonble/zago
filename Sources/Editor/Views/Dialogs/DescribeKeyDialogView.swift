import ANSIStyle
import Foundation
import TextMetrics

/// Interactive modal dialog for querying and describing keybindings across all modes and LOGO macros.
final class DescribeKeyDialogView {
    private let terminal: EditorTerminal
    private weak var editor: Editor?
    private let language: Language

    private enum State {
        case waitingForKey
        case showingDetails(Key)
    }

    private var state: State = .waitingForKey

    init(
        terminal: EditorTerminal,
        editor: Editor? = nil,
        language: Language = .detectSystemLanguage()
    ) {
        self.terminal = terminal
        self.editor = editor
        self.language = language
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

            switch state {
            case .waitingForKey:
                state = .showingDetails(key)
                render()

            case .showingDetails:
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

        switch state {
        case .waitingForKey:
            title = l10n["dialog.describe_key.title"]
            footer = ""
            lines = [
                "",
                l10n["dialog.describe_key.prompt"],
                "",
            ]

        case .showingDetails(let key):
            title = String(format: l10n["dialog.describe_key.key_label"], key.helpBarLabel)
            footer = l10n["dialog.describe_key.footer_close"]
            lines = buildKeyDetails(for: key, l10n: l10n)
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
                let visibleText =
                    lineText.displayWidth > maxLineWidth
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

        // Position cursor at bottom-right corner of terminal
        output += "\u{001B}[\(rows);\(cols)H"

        terminal.write(output)
    }

    private func buildKeyDetails(for key: Key, l10n: L10n) -> [String] {
        guard let editor else {
            return [String(format: l10n["status.describe_unbound"], key.helpBarLabel)]
        }

        func commandInfo(for cmdId: CommandID?) -> (name: String, desc: String, id: String)? {
            guard let cmdId else { return nil }
            if cmdId == .customMacro, let customCmd = editor.commandRegistry.customCommand(for: key) {
                return (customCmd.name, customCmd.description, cmdId.rawValue)
            }
            let key = "command.\(cmdId.rawValue).description"
            let localized = l10n[key]
            let desc: String
            if localized != key && !localized.isEmpty {
                desc = localized
            } else if let cmd = editor.commandRegistry.commands.first(where: { $0.id == cmdId }) {
                desc = cmd.description
            } else {
                desc = cmdId.rawValue
            }
            let name = editor.commandRegistry.commands.first(where: { $0.id == cmdId })?.name ?? cmdId.rawValue
            return (name, desc, cmdId.rawValue)
        }

        let textCmd = editor.keymapManager.resolve(key: key, in: .text)
        let canvasCmd = editor.keymapManager.resolve(key: key, in: .canvas)
        let tableCmd = editor.keymapManager.resolve(key: key, in: .table)

        if textCmd == nil && canvasCmd == nil && tableCmd == nil {
            if case .char(let ch) = key {
                return [
                    "• " + l10n["dialog.describe_key.section_text"].ansiStyled(style: ANSIStyle.boldYellow),
                    "    " + String(format: l10n["dialog.describe_key.insert_char"], String(ch)),
                ]
            }
            return [
                "• " + l10n["dialog.describe_key.section_text"].ansiStyled(style: ANSIStyle.boldYellow),
                "    " + l10n["dialog.describe_key.unbound"],
            ]
        }

        var result: [String] = []

        // 1. Text Mode
        result.append("• " + l10n["dialog.describe_key.section_text"].ansiStyled(style: ANSIStyle.boldYellow))
        if let info = commandInfo(for: textCmd) {
            result.append("    \(info.desc) (\(info.id))".ansiStyled(style: ANSIStyle.bold))
        } else {
            result.append("    \(l10n["dialog.describe_key.unbound"])")
        }

        // 2. Canvas Mode
        result.append("")
        result.append("• " + l10n["dialog.describe_key.section_canvas"].ansiStyled(style: ANSIStyle.boldCyan))
        if let canvasCmd, canvasCmd != textCmd, let info = commandInfo(for: canvasCmd) {
            result.append("    \(info.desc) (\(info.id))".ansiStyled(style: ANSIStyle.bold))
        } else {
            result.append("    \(l10n["dialog.describe_key.same_as_text"])".ansiStyled(style: ANSIStyle.dimGray))
        }

        // 3. Table Mode
        result.append("")
        result.append("• " + l10n["dialog.describe_key.section_table"].ansiStyled(style: ANSIStyle.boldCyan))
        if let tableCmd, tableCmd != textCmd, let info = commandInfo(for: tableCmd) {
            result.append("    \(info.desc) (\(info.id))".ansiStyled(style: ANSIStyle.bold))
        } else {
            result.append("    \(l10n["dialog.describe_key.same_as_text"])".ansiStyled(style: ANSIStyle.dimGray))
        }

        // 4. Custom LOGO Script
        if textCmd == .customMacro, let customCmd = editor.commandRegistry.customCommand(for: key) {
            result.append("")
            result.append("• " + l10n["dialog.describe_key.section_logo"].ansiStyled(style: ANSIStyle.boldYellow))
            let scriptLines = formatScriptLines(customCmd.description, maxLineWidth: 66, maxLines: 3)
            for line in scriptLines {
                result.append("    \(line)")
            }
        }

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
                    remaining = String(remaining.dropFirst(slice.endCharacterOffset)).trimmingCharacters(
                        in: .whitespaces)
                }
            }
        }

        return wrapped
    }
}
