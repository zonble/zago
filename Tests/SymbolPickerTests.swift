import Config
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
                "symbol_category.steps",
                "symbol_category.badges",
                "symbol_category.math_keys",
                "symbol_category.gfm",
            ])
        #expect(SymbolCategories.categories.last?.items.first?.symbol == "> [!NOTE]")
        #expect(SymbolCategories.categories[0].layout == .grid(columns: 5))
        #expect(SymbolCategories.categories[3].layout == .list)
    }

    @Test func testSymbolPickerCategorySwitchingAndSelection() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.char("2")),          // Switch to category 1 (Badges)
            .key(.char("3")),          // Switch to category 2 (Math)
            .key(.char("4")),          // Switch to category 3 (GFM Callouts)
            .key(.tab),                // Wrap to category 0 (Steps)
            .key(.char("b")),          // Direct letter shortcut for index 1 ('②')
            .key(.enter),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == "②")
    }

    @Test func testSymbolPickerGridAndArrowNavigation() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.char("1")),          // Steps category (5 columns grid)
            .key(.arrowRight),         // index 1
            .key(.arrowDown),          // index 1 + 5 = 6
            .key(.arrowLeft),          // index 5
            .key(.arrowUp),            // index 0
            .key(.resize),             // resize event re-renders
            .key(.enter),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == "①")
    }

    @Test func testSymbolPickerMouseScrollNavigation() {
        var chosen: String? = nil
        let terminal = MockInputEventTerminal(events: [
            .key(.char("1")),
            .mouse(MouseEvent(action: .scrollDown, col: 10, row: 10)), // + 5 -> index 5
            .mouse(MouseEvent(action: .scrollDown, col: 10, row: 10)), // + 5 -> index 10
            .mouse(MouseEvent(action: .scrollUp, col: 10, row: 10)),   // - 5 -> index 5
            .key(.enter),
        ])
        let picker = SymbolPickerView(terminal: terminal, language: .en) { symbol in
            chosen = symbol
        }
        picker.show()
        #expect(chosen == "⑥") // Index 5 in Steps category is '⑥'
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
            .key(.char("4")),          // Category 3 (GFM list)
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
}

