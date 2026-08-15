import ANSIStyle
import Foundation
import TextMetrics

/// Generic full-screen, scrollable text viewer for reference-style editor pages.
final class TextDocumentView {
    private let terminal: EditorTerminal
    private let title: String
    private let lines: [String]
    private let footer: String
    private var topIndex: Int = 0

    init(terminal: EditorTerminal, title: String, lines: [String], footer: String) {
        self.terminal = terminal
        self.title = title
        self.lines = lines
        self.footer = footer
    }

    func show() {
        render()
        while true {
            let key = terminal.readKey()
            let (rows, _) = terminal.getWindowSize()
            let availableHeight = max(1, rows - 2)
            let maxTop = max(0, lines.count - availableHeight)

            switch key {
            case .arrowDown, .char("j"), .char("J"):
                topIndex = min(topIndex + 1, maxTop)
                render()
            case .arrowUp, .char("k"), .char("K"):
                topIndex = max(0, topIndex - 1)
                render()
            case .pageDown, .ctrl("v"), .ctrl("V"), .char(" "):
                topIndex = min(topIndex + availableHeight, maxTop)
                render()
            case .pageUp, .ctrl("y"), .ctrl("Y"):
                topIndex = max(0, topIndex - availableHeight)
                render()
            case .home:
                topIndex = 0
                render()
            case .end:
                topIndex = maxTop
                render()
            case .resize:
                terminal.clearScreen()
                render()
            case .unknown:
                render()
            default:
                terminal.clearScreen()
                return
            }
        }
    }

    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        var output = ANSIStyle.cursorHome
        output += title.paddedToDisplayWidth(cols).ansiStyled(
            style: ANSIStyle.inverse,
            endStyle: ANSIStyle.resetShort
        ) + "\r\n"

        let availableHeight = max(1, rows - 2)
        topIndex = max(0, min(topIndex, max(0, lines.count - availableHeight)))

        for i in 0..<availableHeight {
            let lineIndex = topIndex + i
            let line = lineIndex < lines.count ? lines[lineIndex] : ""
            output += "\(ANSIStyle.clearLine)\(line.paddedToDisplayWidth(cols))\r\n"
        }

        output += footer.paddedToDisplayWidth(cols).ansiStyled(style: ANSIStyle.boldCyan)
        terminal.write(output)
        fflush(nil)
    }
}
