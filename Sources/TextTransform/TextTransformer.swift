import Foundation

public enum TextTransformError: Error, Equatable, Sendable, CustomStringConvertible {
    case unknownTransform(String)

    public var description: String {
        switch self {
        case .unknownTransform(let id):
            return "Unknown text transform: \(id)"
        }
    }
}

public enum TextTransformer {
    public static func apply(_ id: String, to text: String) throws -> String {
        let normalizedId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedId.isEmpty else {
            throw TextTransformError.unknownTransform(id)
        }

        if let zagoResult = applyZagoTransform(normalizedId, to: text) {
            return zagoResult
        }

        let transform = StringTransform(rawValue: normalizedId)
        if let result = (text as NSString).applyingTransform(transform, reverse: false) {
            return result
        }

        throw TextTransformError.unknownTransform(normalizedId)
    }

    private static func applyZagoTransform(_ id: String, to text: String) -> String? {
        switch id.lowercased() {
        case "zago-cjk-punctuation":
            return normalizeCJKPunctuation(text)
        case "zago-prose-cleanup":
            return normalizeCJKPunctuation(text)
        default:
            return nil
        }
    }

    private static func normalizeCJKPunctuation(_ text: String) -> String {
        let replacements: [Character: Character] = [
            ",": "，",
            ".": "。",
            ":": "：",
            ";": "；",
            "?": "？",
            "!": "！",
        ]

        return String(text.map { replacements[$0] ?? $0 })
    }
}
