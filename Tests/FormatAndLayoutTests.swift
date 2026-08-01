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

@Test func testCanvasLayoutDoesNotSoftwrap() throws {
    let engine = LayoutEngine(wrapColumn: 10)
    let lines = ["1234567890ABCDEFGHIJ12345"]

    let virtualLines = engine.computeCanvasLines(from: lines)
    #expect(virtualLines.count == 1)
    #expect(virtualLines[0].text == "1234567890ABCDEFGHIJ12345")
    #expect(virtualLines[0].startCol == 0)
    #expect(virtualLines[0].endCol == 25)
}

@Test func testChineseDisplayWidthAndSoftwrap() throws {
    let ch: Character = "中"
    #expect(ch.displayWidth == 2)

    let str = "中文測試"
    #expect(str.displayWidth == 8)
    #expect(str.paddedToDisplayWidth(10) == "中文測試  ")

    // Test CJK softwrap: requested wrapColumn = 6 is clamped to 10 (5 CJK characters per line)
    let engine = LayoutEngine(wrapColumn: 6)
    let lines = ["一二三四五六"]  // 6 CJK characters, total display width 12
    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)

    #expect(virtualLines.count == 2)
    #expect(virtualLines[0].text == "一二三四五")
    #expect(virtualLines[1].text == "六")
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

@Test func testVisualColumnCoordinateHelpers() throws {
    let mixed = "AB中D"

    #expect(mixed.visualColumn(forCharacterOffset: 0) == 0)
    #expect(mixed.visualColumn(forCharacterOffset: 2) == 2)
    #expect(mixed.visualColumn(forCharacterOffset: 3) == 4)
    #expect(mixed.visualColumn(forCharacterOffset: 99) == 5)

    #expect(mixed.characterOffset(forVisualColumn: 0) == 0)
    #expect(mixed.characterOffset(forVisualColumn: 2) == 2)
    #expect(mixed.characterOffset(forVisualColumn: 3) == 2)
    #expect(mixed.characterOffset(forVisualColumn: 4) == 3)
    #expect(mixed.characterOffset(forVisualColumn: 99) == 4)

    #expect(mixed.snappedVisualColumn(3, direction: .backward) == 2)
    #expect(mixed.snappedVisualColumn(3, direction: .forward) == 4)
    #expect(mixed.snappedVisualColumn(4, direction: .backward) == 4)
}

@Test func testVisualColumnWritePaddingReplaceAndClear() throws {
    let padded = "AB".writingAtVisualColumn(4, character: "Z")
    #expect(padded.text == "AB  Z")
    #expect(padded.visualColumnAfterWrite == 5)
    #expect(padded.characterOffsetAfterWrite == 5)

    let wideOverAscii = "ABCD".writingAtVisualColumn(1, character: "中")
    #expect(wideOverAscii.text == "A中D")
    #expect(wideOverAscii.text.displayWidth == 4)

    let narrowOverWide = "中D".writingAtVisualColumn(1, character: "A")
    #expect(narrowOverWide.text == "A D")
    #expect(narrowOverWide.text.displayWidth == 3)

    let cleared = "A中D".clearingAtVisualColumn(2)
    #expect(cleared.text == "A  D")
    #expect(cleared.visualColumnAfterWrite == 3)
}

@Test func testVisualColumnSliceHelper() throws {
    let line = "AB中DEFG"

    let first = line.visualSlice(startVisualColumn: 0, width: 5)
    #expect(first.text == "AB中D")
    #expect(first.startCharacterOffset == 0)
    #expect(first.endCharacterOffset == 4)

    let insideWide = line.visualSlice(startVisualColumn: 3, width: 4)
    #expect(insideWide.text == " DEF")
    #expect(insideWide.startCharacterOffset == 2)

    let beyondEnd = line.visualSlice(startVisualColumn: 10, width: 3)
    #expect(beyondEnd.text == "   ")
    #expect(beyondEnd.startCharacterOffset == line.count)
    #expect(beyondEnd.endCharacterOffset == line.count)
}

@Test func testVisualColumnHelpersWithEmojiCombiningAndTab() throws {
    let emojiLine = "A🙂B"
    #expect(emojiLine.visualColumn(forCharacterOffset: 2) == 3)
    #expect(emojiLine.characterOffset(forVisualColumn: 2) == 1)
    #expect(emojiLine.snappedVisualColumn(2, direction: .forward) == 3)

    let combining = "e\u{301}B"
    #expect(Array(combining).count == 2)
    #expect(combining.visualColumn(forCharacterOffset: 1) == 1)
    #expect(combining.characterOffset(forVisualColumn: 1) == 1)

    let tabLine = "A\tB"
    #expect(tabLine.visualColumn(forCharacterOffset: 2) == Character("\t").displayWidth + 1)
    #expect(tabLine.characterOffset(forVisualColumn: 1) == 1)
}

@Test func testWordStarRuler() throws {
    let editor = Editor(showRuler: true)
    #expect(editor.displayConfig.showRuler == true)
    #expect(editor.displayConfig.enableSyntaxHighlight == true)

    let ruler20 = editor.renderer.generateWordStarRuler(width: 20)
    #expect(ruler20 == "----!----1----!----2")

    let ruler30 = editor.renderer.generateWordStarRuler(width: 30)
    #expect(ruler30 == "----!----1----!----2----!----3")

    let offsetRuler = editor.renderer.generateWordStarRuler(width: 10, startColumn: 11)
    #expect(offsetRuler == "----!----2")

    let wrapMarkerRuler = editor.renderer.generateWordStarRuler(width: 20, startColumn: 1, wrapColumn: 10)
    #expect(wrapMarkerRuler == "----!----<----!----2")
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
    #expect(linesNoRuler[0].contains("zago"))
    #expect(linesNoRuler[0].contains("\u{1B}[7m"))

    // Output must consist of exactly 24 screen line chunks (23 \r\n separators)
    #expect(linesNoRuler.count == 24)

    // Test with ruler (1 title + 1 ruler + 19 main + 1 status + 2 help = 24 rows)
    editor.displayConfig.showRuler = true
    let outputWithRuler = editor.renderer.render(editor: editor, rows: screenRows, cols: screenCols)
    let cleanWithRuler = outputWithRuler.hasPrefix("\u{1B}[H") ? String(outputWithRuler.dropFirst(3)) : outputWithRuler
    let linesWithRuler = cleanWithRuler.components(separatedBy: "\r\n")

    #expect(linesWithRuler[0].contains("zago"))
    #expect(linesWithRuler[0].contains("\u{1B}[7m"))
    #expect(linesWithRuler[1].contains("!"))  // Ruler line

    #expect(linesWithRuler.count == 24)
}

@Test func testLocalizedHelpBarPromptAndCanvasLabels() throws {
    let previousLanguage = L10n.currentLanguage
    defer { L10n.currentLanguage = previousLanguage }

    let renderer = Renderer()

    L10n.currentLanguage = .zh_TW
    let promptHelpBar = renderer.renderHelpBar(cols: 80, promptMode: .search(completion: { _ in }))
    #expect(promptHelpBar.contains("確認"))
    #expect(promptHelpBar.contains("取消"))
    #expect(promptHelpBar.contains("清除"))
    #expect(promptHelpBar.contains("移動"))
    #expect(promptHelpBar.contains("跳轉"))
    #expect(!promptHelpBar.contains("Confirm"))
    #expect(!promptHelpBar.contains("Cancel"))

    let canvasEditor = Editor(language: .zh_TW)
    canvasEditor.switchToCanvasMode()
    let canvasHelpBar = renderer.renderHelpBar(cols: 80, promptMode: .none, editor: canvasEditor)
    #expect(canvasHelpBar.contains("標記區塊"))
    #expect(canvasHelpBar.contains("剪下區塊"))
    #expect(canvasHelpBar.contains("複製區塊"))
    #expect(canvasHelpBar.contains("貼上區塊"))
    #expect(canvasHelpBar.contains("線段"))
    #expect(canvasHelpBar.contains("箭頭"))
    #expect(!canvasHelpBar.contains("Mark Block"))
    #expect(!canvasHelpBar.contains("Copy Block"))

    let confirmHelpBar = renderer.renderHelpBar(cols: 80, promptMode: .confirmExitSave(completion: { _ in }))
    #expect(confirmHelpBar.contains("是"))
    #expect(confirmHelpBar.contains("否"))

    let logoEditor = Editor(language: .zh_TW)
    logoEditor.promptCompletionText = "SET wrap"
    let logoHelpBar = renderer.renderHelpBar(cols: 80, promptMode: .logoMacro(completion: { _ in }), editor: logoEditor)
    #expect(logoHelpBar.contains("補完"))
    #expect(logoHelpBar.contains("確認"))
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

@Test func testTextSelectionKeepsSyntaxHighlightOutsideSelectedRange() throws {
    let editor = Editor(filePath: "test.swift", enableSyntax: true)
    editor.buffer.lines = ["let value = 1"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 7
    editor.selectionMark = (line: 0, column: 4)

    let output = editor.renderer.render(editor: editor, rows: 8, cols: 40)

    #expect(output.contains("\u{1B}[1;36ml\u{1B}[0m"))
    #expect(output.contains("\u{1B}[1;36me\u{1B}[0m"))
    #expect(output.contains("\u{1B}[1;36mt\u{1B}[0m"))
    #expect(output.contains("\u{1B}[7m"))
}

@Test func testCanvasModeAppliesSyntaxHighlightingToBufferText() throws {
    let editor = Editor(filePath: "test.swift", enableSyntax: true)
    editor.buffer.lines = ["let value = 1"]
    editor.switchToCanvasMode()

    let output = editor.renderer.render(editor: editor, rows: 8, cols: 40)

    #expect(output.contains("\u{1B}[1;36ml\u{1B}[0m"))
    #expect(output.contains("\u{1B}[1;36me\u{1B}[0m"))
    #expect(output.contains("\u{1B}[1;36mt\u{1B}[0m"))
}

@Test func testEmbeddedCodeBlockSyntaxHighlighting() throws {
    let editor = Editor()
    editor.displayConfig.enableSyntaxHighlight = true

    // 1. Markdown embedded LOGO code block
    editor.buffer.filePath = "document.md"
    editor.buffer.lines = [
        "# Title",
        "```logo",
        "; comment inside logo block",
        "MAKE \"A 10",
        "```",
        "Normal markdown text",
    ]

    let syntaxMdLogo = editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: 2)
    #expect(syntaxMdLogo?.name == "LOGO")

    let syntaxMdText = editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: 5)
    #expect(syntaxMdText?.name == "Markdown")

    // 2. Org-mode embedded LOGO code block
    editor.buffer.filePath = "notes.org"
    editor.buffer.lines = [
        "* Section Title",
        "#+BEGIN_SRC logo",
        "; comment inside logo org block",
        "#+END_SRC",
    ]
    let syntaxOrgLogo = editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: 2)
    #expect(syntaxOrgLogo?.name == "LOGO")

    // 3. RST embedded LOGO code block
    editor.buffer.filePath = "docs.rst"
    editor.buffer.lines = [
        "Header",
        ".. code-block:: logo",
        "",
        "   ; comment inside logo rst block",
        "Unindented text",
    ]
    let syntaxRstLogo = editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: 3)
    #expect(syntaxRstLogo?.name == "LOGO")

    // 4. Markdown with multiple spaces after backticks (```   logo   )
    editor.buffer.filePath = "document.md"
    editor.buffer.lines = [
        "```   logo   ",
        "; comment inside multi-space logo block",
        "```",
    ]
    let syntaxMultiSpaceLogo = editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: 1)
    #expect(syntaxMultiSpaceLogo?.name == "LOGO")

    // 5. Org-mode with multiple spaces (#+BEGIN_SRC   logo  )
    editor.buffer.filePath = "notes.org"
    editor.buffer.lines = [
        "#+BEGIN_SRC   logo  ",
        "; comment inside multi-space org logo block",
        "#+END_SRC",
    ]
    let syntaxMultiSpaceOrg = editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: 1)
    #expect(syntaxMultiSpaceOrg?.name == "LOGO")

    // 6. RST with multiple spaces (.. code-block::   logo  )
    editor.buffer.filePath = "docs.rst"
    editor.buffer.lines = [
        ".. code-block::   logo  ",
        "",
        "   ; comment inside multi-space rst logo block",
    ]
    let syntaxMultiSpaceRst = editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: 2)
    #expect(syntaxMultiSpaceRst?.name == "LOGO")
}

@Test func testDynamicHelpBarByPromptMode() throws {
    let renderer = Renderer()

    // 1. LOGO macro prompt help bar
    let logoHelp = renderer.renderHelpBar(cols: 80, promptMode: .logoMacro(completion: { _ in }))
    #expect(logoHelp.contains("BOX"))
    #expect(logoHelp.contains("DRAWBOX"))
    #expect(logoHelp.contains("TABLE"))
    #expect(logoHelp.contains("LINE"))
    #expect(logoHelp.contains("Complete"))

    // 2. Exit Confirmation prompt help bar
    let exitHelp = renderer.renderHelpBar(cols: 80, promptMode: .confirmExitSave(completion: { _ in }))
    #expect(exitHelp.contains("Yes"))
    #expect(exitHelp.contains("No"))
    #expect(exitHelp.contains("Cancel"))

    // 3. Search input prompt help bar
    let searchHelp = renderer.renderHelpBar(cols: 80, promptMode: .search(completion: { _ in }))
    #expect(!searchHelp.contains("Help"))
    #expect(searchHelp.contains("Cancel"))
    #expect(searchHelp.contains("Confirm"))
    #expect(searchHelp.contains("Clear"))
    #expect(searchHelp.contains("Move"))
    #expect(searchHelp.contains("Jump"))

    // 4. Default Nano help bar
    let defaultHelp = renderer.renderHelpBar(cols: 80, promptMode: .none)
    #expect(defaultHelp.contains("F1"))
    #expect(defaultHelp.contains("Menu"))
    #expect(!defaultHelp.contains("^G"))
    #expect(defaultHelp.contains("^O"))
    #expect(defaultHelp.contains(L10n.helpWriteOut))

    let editor = Editor()
    editor.switchToCanvasMode()
    let canvasHelp = renderer.renderHelpBar(cols: 80, promptMode: .none, editor: editor)
    #expect(canvasHelp.contains("⇧+Arrow"))
    #expect(canvasHelp.contains("^^"))
    #expect(canvasHelp.contains("^K"))
    #expect(canvasHelp.contains("^U"))
    #expect(canvasHelp.contains("F1"))
    #expect(!canvasHelp.contains("^G"))
    #expect(!canvasHelp.contains(L10n.helpGetHelp))
}

@Test func testCanvasModeRendersLocalizedEndOfFileMarker() throws {
    let editor = Editor()
    editor.buffer.lines = ["abc", "def"]
    editor.switchToCanvasMode()

    let output = editor.renderer.render(editor: editor, rows: 8, cols: 40)

    #expect(output.contains("~ \(L10n["chrome.end_of_file"])"))
    #expect(output.contains("\u{1B}[90m"))
}

@Test func testTextModeDoesNotRenderEndOfFileMarker() throws {
    let editor = Editor()
    editor.buffer.lines = ["abc", "def"]

    let output = editor.renderer.render(editor: editor, rows: 8, cols: 40)

    #expect(!output.contains("~ \(L10n["chrome.end_of_file"])"))
}

@Test func testIdleStatusLineModeIndicators() throws {
    let editor = Editor()
    let renderer = editor.renderer

    #expect(renderer.renderIdleStatusLine(editor: editor, cols: 80).trimmingCharacters(in: .whitespaces).isEmpty)

    editor.switchToCanvasMode()
    let canvasStatus = renderer.renderIdleStatusLine(editor: editor, cols: 80)
    #expect(canvasStatus.contains("CANVAS"))
    #expect(!canvasStatus.contains("[ Canvas Mode ]"))

    editor.overlayMode = .none
    editor.isTableModeActive = true
    let tableStatus = renderer.renderIdleStatusLine(editor: editor, cols: 80)
    #expect(tableStatus.contains("CANVAS | TABLE"))
}

@Test func testRendererModularComponents() throws {
    let editor = Editor()
    let renderer = editor.renderer

    // Test Title Bar component
    let titleBarOutput = renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
    #expect(titleBarOutput.contains("zago"))

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

    editor.menuBar.categoryIndex = 2
    let (startCol2, _, _) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: cols)
    let title1Width = L10n[editor.menuBar.categories[1].titleKey].displayWidth
    #expect(startCol2 == 1 + title0Width + 4 + title1Width + 4)
}

@Test func testMenuDropdownReservesCheckboxColumnForEveryItem() throws {
    let editor = Editor()
    editor.isMenuBarActive = true
    editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.borders" })!

    var (_, _, lines) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
    let cleanChecked = lines[1].replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
    let cleanUnchecked = lines[2].replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
    #expect(cleanChecked.contains("│ ✓ Single"))
    #expect(cleanUnchecked.contains("│   Double"))

    editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.shapes" })!
    (_, _, lines) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
    let cleanPlain = lines[1].replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
    #expect(cleanPlain.contains("│   Box"))
}

@Test func testMenuOverlayReplacesWideCharactersCrossingBoundariesWithSpaces() throws {
    let renderer = Renderer()

    let leftOverlap = renderer.sliceOverlayLine(
        baseFullLineStr: "AB中C",
        boxLine: "[MENU]",
        dropdownStartCol: 3,
        dropdownBoxWidth: 6,
        cols: 12
    )
    let cleanLeft = leftOverlap.replacingOccurrences(
        of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)

    #expect(cleanLeft.hasPrefix("AB [MENU]"))
    #expect(!cleanLeft.contains("中"))

    let rightOverlap = renderer.sliceOverlayLine(
        baseFullLineStr: "ABC中Z",
        boxLine: "MENU",
        dropdownStartCol: 0,
        dropdownBoxWidth: 4,
        cols: 8
    )
    let cleanRight = rightOverlap.replacingOccurrences(
        of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)

    #expect(cleanRight.hasPrefix("MENU Z"))
    #expect(!cleanRight.contains("中"))
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
