import Foundation

public struct LogoSyntaxDefinition: SyntaxDefinition {
    public let name = "LOGO"
    public let fileExtensions = ["logo", "lg", ".serc"]

    public var rules: [SyntaxRule] {
        [
            // LOGO Keywords (Built-in commands, editor controls, turtle graphics, conditionals)
            makeRule("\\b(MAKE|VAR|SET|TYPE|PRINT|MSG|MESSAGE|SHOW|DEL|DELETE|BS|BACKSPACE|MOVE|MARK|CUT|PASTE|UNCUT|JUSTIFY|FIND|SEARCH|GOTO|BOX|LINE|HR|VLINE|VHR|NEWLINE|NL|ENTER|DATE|TIME|PD|PENDOWN|PU|PENUP|FD|FORWARD|BK|BACK|BACKWARD|RT|RIGHT|LT|LEFT|IF|IFELSE|REPEAT|TO|END|EXEC)\\b", .keyword),
            // Variables (:var_name)
            makeRule(":[a-zA-Z0-9_]+", .typeOrAttribute),
            // Strings in double or single quotes
            makeRule("\"[^\"]*\"|'[^']*'", .string),
            // Numbers
            makeRule("\\b\\d+\\b", .number),
            // Comments (# comment, ; comment, // comment)
            makeRule("#.*$|;.*$|//.*$", .comment)
        ].compactMap { $0 }
    }
}
