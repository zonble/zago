import Foundation

/// Protocol defining a self-contained diagram snippet.
public protocol DiagramSnippet: Sendable {
    var engine: DiagramEngine { get }
    var titleKey: String { get }
    var hotkeyChar: Character { get }
    var keywords: [String] { get }
    var codeBlockTag: String { get }
    var templateText: String { get }
}

extension DiagramSnippet {
    public var codeBlockTag: String {
        engine.defaultCodeBlockTag
    }
}
