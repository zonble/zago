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
                    LogoPrimitiveParameter(name: "pattern", required: true, description: "The substring to find.", example: "world"),
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to search.", example: "hello world"),
                    LogoPrimitiveParameter(name: "start", required: false, description: "The 1-based position at which to begin searching.", example: "1"),
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
                    LogoPrimitiveParameter(name: "pattern", required: true, description: "The substring to find.", example: "o"),
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to search.", example: "hello world"),
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
                    LogoPrimitiveParameter(name: "pattern", required: true, description: "The substring whose positions should be returned.", example: "l"),
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to search.", example: "hello world"),
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
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to inspect.", example: "zago editor"),
                    LogoPrimitiveParameter(name: "substring", required: true, description: "The text that must be present.", example: "ago"),
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
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to inspect.", example: "index.html"),
                    LogoPrimitiveParameter(name: "prefix", required: true, description: "The text that must appear at the beginning.", example: "index"),
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
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to inspect.", example: "main.swift"),
                    LogoPrimitiveParameter(name: "suffix", required: true, description: "The text that must appear at the end.", example: ".swift"),
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
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text from which to extract characters.", example: "abcdef"),
                    LogoPrimitiveParameter(name: "start", required: true, description: "The 1-based starting position.", example: "2"),
                    LogoPrimitiveParameter(name: "length", required: false, description: "The number of characters to return; omit to return the remainder.", example: "3"),
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
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to modify.", example: "hello world"),
                    LogoPrimitiveParameter(name: "old", required: true, description: "The substring to replace.", example: "world"),
                    LogoPrimitiveParameter(name: "new", required: true, description: "The replacement text.", example: "Zago"),
                ],
                examples: [LogoPrimitiveExample(input: "REPLACE \"hello world \"world \"there", output: "hello there")]
            )

        case .trim:
            LogoPrimitiveMeta(
                name: "TRIM",
                description: "Trims whitespace from both ends of string.",
                localizedDescriptionKey: "logo.doc.trim",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true, description: "The text whose surrounding whitespace should be removed.", example: "  hello  ")],
                examples: [LogoPrimitiveExample(input: "TRIM \"  hello  ", output: "hello")]
            )

        case .repeatstr:
            LogoPrimitiveMeta(
                name: "REPEATSTR",
                description: "Repeats string specified number of times.",
                localizedDescriptionKey: "logo.doc.repeatstr",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "count", required: true, description: "The number of repetitions.", example: "5"),
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to repeat.", example: "="),
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
                    LogoPrimitiveParameter(name: "separator", required: true, description: "The text placed between list items.", example: ", "),
                    LogoPrimitiveParameter(name: "list", required: true, description: "The list whose items should be joined.", example: "[A B C]"),
                ],
                examples: [LogoPrimitiveExample(input: "JOINSTR \", \" [A B C]", output: "A, B, C")]
            )

        case .lines:
            LogoPrimitiveMeta(
                name: "LINES",
                description: "Splits multiline string into list of individual lines.",
                localizedDescriptionKey: "logo.doc.lines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "multilineString", required: true, description: "The text to split at line breaks.", example: "Line 1\\nLine 2")],
                examples: [LogoPrimitiveExample(input: "LINES :buffer")]
            )

        case .unlines:
            LogoPrimitiveMeta(
                name: "UNLINES",
                description: "Joins list of lines into single multiline string with newlines.",
                localizedDescriptionKey: "logo.doc.unlines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "listOfLines", required: true, description: "The list of text lines to join with newline characters.", example: "[Line1 Line2]")],
                examples: [LogoPrimitiveExample(input: "UNLINES [Line1 Line2]")]
            )

        case .format:
            LogoPrimitiveMeta(
                name: "FORMAT",
                description: "Formats string with printf-style specifiers (%d, %s, %f).",
                localizedDescriptionKey: "logo.doc.format",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "formatString", required: true, description: "The printf-style format containing placeholders such as %s, %d, or %f.", example: "Hello, %s!"),
                    LogoPrimitiveParameter(name: "args", required: false, description: "Values substituted into the format placeholders, in order.", example: "Zago"),
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
                    LogoPrimitiveParameter(name: "width", required: true, description: "The target character width.", example: "8"),
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to pad on the left.", example: "42"),
                    LogoPrimitiveParameter(name: "padChar", required: false, description: "The character used for padding; defaults to a space.", example: "0"),
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
                    LogoPrimitiveParameter(name: "width", required: true, description: "The target character width.", example: "10"),
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to pad on the right.", example: "Title"),
                    LogoPrimitiveParameter(name: "padChar", required: false, description: "The character used for padding; defaults to a space.", example: "."),
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
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to test against the regular expression.", example: "abc-123"),
                    LogoPrimitiveParameter(name: "pattern", required: true, description: "The regular expression pattern.", example: "[a-z]+-[0-9]+"),
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
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text in which matches should be replaced.", example: "hello 2026"),
                    LogoPrimitiveParameter(name: "pattern", required: true, description: "The regular expression pattern to find.", example: "[0-9]+"),
                    LogoPrimitiveParameter(name: "template", required: true, description: "The replacement text or template for each match.", example: "year"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "REGEX.REPLACE \"hello 2026 \"[0-9]+ \"world", output: "hello world")
                ]
            )

        case .regexFind:
            LogoPrimitiveMeta(
                name: "REGEX.FIND",
                description: "Returns list of regex capture groups or matching substrings.",
                localizedDescriptionKey: "logo.doc.regexfind",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true, description: "The text to search for regular expression matches.", example: "abc-123"),
                    LogoPrimitiveParameter(name: "pattern", required: true, description: "The regular expression pattern whose matches should be returned.", example: "[0-9]+"),
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.FIND \"abc-123 \"[0-9]+", output: "[123]")]
            )

        default: nil
        }
    }
}
