import Foundation

public struct CodeBlockPlainTextSyntaxDefinition: SyntaxDefinition {
    public let name = "CodeBlockPlainText"
    public let fileExtensions: [String] = []

    public init() {}

    public var rules: [SyntaxRule] {
        [
            makeRule("^.*$", .typeOrAttribute)
        ].compactMap { $0 }
    }
}
