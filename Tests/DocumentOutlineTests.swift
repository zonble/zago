import Foundation
import Testing

@testable import DocumentOutline

@Suite struct DocumentOutlineTests {

    @Test func testMarkdownOutlineParsing() {
        let lines = [
            "# Title 1",
            "Some content",
            "## Subsection A",
            "```",
            "# Fake Heading Inside Code Block",
            "```",
            "### Deep Section B",
            "Alternative Title",
            "-----------------",
        ]

        let outline = MarkdownOutlineParser.parse(lines: lines)
        #expect(outline.headings.count == 4)

        #expect(outline.headings[0].title == "Title 1")
        #expect(outline.headings[0].level == 1)
        #expect(outline.headings[0].lineIndex == 0)

        #expect(outline.headings[1].title == "Subsection A")
        #expect(outline.headings[1].level == 2)
        #expect(outline.headings[1].lineIndex == 2)

        #expect(outline.headings[2].title == "Deep Section B")
        #expect(outline.headings[2].level == 3)
        #expect(outline.headings[2].lineIndex == 6)

        #expect(outline.headings[3].title == "Alternative Title")
        #expect(outline.headings[3].level == 2)
        #expect(outline.headings[3].lineIndex == 7)
    }

    @Test func testOrgModeOutlineParsing() {
        let lines = [
            "* Org Header 1",
            "Body text",
            "** Org Subheader A",
            "*** Org Deep Header B",
        ]

        let outline = OrgOutlineParser.parse(lines: lines)
        #expect(outline.headings.count == 3)
        #expect(outline.headings[0].title == "Org Header 1")
        #expect(outline.headings[1].title == "Org Subheader A")
        #expect(outline.headings[2].title == "Org Deep Header B")
    }

    @Test func testAsciiDocOutlineParsing() {
        let lines = [
            "= AsciiDoc Document Title",
            "== Chapter 1",
            "=== Section 1.1",
        ]

        let outline = AsciiDocOutlineParser.parse(lines: lines)
        #expect(outline.headings.count == 3)
        #expect(outline.headings[0].title == "AsciiDoc Document Title")
        #expect(outline.headings[1].title == "Chapter 1")
        #expect(outline.headings[2].title == "Section 1.1")
    }
}
