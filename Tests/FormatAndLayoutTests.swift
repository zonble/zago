import Foundation
import Testing
import TextMetrics

@testable import Editor
@testable import Syntax

@Suite(.serialized)
struct FormatAndLayoutTests {
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

    @Test func testVirtualViewportMatchesFullSoftwrapWindow() throws {
        let engine = LayoutEngine(wrapColumn: 10)
        let lines = ["1234567890ABCDEFGHIJ12345", "short", String(repeating: "a", count: 120)]
        let full = engine.computeVirtualLines(from: lines, viewWidth: 80)
        let viewport = engine.computeVirtualViewport(
            from: lines,
            viewWidth: 80,
            topVirtualLineIndex: 2,
            height: 4,
            cursorLineIndex: 2,
            cursorColumnIndex: 35
        )

        #expect(viewport.lines.map(\.text) == full[2..<6].map(\.text))
        #expect(viewport.startVirtualIndex == 2)
        #expect(viewport.totalVirtualLineCount == full.count)

        let (cursorVLine, cursorVCol) = engine.getVirtualCursor(
            lineIndex: 2,
            columnIndex: 35,
            virtualLines: full
        )
        #expect(viewport.cursorVirtualLineIndex == cursorVLine)
        #expect(viewport.cursorVirtualColumnIndex == cursorVCol)

        let partialViewport = engine.computeVirtualViewport(
            from: lines,
            viewWidth: 80,
            topVirtualLineIndex: 2,
            height: 4,
            cursorLineIndex: 2,
            cursorColumnIndex: 35,
            computeTotalLineCount: false
        )
        #expect(partialViewport.lines.map(\.text) == full[2..<6].map(\.text))
        #expect(partialViewport.totalVirtualLineCount < full.count)
        #expect(partialViewport.cursorVirtualLineIndex == cursorVLine)
        #expect(partialViewport.cursorVirtualColumnIndex == cursorVCol)
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

    @Test func testCJKMarkdownListWrapIndentCursorPosition() throws {
        let editor = Editor(wrapColumn: 35, enableSyntax: false)
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.listWrapIndent = true
        let line = "- 有一般編輯模式與畫布模式，畫布模式下可以用 Shift + 方向按鍵拉出框線"
        editor.buffer.lines = [line]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = line.count

        let hangingIndent = LayoutEngine.calculateListHangingIndent(in: line)
        #expect(hangingIndent == 2)

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 80)
        // Row 4, Column 5 (1-based ANSI escape \u{1B}[4;5H: 2 space indent + 2 CJK width + 1)
        #expect(output.contains("\u{1B}[4;5H"))
    }

    @Test func testPositionCursorDirectlyIncludesHangingIndent() throws {
        let editor = Editor(enableSyntax: false)
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.listWrapIndent = true
        let fullLine = "- 測試項目長度超長"
        editor.buffer.lines = [fullLine]

        let vLine0 = VirtualLine(bufferLineIndex: 0, subLineIndex: 0, text: "- 測試項目", startCol: 0, endCol: 5)
        let vLine1 = VirtualLine(bufferLineIndex: 0, subLineIndex: 1, text: "長度超長", startCol: 5, endCol: 9)

        let cursorSequence = editor.renderer.positionCursor(
            editor: editor,
            rows: 8,
            cols: 80,
            cursorVLineIdx: 1,
            cursorVColIdx: 4,
            gutterWidth: 0,
            virtualLines: [vLine0, vLine1],
            renderedPrompt: Renderer.RenderedPrompt(text: "", cursorCol: 1)
        )

        // hangingIndent = 2 ("- "), text width = 8 (4 CJK chars), total col = 2 + 8 + 1 = 11
        // Screen row = 1 (vLine 1) + 2 (title bar) = 3
        #expect(cursorSequence.contains("\u{1B}[3;11H"))
    }

    @Test func testSubLineNumbersRenderForWrappedProse() throws {

        let editor = Editor(wrapColumn: 10, enableSyntax: false, language: .en)
        editor.displayConfig.showSubLineNumbers = true
        editor.buffer.lines = ["中文中文中文中文中文中文"]

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 40)

        #expect(output.contains("[12 chars]"))
        #expect(!output.contains("1 [12 chars]"))
        #expect(output.contains("   ↳ "))
        #expect(output.contains(" \u{1B}[90m2\u{1B}[0m"))
        #expect(output.contains("中文       \u{1B}[90m3\u{1B}[0m"))
    }

    @Test func testSubLineNumbersRequireToggleAndFixedWrapColumn() throws {

        let disabledEditor = Editor(wrapColumn: 10, enableSyntax: false, language: .en)
        disabledEditor.displayConfig.showSubLineNumbers = false
        disabledEditor.buffer.lines = ["中文中文中文中文中文中文"]

        let disabledOutput = disabledEditor.renderer.render(editor: disabledEditor, rows: 8, cols: 40)
        #expect(!disabledOutput.contains("[12 chars]"))

        let dynamicWrapEditor = Editor(enableSyntax: false, language: .en)
        dynamicWrapEditor.displayConfig.showSubLineNumbers = true
        dynamicWrapEditor.buffer.lines = ["中文中文中文中文中文中文中文中文中文中文中文中文"]

        let dynamicOutput = dynamicWrapEditor.renderer.render(editor: dynamicWrapEditor, rows: 8, cols: 20)
        #expect(!dynamicOutput.contains("chars]"))

        let narrowEditor = Editor(wrapColumn: 20, enableSyntax: false, language: .en)
        narrowEditor.displayConfig.showSubLineNumbers = true
        narrowEditor.buffer.lines = ["abcdefghijklmnopqrstuvwxyz"]

        let narrowOutput = narrowEditor.renderer.render(editor: narrowEditor, rows: 8, cols: 20)
        #expect(!narrowOutput.contains("chars]"))
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

    @Test func testJustifyMarkdownListPreservesItemsAndHangingIndent() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            "- This is a long Markdown list item that should remain a list after hard wrapping.",
            "- The next list item must not be merged into the first one.",
        ]
        buffer.lineIndex = 0

        buffer.justifyParagraph(targetWidth: 30)

        #expect(buffer.lines[0].hasPrefix("- "))
        #expect(buffer.lines.dropFirst().allSatisfy { $0.hasPrefix("  ") || $0.hasPrefix("- ") })
        #expect(buffer.lines.contains { $0.hasPrefix("- The next") })
    }

    @Test func testJustifyMarkdownOrderedListPreservesMarker() throws {
        let buffer = TextBuffer()
        buffer.lines = ["12. This is a long ordered Markdown list item that needs wrapping."]
        buffer.lineIndex = 0

        buffer.justifyParagraph(targetWidth: 24)

        #expect(buffer.lines[0].hasPrefix("12. "))
        #expect(buffer.lines.dropFirst().allSatisfy { $0.hasPrefix("    ") })
    }

    @Test func testJustifyUnwrapsShorterLinesUpward() throws {
        let buffer = TextBuffer()
        // 1. CJK short lines unwrapped upwards into a single line
        buffer.lines = [
            "第一行短文字",
            "第二行短文字",
            "第三行短文字",
            "",
            "第二段不被影響",
        ]
        buffer.lineIndex = 0

        // targetWidth = 72 (36 CJK characters), all 3 lines (18 CJK characters = 36 cols) fit in line 0
        buffer.justifyParagraph(targetWidth: 72)

        #expect(buffer.lines.count == 3)
        #expect(buffer.lines[0] == "第一行短文字第二行短文字第三行短文字")
        #expect(buffer.lines[1] == "")
        #expect(buffer.lines[2] == "第二段不被影響")

        // 2. English short lines unwrapped upwards with proper spaces
        let engBuffer = TextBuffer()
        engBuffer.lines = [
            "short line one",
            "short line two",
            "short line three",
        ]
        engBuffer.lineIndex = 1
        engBuffer.justifyParagraph(targetWidth: 72)

        #expect(engBuffer.lines.count == 1)
        #expect(engBuffer.lines[0] == "short line one short line two short line three")
    }

    @Test func testJustifyUsesEditorFillColumnSetting() throws {
        let editor = Editor()
        editor.apply(.fill(20))
        #expect(editor.fillColumn == 20)

        editor.buffer.lines = [
            "This is a long sentence that should be wrapped according to fill column setting."
        ]
        editor.buffer.lineIndex = 0

        _ = editor.commandRegistry.dispatch(id: .editJustify, editor: editor)

        for line in editor.buffer.lines {
            #expect(line.displayWidth <= 20)
        }
    }

    @Test func testLongChineseParagraphReflowAndWrap() throws {
        let buffer = TextBuffer()
        // Long continuous Chinese text originally broken arbitrarily
        buffer.lines = [
            "古人學問無遺力，少壯工夫老始成。",
            "紙上得來終覺淺，絕知此事要躬行。",
            "這是一篇用來測試長篇中文段落重新排版演算法的文章，我們希望在重排之後，",
            "每一個字元都能依照全形字元佔用兩格寬度的規則進行計算與斷行，",
            "並且在段落重排時不會在中文字與中文字之間插入多餘的半形空格。",
        ]
        buffer.lineIndex = 0

        // Target width = 40 (20 CJK full-width characters per line)
        buffer.justifyParagraph(targetWidth: 40)

        #expect(buffer.lines.count > 1)
        for (i, line) in buffer.lines.enumerated() {
            #expect(
                line.displayWidth <= 40,
                "Line \(i) exceeded target width 40: \(line) (displayWidth: \(line.displayWidth))")
        }

        // Verify content integrity: all characters preserved without stray spaces between Chinese chars
        let rejoined = buffer.lines.joined()
        #expect(rejoined.contains("古人學問無遺力，少壯工夫老始成。紙上得來終覺淺"))
        #expect(!rejoined.contains("古 人"))
        #expect(!rejoined.contains("紙 上"))
    }

    @Test func testLongEnglishParagraphReflowAndWrap() throws {
        let buffer = TextBuffer()
        // Long English text with uneven line lengths
        buffer.lines = [
            "GNU nano is a small and friendly text editor that aims to be a free replacement",
            "for the Pico text editor, which was part of the Pine email suite.",
            "Nano copies the look and feel of Pico, but is free software, and implements several features",
            "that Pico lacks, such as opening multiple files, scrolling per line, undo/redo, and syntax highlighting.",
        ]
        buffer.lineIndex = 0

        // Target width = 50 display columns
        buffer.justifyParagraph(targetWidth: 50)

        #expect(buffer.lines.count >= 5)
        for (i, line) in buffer.lines.enumerated() {
            #expect(
                line.displayWidth <= 50,
                "Line \(i) exceeded target width 50: '\(line)' (displayWidth: \(line.displayWidth))")
            #expect(!line.hasPrefix(" "))
            #expect(!line.hasSuffix(" "))
        }

        // Verify words are preserved
        let allWords = buffer.lines.joined(separator: " ").components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        #expect(allWords.contains("replacement"))
        #expect(allWords.contains("highlighting."))
    }

    @Test func testLongMixedCJKAndLatinParagraphReflowAndWrap() throws {
        let buffer = TextBuffer()
        // Long mixed paragraph with Chinese, English terms, version numbers, and symbols
        buffer.lines = [
            "Zago 是一款用 Swift 6.0 開發的終端機文字編輯器，",
            "它結合了 GNU nano 的經典操作模式與 WordStar 的尺規設計，",
            "並且內建了 Logo 語言繪圖引擎，支援 ANSI 繪圖與 Markdown 表格快速編輯。",
            "在處理 UTF-8 與 CJK 全形字元時，Zago 能夠精準計算 Display Width 並進行段落 Reflow。",
        ]
        buffer.lineIndex = 0

        // Target width = 36 display columns
        buffer.justifyParagraph(targetWidth: 36)

        #expect(buffer.lines.count >= 5)
        for (i, line) in buffer.lines.enumerated() {
            #expect(
                line.displayWidth <= 36,
                "Line \(i) exceeded target width 36: '\(line)' (displayWidth: \(line.displayWidth))")
        }

        // Verify key terms and characters are kept intact
        let fullText = buffer.lines.joined(separator: " ")
        #expect(fullText.contains("Swift 6.0"))
        #expect(fullText.contains("GNU nano"))
        #expect(fullText.contains("WordStar"))
        #expect(fullText.contains("Display Width"))
    }

    @Test func testJustifyParagraphPreservesCursorPosition() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            "Swift is a powerful and intuitive",
            "programming language created by Apple",
            "for building apps.",
        ]
        // Cursor is before 'l' in 'language' on line 1 (column 12)
        buffer.lineIndex = 1
        buffer.columnIndex = 12

        buffer.justifyParagraph(targetWidth: 30)

        // Reflowed line 1 is "intuitive programming language"
        // Cursor must remain right before 'language' (column 22)
        #expect(buffer.lineIndex == 1)
        #expect(buffer.columnIndex == 22)
        let line = buffer.lines[buffer.lineIndex]
        let remaining = String(line.dropFirst(buffer.columnIndex))
        #expect(remaining.hasPrefix("language"))
    }

    @Test func testJustifyChineseParagraphPreservesCursorPosition() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            "這是一段很長的中文字段落，用來測試視覺對齊演算法",
            "是否能在指定寬度內正確折行。",
        ]
        // Cursor on '視' in "視覺對齊演算法" on line 0 (char index 18)
        let targetCharIndex = buffer.lines[0].firstIndex(of: "視")!
        let targetCol = buffer.lines[0].distance(from: buffer.lines[0].startIndex, to: targetCharIndex)
        buffer.lineIndex = 0
        buffer.columnIndex = targetCol

        buffer.justifyParagraph(targetWidth: 12)

        // Target char '視' moved during reflow:
        // Line 0: "這是一段很長"
        // Line 1: "的中文字段落"
        // Line 2: "，用來測試視"
        let line = buffer.lines[buffer.lineIndex]
        let remaining = String(line.dropFirst(buffer.columnIndex))
        #expect(remaining.hasPrefix("視"))
    }

    @Test func testJustifyMixedCJKAndEnglishPreservesCursorPosition() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            "Zago 是一個專為終端文字工作者設計的",
            "現代化純文字編輯器，結合了 LOGO 繪圖與 Markdown 支援。",
        ]
        // Cursor on 'L' in "LOGO" on line 1
        let targetIndex = buffer.lines[1].firstIndex(of: "L")!
        let targetCol = buffer.lines[1].distance(from: buffer.lines[1].startIndex, to: targetIndex)
        buffer.lineIndex = 1
        buffer.columnIndex = targetCol

        buffer.justifyParagraph(targetWidth: 28)

        let line = buffer.lines[buffer.lineIndex]
        let remaining = String(line.dropFirst(buffer.columnIndex))
        #expect(remaining.hasPrefix("LOGO"))
    }

    @Test func testJustifyMarkdownListPreservesCursorPosition() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            "- 這是一個包含 Markdown 清單符號的段落，測試重排時",
            "  是否能正確跟隨游標所在的中文關鍵字位置。",
        ]
        // Cursor on '關' in "關鍵字" on line 1
        let targetIndex = buffer.lines[1].firstIndex(of: "關")!
        let targetCol = buffer.lines[1].distance(from: buffer.lines[1].startIndex, to: targetIndex)
        buffer.lineIndex = 1
        buffer.columnIndex = targetCol

        buffer.justifyParagraph(targetWidth: 26)

        let line = buffer.lines[buffer.lineIndex]
        let remaining = String(line.dropFirst(buffer.columnIndex))
        #expect(remaining.hasPrefix("關鍵字"))
    }

    @Test func testJustifyOrderedListPreservesCursorPosition() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            "1. Apple designed Swift to be fast, safe, and modern for all developers."
        ]
        // Cursor on 's' in "safe"
        let safeIndex = buffer.lines[0].range(of: "safe")!.lowerBound
        let targetCol = buffer.lines[0].distance(from: buffer.lines[0].startIndex, to: safeIndex)
        buffer.lineIndex = 0
        buffer.columnIndex = targetCol

        buffer.justifyParagraph(targetWidth: 32)

        let line = buffer.lines[buffer.lineIndex]
        let remaining = String(line.dropFirst(buffer.columnIndex))
        #expect(remaining.hasPrefix("safe"))
    }

    @Test func testJustifyMarkdownBlockquotePreservesQuotes() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            "> aasdads",
            "> asdfasdfsfdfd",
        ]
        buffer.lineIndex = 0
        buffer.columnIndex = 0

        // Target width = 72 unrolls both lines into one single quote line
        buffer.justifyParagraph(targetWidth: 72)
        #expect(buffer.lines.count == 1)
        #expect(buffer.lines[0] == "> aasdads asdfasdfsfdfd")

        // Wrapping back down to 14 columns preserves > on each wrapped line
        buffer.justifyParagraph(targetWidth: 14)
        #expect(buffer.lines.count == 2)
        #expect(buffer.lines[0] == "> aasdads")
        #expect(buffer.lines[1] == "> asdfasdfsfdfd")
    }

    @Test func testJustifyMarkdownNestedBlockquotePreservesQuotesAndCursor() throws {
        let buffer = TextBuffer()
        buffer.lines = [
            ">> 第一行巢狀引用文字內容",
            ">> 第二行繼續引用相關說明資料",
        ]
        // Put cursor on '相' in second line
        let targetIndex = buffer.lines[1].range(of: "相")!.lowerBound
        let targetCol = buffer.lines[1].distance(from: buffer.lines[1].startIndex, to: targetIndex)
        buffer.lineIndex = 1
        buffer.columnIndex = targetCol

        buffer.justifyParagraph(targetWidth: 60)
        #expect(buffer.lines.count == 1)
        #expect(buffer.lines[0] == ">> 第一行巢狀引用文字內容第二行繼續引用相關說明資料")

        let curLine = buffer.lines[buffer.lineIndex]
        let remaining = String(curLine.dropFirst(buffer.columnIndex))
        #expect(remaining.hasPrefix("相關說明資料"))
    }

    @Test func testTerminalDisplayWidthHelpers() throws {
        #expect(Character("A").displayWidth == 1)
        #expect(Character("中").displayWidth == 2)
        #expect(Character("\u{30EDE}").displayWidth == 2)
        #expect(Character("❌").displayWidth == 2)
        #expect(Character("❤️").displayWidth == 2)
        #expect(Character("\u{FE0F}").displayWidth == 0)
        #expect(Character("\u{200D}").displayWidth == 0)
        #expect("Hello".displayWidth == 5)
        #expect("中文".displayWidth == 4)
        #expect("A\u{30EDE}B".displayWidth == 4)
        #expect("A❌B".displayWidth == 4)
        #expect("A❌️B".displayWidth == 4)
        #expect("Hello".paddedToDisplayWidth(10) == "Hello     ")
        #expect("ab".repeatedToDisplayWidth(5) == "ababa")
        #expect("中".repeatedToDisplayWidth(5) == "中中 ")
        #expect("ab".tiledToDisplayWidth(5) == "abab ")
    }

    @Test func testEmojiDisplayWidthAffectsSoftwrapAndCursorPosition() throws {
        let engine = LayoutEngine(wrapColumn: 10)

        let exactFitLines = engine.computeVirtualLines(from: ["12345678❌A"], viewWidth: 80)
        #expect(exactFitLines.map(\.text) == ["12345678❌", "A"])

        let overflowLines = engine.computeVirtualLines(from: ["123456789❌A"], viewWidth: 80)
        #expect(overflowLines.map(\.text) == ["123456789", "❌A"])

        let editor = Editor(enableSyntax: false)
        editor.displayConfig.showLineNumbers = false
        editor.buffer.lines = ["A❌B"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 2

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 20)
        #expect(output.contains("\u{1B}[2;4H"))
    }

    @Test func testRepeatedEmojiCursorPositionUsesDisplayWidth() throws {
        let editor = Editor(enableSyntax: false)
        editor.displayConfig.showLineNumbers = false
        editor.buffer.lines = ["❌❌❌❌❌"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 5

        #expect(editor.buffer.lines[0].count == 5)
        #expect(editor.buffer.lines[0].displayWidth == 10)

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 30)
        #expect(output.contains("\u{1B}[2;11H"))

        editor.displayConfig.showLineNumbers = true
        let outputWithGutter = editor.renderer.render(editor: editor, rows: 8, cols: 30)
        #expect(outputWithGutter.contains("\u{1B}[2;16H"))
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

        let extendedCJK = "A\u{30EDE}B"
        #expect(extendedCJK.visualColumn(forCharacterOffset: 2) == 3)
        #expect(extendedCJK.characterOffset(forVisualColumn: 2) == 1)
        #expect(extendedCJK.snappedVisualColumn(2, direction: .forward) == 3)
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

    @Test func testRendererExpandsRawTabsUsingConfiguredTabStops() throws {
        let editor = Editor(enableSyntax: false)
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.tabSize = 4
        editor.buffer.lines = ["A\tB"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 2

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 20)

        #expect(output.contains("A   B"))
        #expect(!output.contains("A\tB"))
        #expect(output.contains("\u{1B}[2;5H"))
    }

    @Test func testRendererRawTabsHonorCustomTabSize() throws {
        let editor = Editor(enableSyntax: false)
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.tabSize = 2
        editor.buffer.lines = ["A\tB"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 2

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 20)

        #expect(output.contains("A B"))
        #expect(!output.contains("A\tB"))
        #expect(output.contains("\u{1B}[2;3H"))
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

        editor.layoutEngine.setWrapColumn(10)
        let renderedRuler = editor.renderer.renderRulerBar(
            editor: editor,
            textWidth: 20,
            gutterWidth: 0,
            cols: 20,
            dropdownStartCol: 0,
            dropdownBoxWidth: 0,
            dropdownBoxLines: []
        )
        #expect(renderedRuler.contains("\u{1B}[90m"))
        #expect(renderedRuler.contains("\u{1B}[1;33m<\u{1B}[90m"))
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
        let cleanWithRuler =
            outputWithRuler.hasPrefix("\u{1B}[H") ? String(outputWithRuler.dropFirst(3)) : outputWithRuler
        let linesWithRuler = cleanWithRuler.components(separatedBy: "\r\n")

        #expect(linesWithRuler[0].contains("zago"))
        #expect(linesWithRuler[0].contains("\u{1B}[7m"))
        #expect(linesWithRuler[1].contains("!"))  // Ruler line

        #expect(linesWithRuler.count == 24)
    }

    @Test func testInitialFrameRenderDiffDoesNotEndWithTrailingNewlineThatCausesTerminalScroll() throws {
        let editor = Editor()
        let rows = 24
        let cols = 80

        // Initial frame render via renderDiff (full redraw path)
        let initialOutput = editor.renderer.renderDiff(editor: editor, rows: rows, cols: cols)

        // Must start with disable wrap + move cursor top-left
        #expect(initialOutput.hasPrefix("\u{1B}[?7l\u{1B}[H"))

        // Separate main content from trailing cursor positioning ansi (e.g. \u{1B}[3;7H)
        let contentWithoutHeader = String(initialOutput.dropFirst(8))
        let parts = contentWithoutHeader.components(separatedBy: "\r\n")

        // Must have exactly 24 line components (23 \r\n separators)
        #expect(parts.count == 24)

        // The first line must contain topbar title "zago"
        #expect(parts[0].contains("zago"))

        // The 24th line (last row) MUST NOT contain trailing \r\n before cursor positioning
        let lastRowWithCursor = parts[23]
        #expect(!lastRowWithCursor.contains("\r\n"))
        #expect(lastRowWithCursor.contains("\u{1B}[K"))
    }

    @Test func testMenuBarHomeEndPageUpPageDownKeyNavigation() throws {
        let editor = Editor()
        editor.isMenuBarActive = true
        #expect(editor.isMenuBarActive == true)
        #expect(editor.menuBar.categoryIndex == 0)
        #expect(editor.menuBar.itemIndex == 0)

        // PageDown moves itemIndex to bottom of active category
        _ = editor.menuBarController.handleKey(.pageDown)
        #expect(editor.menuBar.categoryIndex == 0)
        #expect(editor.menuBar.itemIndex == editor.menuBar.currentCategory.items.count - 1)

        // PageUp moves itemIndex to top (0)
        _ = editor.menuBarController.handleKey(.pageUp)
        #expect(editor.menuBar.categoryIndex == 0)
        #expect(editor.menuBar.itemIndex == 0)

        // End moves categoryIndex to last category
        _ = editor.menuBarController.handleKey(.end)
        #expect(editor.menuBar.categoryIndex == editor.menuBar.categories.count - 1)

        // Home moves categoryIndex back to first category
        _ = editor.menuBarController.handleKey(.home)
        #expect(editor.menuBar.categoryIndex == 0)
    }

    @Test func testLayoutEngineLineCacheReusesVirtualLineChunks() throws {
        let engine = LayoutEngine(wrapColumn: 20)
        let longLine = "這是一行非常長的中文與英文混合文字，用來測試 LayoutEngine 佈局快取機制能否正確運作並且提升軟換行效能。"

        let firstVirtualLines = engine.computeVirtualLines(from: [longLine], viewWidth: 80)
        #expect(firstVirtualLines.count > 1)

        let secondVirtualLines = engine.computeVirtualLines(from: [longLine], viewWidth: 80)
        #expect(secondVirtualLines.count == firstVirtualLines.count)
        for (v1, v2) in zip(firstVirtualLines, secondVirtualLines) {
            #expect(v1.text == v2.text)
            #expect(v1.startCol == v2.startCol)
            #expect(v1.endCol == v2.endCol)
        }

        #expect(engine.lineCacheHitCount > 0)
    }

    @Test func testLocalizedHelpBarPromptAndCanvasLabels() throws {
        let renderer = Renderer()

        let promptHelpBar = renderer.renderHelpBar(
            cols: 80, promptMode: .search(completion: { _ in }), editor: Editor(language: .zh_TW))
        #expect(promptHelpBar.contains("確認"))
        #expect(promptHelpBar.contains("取消"))
        #expect(promptHelpBar.contains("清除"))
        #expect(promptHelpBar.contains("移動"))
        #expect(promptHelpBar.contains("跳轉"))
        #expect(!promptHelpBar.contains("Confirm"))
        #expect(!promptHelpBar.contains("Cancel"))

        let canvasEditor = Editor(language: .zh_TW)
        canvasEditor.switchToCanvasMode()
        let canvasHelpBar = renderer.renderHelpBar(cols: 120, promptMode: .none, editor: canvasEditor)
        #expect(canvasHelpBar.contains("標記區塊"))
        #expect(canvasHelpBar.contains("剪下區塊"))
        #expect(canvasHelpBar.contains("複製區塊"))
        #expect(canvasHelpBar.contains("貼上區塊"))
        #expect(canvasHelpBar.contains("線段"))
        #expect(canvasHelpBar.contains("箭頭"))
        #expect(canvasHelpBar.contains("清除標記"))
        #expect(canvasHelpBar.contains("邊框樣式"))
        #expect(!canvasHelpBar.contains("Mark Block"))
        #expect(!canvasHelpBar.contains("Copy Block"))

        let confirmHelpBar = renderer.renderHelpBar(
            cols: 80, promptMode: .confirmExitSave(completion: { _ in }), editor: canvasEditor)
        #expect(confirmHelpBar.contains("是"))
        #expect(confirmHelpBar.contains("否"))

        let logoEditor = Editor(language: .zh_TW)
        logoEditor.promptCompletionText = "SET wrap"
        let logoHelpBar = renderer.renderHelpBar(
            cols: 80, promptMode: .logoMacro(completion: { _ in }), editor: logoEditor)
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
        editor.buffer.selectionMark = (line: 0, column: 4)

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

    @Test func testSoftwrappedTableSyntaxHighlighting() throws {
        let editor = Editor(filePath: "document.md", wrapColumn: 30, enableSyntax: true)
        editor.buffer.lines = [
            "| Header 1 | Header 2 | Very Long Table Content That Will Softwrap Across Multiple Sublines |"
        ]

        let output = editor.renderer.render(editor: editor, rows: 10, cols: 35)

        let lines = output.components(separatedBy: "\r\n")
        #expect(lines[1].contains("\u{1B}[94m"))
        #expect(lines[2].contains("\u{1B}[94m"))
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

        let syntaxMdLogo = editor.syntaxForLine(at: 2)
        #expect(syntaxMdLogo?.name == "LOGO")

        let syntaxMdText = editor.syntaxForLine(at: 5)
        #expect(syntaxMdText?.name == "Markdown")

        // 2. Org-mode embedded LOGO code block
        editor.buffer.filePath = "notes.org"
        editor.buffer.lines = [
            "* Section Title",
            "#+BEGIN_SRC logo",
            "; comment inside logo org block",
            "#+END_SRC",
        ]
        let syntaxOrgLogo = editor.syntaxForLine(at: 2)
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
        let syntaxRstLogo = editor.syntaxForLine(at: 3)
        #expect(syntaxRstLogo?.name == "LOGO")

        // 4. Markdown with multiple spaces after backticks (```   logo   )
        editor.buffer.filePath = "document.md"
        editor.buffer.lines = [
            "```   logo   ",
            "; comment inside multi-space logo block",
            "```",
        ]
        let syntaxMultiSpaceLogo = editor.syntaxForLine(at: 1)
        #expect(syntaxMultiSpaceLogo?.name == "LOGO")

        // 5. Org-mode with multiple spaces (#+BEGIN_SRC   logo  )
        editor.buffer.filePath = "notes.org"
        editor.buffer.lines = [
            "#+BEGIN_SRC   logo  ",
            "; comment inside multi-space org logo block",
            "#+END_SRC",
        ]
        let syntaxMultiSpaceOrg = editor.syntaxForLine(at: 1)
        #expect(syntaxMultiSpaceOrg?.name == "LOGO")

        // 6. RST with multiple spaces (.. code-block::   logo  )
        editor.buffer.filePath = "docs.rst"
        editor.buffer.lines = [
            ".. code-block::   logo  ",
            "",
            "   ; comment inside multi-space rst logo block",
        ]
        let syntaxMultiSpaceRst = editor.syntaxForLine(at: 2)
        #expect(syntaxMultiSpaceRst?.name == "LOGO")
    }

}
