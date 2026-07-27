import Foundation

public struct JSONSyntaxDefinition: SyntaxDefinition {
    public let name = "JSON"
    public let fileExtensions = ["json"]

    public var rules: [SyntaxRule] {
        [
            makeRule("\"[^\"]*\"(?=\\s*:)", .keyword),
            makeRule(":\\s*\"[^\"]*\"", .string),
            makeRule("\\b(true|false|null|[0-9]+(\\.[0-9]+)?)\\b", .number)
        ].compactMap { $0 }
    }
}
