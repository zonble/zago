import Testing

@testable import Editor

@Suite struct SymbolPickerTests {
    @Test func calloutsAreTheLastSymbolCategory() {
        #expect(SymbolCategories.categories.map(\.nameKey) == [
            "symbol_category.steps",
            "symbol_category.badges",
            "symbol_category.math_keys",
            "symbol_category.gfm",
        ])
        #expect(SymbolCategories.categories.last?.items.first?.symbol == "> [!NOTE]")
        #expect(SymbolCategories.categories[0].layout == .grid(columns: 5))
        #expect(SymbolCategories.categories[3].layout == .list)
    }
}
