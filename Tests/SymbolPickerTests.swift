import Config
import Drawing
import Foundation
import Testing

@testable import Editor

private final class MockInputEventTerminal: EditorTerminal, @unchecked Sendable {
    var rows: Int = 24
    var cols: Int = 80
    var events: [InputEvent] = []
    var writtenOutputs: [String] = []

    init(events: [InputEvent] = [], rows: Int = 24, cols: Int = 80) {
        self.events = events
        self.rows = rows
        self.cols = cols
    }

    func enableRawMode() throws {}
    func disableRawMode() {}
    func getWindowSize() -> (rows: Int, cols: Int) { (rows, cols) }
    func readKey() -> Key {
        switch readInputEvent() {
        case .key(let key): return key
        default: return .unknown
        }
    }
    func readInputEvent() -> InputEvent {
        events.isEmpty ? .key(.esc) : events.removeFirst()
    }
    func readPendingText(firstChar: Character) -> String { String(firstChar) }
    func write(_ text: String) { writtenOutputs.append(text) }
    func hideCursor() {}
    func showCursor() {}
    func clearScreen() {}
}

@Suite struct SymbolPickerTests {
    @Test func calloutsAreTheLastSymbolCategory() {
        #expect(
            SymbolCategories.categories.map(\.nameKey) == [
                "symbol_category.arrows",
                "symbol_category.steps",
                "symbol_category.badges",
                "symbol_category.math_keys",
                "symbol_category.gfm",
            ])
        #expect(SymbolCategories.categories.last?.items.first?.symbol == "> [!NOTE]")
        #expect(SymbolCategories.categories[0].layout == .grid(columns: 4))
        #expect(SymbolCategories.categories[4].layout == .list)
    }

    @Test func testSymbolPickerCategorySwitchingAndSelection() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.char("2")),          // Switch to category 1 (Steps)
            .key(.char("3")),          // Switch to category 2 (Badges)
            .key(.char("4")),          // Switch to category 3 (Math)
            .key(.char("5")),          // Switch to category 4 (GFM Callouts)
            .key(.tab),                // Wrap to category 0 (Arrows)
            .key(.char("b")),          // Direct letter shortcut for index 1 in Arrows ('↻')
            .key(.enter),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == "↻")
    }

    @Test func testSymbolPickerGridAndArrowNavigation() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.char("1")),          // Arrows category (4 columns grid)
            .key(.arrowRight),         // index 1 ('↻')
            .key(.arrowDown),          // index 1 + 4 = 5 ('⥁')
            .key(.arrowLeft),          // index 4 ('⥀')
            .key(.arrowUp),            // index 0 ('↺')
            .key(.resize),             // resize event re-renders
            .key(.enter),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == "↺")
    }

    @Test func testSymbolPickerMouseScrollNavigation() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.char("1")),          // Arrows category (4 columns grid)
            .mouse(MouseEvent(action: .scrollDown, col: 10, row: 10)), // + 4 -> index 4 ('⥀')
            .mouse(MouseEvent(action: .scrollDown, col: 10, row: 10)), // + 4 -> index 8 ('⤾')
            .mouse(MouseEvent(action: .scrollUp, col: 10, row: 10)),   // - 4 -> index 4 ('⥀')
            .key(.enter),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == "⥀")
    }

    @Test func testSymbolPickerEscapeCancelsSelection() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.arrowRight),
            .key(.esc),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == nil)
    }

    @Test func testSymbolPickerSmallWindowRenderSafeguard() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [.key(.esc)], rows: 5, cols: 15)
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == nil)
    }

    @Test func testSymbolPickerListLayoutCategory() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.char("5")),          // Category 4 (GFM list)
            .key(.arrowDown),          // Next row in list -> index 1
            .key(.arrowDown),          // Next row in list -> index 2
            .key(.enter),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == "> [!IMPORTANT]")
    }

    @Test func testArrowSymbolsDoNotOverlapWithDrawingArrowsAndAreUnique() {
        let arrowCategory = SymbolCategories.categories[0]
        let symbols = arrowCategory.items.map(\.symbol)

        // 1. Verify all symbols in the Arrows tab are unique
        let uniqueSymbols = Set(symbols)
        #expect(uniqueSymbols.count == symbols.count)

        // 2. Verify no symbol in the Arrows tab can be produced by Canvas drawing arrowheads
        let directions: [CanvasDrawDirection] = [.up, .down, .left, .right]
        var allDrawingArrows = Set<Character>()
        for style in ArrowStyle.allCases {
            for dir in directions {
                allDrawingArrows.insert(arrowHead(for: dir, style: .single, arrowStyle: style))
            }
        }
        allDrawingArrows.formUnion(["▲", "▼", "◀", "▶", "►", "◄", "↑", "↓", "←", "→", "△", "▽", "◁", "▷", "▴", "▾", "◂", "▸", "⇑", "⇓", "⇐", "⇒", "⬆", "⬇", "⬅", "⮕", "➡", "◇", "◆", "●", "○", "✕", "⤘", "⤛", "⤙", "⤚", "↿", "⇂", "↼", "⇀", "⇡", "⇣", "⇠", "⇢", "^", "v", "<", ">"])

        for symbol in symbols {
            if symbol.count == 1, let char = symbol.first {
                #expect(!allDrawingArrows.contains(char), "Symbol '\(symbol)' overlaps with Canvas drawing arrowheads!")
                #expect(!isArrowCharacter(char), "Symbol '\(symbol)' overlaps with isArrowCharacter!")
            }
        }
    }
}

