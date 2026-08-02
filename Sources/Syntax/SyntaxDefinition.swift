import Foundation

/// Protocol defining a language syntax specification template.
public protocol SyntaxDefinition: Sendable {
    var name: String { get }
    var fileExtensions: [String] { get }
    var rules: [SyntaxRule] { get }

    /// Polymorphic hook for markup languages to detect embedded code block language names.
    func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String?
}

extension SyntaxDefinition {
    public func makeRule(_ patternStr: String, _ tokenType: SyntaxTokenType) -> SyntaxRule? {
        SyntaxRule(patternStr: patternStr, tokenType: tokenType)
    }

    public func detectEmbeddedLanguageName(in lines: [String], bufferLineIndex: Int) -> String? {
        nil
    }

    public func buildLanguageSyntax() -> LanguageSyntax {
        LanguageSyntax(
            name: name,
            extensions: fileExtensions,
            rules: rules,
            embeddedLanguageDetector: { lines, index in
                self.detectEmbeddedLanguageName(in: lines, bufferLineIndex: index)
            }
        )
    }
}
