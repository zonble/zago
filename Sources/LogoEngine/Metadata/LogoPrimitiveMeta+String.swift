import Foundation

extension LogoPrimitive {
    var stringMeta: LogoPrimitiveMeta? {
        switch self {
        case .indexof:
            LogoPrimitiveMeta(
                name: "INDEXOF",
                description: "Returns 1-based index of first substring occurrence.",
                localizedDescriptionKey: "logo.doc.indexof",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "start", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "INDEXOF \"world \"hello world", output: "7")]
            )

        case .lastindexof:
            LogoPrimitiveMeta(
                name: "LASTINDEXOF",
                description: "Returns 1-based index of last substring occurrence.",
                localizedDescriptionKey: "logo.doc.lastindexof",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LASTINDEXOF \"o \"hello world", output: "8")]
            )

        case .indexesof:
            LogoPrimitiveMeta(
                name: "INDEXESOF",
                description: "Returns list of all 1-based match positions of substring.",
                localizedDescriptionKey: "logo.doc.indexesof",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "INDEXESOF \"l \"hello world", output: "[3 4 10]")]
            )

        case .contains:
            LogoPrimitiveMeta(
                name: "CONTAINS?",
                description: "Tests whether string contains substring.",
                localizedDescriptionKey: "logo.doc.contains",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "substring", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "CONTAINS? \"zago \"ag", output: "true")]
            )

        case .startswith:
            LogoPrimitiveMeta(
                name: "STARTSWITH?",
                description: "Tests whether string starts with specified prefix.",
                localizedDescriptionKey: "logo.doc.startswith",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "prefix", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "STARTSWITH? \"index.html \"index", output: "true")]
            )

        case .endswith:
            LogoPrimitiveMeta(
                name: "ENDSWITH?",
                description: "Tests whether string ends with specified suffix.",
                localizedDescriptionKey: "logo.doc.endswith",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "suffix", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "ENDSWITH? \"main.swift \".swift", output: "true")]
            )

        case .substring:
            LogoPrimitiveMeta(
                name: "SUBSTRING",
                description: "Extracts substring from 1-based start index with optional length.",
                localizedDescriptionKey: "logo.doc.substring",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "start", required: true),
                    LogoPrimitiveParameter(name: "length", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "SUBSTRING \"abcdef 2 3", output: "bcd")]
            )

        case .replace:
            LogoPrimitiveMeta(
                name: "REPLACE",
                description: "Replaces occurrences of substring with replacement string.",
                localizedDescriptionKey: "logo.doc.replace",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "old", required: true),
                    LogoPrimitiveParameter(name: "new", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REPLACE \"hello world \"world \"there", output: "hello there")]
            )

        case .trim:
            LogoPrimitiveMeta(
                name: "TRIM",
                description: "Trims whitespace from both ends of string.",
                localizedDescriptionKey: "logo.doc.trim",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TRIM \"  hello  ", output: "hello")]
            )

        case .repeatstr:
            LogoPrimitiveMeta(
                name: "REPEATSTR",
                description: "Repeats string specified number of times.",
                localizedDescriptionKey: "logo.doc.repeatstr",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "count", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REPEATSTR 5 \"=", output: "=====")]
            )

        case .join:
            LogoPrimitiveMeta(
                name: "JOINSTR",
                description: "Joins list elements into single string using separator.",
                localizedDescriptionKey: "logo.doc.joinstr",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "separator", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "JOINSTR \", \" [A B C]", output: "A, B, C")]
            )

        case .lines:
            LogoPrimitiveMeta(
                name: "LINES",
                description: "Splits multiline string into list of individual lines.",
                localizedDescriptionKey: "logo.doc.lines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "multilineString", required: true)],
                examples: [LogoPrimitiveExample(input: "LINES :buffer")]
            )

        case .unlines:
            LogoPrimitiveMeta(
                name: "UNLINES",
                description: "Joins list of lines into single multiline string with newlines.",
                localizedDescriptionKey: "logo.doc.unlines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "listOfLines", required: true)],
                examples: [LogoPrimitiveExample(input: "UNLINES [Line1 Line2]")]
            )

        case .format:
            LogoPrimitiveMeta(
                name: "FORMAT",
                description: "Formats string with printf-style specifiers (%d, %s, %f).",
                localizedDescriptionKey: "logo.doc.format",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "formatString", required: true),
                    LogoPrimitiveParameter(name: "args", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT \"Hello, %s! \"Zago", output: "Hello, Zago!")]
            )

        case .padleft:
            LogoPrimitiveMeta(
                name: "PADLEFT",
                description: "Pads string on left to target width.",
                localizedDescriptionKey: "logo.doc.padleft",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: true),
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "padChar", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "PADLEFT 8 \"42 \"0", output: "00000042")]
            )

        case .padright:
            LogoPrimitiveMeta(
                name: "PADRIGHT",
                description: "Pads string on right to target width.",
                localizedDescriptionKey: "logo.doc.padright",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: true),
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "padChar", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "PADRIGHT 10 \"Title \".", output: "Title.....")]
            )

        case .regexMatch:
            LogoPrimitiveMeta(
                name: "REGEX.MATCH",
                description: "Tests whether string matches regular expression pattern.",
                localizedDescriptionKey: "logo.doc.regexmatch",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "pattern", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.MATCH \"abc-123 \"[a-z]+-[0-9]+", output: "true")]
            )

        case .regexReplace:
            LogoPrimitiveMeta(
                name: "REGEX.REPLACE",
                description: "Replaces regular expression matches in string with replacement template.",
                localizedDescriptionKey: "logo.doc.regexreplace",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "template", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.REPLACE \"hello 2026 \"[0-9]+ \"world", output: "hello world")]
            )

        case .regexFind:
            LogoPrimitiveMeta(
                name: "REGEX.FIND",
                description: "Returns list of regex capture groups or matching substrings.",
                localizedDescriptionKey: "logo.doc.regexfind",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "pattern", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.FIND \"abc-123 \"[0-9]+", output: "[123]")]
            )

        default: nil
    }
}
}
