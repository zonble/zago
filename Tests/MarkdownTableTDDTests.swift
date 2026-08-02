import Foundation
import Testing

@testable import Editor
@testable import Syntax
@testable import TextMetrics

struct MarkdownTableTDDTests {
    @Test func testHeaderRowTabSkipsSeparatorRowToFirstDataRow() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| Header 1 | Header 2 |",
            "| :--- | :--- |",
            "| Cell 1 | Cell 2 |",
            "| Cell 3 | Cell 4 |",
        ]

        let res1 = mdSyntax.tableNavigator?(lines, 0, 2, true)
        #expect(res1 != nil)
        #expect(res1?.newBufferLineIndex == 0)

        let res2 = mdSyntax.tableNavigator?(lines, 0, 13, true)
        #expect(res2 != nil)
        #expect(res2?.newBufferLineIndex == 2)
        #expect(res2?.newCursorColumn == 2)
    }

    @Test func testSeparatorRowTabJumpsToFirstDataRow() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| Header 1 | Header 2 |",
            "| :--- | :--- |",
            "| Cell 1 | Cell 2 |",
        ]

        let res = mdSyntax.tableNavigator?(lines, 1, 4, true)
        #expect(res != nil)
        #expect(res?.newBufferLineIndex == 2)
        #expect(res?.newCursorColumn == 2)
    }

    @Test func testDataRowTabNavigatesCellsAndAppendsNewRowAtBottom() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| Header 1 | Header 2 |",
            "| :--- | :--- |",
            "| Cell 1 | Cell 2 |",
            "| Cell 3 | Cell 4 |",
        ]

        let res1 = mdSyntax.tableNavigator?(lines, 2, 2, true)
        #expect(res1 != nil)
        #expect(res1?.newBufferLineIndex == 2)

        let res2 = mdSyntax.tableNavigator?(lines, 2, 11, true)
        #expect(res2 != nil)
        #expect(res2?.newBufferLineIndex == 3)
        #expect(res2?.newCursorColumn == 2)

        let res3 = mdSyntax.tableNavigator?(lines, 3, 11, true)
        #expect(res3 != nil)
        #expect(res3?.updatedLines != nil)
        #expect(res3?.newBufferLineIndex == 4)
        #expect(res3?.newCursorColumn == 2)

        if let updated = res3?.updatedLines {
            #expect(updated.count == 5)
            #expect(updated[4].contains("|"))
            #expect(!updated[4].contains("-"))
        }
    }

    @Test func testShiftTabBackwardNavigationSkipsSeparatorRow() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| Header 1 | Header 2 |",
            "| :--- | :--- |",
            "| Cell 1 | Cell 2 |",
        ]

        let res1 = mdSyntax.tableNavigator?(lines, 2, 11, false)
        #expect(res1 != nil)
        #expect(res1?.newBufferLineIndex == 2)
        #expect(res1?.newCursorColumn == 2)

        let res2 = mdSyntax.tableNavigator?(lines, 2, 2, false)
        #expect(res2 != nil)
        #expect(res2?.newBufferLineIndex == 0)
    }

    @Test func testIndentedTableNavigation() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "    | Header 1 | Header 2 |",
            "    | :--- | :--- |",
            "    | Cell 1 | Cell 2 |",
        ]

        let res = mdSyntax.tableNavigator?(lines, 2, 6, true)
        #expect(res != nil)
        #expect(res?.newBufferLineIndex == 2)
    }

    @Test func testDraftHeaderTabCreatesSeparatorAndFirstDataRow() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| a   | b   |",
            "|--",
        ]

        let res = mdSyntax.tableNavigator?(lines, 1, 3, true)
        #expect(res != nil)
        #expect(res?.updatedLines != nil)
        if let updated = res?.updatedLines {
            #expect(updated.count == 3)
            #expect(updated[0] == "| a   | b   |")
            #expect(updated[1] == "| --- | --- |")
            #expect(updated[2] == "|     |     |")
        }
        #expect(res?.newBufferLineIndex == 2)
        #expect(res?.newCursorColumn == 2)
    }

    @Test func testTabAutoAlignsCellWidths() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| test | test |",
            "| ---- | ---- |",
            "| adsaads     |   |",
        ]

        let res = mdSyntax.tableNavigator?(lines, 2, 2, true)
        #expect(res != nil)
        #expect(res?.updatedLines != nil)
        if let updated = res?.updatedLines {
            #expect(updated[0] == "| test    | test |")
            #expect(updated[1] == "| ------- | ---- |")
            #expect(updated[2] == "| adsaads |      |")
        }
    }

    @Test func testTabAutoExpandsColumnCountsAcrossAllRows() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| test | test | asda ds |",
            "| ------- | -------- |",
            "| adsaads | |",
        ]

        let res = mdSyntax.tableNavigator?(lines, 0, 20, true)
        #expect(res != nil)
        #expect(res?.updatedLines != nil)
        if let updated = res?.updatedLines {
            #expect(updated.count == 3)
            #expect(updated[0] == "| test    | test | asda ds |")
            #expect(updated[1] == "| ------- | ---- | ------- |")
            #expect(updated[2] == "| adsaads |      |         |")
        }
    }

    @Test func testCJKVisualWidthTableAlignment() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| 名稱 | 年齡 |",
            "| --- | --- |",
            "| Alice | 30 |",
            "| Bob | 25 |",
        ]

        let res = mdSyntax.tableFormatter?(lines, 0, 2)
        #expect(res != nil)
        #expect(res?.updatedLines != nil)
        if let updated = res?.updatedLines {
            #expect(updated[0] == "| 名稱  | 年齡 |")
            #expect(updated[1] == "| ----- | ---- |")
            #expect(updated[2] == "| Alice | 30   |")
            #expect(updated[3] == "| Bob   | 25   |")
        }
    }

    @Test func testFormatTablePreservesCurrentLineIndexAndExactCellCursor() throws {
        let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| test | test |",
            "| ---- | ---- |",
            "| adsaads |  |",
        ]

        let res = mdSyntax.tableFormatter?(lines, 2, 5)
        #expect(res != nil)
        #expect(res?.startLineIndex == 2)
        #expect(res?.newCursorColumn == 5)
    }

    @Test func testAsciiDocOneCellPerLineTableSupport() throws {
        let adocSyntax = AsciiDocSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "[cols=\"1,1\"]",
            "|===",
            "|Cell in column 1, row 1",
            "|Cell in column 2, row 1",
            "",
            "|Cell in column 1, row 2",
            "|Cell in column 2, row 2",
            "",
            "|Cell in column 1, row 3",
            "|Cell in column 2, row 3",
            "|===",
        ]

        let range = PipeTableFormatter.findTableRange(in: lines, at: 3, style: .asciiDoc)
        #expect(range != nil)
        #expect(range?.lowerBound == 0)
        #expect(range?.upperBound == 11)

        let nav1 = adocSyntax.tableNavigator?(lines, 2, 2, true)
        #expect(nav1 != nil)
        #expect(nav1?.newBufferLineIndex == 3)
        #expect(nav1?.updatedLines == nil)

        let nav2 = adocSyntax.tableNavigator?(lines, 3, 2, true)
        #expect(nav2 != nil)
        #expect(nav2?.newBufferLineIndex == 5)
        #expect(nav2?.updatedLines == nil)

        let nav3 = adocSyntax.tableNavigator?(lines, 9, 2, true)
        #expect(nav3 != nil)
        #expect(nav3?.updatedLines != nil)
        if let updated = nav3?.updatedLines {
            #expect(updated.contains("[cols=\"1,1\"]"))
            #expect(updated.contains("|==="))
            #expect(updated.contains("|Cell in column 1, row 1"))
            #expect(updated.contains("|Cell in column 2, row 1"))
        }
    }

    @Test func testOrgModeDraftRowTabNavigationPreservesBottomRow() throws {
        let orgSyntax = OrgModeSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| 你好嗎？         | asda a     |",
            "|------------------+------------|",
            "|                  | 簡單的表格 |",
            "| 不需要太多操作？ |            |",
            "| asdad            |            |",
            "| sadaasdad        |            |",
            "| ",
        ]

        let res = orgSyntax.tableNavigator?(lines, 6, 2, true)
        #expect(res != nil)
        #expect(res?.newBufferLineIndex == 6)
        #expect(res?.newCursorColumn == 2)

        if let updated = res?.updatedLines {
            #expect(updated.count == 7)
            #expect(updated[6].hasPrefix("| "))
            #expect(updated[6].hasSuffix("|"))
        }
    }

    @Test func testReSTGridTableTopBorderDrafting() throws {
        let restSyntax = ReSTSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "|-",
            "| Header 1 | Header 2 |",
            "| Cell 1   | Cell 2   |",
        ]

        let res = restSyntax.tableNavigator?(lines, 0, 2, true)
        #expect(res != nil)
        #expect(res?.updatedLines != nil)
        if let updated = res?.updatedLines {
            #expect(updated[0] == "+----------+----------+")
            #expect(updated[1] == "| Header 1 | Header 2 |")
        }
    }

    @Test func testReSTGridTableDoubleLineHeaderSeparatorDrafting() throws {
        let restSyntax = ReSTSyntaxDefinition().buildLanguageSyntax()
        let lines = [
            "| Header 1 | Header 2 |",
            "|=",
            "| Cell 1   | Cell 2   |",
        ]

        let res = restSyntax.tableNavigator?(lines, 1, 2, true)
        #expect(res != nil)
        #expect(res?.updatedLines != nil)
        if let updated = res?.updatedLines {
            #expect(updated[1] == "+==========+==========+")
            #expect(updated[0] == "| Header 1 | Header 2 |")
            #expect(updated[2] == "| Cell 1   | Cell 2   |")
        }
    }
}
