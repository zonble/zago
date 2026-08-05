import Foundation

public struct ReSTSyntaxDefinition: SyntaxDefinition {
    public let name = "reStructuredText"
    public let fileExtensions = ["rst", "rest"]
    public let supportsDocumentOutline = true
    public let supportsListAutoIndent = true

    public var rules: [SyntaxRule] {
        [
            // Section Titles / Underlines
            makeRule("^(=+|-+|~+|\\^+|\\*+|#+|\"+)\\s*$", .keyword),
            // Directives & Roles
            makeRule("^\\s*\\.\\.\\s+[a-zA-Z0-9_-]+::|:[a-zA-Z0-9_-]+:", .typeOrAttribute),
            // Inline Code / Literals
            makeRule("``[^`]+``|`[^`]+`", .string),
            // Comments
            makeRule("^\\s*\\.\\.\\s+.*$", .comment),
            // Links / Targets
            makeRule("`[^`]+`_|https?://[^\\s]+|\\[[^\\]]+\\]_", .typeOrAttribute),
            // Field lists / Bullet lists
            makeRule("^\\s*:[a-zA-Z0-9_-]+:|^\\s*[*+-]\\s+", .number),
        ].compactMap { $0 }
    }

    public func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String? {
        guard bufferLineIndex >= 0 && bufferLineIndex < lines.count else { return nil }
        var activeLangName: String? = nil
        var inBlock = false

        for i in 0...bufferLineIndex {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(".. code-block::") || trimmed.hasPrefix(".. code::")
                || trimmed.hasPrefix(".. highlight::")
            {
                inBlock = true
                if let range = trimmed.range(of: "::") {
                    let langStr = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    activeLangName = langStr.isEmpty ? "text" : langStr
                }
            } else if inBlock {
                if !trimmed.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !trimmed.hasPrefix("..") {
                    inBlock = false
                    activeLangName = nil
                }
            }
        }
        if inBlock, let langName = activeLangName {
            let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces)
            if currentLine.hasPrefix("..") {
                return nil
            }
            return langName
        }
        return nil
    }

    public func formatTable(at lineIndex: Int, in lines: [String], cursorColumn: Int) -> TableFormatResult? {
        PipeTableFormatter.formatTable(in: lines, at: lineIndex, cursorColumn: cursorColumn, style: .restGrid)
    }

    public func navigateTableCell(at lineIndex: Int, column: Int, in lines: [String], forward: Bool)
        -> TableNavigationResult?
    {
        PipeTableFormatter.navigateTableCell(
            in: lines, at: lineIndex, column: column, forward: forward, style: .restGrid)
    }

    public func documentOutline(in lines: [String]) -> DocumentOutline? {
        ReSTOutlineParser.parse(lines: lines)
    }
}
