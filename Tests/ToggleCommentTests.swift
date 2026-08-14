import Testing

@testable import Editor

@Test func testToggleCommentSwiftLine() throws {
    let editor = Editor()
    editor.openNewBuffer(filePath: "test.swift")
    editor.buffer.lines = ["let x = 10", "let y = 20"]
    editor.buffer.lineIndex = 0

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "// let x = 10")

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "let x = 10")
}

@Test func testToggleCommentPythonLinePreservesIndent() throws {
    let editor = Editor()
    editor.openNewBuffer(filePath: "test.py")
    editor.buffer.lines = ["    x = 10"]
    editor.buffer.lineIndex = 0

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "    # x = 10")

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "    x = 10")
}

@Test func testToggleCommentLogoLine() throws {
    let editor = Editor()
    editor.openNewBuffer(filePath: "test.logo")
    editor.buffer.lines = ["line 4 double"]
    editor.buffer.lineIndex = 0

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "; line 4 double")

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "line 4 double")
}

@Test func testToggleCommentMarkdownEmbeddedPythonCodeBlock() throws {
    let editor = markdownCommentFixture()
    editor.buffer.lineIndex = 3

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)

    #expect(editor.buffer.lines[3] == "# val = 42")
}

@Test func testToggleCommentMarkdownEmbeddedLogoCodeBlock() throws {
    let editor = markdownCommentFixture()
    editor.buffer.lineIndex = 7

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)

    #expect(editor.buffer.lines[7] == "; fd 100")
}

@Test func testToggleCommentMarkdownDocumentLineUsesHtmlComment() throws {
    let editor = markdownCommentFixture()
    editor.buffer.lineIndex = 0

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "<!-- # Markdown Title -->")

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "# Markdown Title")
}

@Test func testToggleCommentCppLine() throws {
    let editor = Editor()
    editor.openNewBuffer(filePath: "main.cpp")
    editor.buffer.lines = ["int main() {"]
    editor.buffer.lineIndex = 0

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "// int main() {")

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "int main() {")
}

@Test func testToggleCommentWikiLineUsesHtmlComment() throws {
    let editor = Editor()
    editor.openNewBuffer(filePath: "article.wiki")
    editor.buffer.lines = ["== Heading =="]
    editor.buffer.lineIndex = 0

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "<!-- == Heading == -->")

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "== Heading ==")
}

@Test func testToggleCommentSelectionWithEmptyLines() throws {
    let editor = Editor()
    editor.openNewBuffer(filePath: "main.swift")
    editor.buffer.lines = [
        "┌────┐",
        "│ hi │",
        "└────┘",
        "  ",
        "",
    ]
    editor.buffer.selectionMark = (line: 0, column: 0)
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 2

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "// ┌────┐")
    #expect(editor.buffer.lines[1] == "// │ hi │")
    #expect(editor.buffer.lines[2] == "// └────┘")
    #expect(editor.buffer.lines[3] == "//")

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)
    #expect(editor.buffer.lines[0] == "┌────┐")
    #expect(editor.buffer.lines[1] == "│ hi │")
    #expect(editor.buffer.lines[2] == "└────┘")
    #expect(editor.buffer.lines[3] == "")
}

private func markdownCommentFixture() -> Editor {
    let editor = Editor()
    editor.openNewBuffer(filePath: "README.md")
    editor.buffer.lines = [
        "# Markdown Title",
        "",
        "```python",
        "val = 42",
        "```",
        "",
        "```logo",
        "fd 100",
        "```",
    ]
    return editor
}
