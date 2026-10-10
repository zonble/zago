import Foundation
import TextMetrics

public enum TextUnicodeClassifier {
    public static func isUnicodeWordCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "_"
        }
    }

    public static func isASCIIWordCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            scalar.value < 128 && (CharacterSet.alphanumerics.contains(scalar) || scalar == "_")
        }
    }

    public static func isCJKProseCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            isCJKScriptScalar(scalar) || isCJKPunctuationScalar(scalar)
        }
    }

    public static func isCJKScriptCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.contains(where: isCJKScriptScalar)
    }

    static func isCJKScriptScalar(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isCJKScriptScalar
    }

    static func isCJKPunctuationScalar(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isCJKPunctuationScalar
    }

    static func isEmojiCluster(_ character: Character) -> Bool {
        character.isEmojiCluster
    }
}

