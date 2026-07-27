import Foundation

public struct CSyntaxDefinition: SyntaxDefinition {
    public let name = "C/C++"
    public let fileExtensions = ["c", "cpp", "cc", "h", "hpp"]

    public var rules: [SyntaxRule] {
        [
            makeRule("//.*$", .comment),
            makeRule("\"[^\"]*\"|'[^']*'", .string),
            makeRule("#include|#define|#ifdef|#ifndef|#endif|#pragma", .typeOrAttribute),
            makeRule("\\b(int|char|float|double|void|long|short|unsigned|signed|struct|union|enum|typedef|auto|register|extern|static|volatile|const|if|else|switch|case|default|while|do|for|break|continue|return|goto|sizeof)\\b", .keyword),
            makeRule("\\b(NULL|true|false|[0-9]+)\\b", .number)
        ].compactMap { $0 }
    }
}
