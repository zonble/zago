import Foundation

/// Factory managing registration and retrieval of all `DiagramSnippet` instances.
public struct DiagramSnippetFactory {

    /// List of all available snippet instances.
    public static let allSnippets: [any DiagramSnippet] = [
        // Mermaid
        MermaidSequenceSnippet(),
        MermaidFlowchartSnippet(),
        MermaidClassSnippet(),
        MermaidStateSnippet(),
        MermaidERSnippet(),
        MermaidMindmapSnippet(),

        // PlantUML
        PlantUMLSequenceSnippet(),
        PlantUMLFlowchartSnippet(),
        PlantUMLClassSnippet(),
        PlantUMLStateSnippet(),
        PlantUMLERSnippet(),

        // Graphviz (DOT)
        DOTDigraphSnippet(),
        DOTGraphSnippet()
    ]

    /// Returns all snippet instances for a specified diagram engine.
    public static func snippets(for engine: DiagramEngine) -> [any DiagramSnippet] {
        allSnippets.filter { $0.engine == engine }
    }

    /// Finds a diagram snippet matching a query string or keyword.
    public static func findSnippet(by query: String) -> (any DiagramSnippet)? {
        let q = query.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "\" \t\n\r"))
        if q.isEmpty { return nil }

        // Exact keyword match
        for snippet in allSnippets {
            if snippet.keywords.contains(where: { $0.lowercased() == q }) {
                return snippet
            }
        }

        // TitleKey suffix match (e.g. "mermaid_sequence", "puml_sequence")
        for snippet in allSnippets {
            let keySuffix = snippet.titleKey.replacingOccurrences(of: "menu.diagrams.", with: "").lowercased()
            if keySuffix == q || keySuffix.replacingOccurrences(of: "_", with: "") == q {
                return snippet
            }
        }

        // Substring / partial keyword match
        for snippet in allSnippets {
            if snippet.keywords.contains(where: { $0.lowercased().contains(q) }) {
                return snippet
            }
        }

        return nil
    }
}
