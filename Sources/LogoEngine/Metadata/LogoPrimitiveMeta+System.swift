private let sortOrderAllowedValues = LogoSortOrder.allCases.map(\.rawValue)

extension LogoPrimitive {
    var systemMeta: LogoPrimitiveMeta? {
        switch self {
        case .sort:
            return LogoPrimitiveMeta(
                name: "SORT",
                description: "Sorts elements in list alphabetically or numerically.",
                localizedDescriptionKey: "logo.doc.sort",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list to process. Used by SORT.",
                        example: "[A B C]"),
                    LogoPrimitiveParameter(
                        name: "order", required: false, description: "The order argument. Used by SORT.",
                        example: "desc", allowedValues: sortOrderAllowedValues),
                    LogoPrimitiveParameter(
                        name: "template", required: false, description: "The Logo template to apply. Used by SORT.",
                        example: "[FD 1]"),
                ],
                examples: [LogoPrimitiveExample(input: "SORT [3 1 4 1 5 9]", output: "[1 1 3 4 5 9]")]
            )

        case .sortLocalized:
            return LogoPrimitiveMeta(
                name: "SORT.LOCALIZED",
                description: "Sorts elements in list, array, or string using natural localized order.",
                localizedDescriptionKey: "logo.doc.sort.localized",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "list", required: true,
                        description: "The list or string to process. Used by SORT.LOCALIZED.",
                        example: "[item1 item10 item2]"),
                    LogoPrimitiveParameter(
                        name: "order", required: false, description: "The order argument. Used by SORT.LOCALIZED.",
                        example: "desc", allowedValues: sortOrderAllowedValues),
                    LogoPrimitiveParameter(
                        name: "template", required: false,
                        description: "The Logo template to apply. Used by SORT.LOCALIZED.",
                        example: "[?1 < ?2]"),
                ],
                examples: [
                    LogoPrimitiveExample(
                        input: "SORT.LOCALIZED [\"file10.txt \"file2.txt \"file1.txt]",
                        output: "[\"file1.txt \"file2.txt \"file10.txt]"),
                    LogoPrimitiveExample(
                        input: "SORT.LOCALIZED \"desc [\"v1.2 \"v1.10 \"v1.9]", output: "[\"v1.10 \"v1.9 \"v1.2]"),
                ]
            )

        case .fill:
            return LogoPrimitiveMeta(
                name: "FILL",
                description: "Fills active canvas mark block or table cell with text pattern.",
                localizedDescriptionKey: "logo.doc.fill",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "width", required: false, description: "The width. Used by FILL.", example: "3"),
                    LogoPrimitiveParameter(
                        name: "height", required: false, description: "The height. Used by FILL.", example: "3"),
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text value. Used by FILL.", example: "text"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "FILL \".\""),
                    LogoPrimitiveExample(input: "FILL 20 3 \".#\""),
                ]
            )

        case .readWord:
            return LogoPrimitiveMeta(
                name: "READWORD",
                description: "Prompts user to enter a line of text input.",
                localizedDescriptionKey: "logo.doc.readword",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "prompt", required: false, description: "The prompt argument. Used by READWORD.",
                        example: "value")
                ],
                examples: [LogoPrimitiveExample(input: "MAKE \"name READWORD \"Name: ")]
            )

        case .readChar:
            return LogoPrimitiveMeta(
                name: "READCHAR",
                description: "Prompts user to press a single character key.",
                localizedDescriptionKey: "logo.doc.readchar",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "prompt", required: false, description: "The prompt argument. Used by READCHAR.",
                        example: "value")
                ],
                examples: [LogoPrimitiveExample(input: "MAKE \"k READCHAR")]
            )

        case .names:
            return LogoPrimitiveMeta(
                name: "NAMES",
                description: "Returns list of all variable names in current environment.",
                localizedDescriptionKey: "logo.doc.names",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "NAMES")]
            )

        case .procedures:
            return LogoPrimitiveMeta(
                name: "PROCEDURES",
                description: "Returns list of all defined procedure names.",
                localizedDescriptionKey: "logo.doc.procedures",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PROCEDURES")]
            )

        case .primitives:
            return LogoPrimitiveMeta(
                name: "PRIMITIVES",
                description: "Returns list of all built-in LOGO primitive names.",
                localizedDescriptionKey: "logo.doc.primitives",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PRIMITIVES")]
            )

        case .contents:
            return LogoPrimitiveMeta(
                name: "CONTENTS",
                description: "Returns list of procedures, variables, and property lists [procs vars plists].",
                localizedDescriptionKey: "logo.doc.contents",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "CONTENTS")]
            )

        case .text:
            return LogoPrimitiveMeta(
                name: "TEXT",
                description: "Returns definition token list of named procedure.",
                localizedDescriptionKey: "logo.doc.text",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "procname", required: true, description: "The procname argument. Used by TEXT.",
                        example: "text")
                ],
                examples: [LogoPrimitiveExample(input: "TEXT \"square")]
            )

        case .define:
            return LogoPrimitiveMeta(
                name: "DEFINE",
                description: "Defines procedure dynamically from parameter and instruction list.",
                localizedDescriptionKey: "logo.doc.define",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "procname", required: true, description: "The procname argument. Used by DEFINE.",
                        example: "text"),
                    LogoPrimitiveParameter(
                        name: "textList", required: true, description: "The textList argument. Used by DEFINE.",
                        example: "[A B C]"),
                ],
                examples: [LogoPrimitiveExample(input: "DEFINE \"double [[n] [OUTPUT :n * 2]]")]
            )

        case .erase:
            return LogoPrimitiveMeta(
                name: "ERASE",
                description: "Erases named custom procedure definition.",
                localizedDescriptionKey: "logo.doc.erase",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "procname", required: true, description: "The procname argument. Used by ERASE.",
                        example: "text")
                ],
                examples: [LogoPrimitiveExample(input: "ERASE \"oldProc")]
            )

        case .erps:
            return LogoPrimitiveMeta(
                name: "ERPS",
                description: "Erases all user procedure definitions.",
                localizedDescriptionKey: "logo.doc.erps",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERPS")]
            )

        case .erns:
            return LogoPrimitiveMeta(
                name: "ERNS",
                description: "Erases all variable bindings in environment.",
                localizedDescriptionKey: "logo.doc.erns",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERNS")]
            )

        case .erall:
            return LogoPrimitiveMeta(
                name: "ERALL",
                description: "Erases all procedures, variables, and property lists.",
                localizedDescriptionKey: "logo.doc.erall",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERALL")]
            )

        case .arity:
            return LogoPrimitiveMeta(
                name: "ARITY",
                description: "Returns expected argument count of procedure or primitive.",
                localizedDescriptionKey: "logo.doc.arity",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "procname", required: true, description: "The procname argument. Used by ARITY.",
                        example: "text")
                ],
                examples: [LogoPrimitiveExample(input: "ARITY \"sum", output: "2")]
            )

        case .doc:
            return LogoPrimitiveMeta(
                name: "DOC",
                description: "Returns documentation docstring for procedure or built-in primitive.",
                localizedDescriptionKey: "logo.doc.doc",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "name", required: true, description: "The name. Used by DOC.", example: "text")
                ],
                examples: [LogoPrimitiveExample(input: "DOC \"BOX")]
            )

        case .end:
            return LogoPrimitiveMeta(
                name: "END",
                description: "Marks the end of a procedure definition block.",
                localizedDescriptionKey: "logo.doc.end",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "END")]
            )

        default:
            return nil
        }
    }
}
