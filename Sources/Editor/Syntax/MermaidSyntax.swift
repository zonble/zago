import Foundation

public struct MermaidSyntaxDefinition: SyntaxDefinition {
    public let name = "Mermaid"
    public let fileExtensions = ["mmd", "mermaid"]

    public var rules: [SyntaxRule] {
        [
            makeRule("%%.*$", .comment),
            makeRule("\"[^\"]*\"", .string),
            makeRule("\\b(graph|flowchart|sequenceDiagram|gantt|classDiagram|stateDiagram|erDiagram|journey|pie|gitGraph|mindmap|quadrantChart|requirementDiagram|C4Context|subgraph|end|direction|TB|TD|BT|RL|LR|participant|actor|boundary|control|entity|database|collections|title|dateFormat|section)\\b", .keyword),
            makeRule("-->|---|\\.-\\->|==>|--\\||-->\\||->>|-->>|-x|--x|->|--", .typeOrAttribute),
            makeRule("\\b([0-9]+)\\b", .number)
        ].compactMap { $0 }
    }
}
