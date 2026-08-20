@testable import Editor
import Foundation
@testable import SystemClipboard
import Testing

@Suite struct SystemClipboardTests {
    @Test func testInMemoryClipboardStrategyTextAndBlock() {
        let strategy = InMemoryClipboardStrategy()

        #expect(strategy.getText() == nil)
        #expect(strategy.getBlock() == nil)

        strategy.copyText("Hello, World!")
        #expect(strategy.getText() == "Hello, World!")
        #expect(strategy.getBlock() == nil)

        let block = CanvasBlockClipboard(width: 6, rows: ["+----+", "|嗨  |", "+----+"])
        strategy.copyBlock(block)

        #expect(strategy.getBlock() == block)

        strategy.copyText("Only linear text")
        #expect(strategy.getText() == "Only linear text")

        strategy.clear()
        #expect(strategy.getText() == nil)
        #expect(strategy.getBlock() == nil)
    }

    @Test func testSystemClipboardStrategyRoundTrip() {
        let clipboard = SystemClipboardStrategy()

        clipboard.copyText("Zago Terminal Editor")
        #expect(clipboard.getText() == "Zago Terminal Editor")
        #expect(clipboard.getBlock() == nil)

        let block = CanvasBlockClipboard(
            width: 8,
            rows: [
                "┌──────┐",
                "│ Zago │",
                "└──────┘",
            ]
        )
        clipboard.copyBlock(block)

        #expect(clipboard.getBlock() == block)
        #expect(clipboard.getText()?.contains("Zago") == true)

        clipboard.copyText("Resetting to plain text")
        #expect(clipboard.getText() == "Resetting to plain text")
        #expect(clipboard.getBlock() == nil)

        clipboard.clear()
    }

    @Test func testClipboardCoordinatorDelegation() {
        let strategy = InMemoryClipboardStrategy()
        let coordinator = ClipboardCoordinator(strategy: strategy)

        coordinator.clipboardText = "Custom Text"
        #expect(strategy.getText() == "Custom Text")
        #expect(coordinator.clipboardText == "Custom Text")

        let block = CanvasBlockClipboard(width: 4, rows: ["AAAA", "BBBB"])
        coordinator.canvasBlockClipboard = block
        #expect(strategy.getBlock() == block)
        #expect(coordinator.canvasBlockClipboard == block)

        coordinator.clear()
        #expect(coordinator.clipboardText == nil)
        #expect(coordinator.canvasBlockClipboard == nil)
    }

    @Test func testEditorCanvasBlockCopyAndPasteUsingInjectedClipboard() {
        let mockStrategy = InMemoryClipboardStrategy()
        let editor = Editor(
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared,
                clipboardStrategy: mockStrategy
            )
        )
        editor.switchToCanvasMode()
        editor.buffer.lines = [
            "123456",
            "abcdef",
            "ABCDEF",
        ]

        // Mark rectangle: line 0..2, visual col 1..3 (width 3)
        editor.buffer.canvasBlockMark = (line: 0, visualColumn: 1)
        editor.buffer.canvasBlockMarkEnd = (line: 2, visualColumn: 3)
        editor.buffer.lineIndex = 2
        editor.canvasVisualColumn = 3

        #expect(editor.copyCanvasBlock() == true)

        let block = mockStrategy.getBlock()
        #expect(block != nil)
        #expect(block?.width == 3)
        #expect(block?.rows == ["234", "bcd", "BCD"])

        // Paste block at line 0, column 0 in a fresh buffer
        let targetEditor = Editor(
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared,
                clipboardStrategy: mockStrategy
            )
        )
        targetEditor.switchToCanvasMode()
        targetEditor.buffer.lines = ["......", "......", "......"]
        targetEditor.buffer.lineIndex = 0
        targetEditor.canvasVisualColumn = 0

        targetEditor.pasteCanvasBlock()
        #expect(targetEditor.buffer.lines[0] == "234......")
        #expect(targetEditor.buffer.lines[1] == "bcd......")
        #expect(targetEditor.buffer.lines[2] == "BCD......")
    }
}
