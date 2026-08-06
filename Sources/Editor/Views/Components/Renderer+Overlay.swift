import Foundation
import TextMetrics

extension Renderer {
    /// Slices line text (including ANSI syntax highlight sequences) cleanly to insert a 2D dropdown box segment.
    func sliceOverlayLine(
        baseFullLineStr: String,
        boxLine: String,
        dropdownStartCol: Int,
        dropdownBoxWidth: Int,
        cols: Int,
        isDim: Bool = false,
        showLineNumbers: Bool = false,
        gutterWidth: Int = 0
    ) -> String {
        var leftStr = ""
        var rightStr = ""
        var currentVisCol = 0
        var activeAnsiStyle = ""
        var inAnsi = false
        var currentAnsiSeq = ""

        let rightStartCol = dropdownStartCol + dropdownBoxWidth
        let chars = Array(baseFullLineStr)
        var i = 0

        while i < chars.count {
            let ch = chars[i]

            if ch == "\u{1B}" {
                inAnsi = true
                currentAnsiSeq = "\u{1B}"
                i += 1
                continue
            }

            if inAnsi {
                currentAnsiSeq.append(ch)
                if ch == "m" || ch == "H" || ch == "J" || ch == "K" {
                    inAnsi = false
                    if currentAnsiSeq != "\u{1B}[0m" && currentAnsiSeq != "\u{1B}[m" {
                        activeAnsiStyle = currentAnsiSeq
                    } else {
                        activeAnsiStyle = ""
                    }
                    if currentVisCol < dropdownStartCol {
                        leftStr += currentAnsiSeq
                    } else if currentVisCol >= rightStartCol {
                        rightStr += currentAnsiSeq
                    }
                    currentAnsiSeq = ""
                }
                i += 1
                continue
            }

            let chW = ch.displayWidth
            let nextVisCol = currentVisCol + chW

            if currentVisCol < dropdownStartCol && nextVisCol > dropdownStartCol {
                leftStr += String(repeating: " ", count: dropdownStartCol - currentVisCol)
            } else if currentVisCol < dropdownStartCol {
                leftStr.append(ch)
            } else if currentVisCol < rightStartCol && nextVisCol > rightStartCol {
                rightStr += String(repeating: " ", count: nextVisCol - rightStartCol)
            } else if currentVisCol >= rightStartCol {
                rightStr.append(ch)
            }

            currentVisCol = nextVisCol
            i += 1
        }

        if currentVisCol < dropdownStartCol {
            leftStr += String(repeating: " ", count: dropdownStartCol - currentVisCol)
        }

        if isDim {
            leftStr = leftStr.ansiStyled(style: ANSIStyle.dimGray)
        }

        let remainingRight = max(0, cols - rightStartCol - rightStr.displayWidth)
        if remainingRight > 0 {
            rightStr += String(repeating: " ", count: remainingRight)
        }

        if isDim {
            rightStr = rightStr.ansiStyled(style: ANSIStyle.dimGray)
        } else if !activeAnsiStyle.isEmpty {
            rightStr = rightStr.ansiStyled(style: activeAnsiStyle)
        }

        let boxStartCursor = "\u{1B}[\(dropdownStartCol + 1)G"
        let rightStartCursor = "\u{1B}[\(rightStartCol + 1)G"
        return leftStr + ANSIStyle.reset + boxStartCursor + boxLine + ANSIStyle.reset + rightStartCursor + rightStr
    }

    /// Generates 2D dropdown box overlay lines for active menu category.
    func generateDropdownOverlayLines(editor: Editor, cols: Int) -> (
        startCol: Int, boxWidth: Int, boxLines: [String]
    ) {
        guard editor.isMenuBarActive else { return (0, 0, []) }

        var colOffset = 1
        for idx in 0..<editor.menuBar.categoryIndex {
            let title = editor.l10n[editor.menuBar.categories[idx].titleKey]
            colOffset += title.displayWidth + 2
        }

        let cat = editor.menuBar.currentCategory
        let items = cat.items
        guard !items.isEmpty else { return (colOffset, 0, []) }

        var formattedItems: [String] = []
        for item in items {
            let rawStr = editor.l10n[item.titleKey]
            let parts = rawStr.components(separatedBy: "\t")
            let labelPrefix = (item.isChecked?(editor) ?? false) ? "✓ " : "  "
            let label = labelPrefix + parts[0]
            let shortcut = parts.count > 1 ? parts[1] : ""
            formattedItems.append("\(label)\t\(shortcut)")
        }

        let maxLabelW = formattedItems.map { $0.components(separatedBy: "\t")[0].displayWidth }.max() ?? 10
        let maxShortW = formattedItems.map { $0.components(separatedBy: "\t")[1].displayWidth }.max() ?? 0
        let innerWidth = max(20, maxLabelW + maxShortW + 4)
        let boxWidth = innerWidth + 2

        let topBorder = "\(ANSIStyle.menuDefault)┌" + String(repeating: "─", count: innerWidth) + "┐\(ANSIStyle.reset)"
        let bottomBorder = "\(ANSIStyle.menuDefault)└" + String(repeating: "─", count: innerWidth) + "┘\(ANSIStyle.reset)"

        var boxLines: [String] = [topBorder]
        for (iIdx, item) in items.enumerated() {
            let rawStr = editor.l10n[item.titleKey]
            let parts = rawStr.components(separatedBy: "\t")
            let labelPrefix = (item.isChecked?(editor) ?? false) ? "✓ " : "  "
            let label = labelPrefix + parts[0]
            let shortcut = parts.count > 1 ? parts[1] : ""

            let spaceCount = max(1, innerWidth - label.displayWidth - shortcut.displayWidth - 2)
            let itemLine = " " + label + String(repeating: " ", count: spaceCount) + shortcut + " "

            if iIdx == editor.menuBar.itemIndex {
                boxLines.append("\(ANSIStyle.menuDefault)│\(ANSIStyle.menuSelected)\(itemLine)\(ANSIStyle.menuReset)│\(ANSIStyle.reset)")
            } else {
                boxLines.append("\(ANSIStyle.menuDefault)│\(itemLine)│\(ANSIStyle.reset)")
            }
        }
        boxLines.append(bottomBorder)

        let clampedStartCol = max(0, min(colOffset, cols - boxWidth))
        return (clampedStartCol, boxWidth, boxLines)
    }
}
