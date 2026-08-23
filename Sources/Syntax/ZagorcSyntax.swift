import Foundation
import LogoEngine
import LogoLocalization

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
                    #"(?i)^\s*set\s+(wrap|fill|ruler|linenumbers|sublinenumbers|canvas-mode|syntax|smarttab|list-indent-size|list-wrap-indent|autoreload|ipc|trim-trailing-whitespace|nonewlines|git-diff|debug|regex|tab|tabsize|tabstospaces|lang|language|spell-language|spell-lang|border|arrow|keymap|modernbindings|max-file-size|large-file-threshold|max-line-highlight-length|backup|backupdir|launch-to-journal|journal-folder)\b"#
            ),
            NSRegularExpression(pattern: #"(?i)^\s*(bind|unbind|load|include)\s+"#),
            NSRegularExpression(pattern: #"(?i)^\s*(logo-script|logo-prelude|logo)\b"#),
            NSRegularExpression(pattern: #"^#!.*zago"#),
        ]) ?? []
    }

    private static let directivePattern =
        #"(?i)^\s*(set|unset|bind|unbind|load|include|logo|logo-prelude|logo-script|endlogo)\b"#

    private static let settingPattern =
        #"(?i)\b(wrap|fill|ruler|linenumbers|sublinenumbers|canvas-mode|syntax|smarttab|list-indent-size|list-wrap-indent|autoreload|ipc|trim-trailing-whitespace|nonewlines|git-diff|debug|regex|tab|tabsize|tabstospaces|lang|language|spell-language|spell-lang|border|arrow|keymap|modernbindings|max-file-size|large-file-threshold|max-line-highlight-length|backup|backupdir|launch-to-journal|journal-folder|dialect)\b"#

    private static let dialectPattern: String = {
        let names = LogoLocalizationRegistry.allDialects.flatMap { [$0.id] + $0.aliases }
        let alternatives = names
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        return "(?i)(?<![\\p{L}\\p{N}_-])(\(alternatives))(?![\\p{L}\\p{N}_-])"
    }()

    public var rules: [SyntaxRule] {
        [
            makeRule(#"^\s*(#|;|//).*$"#, .comment),
            makeRule(#""(?:[^"\n]|\\.)*"|'[^']*'|`[^`\n]*`"#, .string),
            makeRule(#"(?<!:)#.*$|;.*$|//.*$"#, .comment),
            makeRule(Self.directivePattern, .keyword),
            makeRule(Self.settingPattern, .typeOrAttribute),
            makeRule(Self.dialectPattern, .typeOrAttribute),
            makeRule(LogoSyntaxDefinition.keywordPattern, .keyword),
            makeRule(#":(#|[a-zA-Z0-9_]+)"#, .typeOrAttribute),
            makeRule(
                #"(?i)\b(true|false|on|off|none|single|double|triple-dash|round|ascii|heavy|solid|stemmed|hollow|small|classic|modern|vscode|cua|zh-TW|zh_TW|en|en_US)\b"#,
                .typeOrAttribute),
            makeRule(#"(?i)\b\d+(GB|MB|KB|k|b)?\b"#, .number),
        ].compactMap { $0 }
    }
}
