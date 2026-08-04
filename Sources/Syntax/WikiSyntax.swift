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

    public func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String? {
        guard bufferLineIndex >= 0 && bufferLineIndex < lines.count else { return nil }
        var activeLangName: String? = nil
        var inBlock = false

        for i in 0...bufferLineIndex {
            let line = lines[i].trimmingCharacters(in: .whitespaces).lowercased()
            if line.contains("<syntaxhighlight") || line.contains("<source") || line.contains("<code") {
                inBlock = true
                if let langRange = line.range(of: "lang=\"") ?? line.range(of: "lang='") {
                    let rest = line[langRange.upperBound...]
                    if let quoteEnd = rest.firstIndex(where: { $0 == "\"" || $0 == "'" }) {
                        let langStr = String(rest[..<quoteEnd]).trimmingCharacters(in: .whitespaces)
                        activeLangName = langStr.isEmpty ? "text" : langStr
                    }
                } else {
                    activeLangName = "text"
                }
            }
            if line.contains("</syntaxhighlight>") || line.contains("</source>") || line.contains("</code>") {
                inBlock = false
                activeLangName = nil
            }
        }
        if inBlock, let langName = activeLangName {
            let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces).lowercased()
            if currentLine.contains("<syntaxhighlight") || currentLine.contains("<source")
                || currentLine.contains("<code") || currentLine.contains("</syntaxhighlight>")
                || currentLine.contains("</source>") || currentLine.contains("</code>")
            {
                return nil
            }
            return langName
        }
        return nil
    }
}
