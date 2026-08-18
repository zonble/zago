import Foundation
import LogoEngine

/// Syntax definition for zago configuration files.
///
/// Zagorc embeds Editor LOGO, but its top-level directives have a separate
/// vocabulary that should remain visible while editing configuration.
public struct ZagorcSyntaxDefinition: SyntaxDefinition {
    public let name = "Zagorc"
    public let fileExtensions = ["zagorc", ".zagorc"]
    public var commentPrefix: String { "# " }

    public var headerRules: [NSRegularExpression] {
        (try? [
            NSRegularExpression(
                pattern:
                    #"(?i)^\s*set\s+(wrap|ruler|linenumbers|sublinenumbers|canvas-mode|syntax|smarttab|list-indent-size|list-wrap-indent|autoreload|ipc|trim-trailing-whitespace|tab|lang|language|spell-language|border|arrow|git-diff|debug|regex)\b"#
            ),
            NSRegularExpression(pattern: #"(?i)^\s*(bind|unbind)\s+"#),
            NSRegularExpression(pattern: #"(?i)^\s*(logo-script|logo-prelude|logo)\b"#),
            NSRegularExpression(pattern: #"^#!.*zago"#),
        ]) ?? []
    }

    private static let directivePattern =
        #"(?i)^\s*(set|unset|bind|unbind|logo|logo-prelude|logo-script|endlogo)\b"#

    private static let settingPattern =
        #"(?i)\b(wrap|ruler|linenumbers|sublinenumbers|canvas-mode|syntax|smarttab|list-indent-size|list-wrap-indent|autoreload|ipc|trim-trailing-whitespace|tab|lang|language|spell-language|border|arrow|git-diff|debug|regex)\b"#

    public var rules: [SyntaxRule] {
        [
            makeRule(#"^\s*(#|;|//).*$"#, .comment),
            makeRule(#""(?:[^"\n]|\\.)*"|'[^']*'|`[^`\n]*`"#, .string),
            makeRule(#"(?<!:)#.*$|;.*$|//.*$"#, .comment),
            makeRule(Self.directivePattern, .keyword),
            makeRule(Self.settingPattern, .typeOrAttribute),
            makeRule(LogoSyntaxDefinition.keywordPattern, .keyword),
            makeRule(#":(#|[a-zA-Z0-9_]+)"#, .typeOrAttribute),
            makeRule(
                #"\b(true|false|on|off|none|single|double|round|ascii|solid|stemmed|hollow|small)\b"#, .typeOrAttribute),
            makeRule(#"\b\d+\b"#, .number),
        ].compactMap { $0 }
    }
}
