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
        #expect(editor.canvasVisualColumn == 14)

        // Drag to col 25, row 8
        let dragEvent = MouseEvent(action: .drag(.left), col: 25, row: 8)
        editor.handleMouseEvent(dragEvent)

        #expect(editor.buffer.canvasBlockMark != nil)
        #expect(editor.buffer.canvasBlockMark?.line == 3)
        #expect(editor.buffer.canvasBlockMark?.visualColumn == 14)
        #expect(editor.buffer.canvasBlockMarkEnd?.line == 6)
        #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 24)
        #expect(editor.buffer.lineIndex == 6)
        #expect(editor.canvasVisualColumn == 24)

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

    @Test func testTextModeDragAutoScrollDownAndUp() throws {
        let editor = Editor()
        editor.buffer.lines = (1...60).map { "Line \($0) text content for scrolling test" }
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false

        // Click at row 2 (line 0)
        let clickEvent = MouseEvent(action: .press(.left), col: 5, row: 2)
        editor.handleMouseEvent(clickEvent)
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.topVLineIndex == 0)

        // Drag below viewport bottom (row 25, when window size is 24 rows)
        let dragDown = MouseEvent(action: .drag(.left), col: 5, row: 25)
        editor.handleMouseEvent(dragDown)

        #expect(editor.topVLineIndex > 0)
        #expect(editor.buffer.selectionMark != nil)
        #expect(editor.buffer.selectionMark?.line == 0)
        #expect(editor.buffer.lineIndex > 0)

        let scrolledTop = editor.topVLineIndex

        // Drag above viewport top (row 1)
        let dragUp = MouseEvent(action: .drag(.left), col: 5, row: 1)
        editor.handleMouseEvent(dragUp)

        #expect(editor.topVLineIndex == scrolledTop - 1)
        #expect(editor.buffer.selectionMark?.line == 0)
    }

    @Test func testCanvasModeDragAutoScrollHorizontal() throws {
        let editor = Editor()
        editor.buffer.lines = Array(repeating: String(repeating: " ", count: 120), count: 30)
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false
        editor.toggleCanvasMode()
        #expect(editor.isCanvasModeActive == true)

        // Click at col 10, row 5
        let clickEvent = MouseEvent(action: .press(.left), col: 10, row: 5)
        editor.handleMouseEvent(clickEvent)
        #expect(editor.canvasHorizontalOffset == 0)

        // Drag past right edge of window (col 85 with default 80 cols)
        let dragRight = MouseEvent(action: .drag(.left), col: 85, row: 5)
        editor.handleMouseEvent(dragRight)

        #expect(editor.canvasHorizontalOffset == 2)
        #expect(editor.buffer.canvasBlockMark != nil)
        #expect(editor.buffer.canvasBlockMark?.visualColumn == 9)
        #expect(editor.buffer.canvasBlockMarkEnd != nil)
        #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn ?? 0 > 75)
    }

    @Test func testContinuousAutoScrollStateAndTicks() throws {
        let editor = Editor()
        editor.buffer.lines = (1...100).map { "Line \($0) text content for continuous scroll test" }
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false

        // Click at row 5 (line 3)
        editor.handleMouseEvent(MouseEvent(action: .press(.left), col: 5, row: 5))
        #expect(editor.activeBoundaryDragState == nil)

        // Drag to edge boundary row 23 (Help Bar, inside window) -> Tier 1 (60ms)
        editor.handleMouseEvent(MouseEvent(action: .drag(.left), col: 5, row: 23))
        #expect(editor.activeBoundaryDragState != nil)
        #expect(editor.activeBoundaryDragState?.intervalMs == 60)

        let initialTop = editor.topVLineIndex

        // Simulate continuous scroll ticks triggered by timer poll timeouts
        editor.performBoundaryDragAutoScrollTick()
        #expect(editor.topVLineIndex == initialTop + 1)

        editor.performBoundaryDragAutoScrollTick()
        #expect(editor.topVLineIndex == initialTop + 2)

        // Drag outside window (row 30, when window is 24 rows) -> Tier 2 (30ms)
        editor.handleMouseEvent(MouseEvent(action: .drag(.left), col: 5, row: 30))
        #expect(editor.activeBoundaryDragState?.intervalMs == 30)

        // Drag back to normal viewport area (row 10) -> Clears state
        editor.handleMouseEvent(MouseEvent(action: .drag(.left), col: 5, row: 10))
        #expect(editor.activeBoundaryDragState == nil)

        // Drag outside again, then release button -> Clears state
        editor.handleMouseEvent(MouseEvent(action: .drag(.left), col: 5, row: 0))
        #expect(editor.activeBoundaryDragState != nil)

        editor.handleMouseEvent(MouseEvent(action: .release(.left), col: 5, row: 0))
        #expect(editor.activeBoundaryDragState == nil)
    }

    @Test func testMouseWheelScrollingDecoupledFromCursor() throws {
        let editor = Editor()
        editor.buffer.lines = (1...100).map { "Line \($0) content" }
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.topVLineIndex = 0

        // Scroll down 4 times (12 lines)
        for _ in 0..<4 {
            editor.handleMouseEvent(MouseEvent(action: .scrollDown, col: 10, row: 10))
        }

        #expect(editor.topVLineIndex == 12)
        #expect(editor.buffer.lineIndex == 0)  // Cursor remains at line 0!

        // Typing a character immediately snaps viewport back to cursor
        editor.processKey(.char("a"))
        #expect(editor.topVLineIndex == 0)
        #expect(editor.buffer.lines[0].starts(with: "aLine 1"))
    }

    @Test func testArrowKeysRestoreCursorFocusAfterScroll() throws {
        let editor = Editor()
        editor.buffer.lines = (1...100).map { "Line \($0) content" }
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false
        editor.buffer.lineIndex = 50
        editor.buffer.columnIndex = 0
        editor.topVLineIndex = 45

        // Scroll up to top
        for _ in 0..<20 {
            editor.handleMouseEvent(MouseEvent(action: .scrollUp, col: 10, row: 10))
        }
        #expect(editor.topVLineIndex == 0)
        #expect(editor.buffer.lineIndex == 50)  // Cursor is off-screen

        // Press down arrow -> moves cursor to 51 and restores viewport
        editor.processKey(.arrowDown)
        #expect(editor.buffer.lineIndex == 51)
        #expect(editor.topVLineIndex > 20)  // Snapped back into view
    }

    @Test func testOffScreenCursorRendersAtBottomRight() throws {
        let editor = Editor()
        editor.buffer.lines = (1...100).map { "Line \($0) content" }
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false
        editor.buffer.lineIndex = 0
        editor.topVLineIndex = 40  // Cursor is far above visible viewport

        let renderer = Renderer()
        let output = renderer.renderDiff(editor: editor, rows: 24, cols: 80)
        #expect(output.contains("\u{1B}[24;80H"))  // Hardware cursor parked at bottom-right
    }

    @Test func testMouseInputDoesNotChangeSelectionOrCursorWhenPromptIsActive() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "Line 1 text content",
            "Line 2 text content",
            "Line 3 text content",
        ]
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 5
        editor.buffer.selectionMark = (line: 1, column: 0)

        // Activate command bar / search prompt
        editor.promptSearch()
        #expect(editor.promptController.isActive == true)

        // Left click in viewport area
        let clickEvent = MouseEvent(action: .press(.left), col: 10, row: 2)
        editor.handleMouseEvent(clickEvent)

        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 5)
        #expect(editor.buffer.selectionMark?.line == 1)
        #expect(editor.buffer.selectionMark?.column == 0)

        // Drag in viewport area
        let dragEvent = MouseEvent(action: .drag(.left), col: 15, row: 3)
        editor.handleMouseEvent(dragEvent)

        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 5)
        #expect(editor.buffer.selectionMark?.line == 1)
        #expect(editor.buffer.selectionMark?.column == 0)
        #expect(editor.activeBoundaryDragState == nil)

        // Release in viewport area
        let releaseEvent = MouseEvent(action: .release(.left), col: 15, row: 3)
        editor.handleMouseEvent(releaseEvent)

        #expect(editor.buffer.selectionMark?.line == 1)
        #expect(editor.buffer.selectionMark?.column == 0)

        // Right click in viewport area
        let rightClick = MouseEvent(action: .press(.right), col: 10, row: 2)
        editor.handleMouseEvent(rightClick)
        #expect(editor.isMenuBarActive == false)

        // Top bar click
        let topBarClick = MouseEvent(action: .press(.left), col: 5, row: 1)
        editor.handleMouseEvent(topBarClick)
        #expect(editor.isMenuBarActive == false)
    }

    @Test func testCanvasModeMouseInputDoesNotChangeBlockMarkWhenPromptIsActive() throws {
        let editor = Editor()
        editor.buffer.lines = ["Hello Canvas"]
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false
        editor.toggleCanvasMode()
        editor.buffer.lineIndex = 0
        editor.canvasVisualColumn = 2
        editor.buffer.canvasBlockMark = (line: 0, visualColumn: 0)
        editor.buffer.canvasBlockMarkEnd = (line: 0, visualColumn: 5)

        editor.promptLogoMacro()
        #expect(editor.promptController.isActive == true)

        let clickEvent = MouseEvent(action: .press(.left), col: 10, row: 5)
        editor.handleMouseEvent(clickEvent)

        #expect(editor.buffer.canvasBlockMark?.visualColumn == 0)
        #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 5)
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.canvasVisualColumn == 2)

        let dragEvent = MouseEvent(action: .drag(.left), col: 15, row: 6)
        editor.handleMouseEvent(dragEvent)

        #expect(editor.buffer.canvasBlockMark?.visualColumn == 0)
        #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 5)
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.canvasVisualColumn == 2)
    }
}


