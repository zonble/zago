import Foundation

/// Protocol defining a language syntax specification template.
public protocol SyntaxDefinition {
    var name: String { get }
    var fileExtensions: [String] { get }
    var rules: [SyntaxRule] { get }
}

extension SyntaxDefinition {
    public func makeRule(_ patternStr: String, _ tokenType: SyntaxTokenType) -> SyntaxRule? {
        SyntaxRule(patternStr: patternStr, tokenType: tokenType)
    }

    public func buildLanguageSyntax() -> LanguageSyntax {
        LanguageSyntax(name: name, extensions: fileExtensions, rules: rules)
    }
}
