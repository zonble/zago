import Foundation

public struct DirectorySyntax {
    public static let syntax: LanguageSyntax = {
        var rules: [SyntaxRule] = []

        if let rule = SyntaxRule(patternStr: "^\" .*$", tokenType: .comment) {
            rules.append(rule)
        }
        if let rule = SyntaxRule(patternStr: "^\\.\\. \\(up a dir\\)$", tokenType: .keyword) {
            rules.append(rule)
        }
        if let rule = SyntaxRule(patternStr: "^▸ .*$", tokenType: .typeOrAttribute) {
            rules.append(rule)
        }
        if let rule = SyntaxRule(patternStr: "^  .*\\*$", tokenType: .string) {
            rules.append(rule)
        }

        return LanguageSyntax(name: "directory", extensions: [], rules: rules)
    }()
}
