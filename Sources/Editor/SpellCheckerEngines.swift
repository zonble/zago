import Foundation

/// Represents a misspelled word match in a text buffer.
public struct MisspelledMatch {
    public let line: Int
    public let col: Int
    public let word: String

    public init(line: Int, col: Int, word: String) {
        self.line = line
        self.col = col
        self.word = word
    }
}

/// Abstract protocol for platform-specific spell checking engines.
public protocol SpellCheckerEngine: AnyObject {
    /// Active language tag (e.g. "en_US", "de_DE", "fr_FR")
    var language: String { get set }

    /// Checks if a word is spelled correctly
    func isCorrect(_ word: String) -> Bool

    /// Generates suggestion candidates for a misspelled word
    func suggestions(for word: String) -> [String]

    /// Temporarily ignores a word for the current editing session
    func ignoreWord(_ word: String)

    /// Adds a word to the user dictionary
    func addWordToDictionary(_ word: String)
}

// MARK: - Fallback / Embedded Engine

public final class FallbackCheckerEngine: SpellCheckerEngine {
    public var language: String {
        didSet { loadDictionaryForLanguage() }
    }

    fileprivate(set) var dictionary: Set<String> = []
    private var userDictionary: Set<String> = []
    private var ignoredWords: Set<String> = []

    public init(language: String = "en_US") {
        self.language = language
        loadDictionaryForLanguage()
    }

    private func loadDictionaryForLanguage() {
        dictionary.removeAll()

        let candidatePaths = [
            "/usr/share/dict/words",
            "/usr/dict/words",
            "/usr/share/dict/web2",
        ]

        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path),
               let content = try? String(contentsOfFile: path, encoding: .utf8) {
                let words = content.components(separatedBy: .newlines)
                self.dictionary = Set(words.map { $0.lowercased() })
                return
            }
        }

        // Common fallback words if no system dictionary is present
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
            "hello", "world", "swift", "editor", "nano", "pico", "file", "text", "line", "code", "buffer",
            "project", "document", "function", "variable", "command", "window", "terminal", "table", "canvas",
        ]
        self.dictionary = Set(fallbackWords)
    }

    public func isCorrect(_ word: String) -> Bool {
        let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if cleanWord.isEmpty || cleanWord.count <= 1 { return true }
        if ignoredWords.contains(cleanWord) || userDictionary.contains(cleanWord) { return true }
        return dictionary.contains(cleanWord)
    }

    public func suggestions(for word: String) -> [String] {
        let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        guard !clean.isEmpty else { return [] }

        // Simple prefix match + edit distance heuristic
        return Array(dictionary.filter { $0.hasPrefix(clean.prefix(2)) && abs($0.count - clean.count) <= 2 }.prefix(5))
    }

    public func ignoreWord(_ word: String) {
        let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        ignoredWords.insert(clean)
    }

    public func addWordToDictionary(_ word: String) {
        let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        userDictionary.insert(clean)
    }
}

// MARK: - Unix / Hunspell Engine

public final class UnixSpellCheckerEngine: SpellCheckerEngine {
    public var language: String {
        didSet { loadDictionary() }
    }

    private var dictionary: Set<String> = []
    private var ignoredWords: Set<String> = []
    private var userDictionary: Set<String> = []

    public init(language: String = "en_US") {
        self.language = language
        loadDictionary()
    }

    private func loadDictionary() {
        dictionary.removeAll()
        let normalizedLang = language.replacingOccurrences(of: "-", with: "_")

        let candidatePaths = [
            "/usr/share/hunspell/\(normalizedLang).dic",
            "/usr/share/myspell/\(normalizedLang).dic",
            "/usr/share/myspell/dicts/\(normalizedLang).dic",
            "\(NSHomeDirectory())/.hunspell/\(normalizedLang).dic",
            "/usr/share/dict/words",
            "/usr/dict/words",
        ]

        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path),
               let content = try? String(contentsOfFile: path, encoding: .utf8) {
                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                    // Strip Hunspell flags (e.g. word/FLAGS)
                    let wordPart = trimmed.components(separatedBy: "/").first ?? trimmed
                    dictionary.insert(wordPart.lowercased())
                }
                if !dictionary.isEmpty { return }
            }
        }

        // Fallback to basic word list if no Hunspell or system dictionary file was found
        let fallback = FallbackCheckerEngine(language: language)
        self.dictionary = fallback.dictionary
    }

    public func isCorrect(_ word: String) -> Bool {
        let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if clean.isEmpty || clean.count <= 1 { return true }
        if ignoredWords.contains(clean) || userDictionary.contains(clean) { return true }
        return dictionary.contains(clean)
    }

    public func suggestions(for word: String) -> [String] {
        let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        guard !clean.isEmpty else { return [] }
        return Array(dictionary.filter { $0.hasPrefix(clean.prefix(2)) && abs($0.count - clean.count) <= 2 }.prefix(5))
    }

    public func ignoreWord(_ word: String) {
        let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        ignoredWords.insert(clean)
    }

    public func addWordToDictionary(_ word: String) {
        let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        userDictionary.insert(clean)
    }
}

// MARK: - Windows Engine

public final class WindowsSpellCheckerEngine: SpellCheckerEngine {
    public var language: String {
        didSet { fallbackEngine.language = language }
    }

    private let fallbackEngine: FallbackCheckerEngine

    public init(language: String = "en_US") {
        self.language = language
        self.fallbackEngine = FallbackCheckerEngine(language: language)
    }

    public func isCorrect(_ word: String) -> Bool {
        // Fallback to dictionary engine for cross-platform consistency
        return fallbackEngine.isCorrect(word)
    }

    public func suggestions(for word: String) -> [String] {
        return fallbackEngine.suggestions(for: word)
    }

    public func ignoreWord(_ word: String) {
        fallbackEngine.ignoreWord(word)
    }

    public func addWordToDictionary(_ word: String) {
        fallbackEngine.addWordToDictionary(word)
    }
}
