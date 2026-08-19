import Foundation

private let numberStyleAllowedValues = LogoNumberStyle.allCases.map(\.rawValue)
private let listTypeAllowedValues = LogoListType.allCases.map(\.rawValue)
private let byteCountStyleAllowedValues = LogoByteCountStyle.allCases.map(\.rawValue)
private let personNameStyleAllowedValues = LogoPersonNameStyle.allowedStyleNames

extension LogoPrimitive {
    var formatMeta: LogoPrimitiveMeta? {
        return switch self {
        case .formatNumber:
            LogoPrimitiveMeta(
                name: "FORMAT.NUMBER",
                description:
                    "Formats number using localized decimal, currency, percent, roman, or financial CJK uppercase.",
                localizedDescriptionKey: "logo.doc.formatnumber",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "num", required: true, description: "The number to format.", example: "1234.5"),
                    LogoPrimitiveParameter(
                        name: "style", required: false, description: "The number representation to use.",
                        example: "currency",
                        allowedValues: numberStyleAllowedValues),
                    LogoPrimitiveParameter(
                        name: "locale", required: false,
                        description: "The locale used for decimal separators, symbols, and words.", example: "en_US"),
                    LogoPrimitiveParameter(
                        name: "currency", required: false,
                        description: "The ISO 4217 currency code used by the currency style.", example: "USD"),
                    LogoPrimitiveParameter(
                        name: "precision", required: false,
                        description: "The exact number of fraction digits for numeric styles.", example: "2"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "FORMAT.NUMBER 1234.5 \"currency \"en_US \"USD", output: "$1,234.50"),
                    LogoPrimitiveExample(input: "FORMAT.NUMBER 10050208 \"financial", output: "壹仟零伍萬零貳佰零捌"),
                ]
            )

        case .formatList:
            LogoPrimitiveMeta(
                name: "FORMAT.LIST",
                description: "Formats list into localized natural language string (and, or, unit).",
                localizedDescriptionKey: "logo.doc.formatlist",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list or array to format.", example: "[A B C]"),
                    LogoPrimitiveParameter(
                        name: "type", required: false, description: "The list conjunction style.", example: "and",
                        allowedValues: listTypeAllowedValues),
                    LogoPrimitiveParameter(
                        name: "locale", required: false, description: "The locale used for formatting.",
                        example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.LIST [A B C] \"and \"en_US", output: "A, B, and C")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatBytes:
            LogoPrimitiveMeta(
                name: "FORMAT.BYTES",
                description: "Formats byte counts into human-readable memory or file sizes (KB, MB, GB).",
                localizedDescriptionKey: "logo.doc.formatbytes",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "bytes", required: true, description: "The bytes argument. Used by FORMATBYTES.",
                        example: "value"),
                    LogoPrimitiveParameter(
                        name: "style", required: false,
                        description: "The formatting or border style. Used by FORMATBYTES.", example: "file",
                        allowedValues: byteCountStyleAllowedValues),
                    LogoPrimitiveParameter(
                        name: "locale", required: false, description: "The locale identifier. Used by FORMATBYTES.",
                        example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.BYTES 1048576", output: "1 MB")]
            )

        case .formatName:
            LogoPrimitiveMeta(
                name: "FORMAT.NAME",
                description:
                    "Formats person name components (given, middle, family, prefix, suffix, nickname) into localized name strings.",
                localizedDescriptionKey: "logo.doc.formatname",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "givenOrFullName", required: true,
                        description:
                            "A full name string, given name, or property list [given family middle prefix suffix nickname ...].",
                        example: "Arthur"),
                    LogoPrimitiveParameter(
                        name: "middleOrFamilyOrStyle", required: false,
                        description: "Middle name, family name, or display style.", example: "Conan"),
                    LogoPrimitiveParameter(
                        name: "familyOrStyle", required: false, description: "Family name or display style.",
                        example: "Doyle"),
                    LogoPrimitiveParameter(
                        name: "style", required: false,
                        description: "Display style (short, medium, long, abbreviated).", example: "long",
                        allowedValues: personNameStyleAllowedValues),
                    LogoPrimitiveParameter(
                        name: "locale", required: false, description: "Target locale (e.g. en_US, zh_TW, ja_JP).",
                        example: "en_US"),
                ],
                examples: [
                    LogoPrimitiveExample(
                        input: "FORMAT.NAME \"Arthur \"Conan \"Doyle \"long", output: "Arthur Conan Doyle"),
                    LogoPrimitiveExample(input: "FORMAT.NAME \"Steve \"Jobs \"abbreviated", output: "S. Jobs"),
                    LogoPrimitiveExample(
                        input: "FORMAT.NAME [given \"Arthur middle \"Conan family \"Doyle] \"short", output: "Arthur"),
                ],
                notes:
                    "Supports positional inputs (given family / given middle family), full name strings, and property lists ([given ... middle ... family ... prefix ... suffix ... nickname ...]). Not supported on Linux or Windows."
            )

        default:
            nil
        }
    }
}
