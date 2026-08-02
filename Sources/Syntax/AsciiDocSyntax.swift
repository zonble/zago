import Foundation

public struct AsciiDocSyntaxDefinition: SyntaxDefinition {
    public let name = "AsciiDoc"
    public let fileExtensions = ["adoc", "asciidoc", "ascii"]

    public var rules: [SyntaxRule] {
        [
            makeRule("^=+\\s+.*$", .keyword),
            makeRule("\\[source,\\s*[A-Za-z0-9_+-]+\\]", .keyword),
            makeRule("^----+|^====+|^\\.\\.\\.\\.+|^\\|===+", .comment),
            makeRule("\\b(NOTE|TIP|IMPORTANT|WARNING|CAUTION):", .typeOrAttribute),
            makeRule("^//.*$", .comment),
            makeRule("\\*[^*\\n]+\\*|_[^_\\n]+_|`[^`\\n]+`", .string),
            makeRule("\\b([0-9]+)\\b", .number),
        ].compactMap { $0 }
    }

    public func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String? {
        guard bufferLineIndex >= 0 && bufferLineIndex < lines.count else { return nil }
        var activeLangName: String? = nil
        var inBlock = false

        for i in 0...bufferLineIndex {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[source") && line.contains("]") {
                if let start = line.firstIndex(of: ","), let end = line.firstIndex(of: "]"), start < end {
                    let langStr = String(line[line.index(after: start)..<end]).trimmingCharacters(in: .whitespaces)
                    activeLangName = langStr.isEmpty ? nil : langStr
                }
            } else if line.hasPrefix("----") || line.hasPrefix("....") {
                if inBlock {
                    inBlock = false
                    activeLangName = nil
                } else if activeLangName != nil {
                    inBlock = true
                }
            }
        }
        if inBlock, let langName = activeLangName {
            let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces)
            if currentLine.hasPrefix("----") || currentLine.hasPrefix("....") || currentLine.hasPrefix("[source") {
                return nil
            }
            return langName
        }
        return nil
    }

    public func formatTable(at lineIndex: Int, in lines: [String], cursorColumn: Int) -> TableFormatResult? {
        PipeTableFormatter.formatTable(in: lines, at: lineIndex, cursorColumn: cursorColumn, style: .asciiDoc)
    }

    public func navigateTableCell(at lineIndex: Int, column: Int, in lines: [String], forward: Bool) -> TableNavigationResult? {
        PipeTableFormatter.navigateTableCell(in: lines, at: lineIndex, column: column, forward: forward, style: .asciiDoc)
    }
}
