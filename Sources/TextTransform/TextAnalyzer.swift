import Foundation

public enum TextAnalyzer {
    public static func characterCount(in text: String) -> Int {
        text.count
    }

    public static func cjkCharacterCount(in text: String) -> Int {
        text.reduce(0) { partial, character in
            partial + (TextUnicodeClassifier.isCJKProseCharacter(character) ? 1 : 0)
        }
    }

    public static func wordCount(in text: String) -> Int {
        var count = 0
        var isInsideWord = false

        for character in text {
            if TextUnicodeClassifier.isUnicodeWordCharacter(character) {
                if !isInsideWord {
                    count += 1
                    isInsideWord = true
                }
            } else {
                isInsideWord = false
            }
        }

        return count
    }

    public static func emojiCount(in text: String) -> Int {
        text.reduce(0) { partial, character in
            partial + (TextUnicodeClassifier.isEmojiCluster(character) ? 1 : 0)
        }
    }

    public static func lineCount(in text: String) -> Int {
        if text.isEmpty { return 1 }

        var normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        normalized = normalized.replacingOccurrences(of: "\r", with: "\n")
        return normalized.reduce(1) { partial, character in
            partial + (character == "\n" ? 1 : 0)
        }
    }

}
