import Foundation

public struct MarkdownSyntaxDefinition: SyntaxDefinition {
    public let name = "Markdown"
    public let fileExtensions = ["md", "markdown", "mdown", "mkd"]

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
            makeRule("(\\*\\*|__)[^*_]+(\\*\\*|__)", .string),
            makeRule("\\*[^*]+\\*|_[^_]+_", .string),
            makeRule("~~[^~]+~~", .string),

            // Blockquotes, task lists, ordered/unordered lists, and tables
            makeRule("^\\s*>.*$", .number),
            makeRule("^\\s*[*+-]\\s+\\[[ xX]\\]\\s+", .typeOrAttribute),
            makeRule("^\\s*(\\d+\\.|[*+-])\\s+", .number),
            makeRule("^\\s*\\|?\\s*:?-{3,}:?\\s*(\\|\\s*:?-{3,}:?\\s*)+\\|?\\s*$", .keyword),
            makeRule("^\\s*\\|.*\\|\\s*$", .typeOrAttribute),
            makeRule("^\\s*[^|\\s][^|]*\\|[^|]+(\\|[^|]+)*\\s*$", .typeOrAttribute),
        ].compactMap { $0 }
    }
}
