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
        let titleText = L10n["helpview.title"]
        output += "\u{1B}[7m\(titleText.paddedToDisplayWidth(cols))\u{1B}[m\r\n"

        // 2. Help Content Lines
        let contentLines: [String] = [
            L10n["helpview.header"],
            "  ================================================================",
            L10n["helpview.sec_nav"],
            L10n["helpview.nav_1"],
            L10n["helpview.nav_2"],
            L10n["helpview.nav_3"],
            L10n["helpview.nav_4"],
            L10n["helpview.nav_5"],
            L10n["helpview.nav_6"],
            L10n["helpview.nav_7"],
            L10n["helpview.nav_8"],
            "",
            L10n["helpview.sec_edit"],
            L10n["helpview.edit_1"],
            L10n["helpview.edit_2"],
            L10n["helpview.edit_3"],
            L10n["helpview.edit_4"],
            L10n["helpview.edit_5"],
            "",
            L10n["helpview.sec_search"],
            L10n["helpview.search_1"],
            L10n["helpview.search_2"],
            L10n["helpview.search_3"],
            L10n["helpview.search_4"],
            L10n["helpview.search_5"],
            "",
            L10n["helpview.sec_file"],
            L10n["helpview.file_1"],
            L10n["helpview.file_2"],
            L10n["helpview.file_3"],
            L10n["helpview.file_4"]
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
        let footerRaw = L10n["helpview.footer"]
        let paddedFooter = footerRaw.paddedToDisplayWidth(cols)
        output += "\u{1B}[1;36m\(paddedFooter)\u{1B}[0m"

        print(output, terminator: "")
        // Safely flush output buffer without referencing C global mutable 'stdout'
        fflush(nil)
    }
}
