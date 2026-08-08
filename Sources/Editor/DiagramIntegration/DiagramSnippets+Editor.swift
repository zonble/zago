@_exported import Diagram
import Foundation

extension DiagramSnippets {
    /// Inserts a diagram snippet into the editor buffer with context-aware wrapping.
    public static func insertSnippet(_ snippet: any DiagramSnippet, into editor: Editor) {
        editor.saveUndoSnapshot()

        let ext = (editor.buffer.filePath as NSString?)?.pathExtension.lowercased() ?? ""
        let fileEngine = DiagramEngine.engine(forFileExtension: ext)
        let activeEngineCtx = activeEngine(for: editor)

        let snippetText: String
        if fileEngine != nil || activeEngineCtx != nil {
            snippetText = snippet.templateText
        } else {
            snippetText = "```\(snippet.codeBlockTag)\n\(snippet.templateText)\n```"
        }

        let lines = snippetText.components(separatedBy: .newlines)
        for (i, line) in lines.enumerated() {
            editor.buffer.insertString(line)
            if i < lines.count - 1 {
                editor.buffer.insertNewline()
            }
        }

        editor.buffer.isModified = true
        editor.setStatusMessage(editor.l10n.insertedDiagramSnippet(snippet.engine.rawValue))
    }

    /// Generates the `MenuCategory` for Diagrams to be placed between Tools and Help, filtering items by active engine context.
    public static func makeMenuCategory(for editor: Editor? = nil) -> MenuCategory {
        let filteredSnippets: [any DiagramSnippet]
        if let editor, let filterEngine = activeEngine(for: editor) {
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

    /// Determines active diagram engine context based on file extension and code block position.
    public static func activeEngine(for editor: Editor) -> DiagramEngine? {
        activeEngine(filePath: editor.buffer.filePath, lines: editor.buffer.lines, lineIndex: editor.buffer.lineIndex)
    }

    /// Determines if the current buffer context warrants showing the Diagram menu in MenuBar.
    public static func shouldShowDiagramMenu(for editor: Editor) -> Bool {
        shouldShowDiagramMenu(
            filePath: editor.buffer.filePath,
            lines: editor.buffer.lines,
            lineIndex: editor.buffer.lineIndex,
            allowsLogoExecution: editor.buffer.allowsLogoExecution
        )
    }
}
