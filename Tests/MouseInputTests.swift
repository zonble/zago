import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import zago

@Suite struct MouseInputTests {

    @Test func testSGRMouseSequenceParsing() throws {
        // Left click press at col 20, row 10
        let leftPress = ANSIKeyMapping.parseSGRMouseEvent("<0;20;10M")
        #expect(leftPress != nil)
        #expect(leftPress?.action == .press(.left))
        #expect(leftPress?.col == 20)
        #expect(leftPress?.row == 10)
        #expect(leftPress?.shift == false)
        #expect(leftPress?.ctrl == false)

        // Middle and Right click
        let middlePress = ANSIKeyMapping.parseSGRMouseEvent("<1;5;8M")
        #expect(middlePress?.action == .press(.middle))

        let rightPress = ANSIKeyMapping.parseSGRMouseEvent("<2;12;4M")
        #expect(rightPress?.action == .press(.right))

        // Left click release (trailing 'm')
        let leftRelease = ANSIKeyMapping.parseSGRMouseEvent("<0;20;10m")
        #expect(leftRelease?.action == .release(.left))
        #expect(leftRelease?.col == 20)
        #expect(leftRelease?.row == 10)

        // Left drag motion (button 32)
        let leftDrag = ANSIKeyMapping.parseSGRMouseEvent("<32;25;12M")
        #expect(leftDrag?.action == .drag(.left))
        #expect(leftDrag?.col == 25)
        #expect(leftDrag?.row == 12)

        // Scroll wheel Up (64) and Down (65)
        let scrollUp = ANSIKeyMapping.parseSGRMouseEvent("<64;10;5M")
        #expect(scrollUp?.action == .scrollUp)

        let scrollDown = ANSIKeyMapping.parseSGRMouseEvent("<65;10;5M")
        #expect(scrollDown?.action == .scrollDown)

        // Modifiers: Shift (+4), Alt (+8), Ctrl (+16)
        let modifiedPress = ANSIKeyMapping.parseSGRMouseEvent("<28;15;6M") // 0 + 4 + 8 + 16 = 28
        #expect(modifiedPress?.action == .press(.left))
        #expect(modifiedPress?.shift == true)
        #expect(modifiedPress?.alt == true)
        #expect(modifiedPress?.ctrl == true)
    }

    @Test func testTextModeMouseClickAndDragSelection() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "Hello World line 1",
            "Second line of text content",
            "Third line for testing",
        ]
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false

        // Click at row 2 (first text line, since row 1 is Title Bar), col 7 (character index 6: 'W')
        let clickEvent = MouseEvent(action: .press(.left), col: 7, row: 2)
        editor.handleMouseEvent(clickEvent)

        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.buffer.columnIndex == 6)

        // Drag to row 3 (second line), col 12
        let dragEvent = MouseEvent(action: .drag(.left), col: 12, row: 3)
        editor.handleMouseEvent(dragEvent)

        #expect(editor.buffer.selectionMark != nil)
        #expect(editor.buffer.selectionMark?.line == 0)
        #expect(editor.buffer.selectionMark?.column == 6)
        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 11)

        // Right click opens Menu Bar
        let rightClick = MouseEvent(action: .press(.right), col: 10, row: 2)
        editor.handleMouseEvent(rightClick)
        #expect(editor.isMenuBarActive == true)

        // Click outside dismisses Menu Bar
        let outsideClick = MouseEvent(action: .press(.left), col: 40, row: 15)
        editor.handleMouseEvent(outsideClick)
        #expect(editor.isMenuBarActive == false)
    }

    @Test func testCanvasModeMouseClickAnd2DMark() throws {
        let editor = Editor()
        editor.buffer.lines = [""]
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false
        editor.toggleCanvasMode()
        #expect(editor.isCanvasModeActive == true)

        // Click at col 15, row 5 (row 5 is canvas y=3 since row 1 is title bar, 1-based)
        let clickEvent = MouseEvent(action: .press(.left), col: 15, row: 5)
        editor.handleMouseEvent(clickEvent)

        #expect(editor.buffer.lineIndex == 3)
        #expect(editor.buffer.columnIndex == 14)

        // Drag to col 25, row 8
        let dragEvent = MouseEvent(action: .drag(.left), col: 25, row: 8)
        editor.handleMouseEvent(dragEvent)

        #expect(editor.buffer.canvasBlockMark != nil)
        #expect(editor.buffer.canvasBlockMark?.line == 3)
        #expect(editor.buffer.canvasBlockMark?.visualColumn == 14)
        #expect(editor.buffer.canvasBlockMarkEnd?.line == 6)
        #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 24)

        // Right click clears 2D mark area
        let rightClick = MouseEvent(action: .press(.right), col: 5, row: 5)
        editor.handleMouseEvent(rightClick)
        #expect(editor.buffer.canvasBlockMark == nil)
        #expect(editor.buffer.canvasBlockMarkEnd == nil)
        #expect(editor.isMenuBarActive == false)
    }

    @Test func testHelpBarHitTesting() throws {
        let editor = Editor()
        editor.displayConfig.showLineNumbers = false
        let (rows, cols) = (24, 80)
        let geometry = ScreenGeometry(rows: rows, cols: cols, editor: editor)

        // Help bar is at rows 23 and 24
        let hitF1 = editor.renderer.hitTestHelpBar(
            col: 2,
            row: 23,
            geometry: geometry,
            promptMode: .none,
            editor: editor
        )
        #expect(hitF1 != nil)
        #expect(hitF1 == "F1" || hitF1 == "^G")

        // Clicking F8 in Help Bar triggers Canvas mode toggle
        let clickHelpBar = MouseEvent(action: .press(.left), col: 10, row: 23)
        editor.handleMouseEvent(clickHelpBar)
    }

    @Test func testMouseConfigParsing() throws {
        let provider = InMemoryConfigFileProvider(files: [
            "/home/user/.zagorc": """
            set mouse off
            """
        ])
        let loader = ConfigLoader(provider: provider)
        let config = loader.loadConfig()
        #expect(config.enableMouse == false)

        let providerOn = InMemoryConfigFileProvider(files: [
            "/home/user/.zagorc": """
            set mouse on
            """
        ])
        let loaderOn = ConfigLoader(provider: providerOn)
        let configOn = loaderOn.loadConfig()
        #expect(configOn.enableMouse == true)
    }
}
