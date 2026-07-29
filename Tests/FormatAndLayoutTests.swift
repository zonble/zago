import Foundation
import Testing
import TextMetrics

@testable import Editor

@Test func testSoftwrapLayoutEngine() throws {
    let engine = LayoutEngine(wrapColumn: 10)
    let lines = ["1234567890ABCDEFGHIJ12345"]  // 25 characters

    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)
    #expect(virtualLines.count == 3)
    #expect(virtualLines[0].text == "1234567890")
    #expect(virtualLines[1].text == "ABCDEFGHIJ")
    #expect(virtualLines[2].text == "12345")

    // Verify real cursor (0, 15) maps to virtual cursor (1, 5)
    let (vLine, vCol) = engine.getVirtualCursor(lineIndex: 0, columnIndex: 15, virtualLines: virtualLines)
    #expect(vLine == 1)
    #expect(vCol == 5)

    // Verify virtual cursor (1, 5) maps back to real cursor (0, 15)
    let (bLine, bCol) = engine.getBufferCursor(vLineIndex: 1, vColIndex: 5, virtualLines: virtualLines)
    #expect(bLine == 0)
    #expect(bCol == 15)

    // Verify virtual line bounds (Home / End navigation)
    #expect(virtualLines[1].startCol == 10)
    #expect(virtualLines[1].endCol == 20)
}

@Test func testChineseDisplayWidthAndSoftwrap() throws {
    let ch: Character = "中"
    #expect(ch.displayWidth == 2)

    let str = "中文測試"
    #expect(str.displayWidth == 8)
    #expect(str.paddedToDisplayWidth(10) == "中文測試  ")

    // Test CJK softwrap: wrapColumn = 6 (accommodates 3 CJK characters per line)
    let engine = LayoutEngine(wrapColumn: 6)
    let lines = ["一二三四五六"]  // 6 CJK characters, total display width 12
    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)

    #expect(virtualLines.count == 2)
    #expect(virtualLines[0].text == "一二三")
    #expect(virtualLines[1].text == "四五六")
}

@Test func testJustifyParagraph() throws {
    let buffer = TextBuffer()
    buffer.lines = [
        "Swift is a powerful and intuitive",
        "programming language created by Apple",
        "for building apps.",
        "",
        "Second paragraph.",
    ]
    buffer.lineIndex = 0

    // Justify the first paragraph with target width 30
    buffer.justifyParagraph(targetWidth: 30)

    #expect(buffer.lines[0] == "Swift is a powerful and")
    #expect(buffer.lines[1] == "intuitive programming language")
    #expect(buffer.lines[2] == "created by Apple for building")
    #expect(buffer.lines[3] == "apps.")
    #expect(buffer.lines[4] == "")
    #expect(buffer.lines[5] == "Second paragraph.")
}

@Test func testChineseAndMixedJustifyParagraph() throws {
    let buffer = TextBuffer()
    buffer.lines = [
        "這是一段很長的中文字段落，用來測試視覺對齊演算法",
        "是否能在指定寬度內正確折行。",
    ]
    buffer.lineIndex = 0

    // Justify Chinese paragraph with target width 12 (6 CJK characters per line)
    buffer.justifyParagraph(targetWidth: 12)

    #expect(buffer.lines[0] == "這是一段很長")
    #expect(buffer.lines[1] == "的中文字段落")
    #expect(buffer.lines[2] == "，用來測試視")
    #expect(buffer.lines[3] == "覺對齊演算法")
    #expect(buffer.lines[4] == "是否能在指定")
    #expect(buffer.lines[5] == "寬度內正確折")
    #expect(buffer.lines[6] == "行。")
}

@Test func testTerminalDisplayWidthHelpers() throws {
    #expect(Character("A").displayWidth == 1)
    #expect(Character("中").displayWidth == 2)
    #expect("Hello".displayWidth == 5)
    #expect("中文".displayWidth == 4)
    #expect("Hello".paddedToDisplayWidth(10) == "Hello     ")
}

@Test func testWordStarRuler() throws {
    let editor = Editor(showRuler: true)
    #expect(editor.displayConfig.showRuler == true)
    #expect(editor.displayConfig.enableSyntaxHighlight == true)

    let ruler20 = editor.renderer.generateWordStarRuler(width: 20)
    #expect(ruler20 == "----!----1----!----2")

    let ruler30 = editor.renderer.generateWordStarRuler(width: 30)
    #expect(ruler30 == "----!----1----!----2----!----3")
}

@Test func testScreenRenderLayoutAndHeight() throws {
    let editor = Editor()
    let screenRows = 24
    let screenCols = 80

    // Test without ruler (1 title + 20 main + 1 status + 2 help = 24 rows)
    let outputNoRuler = editor.renderer.render(editor: editor, rows: screenRows, cols: screenCols)
    let cleanNoRuler = outputNoRuler.hasPrefix("\u{1B}[H") ? String(outputNoRuler.dropFirst(3)) : outputNoRuler
    let linesNoRuler = cleanNoRuler.components(separatedBy: "\r\n")

    // Verify title bar on line 0 (with inverted video ANSI)
    #expect(linesNoRuler[0].contains("se"))
    #expect(linesNoRuler[0].contains("\u{1B}[7m"))

    // Output must consist of exactly 24 screen line chunks (23 \r\n separators)
    #expect(linesNoRuler.count == 24)

    // Test with ruler (1 title + 1 ruler + 19 main + 1 status + 2 help = 24 rows)
    editor.displayConfig.showRuler = true
    let outputWithRuler = editor.renderer.render(editor: editor, rows: screenRows, cols: screenCols)
    let cleanWithRuler = outputWithRuler.hasPrefix("\u{1B}[H") ? String(outputWithRuler.dropFirst(3)) : outputWithRuler
    let linesWithRuler = cleanWithRuler.components(separatedBy: "\r\n")

    #expect(linesWithRuler[0].contains("se"))
    #expect(linesWithRuler[0].contains("\u{1B}[7m"))
    #expect(linesWithRuler[1].contains("!"))  // Ruler line

    #expect(linesWithRuler.count == 24)
}

@Test func testScreenRenderCanHideLineNumbers() throws {
    let editor = Editor()
    editor.buffer.lines = ["alpha", "beta"]

    let outputWithLineNumbers = editor.renderer.render(editor: editor, rows: 10, cols: 40)
    let linesWithLineNumbers = outputWithLineNumbers.components(separatedBy: "\r\n")
    #expect(linesWithLineNumbers[1].contains("\u{1B}[90m   1 \u{1B}[0malpha"))
    #expect(outputWithLineNumbers.contains("\u{1B}[2;6H"))

    editor.displayConfig.showLineNumbers = false
    let outputWithoutLineNumbers = editor.renderer.render(editor: editor, rows: 10, cols: 40)
    let linesWithoutLineNumbers = outputWithoutLineNumbers.components(separatedBy: "\r\n")
    #expect(linesWithoutLineNumbers[1].contains("\u{1B}[Kalpha"))
    #expect(!linesWithoutLineNumbers[1].contains("   1 "))
    #expect(outputWithoutLineNumbers.contains("\u{1B}[2;1H"))
}

@Test func testRulerBarDimColorWhenMenuBarActive() throws {
    let editor = Editor()
    editor.displayConfig.showRuler = true
    editor.isMenuBarActive = true

    let output = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    let lines = output.components(separatedBy: "\r\n")

    // Line 1 is the Ruler Bar line
    let rulerLine = lines[1]
    #expect(rulerLine.contains("\u{1B}[90m"))  // Dim Gray ANSI code MUST be present in Ruler line!
}

@Test func testPromptHorizontalScrolling() throws {
    let editor = Editor()
    editor.currentPromptMode = .logoMacro(completion: { _ in })
    editor.promptInputText = "TYPE \"THIS IS A VERY LONG LOGO MACRO COMMAND THAT EXCEEDS SCREEN WIDTH\""
    editor.promptCursorIndex = editor.promptInputText.count

    // Render screen with 40 columns
    let renderedScreen = editor.renderer.render(editor: editor, rows: 10, cols: 40)
    let lines = renderedScreen.components(separatedBy: "\r\n")

    // Line at index 7 is status/prompt line
    #expect(lines.count >= 10)
    let promptLine = lines[7]  // status/prompt line

    // Verify prompt line contains '$' horizontal scroll indicator
    #expect(promptLine.contains("$"))
}

@Test func testMermaidDotAndPlantUMLSyntaxHighlighting() throws {
    let highlighter = SyntaxHighlighter()

    // Test Mermaid language detection & highlighting
    let mermaidLang = highlighter.detectLanguage(for: "diagram.mmd")
    #expect(mermaidLang != nil)
    #expect(mermaidLang?.name == "Mermaid")

    let mermaidHighlighted = highlighter.highlight(line: "flowchart TD", syntax: mermaidLang!)
    #expect(mermaidHighlighted.contains("\u{1B}["))

    // Test DOT language detection & highlighting
    let dotLang = highlighter.detectLanguage(for: "graph.dot")
    #expect(dotLang != nil)
    #expect(dotLang?.name == "DOT")

    let dotHighlighted = highlighter.highlight(line: "digraph G {", syntax: dotLang!)
    #expect(dotHighlighted.contains("\u{1B}["))

    // Test PlantUML language detection & highlighting
    let plantUMLLang = highlighter.detectLanguage(for: "diagram.puml")
    #expect(plantUMLLang != nil)
    #expect(plantUMLLang?.name == "PlantUML")

    let plantUMLHighlighted = highlighter.highlight(line: "User -> Server", syntax: plantUMLLang!)
    #expect(plantUMLHighlighted.contains("\u{1B}["))
}

@Test func testDynamicHelpBarByPromptMode() throws {
    let renderer = Renderer()

    // 1. LOGO macro prompt help bar
    let logoHelp = renderer.renderHelpBar(cols: 80, promptMode: .logoMacro(completion: { _ in }))
    #expect(logoHelp.contains("BOX"))
    #expect(logoHelp.contains("DRAWBOX"))
    #expect(logoHelp.contains("TABLE"))
    #expect(logoHelp.contains("VLINE"))
    #expect(logoHelp.contains("TYPE"))

    // 2. Exit Confirmation prompt help bar
    let exitHelp = renderer.renderHelpBar(cols: 80, promptMode: .confirmExitSave(completion: { _ in }))
    #expect(exitHelp.contains("Yes"))
    #expect(exitHelp.contains("No"))
    #expect(exitHelp.contains("Cancel"))

    // 3. Search input prompt help bar
    let searchHelp = renderer.renderHelpBar(cols: 80, promptMode: .search(completion: { _ in }))
    #expect(searchHelp.contains("Help"))
    #expect(searchHelp.contains("Cancel"))
    #expect(searchHelp.contains("Confirm"))
    #expect(searchHelp.contains("Clear"))

    // 4. Default Nano help bar
    let defaultHelp = renderer.renderHelpBar(cols: 80, promptMode: .none)
    #expect(defaultHelp.contains("^G"))
    #expect(defaultHelp.contains(L10n.helpGetHelp))
    #expect(defaultHelp.contains("^O"))
    #expect(defaultHelp.contains(L10n.helpWriteOut))
}

@Test func testRendererModularComponents() throws {
    let editor = Editor()
    let renderer = editor.renderer

    // Test Title Bar component
    let titleBarOutput = renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
    #expect(titleBarOutput.contains("se"))

    // Test Ruler Bar component
    let rulerOutput = renderer.generateWordStarRuler(width: 30)
    #expect(rulerOutput == "----!----1----!----2----!----3")

    // Test Line Number Gutter component
    let gutterOutput = renderer.renderLineNumberGutter(lineNumber: 5, isFirstSubLine: true, showLineNumbers: true)
    #expect(gutterOutput == "   5 ")

    // Test full screen render
    let fullOutput = renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(fullOutput.hasPrefix("\u{1B}[?7l\u{1B}[H"))
}

@Test func testMenuBarCategoryHighlightStability() throws {
    let editor = Editor()
    editor.isMenuBarActive = true
    let cols = 80

    // Render with category 0 highlighted
    editor.menuBar.categoryIndex = 0
    let line0 = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: cols)

    // Render with category 1 highlighted
    editor.menuBar.categoryIndex = 1
    let line1 = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: cols)

    // Render with category 2 highlighted
    editor.menuBar.categoryIndex = 2
    let line2 = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: cols)

    // Verify raw display lengths of all category selections are strictly identical (no horizontal jumping)
    let clean0 = line0.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
    let clean1 = line1.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
    let clean2 = line2.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)

    #expect(clean0.count == clean1.count)
    #expect(clean1.count == clean2.count)

    // Verify dropdown overlay column offset is aligned directly with category index
    editor.menuBar.categoryIndex = 0
    let (startCol0, _, _) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: cols)
    #expect(startCol0 == 1)

    editor.menuBar.categoryIndex = 1
    let (startCol1, _, _) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: cols)
    let title0Width = L10n[editor.menuBar.categories[0].titleKey].displayWidth
    #expect(startCol1 == 1 + title0Width + 4)
}

@Test func testMenuBarCursorPositioningBottomRight() throws {
    let editor = Editor()
    editor.buffer.lines = ["Hello World"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0

    let rows = 24
    let cols = 80

    // 1. When menu bar is inactive (isMenuBarActive == false)
    editor.isMenuBarActive = false
    let normalOutput = editor.renderer.render(editor: editor, rows: rows, cols: cols)
    #expect(!normalOutput.contains("\u{1B}[\(rows);\(cols)H"))

    // 2. When menu bar is active (isMenuBarActive == true)
    editor.isMenuBarActive = true
    let menuActiveOutput = editor.renderer.render(editor: editor, rows: rows, cols: cols)
    #expect(menuActiveOutput.contains("\u{1B}[\(rows);\(cols)H"))

    // 3. When menu bar is toggled back off (isMenuBarActive == false)
    editor.isMenuBarActive = false
    let menuClosedOutput = editor.renderer.render(editor: editor, rows: rows, cols: cols)
    #expect(!menuClosedOutput.contains("\u{1B}[\(rows);\(cols)H"))
}

@Test func testLineNumberColorPreservedWhenMenuBarActive() throws {
    let editor = Editor()
    editor.buffer.lines = ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6", "Line 7"]

    // 1. Menu inactive -> Line numbers have \u{1B}[90m (dim gray)
    editor.isMenuBarActive = false
    let outputInactive = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(outputInactive.contains("\u{1B}[90m   1 \u{1B}[0m"))

    // 2. Menu active with category 3 (dropdown offset at col > 20) -> Line numbers MUST STILL have \u{1B}[90m (dim gray)
    editor.isMenuBarActive = true
    editor.menuBar.categoryIndex = 3
    let outputActive = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(outputActive.contains("\u{1B}[90m   1 \u{1B}[0m"))
}


