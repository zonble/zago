import Foundation

public enum LogoPrimitiveMetaSource: Sendable, Equatable {
    case ucbLogo
    case zago
}

public struct LogoPrimitiveParameter: Sendable, Equatable {
    public let name: String
    public let required: Bool
    public let example: String?
    public let allowedValues: [String]

    public init(name: String, required: Bool, example: String? = nil, allowedValues: [String] = []) {
        self.name = name
        self.required = required
        self.example = example
        self.allowedValues = allowedValues
    }
}

public struct LogoPrimitiveExample: Sendable, Equatable {
    public let input: String
    public let output: String

    public init(input: String, output: String = "") {
        self.input = input
        self.output = output
    }
}

public struct LogoPrimitiveMeta: Sendable, Equatable {
    public let name: String
    public let description: String
    public let localizedDescriptionKey: String
    public let source: LogoPrimitiveMetaSource
    public let parameters: [LogoPrimitiveParameter]?
    public let examples: [LogoPrimitiveExample]?
    public let notes: String?

    public init(
        name: String,
        description: String,
        localizedDescriptionKey: String,
        source: LogoPrimitiveMetaSource,
        parameters: [LogoPrimitiveParameter]? = nil,
        examples: [LogoPrimitiveExample]? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.description = description
        self.localizedDescriptionKey = localizedDescriptionKey
        self.source = source
        self.parameters = parameters
        self.examples = examples
        self.notes = notes
    }
}

extension LogoPrimitive {
    public var meta: LogoPrimitiveMeta {
        if let meta = statementMeta { return meta }
        if let meta = bufferMeta { return meta }
        if let meta = dataMeta { return meta }
        if let meta = stringMeta { return meta }
        if let meta = comparisonMeta { return meta }
        if let meta = logicalMeta { return meta }
        if let meta = mathMeta { return meta }
        preconditionFailure("Missing metadata for \(self)")
    }
}
