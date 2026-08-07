import Foundation
import Testing

@testable import Config
@testable import Editor

@Test func testEditorOptionsInitialLineAndColumnPositioning() throws {
    let deps = EditorDependencies(
        fileIOStrategy: MemoryEditorFileIOStrategy(),
        terminal: TestEditorTerminal.shared
    )
    let options = EditorOptions(
        filePaths: ["test.txt"],
        initialLine: 42,
        initialColumn: 10
    )
    let editor = Editor(options: options, dependencies: deps)
    // Add dummy lines so line 42 can be jumped to
    editor.buffer.lines = Array(repeating: "Line text content", count: 50)
    editor.goToLocation(line: 42, column: 10)

    #expect(editor.buffer.lineIndex == 41)
    #expect(editor.buffer.columnIndex == 9)
}

@Test func testEditorOptionsPipedInputAndReadOnlyMode() throws {
    let deps = EditorDependencies(
        fileIOStrategy: MemoryEditorFileIOStrategy(),
        terminal: TestEditorTerminal.shared
    )
    let options = EditorOptions(
        readOnly: true,
        pipedInput: "Piped Line 1\nPiped Line 2\nPiped Line 3"
    )
    let editor = Editor(options: options, dependencies: deps)

    #expect(editor.buffer.isReadOnly == true)
    #expect(editor.buffer.lines.count == 3)
    #expect(editor.buffer.lines[0] == "Piped Line 1")
    #expect(editor.buffer.lines[1] == "Piped Line 2")
    #expect(editor.buffer.lines[2] == "Piped Line 3")
}
