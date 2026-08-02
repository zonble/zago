import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

struct DiagramSnippetsTests {

    @Test
    func testDiagramMenuVisibilityAndFiltering() {
        let editor = Editor()
        editor.openNewBuffer(filePath: "notes.md")

        // 1. Outside code block in Markdown -> DO NOT show Diagrams menu
        editor.menuBar.updateCategories(for: editor)
        #expect(DiagramSnippets.shouldShowDiagramMenu(for: editor) == false)
        #expect(!editor.menuBar.categories.contains(where: { $0.titleKey == "menu.diagrams" }))

        // 2. Inside generic ``` block in Markdown -> shows Diagrams menu with ALL diagram snippets
        editor.buffer.lines = ["```", ""]
        editor.buffer.lineIndex = 1
        editor.menuBar.updateCategories(for: editor)
        #expect(DiagramSnippets.shouldShowDiagramMenu(for: editor) == true)
        guard let diagramsCat = editor.menuBar.categories.first(where: { $0.titleKey == "menu.diagrams" }) else {
            Issue.record("Diagrams category missing in generic code block")
            return
        }
        #expect(diagramsCat.items.count == DiagramSnippetFactory.allSnippets.count)

        // Verify position: Diagrams category must be between Tools and Help
        let categoryKeys = editor.menuBar.categories.map { $0.titleKey }
        if let toolsIdx = categoryKeys.firstIndex(of: "menu.tools"),
            let diagramsIdx = categoryKeys.firstIndex(of: "menu.diagrams"),
            let helpIdx = categoryKeys.firstIndex(of: "menu.help")
        {
            #expect(diagramsIdx == toolsIdx + 1)
            #expect(helpIdx == diagramsIdx + 1)
        } else {
            Issue.record("Diagrams category was not correctly positioned between Tools and Help")
        }

        // 3. Inside ```mermaid block in Markdown -> shows ONLY Mermaid snippets
        editor.buffer.lines = ["```mermaid", ""]
        editor.buffer.lineIndex = 1
        editor.menuBar.updateCategories(for: editor)
        let mermaidCat = editor.menuBar.categories.first(where: { $0.titleKey == "menu.diagrams" })!
        #expect(mermaidCat.items.count == DiagramSnippetFactory.snippets(for: .mermaid).count)
        #expect(mermaidCat.items.allSatisfy { $0.titleKey.contains("mermaid") })

        // 4. Inside ```puml block in Markdown -> shows ONLY PlantUML snippets
        editor.buffer.lines = ["```puml", ""]
        editor.buffer.lineIndex = 1
        editor.menuBar.updateCategories(for: editor)
        let pumlCat = editor.menuBar.categories.first(where: { $0.titleKey == "menu.diagrams" })!
        #expect(pumlCat.items.count == DiagramSnippetFactory.snippets(for: .plantuml).count)
        #expect(pumlCat.items.allSatisfy { $0.titleKey.contains("puml") })

        // 5. In a standalone .dot file -> shows ONLY DOT snippets
        editor.openNewBuffer(filePath: "architecture.dot")
        editor.menuBar.updateCategories(for: editor)
        let dotCat = editor.menuBar.categories.first(where: { $0.titleKey == "menu.diagrams" })!
        #expect(dotCat.items.count == DiagramSnippetFactory.snippets(for: .dot).count)
        #expect(dotCat.items.allSatisfy { $0.titleKey.contains("dot") })
    }

    @Test
    func testMarkdownCodeBlockDetection() {
        let editor = Editor()
        editor.openNewBuffer(filePath: "README.md")

        // Outside code block
        #expect(DiagramSnippets.detectCodeBlockEngine(editor: editor) == nil)

        // Inside ```mermaid block
        editor.buffer.lines = [
            "# Header",
            "```mermaid",
            "",
        ]
        editor.buffer.lineIndex = 2
        #expect(DiagramSnippets.detectCodeBlockEngine(editor: editor) == .mermaid)
        #expect(DiagramSnippets.shouldShowDiagramMenu(for: editor) == true)

        // Inside ```dot block
        editor.buffer.lines = [
            "```dot",
            "",
        ]
        editor.buffer.lineIndex = 1
        #expect(DiagramSnippets.detectCodeBlockEngine(editor: editor) == .dot)
        #expect(DiagramSnippets.shouldShowDiagramMenu(for: editor) == true)
    }

    @Test
    func testSnippetInsertionInDiagramFiles() {
        let editor = Editor()
        editor.openNewBuffer(filePath: "diagram.puml")

        DiagramSnippets.insertSnippet(PlantUMLSequenceSnippet(), into: editor)
        let content = editor.buffer.lines.joined(separator: "\n")
        #expect(content.contains("@startuml"))
        #expect(content.contains("sequenceDiagram") == false)
        #expect(content.contains("@enduml"))
    }

    @Test
    func testSnippetInsertionInMarkdownOutsideCodeBlock() {
        let editor = Editor()
        editor.openNewBuffer(filePath: "notes.md")

        DiagramSnippets.insertSnippet(MermaidFlowchartSnippet(), into: editor)
        let content = editor.buffer.lines.joined(separator: "\n")
        #expect(content.contains("```mermaid"))
        #expect(content.contains("flowchart TD"))
        #expect(content.contains("```"))
    }

    @Test
    func testSnippetInsertionInMarkdownInsideCodeBlock() {
        let editor = Editor()
        editor.openNewBuffer(filePath: "doc.md")
        editor.buffer.lines = ["```mermaid", ""]
        editor.buffer.lineIndex = 1

        DiagramSnippets.insertSnippet(MermaidSequenceSnippet(), into: editor)
        let content = editor.buffer.lines.joined(separator: "\n")
        #expect(content.contains("sequenceDiagram"))
        // Should not create double fenced code blocks
        #expect(content.components(separatedBy: "```mermaid").count == 2)
    }

    @Test
    func testGraphvizDotSnippetInsertion() {
        let editor = Editor()
        editor.openNewBuffer(filePath: "graph.dot")

        DiagramSnippets.insertSnippet(DOTDigraphSnippet(), into: editor)
        let content = editor.buffer.lines.joined(separator: "\n")
        #expect(content.contains("digraph G {"))
        #expect(content.contains("rankdir=LR;"))
    }

    @Test
    func testLogoEngineDiagramCommand() {
        let editor = Editor()
        editor.openNewBuffer(filePath: "doc.md")

        editor.runLogoScript("DIAGRAM \"sequence")
        let content = editor.buffer.lines.joined(separator: "\n")
        #expect(content.contains("sequenceDiagram"))
    }

    @Test
    func testAllMermaidPlantUMLDOTSnippets() {
        let allSnippets = DiagramSnippetFactory.allSnippets
        #expect(allSnippets.count >= 10)

        for snippet in allSnippets {
            let editor = Editor()
            editor.openNewBuffer(filePath: "test.md")
            DiagramSnippets.insertSnippet(snippet, into: editor)
            #expect(!editor.buffer.lines.isEmpty)
            #expect(snippet.titleKey.count > 0)
        }
    }
}
