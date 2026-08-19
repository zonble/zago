import Foundation

extension LogoPrimitive {
    var statementMeta: LogoPrimitiveMeta? {
        return switch self {
        case .make:
            LogoPrimitiveMeta(
                name: "MAKE",
                description: "Assigns a value to a named variable in current scope.",
                localizedDescriptionKey: "logo.doc.make",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "varname", required: true, description: "The variable name. Used by MAKE.",
                        example: "text"),
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "The value to process. Used by MAKE.", example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "MAKE \"count 10")]
            )

        case .name:
            LogoPrimitiveMeta(
                name: "NAME",
                description: "Assigns a value to a named variable (reverse argument order of MAKE).",
                localizedDescriptionKey: "logo.doc.name",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "The value to process. Used by NAME.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "varname", required: true, description: "The variable name. Used by NAME.",
                        example: "text"),
                ],
                examples: [LogoPrimitiveExample(input: "NAME 42 \"answer")]
            )

        case .show:
            LogoPrimitiveMeta(
                name: "SHOW",
                description: "Displays a status message or formatted output to the user.",
                localizedDescriptionKey: "logo.doc.show",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "The value to process. Used by SHOW.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "...", required: false, description: "The ... argument. Used by SHOW.", example: "..."),
                ],
                examples: [LogoPrimitiveExample(input: "SHOW \"Done")]
            )

        default:
            nil
        }
    }
}
