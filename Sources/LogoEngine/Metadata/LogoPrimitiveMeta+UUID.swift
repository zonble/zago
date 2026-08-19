import Foundation

private let uuidFlavorAllowedValues = LogoUUIDGenerator.allowedFlavors

extension LogoPrimitive {
    var uuidMeta: LogoPrimitiveMeta? {
        return switch self {
        case .uuid:
            LogoPrimitiveMeta(
                name: "UUID",
                description: "Generates a unique identifier string (UUID v4, v7, nil, or short ID).",
                localizedDescriptionKey: "logo.doc.uuid",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "flavor", required: false,
                        description: "UUID version or format: v4, v7, nil, short.", example: "v7",
                        allowedValues: uuidFlavorAllowedValues)
                ],
                examples: [
                    LogoPrimitiveExample(input: "UUID"),
                    LogoPrimitiveExample(input: "UUID \"v7"),
                    LogoPrimitiveExample(input: "UUID \"nil", output: "00000000-0000-0000-0000-000000000000"),
                    LogoPrimitiveExample(input: "UUID \"short"),
                ]
            )

        case .isUUID:
            LogoPrimitiveMeta(
                name: "UUID?",
                description: "Tests whether a string is a valid UUID representation.",
                localizedDescriptionKey: "logo.doc.is_uuid",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "string", required: true, description: "The string to test.",
                        example: "f47ac10b-58cc-4372-a567-0e02b2c3d479")
                ],
                examples: [
                    LogoPrimitiveExample(input: "UUID? \"f47ac10b-58cc-4372-a567-0e02b2c3d479", output: "true"),
                    LogoPrimitiveExample(input: "UUID? \"hello", output: "false"),
                ]
            )

        case .uuidTime:
            LogoPrimitiveMeta(
                name: "UUID.TIME",
                description: "Extracts ISO8601 timestamp string from a UUID v7 identifier.",
                localizedDescriptionKey: "logo.doc.uuid_time",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "uuid_v7_string", required: true, description: "A valid UUID v7 string.",
                        example: "018f4a3c-b1d5-7123-8abc-def012345678")
                ],
                examples: [
                    LogoPrimitiveExample(input: "UUID.TIME (UUID \"v7)")
                ]
            )

        default:
            nil
        }
    }
}
