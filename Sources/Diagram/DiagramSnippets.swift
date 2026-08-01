import Foundation

/// Central Diagram Snippet Manager handling snippet lookup.
public struct DiagramSnippets {
    /// Finds a diagram snippet matching a query string (e.g., "sequence", "flowchart", "digraph").
    public static func findDiagramSnippet(by query: String) -> (any DiagramSnippet)? {
        DiagramSnippetFactory.findSnippet(by: query)
    }
}
