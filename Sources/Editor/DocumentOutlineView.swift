import Foundation
import Syntax
import TextMetrics

public final class DocumentOutlineView {
    private let terminal: Terminal
    private let title: String
    private let headings: [DocumentHeading]
    private let footer: String
    private var selectedIndex: Int
    private var topIndex: Int = 0

    public init(
        terminal: Terminal,
        title: String,
        headings: [DocumentHeading],
        footer: String,
        initialSelectedIndex: Int = 0
    ) {
        self.terminal = terminal
        self.title = title
        self.headings = headings
        self.footer = footer
        self.selectedIndex = max(0, min(initialSelectedIndex, max(0, headings.count - 1)))
    }

    public func show() -> DocumentHeading? {
        render()
        while true {
            let key = terminal.readKey()
            let (rows, _) = terminal.getWindowSize()
            let availableHeight = max(1, rows - 2)
            let maxTop = max(0, headings.count - availableHeight)

            switch key {
            case .arrowDown, .char("j"), .char("J"):
                selectedIndex = min(selectedIndex + 1, max(0, headings.count - 1))
                ensureSelectionVisible(availableHeight: availableHeight)
                render()
            case .arrowUp, .char("k"), .char("K"):
                selectedIndex = max(0, selectedIndex - 1)
                ensureSelectionVisible(availableHeight: availableHeight)
                render()
            case .pageDown, .char(" "):
                selectedIndex = min(selectedIndex + availableHeight, max(0, headings.count - 1))
                topIndex = min(topIndex + availableHeight, maxTop)
                ensureSelectionVisible(availableHeight: availableHeight)
                render()
            case .pageUp:
                selectedIndex = max(0, selectedIndex - availableHeight)
                topIndex = max(0, topIndex - availableHeight)
                ensureSelectionVisible(availableHeight: availableHeight)
                render()
            case .home:
                selectedIndex = 0
                topIndex = 0
                render()
            case .end:
                selectedIndex = max(0, headings.count - 1)
                topIndex = maxTop
                render()
            case .enter:
                guard headings.indices.contains(selectedIndex) else { return nil }
                return headings[selectedIndex]
            case .resize:
                Terminal.clearScreen()
                ensureSelectionVisible(availableHeight: availableHeight)
                render()
            case .unknown:
                render()
            default:
                return nil
            }
        }
    }

    public static func rows(for headings: [DocumentHeading]) -> [String] {
        headings.map { heading in
            let lineNumber = String(format: "%4d", heading.lineIndex + 1)
            let indent = String(repeating: "  ", count: max(0, heading.level - 1))
            return "\(lineNumber)  \(indent)\(heading.marker) \(heading.title)"
        }
    }

    private func ensureSelectionVisible(availableHeight: Int) {
        if selectedIndex < topIndex {
            topIndex = selectedIndex
        } else if selectedIndex >= topIndex + availableHeight {
            topIndex = max(0, selectedIndex - availableHeight + 1)
        }
    }

    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        let availableHeight = max(1, rows - 2)
        let maxTop = max(0, headings.count - availableHeight)
        topIndex = max(0, min(topIndex, maxTop))
        ensureSelectionVisible(availableHeight: availableHeight)

        let outlineRows = Self.rows(for: headings)
        var output = "\u{1B}[H"
        output += "\u{1B}[7m\(title.paddedToDisplayWidth(cols))\u{1B}[m\r\n"

        for i in 0..<availableHeight {
            let rowIndex = topIndex + i
            let row = rowIndex < outlineRows.count ? outlineRows[rowIndex] : ""
            let padded = row.paddedToDisplayWidth(cols)
            if rowIndex == selectedIndex {
                output += "\u{1B}[7m\(padded)\u{1B}[m\r\n"
            } else {
                output += "\u{1B}[K\(padded)\r\n"
            }
        }

        output += "\u{1B}[1;36m\(footer.paddedToDisplayWidth(cols))\u{1B}[0m"
        Terminal.write(output)
        fflush(nil)
    }
}
