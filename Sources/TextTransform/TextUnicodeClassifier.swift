import Foundation

enum TextUnicodeClassifier {
    static func isUnicodeWordCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "_"
        }
    }

    static func isASCIIWordCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            scalar.value < 128 && (CharacterSet.alphanumerics.contains(scalar) || scalar == "_")
        }
    }

    static func isCJKProseCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            isCJKScriptScalar(scalar) || isCJKPunctuationScalar(scalar)
        }
    }

    static func isCJKScriptCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.contains(where: isCJKScriptScalar)
    }

    static func isCJKScriptScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3040...0x30FF,  // Hiragana, Katakana
            0x31F0...0x31FF,  // Katakana Phonetic Extensions
            0x3400...0x4DBF,  // CJK Unified Ideographs Extension A
            0x4E00...0x9FFF,  // CJK Unified Ideographs
            0xAC00...0xD7AF,  // Hangul Syllables
            0xF900...0xFAFF,  // CJK Compatibility Ideographs
            0x20000...0x2FA1F:  // CJK extensions and compatibility supplements
            return true
        default:
            return false
        }
    }

    static func isCJKPunctuationScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3000...0x303F,
            0xFE10...0xFE1F,
            0xFE30...0xFE4F,
            0xFF01...0xFF0F,
            0xFF1A...0xFF20,
            0xFF3B...0xFF40,
            0xFF5B...0xFF65:
            return true
        default:
            return false
        }
    }

    static func isEmojiCluster(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            let value = scalar.value
            return scalar.properties.isEmojiPresentation
                || scalar.properties.isEmojiModifier
                || scalar.properties.isEmojiModifierBase
                || value == 0xFE0F
                || value == 0x20E3
                || (0x1F1E6...0x1F1FF).contains(value)
                || (0x1F300...0x1FAFF).contains(value)
        }
    }
}
