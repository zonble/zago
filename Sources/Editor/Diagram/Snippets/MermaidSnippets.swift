import Foundation

/// Mermaid Sequence Diagram snippet.
public struct MermaidSequenceSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .mermaid }
    public var titleKey: String { "menu.diagrams.mermaid_sequence" }
    public var hotkeyChar: Character { "s" }
    public var keywords: [String] { ["mermaid_sequence", "sequence", "seq"] }
    public var templateText: String {
        """
        sequenceDiagram
            autonumber
            actor Alice
            actor Bob
            Alice->>Bob: Hello Bob, how are you?
            Bob-->>Alice: Fine, thank you!
        """
    }
}

/// Mermaid Flowchart snippet.
public struct MermaidFlowchartSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .mermaid }
    public var titleKey: String { "menu.diagrams.mermaid_flowchart" }
    public var hotkeyChar: Character { "f" }
    public var keywords: [String] { ["mermaid_flowchart", "flowchart", "flow"] }
    public var templateText: String {
        """
        flowchart TD
            A[Start] --> B{Is it?}
            B -- Yes --> C[OK]
            B -- No --> D[Cancel]
        """
    }
}

/// Mermaid Class Diagram snippet.
public struct MermaidClassSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .mermaid }
    public var titleKey: String { "menu.diagrams.mermaid_class" }
    public var hotkeyChar: Character { "c" }
    public var keywords: [String] { ["mermaid_class", "class"] }
    public var templateText: String {
        """
        classDiagram
            class Animal {
                +String name
                +makeSound()
            }
            class Dog {
                +bark()
            }
            Animal <|-- Dog
        """
    }
}

/// Mermaid State Diagram snippet.
public struct MermaidStateSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .mermaid }
    public var titleKey: String { "menu.diagrams.mermaid_state" }
    public var hotkeyChar: Character { "a" }
    public var keywords: [String] { ["mermaid_state", "state"] }
    public var templateText: String {
        """
        stateDiagram-v2
            [*] --> Idle
            Idle --> Processing : Event
            Processing --> Idle : Done
        """
    }
}

/// Mermaid Entity Relationship Diagram snippet.
public struct MermaidERSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .mermaid }
    public var titleKey: String { "menu.diagrams.mermaid_er" }
    public var hotkeyChar: Character { "e" }
    public var keywords: [String] { ["mermaid_er", "er"] }
    public var templateText: String {
        """
        erDiagram
            CUSTOMER ||--o{ ORDER : places
            ORDER ||--|{ LINE-ITEM : contains
        """
    }
}

/// Mermaid Mindmap snippet.
public struct MermaidMindmapSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .mermaid }
    public var titleKey: String { "menu.diagrams.mermaid_mindmap" }
    public var hotkeyChar: Character { "m" }
    public var keywords: [String] { ["mermaid_mindmap", "mindmap", "mind"] }
    public var templateText: String {
        """
        mindmap
          root((Main Topic))
            Topic 1
              Subtopic A
              Subtopic B
            Topic 2
        """
    }
}
