import Foundation

/// Graphviz (DOT) Directed Graph snippet.
public struct DOTDigraphSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .dot }
    public var titleKey: String { "menu.diagrams.dot_digraph" }
    public var hotkeyChar: Character { "g" }
    public var keywords: [String] { ["dot_digraph", "digraph", "dot"] }
    public var templateText: String {
        """
        digraph G {
            rankdir=LR;
            node [shape=box];
            A -> B;
            B -> C;
        }
        """
    }
}

/// Graphviz (DOT) Undirected Graph snippet.
public struct DOTGraphSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .dot }
    public var titleKey: String { "menu.diagrams.dot_graph" }
    public var hotkeyChar: Character { "u" }
    public var keywords: [String] { ["dot_graph", "graph"] }
    public var templateText: String {
        """
        graph G {
            node [shape=circle];
            A -- B;
            B -- C;
        }
        """
    }
}
