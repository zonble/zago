import Foundation

extension DiagramSnippets {

    /// Detects if cursor is currently inside a code block (` ``` ` or ` ~~~ `).
    /// Returns `nil` if outside any code block, `""` if inside a generic code block without specified language,
    /// or the lowercased language tag (e.g. `"mermaid"`, `"puml"`, `"dot"`).
    public static func currentCodeBlockTag(lines: [String], lineIndex: Int) -> String? {
        let lineIdx = min(lineIndex, lines.count - 1)
        guard lineIdx >= 0 else { return nil }

        var currentBlockTag: String? = nil

        for i in 0...lineIdx {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
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
    public static func activeEngine(filePath: String?, lines: [String], lineIndex: Int) -> DiagramEngine? {
        let ext = (filePath as NSString?)?.pathExtension.lowercased() ?? ""
        if let engine = DiagramEngine.engine(forFileExtension: ext) {
            return engine
        }

        guard let tag = currentCodeBlockTag(lines: lines, lineIndex: lineIndex) else { return nil }
        return DiagramEngine.engine(forCodeBlockTag: tag)
    }

    /// Determines if the current buffer context warrants showing the Diagram menu in MenuBar.
    public static func shouldShowDiagramMenu(
        filePath: String?,
        lines: [String],
        lineIndex: Int,
        allowsLogoExecution: Bool
    ) -> Bool {
        guard allowsLogoExecution else { return false }
        let ext = (filePath as NSString?)?.pathExtension.lowercased() ?? ""
        if DiagramEngine.engine(forFileExtension: ext) != nil {
            return true
        }

        if let _ = currentCodeBlockTag(lines: lines, lineIndex: lineIndex) {
            return true
        }

        let rawLine = (lineIndex >= 0 && lineIndex < lines.count) ? lines[lineIndex] : ""
        let currentLine = rawLine.trimmingCharacters(in: CharacterSet.whitespaces)
        if currentLine.hasPrefix("```") || currentLine.hasPrefix("~~~") {
            return true
        }

        return false
    }
}
