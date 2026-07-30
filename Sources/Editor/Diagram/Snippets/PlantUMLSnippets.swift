import Foundation

/// PlantUML Sequence Diagram snippet.
public struct PlantUMLSequenceSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .plantuml }
    public var titleKey: String { "menu.diagrams.puml_sequence" }
    public var hotkeyChar: Character { "q" }
    public var keywords: [String] { ["puml_sequence", "puml_seq", "pumlsequence"] }
    public var templateText: String {
        """
        @startuml
        autonumber
        actor User
        participant "System" as System
        User -> System: Request Data
        System --> User: Response Data
        @enduml
        """
    }
}

/// PlantUML Flowchart / Activity Diagram snippet.
public struct PlantUMLFlowchartSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .plantuml }
    public var titleKey: String { "menu.diagrams.puml_flowchart" }
    public var hotkeyChar: Character { "l" }
    public var keywords: [String] { ["puml_flowchart", "puml_flow", "pumlflowchart"] }
    public var templateText: String {
        """
        @startuml
        start
        if (Condition?) then (yes)
          :Process A;
        else (no)
          :Process B;
        endif
        stop
        @enduml
        """
    }
}

/// PlantUML Class Diagram snippet.
public struct PlantUMLClassSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .plantuml }
    public var titleKey: String { "menu.diagrams.puml_class" }
    public var hotkeyChar: Character { "k" }
    public var keywords: [String] { ["puml_class", "pumlclass"] }
    public var templateText: String {
        """
        @startuml
        class User {
          +id: Int
          +name: String
          +login()
        }
        @enduml
        """
    }
}

/// PlantUML State Diagram snippet.
public struct PlantUMLStateSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .plantuml }
    public var titleKey: String { "menu.diagrams.puml_state" }
    public var hotkeyChar: Character { "t" }
    public var keywords: [String] { ["puml_state", "pumlstate"] }
    public var templateText: String {
        """
        @startuml
        [*] -> State1
        State1 -> State2 : Event
        State2 -> [*]
        @enduml
        """
    }
}

/// PlantUML Entity Relationship Diagram snippet.
public struct PlantUMLERSnippet: DiagramSnippet {
    public init() {}
    public var engine: DiagramEngine { .plantuml }
    public var titleKey: String { "menu.diagrams.puml_er" }
    public var hotkeyChar: Character { "r" }
    public var keywords: [String] { ["puml_er", "pumler"] }
    public var templateText: String {
        """
        @startuml
        entity Customer {
          *id : number
          --
          name : text
        }
        entity Order {
          *id : number
          --
          customer_id : number
        }
        Customer ||--o{ Order
        @enduml
        """
    }
}
