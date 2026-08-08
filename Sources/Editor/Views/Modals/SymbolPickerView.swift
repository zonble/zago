import Config
import Foundation
import TextMetrics

public struct SymbolItem: Sendable {
    public let symbol: String
    public let descriptionKey: String

    public init(symbol: String, descriptionKey: String) {
        self.symbol = symbol
        self.descriptionKey = descriptionKey
    }
}

public struct SymbolCategory: Sendable {
    public let nameKey: String
    public let items: [SymbolItem]

    public init(nameKey: String, items: [SymbolItem]) {
        self.nameKey = nameKey
        self.items = items
    }
}

public enum SymbolCategories {
    public static let categories: [SymbolCategory] = [
        SymbolCategory(
            nameKey: "symbol_category.gfm",
            items: [
                SymbolItem(symbol: "> [!NOTE]", descriptionKey: "symbol.callout.note"),
                SymbolItem(symbol: "> [!TIP]", descriptionKey: "symbol.callout.tip"),
                SymbolItem(symbol: "> [!IMPORTANT]", descriptionKey: "symbol.callout.important"),
                SymbolItem(symbol: "> [!WARNING]", descriptionKey: "symbol.callout.warning"),
                SymbolItem(symbol: "> [!CAUTION]", descriptionKey: "symbol.callout.caution")
            ]
        ),
        SymbolCategory(
            nameKey: "symbol_category.steps",
            items: [
                SymbolItem(symbol: "①", descriptionKey: "symbol.step.circled_1"),
                SymbolItem(symbol: "②", descriptionKey: "symbol.step.circled_2"),
                SymbolItem(symbol: "③", descriptionKey: "symbol.step.circled_3"),
                SymbolItem(symbol: "④", descriptionKey: "symbol.step.circled_4"),
                SymbolItem(symbol: "⑤", descriptionKey: "symbol.step.circled_5"),
                SymbolItem(symbol: "⑥", descriptionKey: "symbol.step.circled_6"),
                SymbolItem(symbol: "⑦", descriptionKey: "symbol.step.circled_7"),
                SymbolItem(symbol: "⑧", descriptionKey: "symbol.step.circled_8"),
                SymbolItem(symbol: "⑨", descriptionKey: "symbol.step.circled_9"),
                SymbolItem(symbol: "⑩", descriptionKey: "symbol.step.circled_10"),

                SymbolItem(symbol: "❶", descriptionKey: "symbol.step.filled_circled_1"),
                SymbolItem(symbol: "❷", descriptionKey: "symbol.step.filled_circled_2"),
                SymbolItem(symbol: "❸", descriptionKey: "symbol.step.filled_circled_3"),
                SymbolItem(symbol: "❹", descriptionKey: "symbol.step.filled_circled_4"),
                SymbolItem(symbol: "❺", descriptionKey: "symbol.step.filled_circled_5"),
                SymbolItem(symbol: "❻", descriptionKey: "symbol.step.filled_circled_6"),
                SymbolItem(symbol: "❼", descriptionKey: "symbol.step.filled_circled_7"),
                SymbolItem(symbol: "❽", descriptionKey: "symbol.step.filled_circled_8"),
                SymbolItem(symbol: "❾", descriptionKey: "symbol.step.filled_circled_9"),
                SymbolItem(symbol: "❿", descriptionKey: "symbol.step.filled_circled_10"),

                SymbolItem(symbol: "Ⅰ", descriptionKey: "symbol.step.roman_1"),
                SymbolItem(symbol: "Ⅱ", descriptionKey: "symbol.step.roman_2"),
                SymbolItem(symbol: "Ⅲ", descriptionKey: "symbol.step.roman_3"),
                SymbolItem(symbol: "Ⅳ", descriptionKey: "symbol.step.roman_4"),
                SymbolItem(symbol: "Ⅴ", descriptionKey: "symbol.step.roman_5"),
                SymbolItem(symbol: "Ⅵ", descriptionKey: "symbol.step.roman_6"),
                SymbolItem(symbol: "Ⅶ", descriptionKey: "symbol.step.roman_7"),
                SymbolItem(symbol: "Ⅷ", descriptionKey: "symbol.step.roman_8"),
                SymbolItem(symbol: "Ⅸ", descriptionKey: "symbol.step.roman_9"),
                SymbolItem(symbol: "Ⅹ", descriptionKey: "symbol.step.roman_10"),

                SymbolItem(symbol: "ⓐ", descriptionKey: "symbol.step.circled_a"),
                SymbolItem(symbol: "ⓑ", descriptionKey: "symbol.step.circled_b"),
                SymbolItem(symbol: "ⓒ", descriptionKey: "symbol.step.circled_c"),
                SymbolItem(symbol: "ⓓ", descriptionKey: "symbol.step.circled_d"),
                SymbolItem(symbol: "ⓔ", descriptionKey: "symbol.step.circled_e"),

                SymbolItem(symbol: "▸", descriptionKey: "symbol.step.right_pointer_small"),
                SymbolItem(symbol: "▹", descriptionKey: "symbol.step.right_pointer_small_hollow"),
                SymbolItem(symbol: "►", descriptionKey: "symbol.step.right_pointer_med"),
                SymbolItem(symbol: "▻", descriptionKey: "symbol.step.right_pointer_med_hollow")
            ]
        ),
        SymbolCategory(
            nameKey: "symbol_category.badges",
            items: [
                SymbolItem(symbol: "✓", descriptionKey: "symbol.badge.check"),
                SymbolItem(symbol: "✔", descriptionKey: "symbol.badge.heavy_check"),
                SymbolItem(symbol: "✅", descriptionKey: "symbol.badge.check_button"),
                SymbolItem(symbol: "✕", descriptionKey: "symbol.badge.cross"),
                SymbolItem(symbol: "✖", descriptionKey: "symbol.badge.heavy_cross"),

                SymbolItem(symbol: "★", descriptionKey: "symbol.badge.black_star"),
                SymbolItem(symbol: "☆", descriptionKey: "symbol.badge.white_star"),
                SymbolItem(symbol: "◆", descriptionKey: "symbol.badge.black_diamond"),
                SymbolItem(symbol: "◇", descriptionKey: "symbol.badge.white_diamond"),

                SymbolItem(symbol: "💡", descriptionKey: "symbol.badge.bulb"),
                SymbolItem(symbol: "⚠️", descriptionKey: "symbol.badge.warning"),
                SymbolItem(symbol: "📌", descriptionKey: "symbol.badge.pushpin"),
                SymbolItem(symbol: "🚀", descriptionKey: "symbol.badge.rocket"),
                SymbolItem(symbol: "📦", descriptionKey: "symbol.badge.package"),
                SymbolItem(symbol: "📥", descriptionKey: "symbol.badge.inbox"),
                SymbolItem(symbol: "📖", descriptionKey: "symbol.badge.open_book"),
                SymbolItem(symbol: "📚", descriptionKey: "symbol.badge.books"),
                SymbolItem(symbol: "❓", descriptionKey: "symbol.badge.question"),
                SymbolItem(symbol: "💬", descriptionKey: "symbol.badge.speech_balloon"),
                SymbolItem(symbol: "📄", descriptionKey: "symbol.badge.document"),
                SymbolItem(symbol: "⚖️", descriptionKey: "symbol.badge.scale"),
                SymbolItem(symbol: "🤝", descriptionKey: "symbol.badge.handshake"),
                SymbolItem(symbol: "👥", descriptionKey: "symbol.badge.team"),
                SymbolItem(symbol: "🔒", descriptionKey: "symbol.badge.lock"),
                SymbolItem(symbol: "⚡", descriptionKey: "symbol.badge.lightning")
            ]
        ),
        SymbolCategory(
            nameKey: "symbol_category.math_keys",
            items: [
                SymbolItem(symbol: "±", descriptionKey: "symbol.math.plus_minus"),
                SymbolItem(symbol: "×", descriptionKey: "symbol.math.multiply"),
                SymbolItem(symbol: "÷", descriptionKey: "symbol.math.divide"),
                SymbolItem(symbol: "≠", descriptionKey: "symbol.math.not_equal"),
                SymbolItem(symbol: "≈", descriptionKey: "symbol.math.approx_equal"),
                SymbolItem(symbol: "≤", descriptionKey: "symbol.math.less_equal"),
                SymbolItem(symbol: "≥", descriptionKey: "symbol.math.greater_equal"),
                SymbolItem(symbol: "∞", descriptionKey: "symbol.math.infinity"),
                SymbolItem(symbol: "∑", descriptionKey: "symbol.math.summation"),
                SymbolItem(symbol: "∏", descriptionKey: "symbol.math.product"),
                SymbolItem(symbol: "√", descriptionKey: "symbol.math.square_root"),
                SymbolItem(symbol: "∫", descriptionKey: "symbol.math.integral"),
                SymbolItem(symbol: "∈", descriptionKey: "symbol.math.element_of"),
                SymbolItem(symbol: "∉", descriptionKey: "symbol.math.not_element_of"),
                SymbolItem(symbol: "∩", descriptionKey: "symbol.math.intersection"),
                SymbolItem(symbol: "∪", descriptionKey: "symbol.math.union"),

                SymbolItem(symbol: "⌘", descriptionKey: "symbol.key.command"),
                SymbolItem(symbol: "⌥", descriptionKey: "symbol.key.option"),
                SymbolItem(symbol: "⇧", descriptionKey: "symbol.key.shift"),
                SymbolItem(symbol: "⌃", descriptionKey: "symbol.key.control"),
                SymbolItem(symbol: "⎋", descriptionKey: "symbol.key.escape"),
                SymbolItem(symbol: "⏎", descriptionKey: "symbol.key.return"),
                SymbolItem(symbol: "⌫", descriptionKey: "symbol.key.backspace")
            ]
        )
    ]
}

/// Interactive TUI Symbol Picker dialog window.
public final class SymbolPickerView {
    private let terminal: EditorTerminal
    private let language: Language
    private weak var editor: Editor?
    private let onSelect: (String) -> Void

    public var categoryIndex: Int = 0
    public var selectedIndex: Int = 0

    public init(
        terminal: EditorTerminal,
        editor: Editor? = nil,
        language: Language = .detectSystemLanguage(),
        onSelect: @escaping (String) -> Void
    ) {
        self.terminal = terminal
        self.editor = editor
        self.language = language
        self.onSelect = onSelect
    }

    public func show() {
        render()
        while true {
            let key = terminal.readKey()
            switch key {
            case .esc:
                terminal.clearScreen()
                return

            case .char(let ch):
                let lowerStr = String(ch).lowercased()
                if lowerStr == "1" {
                    setCategory(0)
                    render()
                } else if lowerStr == "2" {
                    setCategory(1)
                    render()
                } else if lowerStr == "3" {
                    setCategory(2)
                    render()
                } else if lowerStr == "4" {
                    setCategory(3)
                    render()
                } else if let firstChar = lowerStr.first,
                          let ascii = firstChar.asciiValue,
                          let aVal = Character("a").asciiValue,
                          ascii >= aVal && ascii <= Character("z").asciiValue! {
                    let idx = Int(ascii - aVal)
                    let itemsCount = currentCategoryItems().count
                    if idx >= 0 && idx < itemsCount {
                        selectedIndex = idx
                        render()
                    }
                }

            case .tab:
                setCategory((categoryIndex + 1) % SymbolCategories.categories.count)
                render()

            case .arrowLeft:
                moveSelection(by: -1)
                render()
            case .arrowRight:
                moveSelection(by: 1)
                render()
            case .arrowUp:
                moveSelectionInGrid(rowDelta: -1, colsCount: gridColumnsCount())
                render()
            case .arrowDown:
                moveSelectionInGrid(rowDelta: 1, colsCount: gridColumnsCount())
                render()

            case .enter:
                let currentItems = currentCategoryItems()
                if selectedIndex >= 0 && selectedIndex < currentItems.count {
                    let chosenSymbol = currentItems[selectedIndex].symbol
                    onSelect(chosenSymbol)
                }
                terminal.clearScreen()
                return

            case .resize:
                terminal.clearScreen()
                render()

            default:
                break
            }
        }
    }

    private func letterIndicator(for idx: Int) -> String? {
        guard idx >= 0 && idx < 26 else { return nil }
        let aVal = Character("a").asciiValue!
        let scalar = UnicodeScalar(aVal + UInt8(idx))
        return String(scalar)
    }

    private func currentCategoryItems() -> [SymbolItem] {
        guard categoryIndex >= 0 && categoryIndex < SymbolCategories.categories.count else { return [] }
        return SymbolCategories.categories[categoryIndex].items
    }

    private func setCategory(_ index: Int) {
        if index >= 0 && index < SymbolCategories.categories.count {
            categoryIndex = index
            selectedIndex = 0
        }
    }

    private func moveSelection(by delta: Int) {
        let count = currentCategoryItems().count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + delta + count) % count
    }

    private func gridColumnsCount() -> Int {
        if categoryIndex == 0 {
            return 1
        } else {
            return 5
        }
    }

    private func moveSelectionInGrid(rowDelta: Int, colsCount: Int) {
        let count = currentCategoryItems().count
        guard count > 0 else { return }
        let newIndex = selectedIndex + (rowDelta * colsCount)
        if newIndex >= 0 && newIndex < count {
            selectedIndex = newIndex
        }
    }

    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        guard rows > 6 && cols > 20 else { return }

        let dialogWidth = min(cols - 4, 76)
        let dialogHeight = min(rows - 4, 20)
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
        let title = l10n["dialog.symbol_picker.title"]

        // Top Frame
        let topBar = "╔" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╗"
        output += "\u{001B}[\(startRow);\(startCol)H\(topBar)"
        output += "\u{001B}[\(startRow);\(startCol + 2)H\u{001B}[1m\(title)\u{001B}[0m"

        // Tab Bar
        let tabRow = startRow + 1
        output += "\u{001B}[\(tabRow);\(startCol)H║"
        output += String(repeating: " ", count: max(0, dialogWidth - 2))
        output += "\u{001B}[\(tabRow);\(startCol + dialogWidth - 1)H║"

        var currentTabCol = startCol + 2
        for (idx, cat) in SymbolCategories.categories.enumerated() {
            let catName = l10n[cat.nameKey]
            output += "\u{001B}[\(tabRow);\(currentTabCol)H"
            if idx == categoryIndex {
                output += "\u{001B}[7;1m[\(catName)]\u{001B}[0m"
                currentTabCol += catName.displayWidth + 3
            } else {
                output += " \(catName) "
                currentTabCol += catName.displayWidth + 3
            }
        }

        // Separator
        let sepRow = startRow + 2
        let midBar = "╠" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╣"
        output += "\u{001B}[\(sepRow);\(startCol)H\(midBar)"

        // Grid Content
        let items = currentCategoryItems()
        let contentRows = dialogHeight - 6
        let contentStartRow = startRow + 3

        for r in 0..<contentRows {
            let currentRow = contentStartRow + r
            output += "\u{001B}[\(currentRow);\(startCol)H║"
            output += String(repeating: " ", count: max(0, dialogWidth - 2))
            output += "\u{001B}[\(currentRow);\(startCol + dialogWidth - 1)H║"
        }

        // Draw items with letter indicators [a]..[z]
        if categoryIndex == 0 {
            // GFM Callout List Mode - uniform full row selection bar
            let maxListWidth = max(10, dialogWidth - 6)
            for (idx, item) in items.enumerated() {
                if idx < contentRows {
                    let r = contentStartRow + idx
                    output += "\u{001B}[\(r);\(startCol + 3)H"
                    let hint = letterIndicator(for: idx).map { "[\($0)] " } ?? "    "
                    let rawStr = "\(hint)\(item.symbol)"
                    let paddedStr = rawStr.paddedToDisplayWidth(maxListWidth)
                    if idx == selectedIndex {
                        output += "\u{001B}[7;1m\(paddedStr)\u{001B}[0m"
                    } else {
                        output += paddedStr
                    }
                }
            }
        } else {
            // Grid Mode - uniform cell width selection bar
            let colsCount = 5
            let cellWidth = 13
            for (idx, item) in items.enumerated() {
                let rowOffset = idx / colsCount
                let colOffset = idx % colsCount
                if rowOffset < contentRows {
                    let r = contentStartRow + rowOffset
                    let c = startCol + 3 + (colOffset * 14)
                    output += "\u{001B}[\(r);\(c)H"
                    let hint = letterIndicator(for: idx).map { "[\($0)]" } ?? "   "
                    let rawStr = " \(hint) \(item.symbol) "
                    let paddedStr = rawStr.paddedToDisplayWidth(cellWidth)
                    if idx == selectedIndex {
                        output += "\u{001B}[7;1m\(paddedStr)\u{001B}[0m"
                    } else {
                        output += paddedStr
                    }
                }
            }
        }

        // Preview Line
        let previewRow = startRow + dialogHeight - 3
        output += "\u{001B}[\(previewRow);\(startCol)H║"
        output += String(repeating: " ", count: max(0, dialogWidth - 2))
        output += "\u{001B}[\(previewRow);\(startCol + dialogWidth - 1)H║"

        if selectedIndex >= 0 && selectedIndex < items.count {
            let item = items[selectedIndex]
            let desc = l10n[item.descriptionKey]
            let previewText = "\(l10n["dialog.symbol_picker.selected"])\(item.symbol) (\(desc))"
            output += "\u{001B}[\(previewRow);\(startCol + 1)H\(previewText)"
        }

        // Footer Instruction Line (inside the dialog box)
        let footerRow = startRow + dialogHeight - 2
        output += "\u{001B}[\(footerRow);\(startCol)H║"
        output += String(repeating: " ", count: max(0, dialogWidth - 2))
        output += "\u{001B}[\(footerRow);\(startCol + dialogWidth - 1)H║"

        let footerText = l10n["dialog.symbol_picker.footer"]
        output += "\u{001B}[\(footerRow);\(startCol + 2)H\u{001B}[1;36m\(footerText)\u{001B}[0m"

        // Bottom Frame
        let bottomRow = startRow + dialogHeight - 1
        let bottomBar = "╚" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╝"
        output += "\u{001B}[\(bottomRow);\(startCol)H\(bottomBar)"

        terminal.write(output)
        fflush(nil)
    }
}
