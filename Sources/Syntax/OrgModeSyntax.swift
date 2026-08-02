import Foundation

public struct OrgModeSyntaxDefinition: SyntaxDefinition {
    public let name = "Org-mode"
    public let fileExtensions = ["org"]

    public var rules: [SyntaxRule] {
        [
            // Headlines (* Heading)
            makeRule("^\\s*\\*+\\s+.*$", .keyword),
            // TODO Keywords
            makeRule("\\b(TODO|NEXT|DONE|WAITING|CANCELLED|HOLD|PHONE|MEETING)\\b", .keyword),
            // Header / Block Directives (#+TITLE:, #+BEGIN_SRC, #+END_SRC)
            makeRule("^\\s*#\\+[A-Za-z0-9_]+.*$", .typeOrAttribute),
            // Comments
            makeRule("^\\s*#\\s+.*$|^\\s*#$", .comment),
            // Links [[link][description]]
            makeRule("\\[\\[[^\\]]+\\](\\[[^\\]]+\\])?\\]", .typeOrAttribute),
            // Code & Timestamps (~code~, =verbatim=, <2026-07-28 Tue>)
            makeRule("~[^~]+~|=[^=]+=|\\<[^\\>]+\\>|\\[[^\\]]+\\]", .string),
        ].compactMap { $0 }
    }

    public func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String? {
        guard bufferLineIndex >= 0 && bufferLineIndex < lines.count else { return nil }
        var activeLangName: String? = nil
        var inBlock = false

        for i in 0...bufferLineIndex {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            let upper = line.uppercased()
            if upper.hasPrefix("#+BEGIN_SRC") {
                inBlock = true
                let langStr = String(line.dropFirst("#+BEGIN_SRC".count)).trimmingCharacters(in: .whitespaces)
                activeLangName = langStr.isEmpty ? nil : langStr
            } else if upper.hasPrefix("#+END_SRC") {
                inBlock = false
                activeLangName = nil
            }
        }
        if inBlock, let langName = activeLangName {
            let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces).uppercased()
            if currentLine.hasPrefix("#+BEGIN_SRC") || currentLine.hasPrefix("#+END_SRC") {
                return nil
            }
            return langName
        }
        return nil
    }
}
