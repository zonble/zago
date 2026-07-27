import Foundation

/// Full-screen Help Viewer (^G / F1) displaying all editor keybindings.
public final class HelpView {
    private let terminal: Terminal

    public init(terminal: Terminal) {
        self.terminal = terminal
    }

    /// Displays full-screen help viewer and waits for key input to dismiss.
    public func show() {
        render()
        // Wait for an actual non-timeout key press to return to editor
        while true {
            let key = terminal.readKey()
            if key != .unknown {
                break
            }
            render()
        }
    }

    /// Renders full-screen help page displaying all command bindings.
    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        var output = ""
        output += "\u{1B}[H" // Move cursor to top-left (1, 1)

        // 1. Title Bar (Inverted colors)
        let titleText = "  se - Full Help & Command Reference"
        output += "\u{1B}[7m\(titleText.paddedToDisplayWidth(cols))\u{1B}[m\r\n"

        // 2. Help Content Lines
        let contentLines: [String] = [
            "  KEYBINDINGS & COMMANDS REFERENCE",
            "  ================================================================",
            "  NAVIGATION & CURSOR MOVEMENT:",
            "    ^F / Right Arrow   Move forward one character",
            "    ^B / Left Arrow    Move backward one character",
            "    ^P / Up Arrow      Move to previous line",
            "    ^N / Down Arrow    Move to next line",
            "    ^A / Home          Move to beginning of current line",
            "    ^E / End           Move to end of current line",
            "    ^V / F8 / PgDn     Move forward one page of text",
            "    ^Y / F7 / PgUp     Move backward one page of text",
            "",
            "  EDITING & SELECTION:",
            "    ^D / Delete        Delete character at cursor position",
            "    ^^ (Ctrl+^)        Set / Unset selection mark (starts text selection)",
            "    ^K / F9            Cut selected text (or current line if no mark set)",
            "    ^U / F10           Uncut (paste) last cut text at cursor position",
            "    ^I / Tab           Insert tab (4 spaces) at cursor position",
            "",
            "  SEARCH & PARAGRAPH FORMATTING:",
            "    ^W / F6            Where Is (case-insensitive text search)",
            "    ^J / F4            Justify (format) current paragraph (CJK/Latin reflow)",
            "    ^L                 Refresh screen display",
            "    ^C / F11           Display current cursor position info",
            "    ^T / F12           Spell checker status",
            "",
            "  FILE OPERATIONS & EXIT:",
            "    ^O / ^S / F3       WriteOut (save buffer to file)",
            "    ^R / F5            Read file (insert external file into buffer)",
            "    ^X / F2            Exit editor (prompts to save modified buffer)",
            "    ^G / F1            Display this full-screen help page"
        ]

        let availableHeight = max(1, rows - 2) // Reserve 1 line for header and 1 for footer
        for i in 0..<availableHeight {
            let lineStr: String
            if i < contentLines.count {
                lineStr = contentLines[i].paddedToDisplayWidth(cols)
            } else {
                lineStr = String(repeating: " ", count: cols)
            }
            output += "\u{1B}[K\(lineStr)\r\n"
        }

        // 3. Footer Bar (Bold Cyan text, no inverted background)
        let footerRaw = "  [ Press any key to return to editor ]"
        let paddedFooter = footerRaw.paddedToDisplayWidth(cols)
        output += "\u{1B}[1;36m\(paddedFooter)\u{1B}[0m"

        print(output, terminator: "")
        // Safely flush output buffer without referencing C global mutable 'stdout'
        fflush(nil)
    }
}
