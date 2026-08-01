import Foundation

extension DiagramSnippets {

    /// Detects if cursor is currently inside a code block (` ``` ` or ` ~~~ `).
    /// Returns `nil` if outside any code block, `""` if inside a generic code block without specified language,
    /// or the lowercased language tag (e.g. `"mermaid"`, `"puml"`, `"dot"`).
    public static func currentCodeBlockTag(editor: Editor) -> String? {
        let lineIdx = min(editor.buffer.lineIndex, editor.buffer.lines.count - 1)
        guard lineIdx >= 0 else { return nil }

        var currentBlockTag: String? = nil

        for i in 0...lineIdx {
            let line = editor.buffer.lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                if currentBlockTag == nil {
                    let tag = line.dropFirst(3).trimmingCharacters(in: .whitespaces).lowercased()
                    currentBlockTag = tag
                } else {
                    currentBlockTag = nil
                }
            }
        }

        return currentBlockTag
    }

    /// Determines active diagram engine context based on file extension and code block position.
    public static func activeEngine(for editor: Editor) -> DiagramEngine? {
        let ext = (editor.buffer.filePath as NSString?)?.pathExtension.lowercased() ?? ""
        if let engine = DiagramEngine.engine(forFileExtension: ext) {
            return engine
        }

        guard let tag = currentCodeBlockTag(editor: editor) else { return nil }
        return DiagramEngine.engine(forCodeBlockTag: tag)
    }

    /// Determines if the current buffer context warrants showing the Diagram menu in MenuBar.
    public static func shouldShowDiagramMenu(for editor: Editor) -> Bool {
        guard editor.buffer.allowsLogoExecution else { return false }
        let ext = (editor.buffer.filePath as NSString?)?.pathExtension.lowercased() ?? ""
        if DiagramEngine.engine(forFileExtension: ext) != nil {
            return true
        }

        if let _ = currentCodeBlockTag(editor: editor) {
            return true
        }

        let rawLine = (editor.buffer.lineIndex >= 0 && editor.buffer.lineIndex < editor.buffer.lines.count) ? editor.buffer.lines[editor.buffer.lineIndex] : ""
        let currentLine = rawLine.trimmingCharacters(in: CharacterSet.whitespaces)
        if currentLine.hasPrefix("```") || currentLine.hasPrefix("~~~") {
            return true
        }

        return false
    }

    /// Legacy alias helper for backward compatibility.
    public static func detectCodeBlockEngine(editor: Editor) -> DiagramEngine? {
        activeEngine(for: editor)
    }
}
