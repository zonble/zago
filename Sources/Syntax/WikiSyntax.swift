import Foundation

public struct WikiSyntaxDefinition: SyntaxDefinition {
    public let name = "Wiki"
    public let fileExtensions = ["wiki", "mediawiki"]

    public var rules: [SyntaxRule] {
        [
            makeRule("^==+.*==+$", .keyword),
            makeRule("</?(?:syntaxhighlight|source|code)[^>]*>", .keyword),
            makeRule("\\[\\[[^\\]\\n]+\\]\\]", .typeOrAttribute),
            makeRule("\\[https?://[^\\s\\]]+(?:\\s+[^\\]]+)?\\]", .typeOrAttribute),
            makeRule("'''[^'\\n]+'''|''[^'\\n]+''", .string),
            makeRule("\\{\\{[^\\}\\n]+\\}\\}" , .keyword),
            makeRule("<!--.*?-->", .comment),
            makeRule("\\b([0-9]+)\\b", .number),
        ].compactMap { $0 }
    }
}
