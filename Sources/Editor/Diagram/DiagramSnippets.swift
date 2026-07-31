import Foundation

/// Central Diagram Snippet Manager handling snippet insertion and menu bar category generation.
public struct DiagramSnippets {

    /// Inserts a diagram snippet into the editor buffer with context-aware wrapping.
    public static func insertSnippet(_ snippet: any DiagramSnippet, into editor: Editor) {
        editor.saveUndoSnapshot()

        let ext = (editor.buffer.filePath as NSString?)?.pathExtension.lowercased() ?? ""
        let fileEngine = DiagramEngine.engine(forFileExtension: ext)
        let activeEngineCtx = activeEngine(for: editor)

        let snippetText: String

        if fileEngine != nil || activeEngineCtx != nil {
            // Already inside a dedicated diagram file or language code block
            snippetText = snippet.templateText
        } else {
            // Outside code block in Markdown/RST/Org or plain text buffer: wrap in fenced code block
            snippetText = "```\(snippet.codeBlockTag)\n\(snippet.templateText)\n```"
        }

        // Insert snippet line by line into editor buffer
        let lines = snippetText.components(separatedBy: .newlines)
        for (i, line) in lines.enumerated() {
            editor.buffer.insertString(line)
            if i < lines.count - 1 {
                editor.buffer.insertNewline()
            }
        }

        editor.buffer.isModified = true
        editor.setStatusMessage(L10n.insertedDiagramSnippet(snippet.engine.rawValue))
    }

    /// Generates the `MenuCategory` for Diagrams to be placed between Tools and Help, filtering items by active engine context.
    public static func makeMenuCategory(for editor: Editor? = nil) -> MenuCategory {
        let filteredSnippets: [any DiagramSnippet]
        if let editor = editor, let filterEngine = activeEngine(for: editor) {
            filteredSnippets = DiagramSnippetFactory.snippets(for: filterEngine)
        } else {
            filteredSnippets = DiagramSnippetFactory.allSnippets
        }

        let items = filteredSnippets.map { snippet in
            MenuItem(
                titleKey: snippet.titleKey,
                hotkeyChar: snippet.hotkeyChar,
                action: { editor in
                    insertSnippet(snippet, into: editor)
                }
            )
        }
        return MenuCategory(titleKey: "menu.diagrams", hotkeyChar: "d", items: items)
    }

    /// Finds a diagram snippet matching a query string (e.g., "sequence", "flowchart", "digraph").
    public static func findDiagramSnippet(by query: String) -> (any DiagramSnippet)? {
        DiagramSnippetFactory.findSnippet(by: query)
    }
}
