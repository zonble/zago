import Foundation

/// Lightweight Spell Checker (^T / F12) using dictionary lookup and interactive word replacement.
public final class SpellChecker {
    private var dictionary: Set<String> = []
    private var isDictionaryLoaded = false

    public init() {
        loadDictionary()
    }

    /// Loads system dictionary words (/usr/share/dict/words) or fallback word set.
    private func loadDictionary() {
        let candidatePaths = [
            "/usr/share/dict/words",
            "/usr/dict/words",
            "/usr/share/dict/web2"
        ]

        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path),
               let content = try? String(contentsOfFile: path, encoding: .utf8) {
                let words = content.components(separatedBy: .newlines)
                self.dictionary = Set(words.map { $0.lowercased() })
                self.isDictionaryLoaded = true
                return
            }
        }

        // Fallback common English word set if system dictionary is missing
        let fallbackWords = [
            "the", "be", "to", "of", "and", "a", "in", "that", "have", "i",
            "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
            "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
            "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
            "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
            "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
            "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
            "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
            "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
            "even", "new", "want", "because", "any", "these", "give", "day", "most", "us",
            "hello", "world", "swift", "editor", "nano", "pico", "file", "text", "line", "code", "buffer"
        ]
        self.dictionary = Set(fallbackWords)
        self.isDictionaryLoaded = true
    }

    /// Checks whether a word is spelled correctly (skips CJK and non-ASCII characters).
    public func isCorrect(_ word: String) -> Bool {
        for scalar in word.unicodeScalars {
            // Ignore non-ASCII (e.g. CJK Chinese, Japanese, Korean) or numeric digits
            if scalar.value > 127 || (scalar.value >= 48 && scalar.value <= 57) {
                return true
            }
        }

        let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if cleanWord.isEmpty || cleanWord.count <= 1 { return true }
        return dictionary.contains(cleanWord)
    }

    /// Finds misspelled words in buffer, skipping CJK and non-ASCII text.
    public func findNextMisspelled(in buffer: TextBuffer) -> (line: Int, col: Int, word: String)? {
        let range = 0..<buffer.lines.count
        for lIdx in range {
            let line = buffer.lines[lIdx]
            var currentWord = ""
            var wordStartCol = 0

            for (cIdx, ch) in line.enumerated() {
                // Only scan ASCII English letters for spell checking
                if ch.isASCII && ch.isLetter {
                    if currentWord.isEmpty { wordStartCol = cIdx }
                    currentWord.append(ch)
                } else {
                    if !currentWord.isEmpty {
                        if !isCorrect(currentWord) {
                            return (line: lIdx, col: wordStartCol, word: currentWord)
                        }
                        currentWord = ""
                    }
                }
            }
            if !currentWord.isEmpty && !isCorrect(currentWord) {
                return (line: lIdx, col: wordStartCol, word: currentWord)
            }
        }
        return nil
    }
}
