import Foundation

public struct MarkdownSyntaxDefinition: SyntaxDefinition {
    public let name = "Markdown"
    public let fileExtensions = ["md", "markdown", "mdown", "mkd"]
    public let supportsDocumentOutline = true

    public var rules: [SyntaxRule] {
        [
            // Front matter delimiters and fenced code blocks
            makeRule("^\\s*(---|\\.\\.\\.)\\s*$", .keyword),
            makeRule("^\\s*(```+|~~~+).*$", .typeOrAttribute),

            // Headings
            makeRule("^#{1,6}\\s+.*$", .keyword),
            makeRule("^\\s*(=+|-+)\\s*$", .keyword),

            // HTML comments and Markdown reference definitions
            makeRule("<!--.*-->", .comment),
            makeRule("^\\s*\\[[^\\]]+\\]:\\s+\\S+.*$", .typeOrAttribute),
            makeRule("^\\s*\\[\\^[^\\]]+\\]:.*$", .typeOrAttribute),

            // Inline code, links, images, and automatic URLs
            makeRule("`[^`]+`", .string),
            makeRule("!?\\[[^\\]]+\\]\\([^\\)]+\\)", .typeOrAttribute),
            makeRule("\\[\\^[^\\]]+\\]|https?://[^\\s<>]+|<https?://[^>]+>", .typeOrAttribute),

            // Emphasis and strikethrough
            makeRule("(\\*\\*|__)[^*`|\\n_]+(\\*\\*|__)", .string),
            makeRule("\\*[^*`|\\n]+\\*|_[^_`|\\n]+_", .string),
            makeRule("~~[^~`|\\n]+~~", .string),

            // Blockquotes, task lists, ordered/unordered lists, and tables
            makeRule("^\\s*>.*$", .number),
            makeRule("^\\s*[*+-]\\s+\\[[ xX]\\]\\s+", .typeOrAttribute),
            makeRule("^\\s*(\\d+\\.|[*+-])\\s+", .number),
            makeRule("^\\s*\\|?\\s*:?-{3,}:?\\s*(\\|\\s*:?-{3,}:?\\s*)+\\|?\\s*$", .keyword),
            makeRule("^\\s*\\|.*\\|\\s*$", .typeOrAttribute),
            makeRule("^\\s*(?!(\\d+\\.|[*+-])\\s+)[^|\\s][^|]*\\|[^|]+(\\|[^|]+)*\\s*$", .typeOrAttribute),
        ].compactMap { $0 }
    }

    public func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String? {
        guard bufferLineIndex >= 0 && bufferLineIndex < lines.count else { return nil }
        var activeLangName: String? = nil
        var inBlock = false

        for i in 0...bufferLineIndex {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                if inBlock {
                    inBlock = false
                    activeLangName = nil
                } else {
                    inBlock = true
                    let langStr = String(line.drop(while: { $0 == "`" || $0 == "~" })).trimmingCharacters(
                        in: .whitespaces)
                    activeLangName = langStr.isEmpty ? "text" : langStr
                }
            }
        }
        if inBlock, let langName = activeLangName {
            let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces)
            if currentLine.hasPrefix("```") || currentLine.hasPrefix("~~~") {
                return nil
            }
            return langName
        }
        return nil
    }

    public func formatTable(at lineIndex: Int, in lines: [String], cursorColumn: Int) -> TableFormatResult? {
        PipeTableFormatter.formatTable(in: lines, at: lineIndex, cursorColumn: cursorColumn, style: .markdown)
    }

    public func navigateTableCell(at lineIndex: Int, column: Int, in lines: [String], forward: Bool) -> TableNavigationResult? {
        PipeTableFormatter.navigateTableCell(in: lines, at: lineIndex, column: column, forward: forward, style: .markdown)
    }

    public func documentOutline(in lines: [String]) -> DocumentOutline? {
        MarkdownOutlineParser.parse(lines: lines)
    }
}
