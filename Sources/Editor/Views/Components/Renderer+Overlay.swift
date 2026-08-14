import ANSIStyle
import Foundation
import TextMetrics

extension Renderer {
    /// Slices line text (including ANSI syntax highlight sequences) cleanly to insert a 2D dropdown box segment.
    ///
    /// - Parameters:
    ///   - baseFullLineStr: The already-rendered full screen line that the dropdown segment will overlay.
    ///   - boxLine: The pre-rendered dropdown box segment to place at `dropdownStartCol`.
    ///   - dropdownStartCol: Zero-based visual column where `boxLine` starts.
    ///   - dropdownBoxWidth: Display width occupied by `boxLine`.
    ///   - cols: Total terminal column count used to pad the right-side remainder.
    ///   - isDim: Whether to dim the non-overlay text around the dropdown segment.
    /// - Returns: A line composed from the left remainder, dropdown segment, and right remainder.
    func sliceOverlayLine(
        baseFullLineStr: String,
        boxLine: String,
        dropdownStartCol: Int,
        dropdownBoxWidth: Int,
        cols: Int,
        isDim: Bool = false
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
            let label = labelPrefix + plainMenuTitleWithHotkey(parts[0], hotkeyChar: item.hotkeyChar)
            let shortcut: String
            if let cmd = item.commandId, let keyLabel = editor.keymapManager.primaryKeyLabel(for: cmd, in: editor.currentMode) {
                shortcut = keyLabel
            } else if parts.count > 1 {
                shortcut = parts[1]
            } else {
                shortcut = ""
            }
            formattedItems.append("\(label)\t\(shortcut)")
        }

        let maxLabelW = formattedItems.map { $0.components(separatedBy: "\t")[0].displayWidth }.max() ?? 10
        let maxShortW = formattedItems.map { $0.components(separatedBy: "\t")[1].displayWidth }.max() ?? 0
        let innerWidth = max(20, maxLabelW + maxShortW + 4)
        let boxWidth = innerWidth + 2

        let topBorder = "\(ANSIStyle.menuDefault)┌" + String(repeating: "─", count: innerWidth) + "┐\(ANSIStyle.reset)"
        let bottomBorder =
            "\(ANSIStyle.menuDefault)└" + String(repeating: "─", count: innerWidth) + "┘\(ANSIStyle.reset)"

        var boxLines: [String] = [topBorder]
        for (iIdx, item) in items.enumerated() {
            let rawStr = editor.l10n[item.titleKey]
            let parts = rawStr.components(separatedBy: "\t")
            let labelPrefix = (item.isChecked?(editor) ?? false) ? "✓ " : "  "
            let rawLabel = labelPrefix + plainMenuTitleWithHotkey(parts[0], hotkeyChar: item.hotkeyChar)
            let styledLabel =
                labelPrefix
                + menuTitleWithUnderlinedHotkey(parts[0], hotkeyChar: item.hotkeyChar, appendMissingHotkey: true)
            let shortcut: String
            if let cmd = item.commandId, let keyLabel = editor.keymapManager.primaryKeyLabel(for: cmd, in: editor.currentMode) {
                shortcut = keyLabel
            } else if parts.count > 1 {
                shortcut = parts[1]
            } else {
                shortcut = ""
            }

            let spaceCount = max(1, innerWidth - rawLabel.displayWidth - shortcut.displayWidth - 2)
            let itemLine = " " + styledLabel + String(repeating: " ", count: spaceCount) + shortcut + " "

            if iIdx == editor.menuBar.itemIndex {
                boxLines.append(
                    "\(ANSIStyle.menuDefault)│\(ANSIStyle.menuSelected)\(itemLine)\(ANSIStyle.menuReset)│\(ANSIStyle.reset)"
                )
            } else {
                boxLines.append("\(ANSIStyle.menuDefault)│\(itemLine)│\(ANSIStyle.reset)")
            }
        }
        boxLines.append(bottomBorder)

        let clampedStartCol = max(0, min(colOffset, cols - boxWidth))
        return (clampedStartCol, boxWidth, boxLines)
    }

    private func plainMenuTitleWithHotkey(_ title: String, hotkeyChar: Character) -> String {
        let hotkey = String(hotkeyChar).lowercased()
        if title.contains(where: { String($0).lowercased() == hotkey }) {
            return title
        }
        return "\(title) (\(displayMenuHotkey(hotkeyChar)))"
    }
}
