import Foundation

public struct VhsSyntaxDefinition: SyntaxDefinition {
    public let name = "VHS"
    public let fileExtensions = ["tape", "vhs"]

    public var rules: [SyntaxRule] {
        [
            // Quoted Type/Paste text can contain #, so strings must win before comments.
            makeRule(#""(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`"#, .string),
            makeRule(#"/(?:\\.|[^/\r\n\\])*/"#, .string),
            makeRule(#"#.*$"#, .comment),
            makeRule(
                #"(?i)\b[0-9]+(?:\.[0-9]+)?\s*(?:ms|s|m|px|em|%)?\b"#,
                .number),
            makeRule(#"\b(true|false)\b"#, .typeOrAttribute),
            makeRule(
                #"\b(Shell|FontFamily|FontSize|Framerate|PlaybackSpeed|Height|Width|LetterSpacing|LineHeight|TypingSpeed|Padding|Theme|LoopOffset|MarginFill|Margin|WindowBar|WindowBarSize|BorderRadius|CornerRadius|WaitTimeout|WaitPattern|CursorBlink)\b"#,
                .typeOrAttribute),
            makeRule(
                #"\b(Output|Require|Set|Type|Sleep|Enter|Space|Backspace|Delete|Insert|Ctrl|Alt|Shift|Down|Left|Right|Up|PageUp|PageDown|ScrollUp|ScrollDown|Tab|Escape|Esc|End|Home|Hide|Show|Source|Screenshot|Copy|Paste|Wait|WaitScreen|WaitLine|WaitScreenLine|Env)\b"#,
                .keyword),
            makeRule(#"[\[\]\+\=@]"#, .typeOrAttribute),
        ].compactMap { $0 }
    }
}
