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
        case "zago-cjk-spacing":
            return normalizeCJKSpacing(text)
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

    private static func normalizeCJKSpacing(_ text: String) -> String {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        return
            normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { normalizeCJKSpacingLine(String($0)) }
            .joined(separator: "\n")
    }

    private static func normalizeCJKSpacingLine(_ line: String) -> String {
        var result = ""
        var pendingWhitespace = ""
        var previousNonWhitespace: Character?

        for character in line {
            if character.isWhitespace {
                pendingWhitespace += String(character)
                continue
            }

            if let previous = previousNonWhitespace {
                if shouldSeparate(previous, character) {
                    result += " "
                } else if shouldJoin(previous, character) {
                    // Intentionally drop whitespace between CJK prose characters.
                } else if !pendingWhitespace.isEmpty {
                    result += " "
                }
            } else if !pendingWhitespace.isEmpty {
                result += pendingWhitespace
            }

            result += String(character)
            previousNonWhitespace = character
            pendingWhitespace = ""
        }

        result += pendingWhitespace
        return result
    }

    private static func shouldSeparate(_ lhs: Character, _ rhs: Character) -> Bool {
        (TextUnicodeClassifier.isCJKScriptCharacter(lhs) && TextUnicodeClassifier.isASCIIWordCharacter(rhs))
            || (TextUnicodeClassifier.isASCIIWordCharacter(lhs) && TextUnicodeClassifier.isCJKScriptCharacter(rhs))
    }

    private static func shouldJoin(_ lhs: Character, _ rhs: Character) -> Bool {
        TextUnicodeClassifier.isCJKScriptCharacter(lhs) && TextUnicodeClassifier.isCJKScriptCharacter(rhs)
    }
}
