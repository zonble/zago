import Foundation
import Testing

@testable import Config
@testable import Editor

@Test func testSmartTabBlockIndentAndOutdentEdgeCases() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "Line 1",
        "  Line 2 with 2 spaces",
        "    Line 3 with 4 spaces",
    ]

    // 1. Select Line 1 to Line 3
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    editor.buffer.selectionMark = (line: 2, column: 10)

    // Indent block (4 spaces)
    _ = editor.commandRegistry.dispatch(key: Key.tab, editor: editor)
    #expect(editor.buffer.lines[0] == "    Line 1")
    #expect(editor.buffer.lines[1] == "      Line 2 with 2 spaces")
    #expect(editor.buffer.lines[2] == "        Line 3 with 4 spaces")
    #expect(editor.buffer.selectionMark?.line == 2)
    #expect(editor.buffer.selectionMark?.column == 14)

    // Outdent block (4 spaces)
    _ = editor.commandRegistry.dispatch(key: Key.backtab, editor: editor)
    #expect(editor.buffer.lines[0] == "Line 1")
    #expect(editor.buffer.lines[1] == "  Line 2 with 2 spaces")
    #expect(editor.buffer.lines[2] == "    Line 3 with 4 spaces")

    // Outdent block again (Line 1 has 0 spaces -> stays 0; Line 2 has 2 spaces -> outdents 2; Line 3 has 4 -> outdents 4)
    _ = editor.commandRegistry.dispatch(key: Key.backtab, editor: editor)
    #expect(editor.buffer.lines[0] == "Line 1")
    #expect(editor.buffer.lines[1] == "Line 2 with 2 spaces")
    #expect(editor.buffer.lines[2] == "Line 3 with 4 spaces")
}

@Test func testSmartTabMarkupListItemsAllFormats() throws {
    let listSamples = [
        "- Markdown dash",
        "* Asterisk item",
        "+ Plus item",
        ". AsciiDoc dot",
        ".. AsciiDoc double dot",
        "1. Numbered item",
        "1) Org numbered item",
        "a. Lettered item",
        "#." + " ReST auto numbered",
    ]

    for sample in listSamples {
        let editor = Editor(filePath: "test.md")
        editor.buffer.lines = [sample]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0

        #expect(editor.isListItemLine(at: 0) == true)

        // Indent list item by default listIndentSize (2 spaces)
        _ = editor.commandRegistry.dispatch(key: Key.tab, editor: editor)
        #expect(editor.buffer.lines[0] == "  " + sample)

        // Outdent list item back
        _ = editor.commandRegistry.dispatch(key: Key.backtab, editor: editor)
        #expect(editor.buffer.lines[0] == sample)
    }
}

@Test func testSmartTabWordBoundaryAlignmentAndLeadingWhitespace() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "  leading text",
        "alpha beta gamma",
    ]

    // 1. Cursor inside leading whitespace (col 1) -> Line Indent by 4 spaces
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 1
    _ = editor.commandRegistry.dispatch(key: Key.tab, editor: editor)
    #expect(editor.buffer.lines[0] == "      leading text")

    // 2. Cursor in middle of word ("al|pha", col 2) -> Aligns to next Tab Stop (col 4, inserting 2 spaces)
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    _ = editor.commandRegistry.dispatch(key: Key.tab, editor: editor)
    #expect(editor.buffer.lines[1] == "al  pha beta gamma")
    #expect(editor.buffer.columnIndex == 4)

    // 3. Cursor at Tab Stop (col 4) -> Inserts 4 spaces to reach next Tab Stop (col 8)
    _ = editor.commandRegistry.dispatch(key: Key.tab, editor: editor)
    #expect(editor.buffer.lines[1] == "al      pha beta gamma")
    #expect(editor.buffer.columnIndex == 8)
}

@Test func testSmartTabZagorcConfigurationDirectives() throws {
    let configStr = """
    set smart_tab false
    set list_indent_size 4
    set tab_size 2
    """
    let mockProvider = InMemoryConfigFileProvider(homePath: "/home/user", files: ["/home/user/.zagorc": configStr])
    let loader = ConfigLoader(provider: mockProvider)
    let config = loader.loadConfig()
    #expect(config.smartTab == false)
    #expect(config.listIndentSize == 4)
    #expect(config.tabSize == 2)

    // Verify Editor behavior with smart_tab = false (raw tab spaces insertion)
    let editor = Editor()
    editor.displayConfig.smartTab = config.smartTab
    editor.displayConfig.listIndentSize = config.listIndentSize
    editor.displayConfig.tabSize = config.tabSize

    editor.buffer.lines = ["- List item"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0

    // With smart_tab false, pressing Tab inserts raw tab_size spaces (2 spaces) at cursor without smart list indenting
    let handled = editor.commandRegistry.dispatch(key: Key.tab, editor: editor)
    #expect(handled == true)
    #expect(editor.buffer.lines[0] == "  - List item")
    #expect(editor.buffer.columnIndex == 2)
}

@Test func testBlockIndentUndoRestoresSelectionMark() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "Line 1",
        "Line 2",
    ]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    editor.buffer.selectionMark = (line: 1, column: 6)

    // Save initial selection mark
    let originalMarkLine = editor.buffer.selectionMark?.line
    let originalMarkCol = editor.buffer.selectionMark?.column

    // Press Tab -> Indents block, moves selectionMark
    _ = editor.commandRegistry.dispatch(key: Key.tab, editor: editor)
    #expect(editor.buffer.selectionMark?.line == 1)
    #expect(editor.buffer.selectionMark?.column == 10)

    // Press Undo -> Restores lines AND selectionMark to original exact coordinates
    _ = editor.commandRegistry.dispatch(key: Key.ctrl("z"), editor: editor)
    #expect(editor.buffer.lines[0] == "Line 1")
    #expect(editor.buffer.lines[1] == "Line 2")
    #expect(editor.buffer.selectionMark?.line == originalMarkLine)
    #expect(editor.buffer.selectionMark?.column == originalMarkCol)
}
