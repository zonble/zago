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

    /// Finds all word ranges in `text` using ICU natural language word breaking (`byWords`) on Darwin, or portable word boundary scanning on Linux/Windows.
    public static func wordRanges(in text: String) -> [Range<Int>] {
        guard !text.isEmpty else { return [] }
        #if canImport(Darwin)
            var ranges: [Range<Int>] = []
            text.enumerateSubstrings(in: text.startIndex..., options: [.byWords, .substringNotRequired]) {
                _, substringRange, _, _ in
                let lower = text.distance(from: text.startIndex, to: substringRange.lowerBound)
                let upper = text.distance(from: text.startIndex, to: substringRange.upperBound)
                if lower < upper {
                    ranges.append(lower..<upper)
                }
            }
            return ranges
        #else
            var ranges: [Range<Int>] = []
            var wordStart: Int? = nil
            var index = 0
            for character in text {
                if TextUnicodeClassifier.isCJKScriptCharacter(character) {
                    if let start = wordStart {
                        ranges.append(start..<index)
                        wordStart = nil
                    }
                    ranges.append(index..<(index + 1))
                } else if TextUnicodeClassifier.isUnicodeWordCharacter(character) {
                    if wordStart == nil {
                        wordStart = index
                    }
                } else {
                    if let start = wordStart {
                        ranges.append(start..<index)
                        wordStart = nil
                    }
                }
                index += 1
            }
            if let start = wordStart {
                ranges.append(start..<index)
            }
            return ranges
        #endif
    }

    /// Computes next word boundary index after `currentIndex` using ICU word breaking.
    public static func nextWordIndex(in text: String, from currentIndex: Int) -> Int {
        let textCount = text.count
        guard currentIndex < textCount else { return textCount }
        let ranges = wordRanges(in: text)
        for range in ranges {
            if range.upperBound > currentIndex {
                // If cursor is before the word, jumping to its end
                return range.upperBound
            }
        }
        return textCount
    }

    /// Computes previous word boundary index before `currentIndex` using ICU word breaking.
    public static func previousWordIndex(in text: String, from currentIndex: Int) -> Int {
        guard currentIndex > 0 else { return 0 }
        let ranges = wordRanges(in: text)
        for range in ranges.reversed() {
            if range.lowerBound < currentIndex {
                return range.lowerBound
            }
        }
        return 0
    }
}
