import Foundation

public struct DotSyntaxDefinition: SyntaxDefinition {
    public let name = "DOT"
    public let fileExtensions = ["dot", "gv"]

    public var rules: [SyntaxRule] {
        [
            makeRule("//.*$|#.*$", .comment),
            makeRule("\"[^\"]*\"", .string),
            makeRule("\\b(digraph|graph|subgraph|node|edge|strict|shape|label|color|fillcolor|style|fontname|fontsize|rankdir|dir|arrowhead|arrowtail|weight|width|height|penwidth|splines|overlap)\\b", .keyword),
            makeRule("->|--", .typeOrAttribute),
            makeRule("\\b([0-9]+)\\b", .number)
        ].compactMap { $0 }
    }
}
