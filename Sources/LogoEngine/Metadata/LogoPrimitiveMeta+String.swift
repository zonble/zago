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
                    LogoPrimitiveParameter(
                        name: "pattern", required: true, description: "The substring to find.", example: "world"),
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to search.", example: "hello world"),
                    LogoPrimitiveParameter(
                        name: "start", required: false,
                        description: "The 1-based position at which to begin searching.", example: "1"),
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
                    LogoPrimitiveParameter(
                        name: "pattern", required: true, description: "The substring to find.", example: "o"),
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to search.", example: "hello world"),
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
                    LogoPrimitiveParameter(
                        name: "pattern", required: true,
                        description: "The substring whose positions should be returned.", example: "l"),
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to search.", example: "hello world"),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to inspect.", example: "zago editor"),
                    LogoPrimitiveParameter(
                        name: "substring", required: true, description: "The text that must be present.", example: "ago"
                    ),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to inspect.", example: "index.html"),
                    LogoPrimitiveParameter(
                        name: "prefix", required: true, description: "The text that must appear at the beginning.",
                        example: "index"),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to inspect.", example: "main.swift"),
                    LogoPrimitiveParameter(
                        name: "suffix", required: true, description: "The text that must appear at the end.",
                        example: ".swift"),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text from which to extract characters.",
                        example: "abcdef"),
                    LogoPrimitiveParameter(
                        name: "start", required: true, description: "The 1-based starting position.", example: "2"),
                    LogoPrimitiveParameter(
                        name: "length", required: false,
                        description: "The number of characters to return; omit to return the remainder.", example: "3"),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to modify.", example: "hello world"),
                    LogoPrimitiveParameter(
                        name: "old", required: true, description: "The substring to replace.", example: "world"),
                    LogoPrimitiveParameter(
                        name: "new", required: true, description: "The replacement text.", example: "Zago"),
                ],
                examples: [LogoPrimitiveExample(input: "REPLACE \"hello world \"world \"there", output: "hello there")]
            )

        case .trim:
            LogoPrimitiveMeta(
                name: "TRIM",
                description: "Trims whitespace from both ends of string.",
                localizedDescriptionKey: "logo.doc.trim",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "string", required: true,
                        description: "The text whose surrounding whitespace should be removed.", example: "  hello  ")
                ],
                examples: [LogoPrimitiveExample(input: "TRIM \"  hello  ", output: "hello")]
            )

        case .repeatstr:
            LogoPrimitiveMeta(
                name: "REPEATSTR",
                description: "Repeats string specified number of times.",
                localizedDescriptionKey: "logo.doc.repeatstr",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "count", required: true, description: "The number of repetitions.", example: "5"),
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to repeat.", example: "="),
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
                    LogoPrimitiveParameter(
                        name: "separator", required: true, description: "The text placed between list items.",
                        example: ", "),
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list whose items should be joined.",
                        example: "[A B C]"),
                ],
                examples: [LogoPrimitiveExample(input: "JOINSTR \", \" [A B C]", output: "A, B, C")]
            )

        case .lines:
            LogoPrimitiveMeta(
                name: "LINES",
                description: "Splits multiline string into list of individual lines.",
                localizedDescriptionKey: "logo.doc.lines",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "multilineString", required: true, description: "The text to split at line breaks.",
                        example: "Line 1\\nLine 2")
                ],
                examples: [LogoPrimitiveExample(input: "LINES :buffer")]
            )

        case .unlines:
            LogoPrimitiveMeta(
                name: "UNLINES",
                description: "Joins list of lines into single multiline string with newlines.",
                localizedDescriptionKey: "logo.doc.unlines",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "listOfLines", required: true,
                        description: "The list of text lines to join with newline characters.", example: "[Line1 Line2]"
                    )
                ],
                examples: [LogoPrimitiveExample(input: "UNLINES [Line1 Line2]")]
            )

        case .format:
            LogoPrimitiveMeta(
                name: "FORMAT",
                description: "Formats string with printf-style specifiers (%d, %s, %f).",
                localizedDescriptionKey: "logo.doc.format",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "formatString", required: true,
                        description: "The printf-style format containing placeholders such as %s, %d, or %f.",
                        example: "Hello, %s!"),
                    LogoPrimitiveParameter(
                        name: "args", required: false,
                        description: "Values substituted into the format placeholders, in order.", example: "Zago"),
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
                    LogoPrimitiveParameter(
                        name: "width", required: true, description: "The target character width.", example: "8"),
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to pad on the left.", example: "42"),
                    LogoPrimitiveParameter(
                        name: "padChar", required: false,
                        description: "The character used for padding; defaults to a space.", example: "0"),
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
                    LogoPrimitiveParameter(
                        name: "width", required: true, description: "The target character width.", example: "10"),
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to pad on the right.", example: "Title"),
                    LogoPrimitiveParameter(
                        name: "padChar", required: false,
                        description: "The character used for padding; defaults to a space.", example: "."),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text to test against the regular expression.",
                        example: "abc-123"),
                    LogoPrimitiveParameter(
                        name: "pattern", required: true, description: "The regular expression pattern.",
                        example: "[a-z]+-[0-9]+"),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The text in which matches should be replaced.",
                        example: "hello 2026"),
                    LogoPrimitiveParameter(
                        name: "pattern", required: true, description: "The regular expression pattern to find.",
                        example: "[0-9]+"),
                    LogoPrimitiveParameter(
                        name: "template", required: true,
                        description: "The replacement text or template for each match.", example: "year"),
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
                    LogoPrimitiveParameter(
                        name: "string", required: true,
                        description: "The text to search for regular expression matches.", example: "abc-123"),
                    LogoPrimitiveParameter(
                        name: "pattern", required: true,
                        description: "The regular expression pattern whose matches should be returned.",
                        example: "[0-9]+"),
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.FIND \"abc-123 \"[0-9]+", output: "[123]")]
            )

        case .base64Encode:
            LogoPrimitiveMeta(
                name: "BASE64.ENCODE",
                description: "Encodes a UTF-8 string to Base64 format.",
                localizedDescriptionKey: "logo.doc.base64encode",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "text", required: true, description: "Text to encode to Base64.", example: "Hello World")
                ],
                examples: [
                    LogoPrimitiveExample(input: "BASE64.ENCODE \"Hello", output: "SGVsbG8=")
                ]
            )

        case .base64Decode:
            LogoPrimitiveMeta(
                name: "BASE64.DECODE",
                description: "Decodes a Base64 encoded string back to UTF-8 text.",
                localizedDescriptionKey: "logo.doc.base64decode",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "b64_text", required: true, description: "Base64 text to decode.", example: "SGVsbG8=")
                ],
                examples: [
                    LogoPrimitiveExample(input: "BASE64.DECODE \"SGVsbG8=", output: "Hello")
                ]
            )

        case .isBase64:
            LogoPrimitiveMeta(
                name: "BASE64?",
                description: "Tests whether a string is valid Base64 encoded format.",
                localizedDescriptionKey: "logo.doc.isbase64",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true, description: "String to test for Base64 validity.", example: "SGVsbG8=")
                ],
                examples: [
                    LogoPrimitiveExample(input: "BASE64? \"SGVsbG8=", output: "true"),
                    LogoPrimitiveExample(input: "BASE64? \"hello", output: "false")
                ]
            )

        case .urlEncode:
            LogoPrimitiveMeta(
                name: "URL.ENCODE",
                description: "Percent-encodes a string for use in URLs.",
                localizedDescriptionKey: "logo.doc.urlencode",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "text", required: true, description: "Text string to URL encode.", example: "hello world")
                ],
                examples: [
                    LogoPrimitiveExample(input: "URL.ENCODE \"hello_world", output: "hello_world"),
                    LogoPrimitiveExample(input: "URL.ENCODE \"你好", output: "%E4%BD%A0%E5%A5%BD")
                ]
            )

        case .urlDecode:
            LogoPrimitiveMeta(
                name: "URL.DECODE",
                description: "Decodes a percent-encoded URL string.",
                localizedDescriptionKey: "logo.doc.urldecode",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "url_text", required: true, description: "Percent-encoded URL string to decode.", example: "%E4%BD%A0%E5%A5%BD")
                ],
                examples: [
                    LogoPrimitiveExample(input: "URL.DECODE \"%E4%BD%A0%E5%A5%BD", output: "你好")
                ]
            )

        case .hexEncode:
            LogoPrimitiveMeta(
                name: "HEX.ENCODE",
                description: "Encodes an integer into 0xXXXX format or UTF-8 text into hex bytes.",
                localizedDescriptionKey: "logo.doc.hexencode",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "Integer number or text string to encode.", example: "255")
                ],
                examples: [
                    LogoPrimitiveExample(input: "HEX.ENCODE 255", output: "0xFF"),
                    LogoPrimitiveExample(input: "HEX.ENCODE \"abc", output: "616263")
                ]
            )

        case .hexDecode:
            LogoPrimitiveMeta(
                name: "HEX.DECODE",
                description: "Decodes 0xXXXX to decimal integer or hex bytes to UTF-8 text.",
                localizedDescriptionKey: "logo.doc.hexdecode",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "hex_string", required: true, description: "0x hex number or hex byte string to decode.", example: "0xFF")
                ],
                examples: [
                    LogoPrimitiveExample(input: "HEX.DECODE \"0xFF", output: "255"),
                    LogoPrimitiveExample(input: "HEX.DECODE \"616263", output: "abc")
                ]
            )

        case .hashSha256:
            LogoPrimitiveMeta(
                name: "HASH.SHA256",
                description: "Computes the 64-character lowercase SHA-256 hex digest of a string.",
                localizedDescriptionKey: "logo.doc.hashsha256",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "text", required: true, description: "Text to hash.", example: "zago")
                ],
                examples: [
                    LogoPrimitiveExample(input: "HASH.SHA256 \"zago", output: "a8c9c415e3c160a7da0b080e3ad97dbde9fb7dc26f961a9ab36b0f35c1b990eb")
                ]
            )

        case .hashSha1:
            LogoPrimitiveMeta(
                name: "HASH.SHA1",
                description: "Computes the 40-character lowercase SHA-1 hex digest of a string.",
                localizedDescriptionKey: "logo.doc.hashsha1",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "text", required: true, description: "Text to hash.", example: "zago")
                ],
                examples: [
                    LogoPrimitiveExample(input: "HASH.SHA1 \"zago", output: "c638cf03c5bc5b232cd77bce0187768802868ac4")
                ]
            )

        case .hashMd5:
            LogoPrimitiveMeta(
                name: "HASH.MD5",
                description: "Computes the 32-character lowercase MD5 hex digest of a string.",
                localizedDescriptionKey: "logo.doc.hashmd5",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "text", required: true, description: "Text to hash.", example: "zago")
                ],
                examples: [
                    LogoPrimitiveExample(input: "HASH.MD5 \"zago", output: "d8bbeea6bd5b4499ac006dd6bdece342")
                ]
            )

        default: nil
        }
    }
}
