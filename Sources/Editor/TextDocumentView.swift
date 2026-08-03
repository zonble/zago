import Foundation
import TextMetrics

/// Generic full-screen, scrollable text viewer for reference-style editor pages.
public final class TextDocumentView {
    private let terminal: Terminal
    private let title: String
    private let lines: [String]
    private let footer: String
    private var topIndex: Int = 0

    public init(terminal: Terminal, title: String, lines: [String], footer: String) {
        self.terminal = terminal
        self.title = title
        self.lines = lines
        self.footer = footer
    }

    public func show() {
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
            case .resize:
                Terminal.clearScreen()
                render()
            case .unknown:
                render()
            default:
                return
            }
        }
    }

    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        var output = "\u{1B}[H"
        output += "\u{1B}[7m\(title.paddedToDisplayWidth(cols))\u{1B}[m\r\n"

        let availableHeight = max(1, rows - 2)
        topIndex = max(0, min(topIndex, max(0, lines.count - availableHeight)))

        for i in 0..<availableHeight {
            let lineIndex = topIndex + i
            let line = lineIndex < lines.count ? lines[lineIndex] : ""
            output += "\u{1B}[K\(line.paddedToDisplayWidth(cols))\r\n"
        }

        output += "\u{1B}[1;36m\(footer.paddedToDisplayWidth(cols))\u{1B}[0m"
        Terminal.write(output)
        fflush(nil)
    }
}
