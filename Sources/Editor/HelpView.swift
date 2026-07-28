import Foundation

/// Full-screen Help Viewer (^G / F1) displaying all editor keybindings with interactive scrolling.
public final class HelpView {
    private let terminal: Terminal
    private var topIndex: Int = 0

    public init(terminal: Terminal) {
        self.terminal = terminal
    }

    /// Displays full-screen help viewer and waits for key input to scroll or dismiss.
    public func show() {
        render()
        while true {
            let key = terminal.readKey()
            let (rows, _) = terminal.getWindowSize()
            let availableHeight = max(1, rows - 2)
            let maxTop = max(0, getContentLines().count - availableHeight)

            switch key {
            case .arrowDown, .char("j"), .char("J"):
                topIndex = min(topIndex + 1, maxTop)
                render()
            case .arrowUp, .char("k"), .char("K"):
                topIndex = max(0, topIndex - 1)
                render()
            case .pageDown, .char(" "):
                topIndex = min(topIndex + availableHeight, maxTop)
                render()
            case .pageUp:
                topIndex = max(0, topIndex - availableHeight)
                render()
            case .home:
                topIndex = 0
                render()
            case .end:
                topIndex = maxTop
                render()
            case .unknown:
                render()
            default:
                // Any other key (Esc, Enter, ^G, F1, q, Q, etc.) dismisses HelpView
                return
            }
        }
    }

    /// Returns all formatted help lines.
    private func getContentLines() -> [String] {
        [
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
            L10n["helpview.file_4"],
            L10n["helpview.file_5"],
            L10n["helpview.file_6"],
            L10n["helpview.file_7"],
            L10n["helpview.file_8"],
            L10n["helpview.file_9"],
            "",
            L10n["helpview.sec_logo"],
            L10n["helpview.logo_1"],
            L10n["helpview.logo_2"],
            L10n["helpview.logo_3"],
            L10n["helpview.logo_4"],
            L10n["helpview.logo_5"],
            L10n["helpview.logo_6"],
            L10n["helpview.logo_7"],
            L10n["helpview.logo_8"],
            L10n["helpview.logo_9"]
        ]
    }

    /// Renders full-screen help page displaying all command bindings.
    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        var output = ""
        output += "\u{1B}[H" // Move cursor to top-left (1, 1)

        // 1. Title Bar (Inverted colors)
        let titleText = L10n["helpview.title"]
        output += "\u{1B}[7m\(titleText.paddedToDisplayWidth(cols))\u{1B}[m\r\n"

        // 2. Help Content Lines (Scrollable Viewport)
        let contentLines = getContentLines()
        let availableHeight = max(1, rows - 2) // Reserve 1 line for header and 1 for footer
        topIndex = max(0, min(topIndex, max(0, contentLines.count - availableHeight)))

        for i in 0..<availableHeight {
            let lineIdx = topIndex + i
            let lineStr: String
            if lineIdx < contentLines.count {
                lineStr = contentLines[lineIdx].paddedToDisplayWidth(cols)
            } else {
                lineStr = String(repeating: " ", count: cols)
            }
            output += "\u{1B}[K\(lineStr)\r\n"
        }

        // 3. Footer Bar (Bold Cyan text)
        let footerRaw = L10n["helpview.footer"]
        let paddedFooter = footerRaw.paddedToDisplayWidth(cols)
        output += "\u{1B}[1;36m\(paddedFooter)\u{1B}[0m"

        print(output, terminator: "")
        fflush(nil)
    }
}
