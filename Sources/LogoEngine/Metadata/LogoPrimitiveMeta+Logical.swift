import Foundation

extension LogoPrimitive {
    var logicalMeta: LogoPrimitiveMeta? {
        switch self {
        case .trueVal:
            LogoPrimitiveMeta(
                name: "TRUE",
                description: "Boolean literal true (evaluates to \"true\").",
                localizedDescriptionKey: "logo.doc.true",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "TRUE", output: "true")]
            )

        case .falseVal:
            LogoPrimitiveMeta(
                name: "FALSE",
                description: "Boolean literal false (evaluates to \"false\").",
                localizedDescriptionKey: "logo.doc.false",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "FALSE", output: "false")]
            )

        case .andLogic:
            LogoPrimitiveMeta(
                name: "AND",
                description: "Logical AND operation across multiple conditions.",
                localizedDescriptionKey: "logo.doc.and",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "cond1", required: true),
                    LogoPrimitiveParameter(name: "cond2", required: true),
                    LogoPrimitiveParameter(name: "...", required: false),
                ],
                examples: [LogoPrimitiveExample(input: "AND (:x > 0) (:y > 0)")]
            )

        case .orLogic:
            LogoPrimitiveMeta(
                name: "OR",
                description: "Logical OR operation across multiple conditions.",
                localizedDescriptionKey: "logo.doc.or",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "cond1", required: true),
                    LogoPrimitiveParameter(name: "cond2", required: true),
                    LogoPrimitiveParameter(name: "...", required: false),
                ],
                examples: [LogoPrimitiveExample(input: "OR (:a = 1) (:b = 1)")]
            )

        case .xorLogic:
            LogoPrimitiveMeta(
                name: "XOR",
                description: "Logical exclusive-OR operation on two boolean conditions.",
                localizedDescriptionKey: "logo.doc.xor",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true),
                ],
                examples: [LogoPrimitiveExample(input: "XOR TRUE FALSE", output: "true")]
            )

        case .notLogic:
            LogoPrimitiveMeta(
                name: "NOT",
                description: "Logical negation of condition.",
                localizedDescriptionKey: "logo.doc.not",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "condition", required: true)],
                examples: [LogoPrimitiveExample(input: "NOT :ready")]
            )

        default: nil
        }
    }
}
