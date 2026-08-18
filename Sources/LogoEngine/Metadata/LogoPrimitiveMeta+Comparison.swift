import Foundation

extension LogoPrimitive {
    var comparisonMeta: LogoPrimitiveMeta? {
        switch self {
        case .less:
            LogoPrimitiveMeta(
                name: "LESS?",
                description: "Tests whether a is strictly less than b (same as <).",
                localizedDescriptionKey: "logo.doc.less",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "a", required: true, description: "The a argument. Used by LESS.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "b", required: true, description: "The b argument. Used by LESS.", example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "LESS? 3 5", output: "true")]
            )

        case .greater:
            LogoPrimitiveMeta(
                name: "GREATER?",
                description: "Tests whether a is strictly greater than b (same as >).",
                localizedDescriptionKey: "logo.doc.greater",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "a", required: true, description: "The a argument. Used by GREATER.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "b", required: true, description: "The b argument. Used by GREATER.", example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "GREATER? 10 5", output: "true")]
            )

        case .lessOrEqual:
            LogoPrimitiveMeta(
                name: "LESSEQUAL?",
                description: "Tests whether a is less than or equal to b (same as <=).",
                localizedDescriptionKey: "logo.doc.lessequal",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "a", required: true, description: "The a argument. Used by LESSOREQUAL.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "b", required: true, description: "The b argument. Used by LESSOREQUAL.", example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "LESSEQUAL? 5 5", output: "true")]
            )

        case .greaterOrEqual:
            LogoPrimitiveMeta(
                name: "GREATEREQUAL?",
                description: "Tests whether a is greater than or equal to b (same as >=).",
                localizedDescriptionKey: "logo.doc.greaterequal",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "a", required: true, description: "The a argument. Used by GREATEROREQUAL.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "b", required: true, description: "The b argument. Used by GREATEROREQUAL.", example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "GREATEREQUAL? 10 5", output: "true")]
            )

        default: nil
        }
    }
}
