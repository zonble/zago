import Foundation

/// Result of table formatting operation.
public struct TableFormatResult: Sendable {
    public let updatedLines: [String]
    public let startLineIndex: Int
    public let newCursorColumn: Int

    public init(updatedLines: [String], startLineIndex: Int, newCursorColumn: Int) {
        self.updatedLines = updatedLines
        self.startLineIndex = startLineIndex
        self.newCursorColumn = newCursorColumn
    }
}

/// Result of table cell navigation operation.
public struct TableNavigationResult: Sendable {
    public let newBufferLineIndex: Int
    public let newCursorColumn: Int
    public let updatedLines: [String]?

    public init(newBufferLineIndex: Int, newCursorColumn: Int, updatedLines: [String]? = nil) {
        self.newBufferLineIndex = newBufferLineIndex
        self.newCursorColumn = newCursorColumn
        self.updatedLines = updatedLines
    }
}

/// Protocol defining a language syntax specification template.
public protocol SyntaxDefinition: Sendable {
    var name: String { get }
    var fileExtensions: [String] { get }
    var rules: [SyntaxRule] { get }

    /// Polymorphic hook for markup languages to detect embedded code block language names.
    func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String?

    /// Polymorphic hook for markup languages to format and align text tables.
    func formatTable(at lineIndex: Int, in lines: [String], cursorColumn: Int) -> TableFormatResult?

    /// Polymorphic hook for markup languages to navigate between table cells (Tab / Shift+Tab).
    func navigateTableCell(at lineIndex: Int, column: Int, in lines: [String], forward: Bool) -> TableNavigationResult?
}

extension SyntaxDefinition {
    public func makeRule(_ patternStr: String, _ tokenType: SyntaxTokenType) -> SyntaxRule? {
        SyntaxRule(patternStr: patternStr, tokenType: tokenType)
    }

    public func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String? {
        nil
    }

    public func formatTable(at lineIndex: Int, in lines: [String], cursorColumn: Int) -> TableFormatResult? {
        nil
    }

    public func navigateTableCell(at lineIndex: Int, column: Int, in lines: [String], forward: Bool) -> TableNavigationResult? {
        nil
    }

    public func buildLanguageSyntax() -> LanguageSyntax {
        LanguageSyntax(
            name: name,
            extensions: fileExtensions,
            rules: rules,
            embeddedLanguageDetector: { lines, index in
                self.detectEmbeddedLanguageName(in: lines, bufferLineIndex: index)
            },
            tableFormatter: { lines, index, col in
                self.formatTable(at: index, in: lines, cursorColumn: col)
            },
            tableNavigator: { lines, index, col, fwd in
                self.navigateTableCell(at: index, column: col, in: lines, forward: fwd)
            }
        )
    }
}
