import Foundation

/// Supported diagram rendering engines.
public enum DiagramEngine: String, CaseIterable, Sendable {
    case mermaid = "Mermaid"
    case plantuml = "PlantUML"
    case dot = "DOT"

    /// File extensions associated with this diagram engine.
    public var fileExtensions: [String] {
        switch self {
        case .mermaid: return ["mermaid", "mmd"]
        case .plantuml: return ["puml", "plantuml", "iuml"]
        case .dot: return ["dot", "gv"]
        }
    }

    /// Code block tags associated with this diagram engine. Primary tag is the first element.
    public var codeBlockTags: [String] {
        switch self {
        case .mermaid: return ["mermaid", "mmd"]
        case .plantuml: return ["puml", "plantuml", "iuml"]
        case .dot: return ["dot", "graphviz", "gv"]
        }
    }

    /// Primary code block tag for markdown snippet wrapping (e.g. "mermaid", "puml", "dot").
    public var defaultCodeBlockTag: String {
        codeBlockTags.first ?? rawValue.lowercased()
    }

    /// Finds the matching `DiagramEngine` for a given file extension.
    public static func engine(forFileExtension ext: String) -> DiagramEngine? {
        let e = ext.lowercased()
        return allCases.first { $0.fileExtensions.contains(e) }
    }

    /// Finds the matching `DiagramEngine` for a given code block tag.
    public static func engine(forCodeBlockTag tag: String) -> DiagramEngine? {
        let t = tag.lowercased()
        return allCases.first { $0.codeBlockTags.contains(t) }
    }
}
