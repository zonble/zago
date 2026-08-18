import Foundation

extension LogoPrimitive {
    var detectMeta: LogoPrimitiveMeta? {
        switch self {
        case .detectURL:
            return LogoPrimitiveMeta(
                name: "DETECT.URL",
                description: "Detects URLs in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detecturl",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text to scan for URLs.",
                        example: "Visit https://example.com")
                ],
                examples: [
                    LogoPrimitiveExample(
                        input: "DETECT.URL \"Visit https://example.com", output: "[https://example.com]")
                ],
                notes: "Not supported on Linux or Windows."
            )

        case .detectEmail:
            return LogoPrimitiveMeta(
                name: "DETECT.EMAIL",
                description: "Detects email addresses in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectemail",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text to scan for email addresses.",
                        example: "Mail team@example.com")
                ],
                examples: [
                    LogoPrimitiveExample(input: "DETECT.EMAIL \"Mail team@example.com", output: "[team@example.com]")
                ],
                notes: "Not supported on Linux or Windows."
            )

        case .detectPhone:
            return LogoPrimitiveMeta(
                name: "DETECT.PHONE",
                description: "Detects phone numbers in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectphone",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text to scan for phone numbers.",
                        example: "Call 555-123-4567")
                ],
                examples: [LogoPrimitiveExample(input: "DETECT.PHONE \"Call 555-123-4567", output: "[555-123-4567]")],
                notes: "Not supported on Linux or Windows."
            )

        case .detectDate:
            return LogoPrimitiveMeta(
                name: "DETECT.DATE",
                description: "Detects dates in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectdate",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text to scan for dates.",
                        example: "Meeting on January 5, 2027")
                ],
                examples: [
                    LogoPrimitiveExample(input: "DETECT.DATE \"Meeting on January 5, 2027", output: "[January 5, 2027]")
                ],
                notes: "Not supported on Linux or Windows."
            )

        case .detectAddress:
            return LogoPrimitiveMeta(
                name: "DETECT.ADDRESS",
                description: "Detects postal addresses in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectaddress",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text to scan for postal addresses.",
                        example: "1600 Pennsylvania Avenue NW")
                ],
                examples: [
                    LogoPrimitiveExample(
                        input: "DETECT.ADDRESS \"1600 Pennsylvania Avenue NW", output: "[1600 Pennsylvania Avenue NW]")
                ],
                notes: "Not supported on Linux or Windows."
            )

        default:
            return nil
        }
    }
}
