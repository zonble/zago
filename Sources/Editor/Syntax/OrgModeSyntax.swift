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
            makeRule("~[^~]+~|=[^=]+=|\\<[^\\>]+\\>|\\[[^\\]]+\\]", .string)
        ].compactMap { $0 }
    }
}
