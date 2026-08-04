import Foundation

#if canImport(AppKit)
    import AppKit
#endif

#if os(Windows)
    import WinSDK
#endif

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
                let content = try? String(contentsOfFile: path, encoding: .utf8)
            {
                let words = content.components(separatedBy: .newlines)
                self.dictionary = Set(words.map { $0.lowercased() })
                return
            }
        }

        // Common fallback words if no system dictionary is present
        let fallbackWords = [
            "the", "be", "to", "of", "and", "a", "in", "is", "that", "have", "i",
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
            "inside", "outside",
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

#if canImport(AppKit)
    public final class AppleSpellCheckerEngine: SpellCheckerEngine {
        public var language: String

        private let checker = NSSpellChecker.shared
        private let documentTag: Int
        private let usesSystemChecker: Bool
        private let fallbackEngine: FallbackCheckerEngine
        private var ignoredWords: Set<String> = []
        private var userDictionary: Set<String> = []

        public init(language: String = "en_US") {
            self.language = language
            self.documentTag = NSSpellChecker.uniqueSpellDocumentTag()
            self.fallbackEngine = FallbackCheckerEngine(language: language)
            let probe = checker.checkSpelling(
                of: "hello",
                startingAt: 0,
                language: bcp47LanguageTag(language),
                wrap: false,
                inSpellDocumentWithTag: documentTag,
                wordCount: nil
            )
            self.usesSystemChecker = probe.location == NSNotFound
        }

        deinit {
            checker.closeSpellDocument(withTag: documentTag)
        }

        public func isCorrect(_ word: String) -> Bool {
            let clean = normalizedWord(word)
            if clean.isEmpty || clean.count <= 1 { return true }
            if ignoredWords.contains(clean) || userDictionary.contains(clean) { return true }
            guard usesSystemChecker else {
                return fallbackEngine.isCorrect(word)
            }

            let range = checker.checkSpelling(
                of: word,
                startingAt: 0,
                language: bcp47LanguageTag(language),
                wrap: false,
                inSpellDocumentWithTag: documentTag,
                wordCount: nil
            )
            return range.location == NSNotFound
        }

        public func suggestions(for word: String) -> [String] {
            let nsRange = NSRange(location: 0, length: (word as NSString).length)
            let guesses = checker.guesses(
                forWordRange: nsRange,
                in: word,
                language: bcp47LanguageTag(language),
                inSpellDocumentWithTag: documentTag
            )
            return guesses?.isEmpty == false ? guesses! : fallbackEngine.suggestions(for: word)
        }

        public func ignoreWord(_ word: String) {
            let clean = normalizedWord(word)
            ignoredWords.insert(clean)
            checker.ignoreWord(word, inSpellDocumentWithTag: documentTag)
            fallbackEngine.ignoreWord(word)
        }

        public func addWordToDictionary(_ word: String) {
            let clean = normalizedWord(word)
            userDictionary.insert(clean)
            fallbackEngine.addWordToDictionary(word)
        }
    }
#endif

public final class UnixSpellCheckerEngine: SpellCheckerEngine {
    public var language: String {
        didSet {
            commandLineChecker = CommandLineSpellChecker(language: language)
            loadDictionary()
        }
    }

    private var dictionary: Set<String> = []
    private var ignoredWords: Set<String> = []
    private var userDictionary: Set<String> = []
    private var commandLineChecker: CommandLineSpellChecker?

    public init(language: String = "en_US") {
        self.language = language
        self.commandLineChecker = CommandLineSpellChecker(language: language)
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
                let content = try? String(contentsOfFile: path, encoding: .utf8)
            {
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
        if let commandLineResult = commandLineChecker?.isCorrect(clean) {
            return commandLineResult
        }
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

private final class CommandLineSpellChecker {
    private let candidates: [(executable: URL, arguments: [String])]
    private var cache: [String: Bool] = [:]

    init?(language: String) {
        let normalized = language.replacingOccurrences(of: "-", with: "_")
        var found: [(URL, [String])] = []

        if let hunspell = Self.findExecutable("hunspell") {
            found.append((hunspell, ["-d", normalized, "-l"]))
            found.append((hunspell, ["-l"]))
        }
        if let aspell = Self.findExecutable("aspell") {
            found.append((aspell, ["--lang=\(normalized)", "list"]))
            found.append((aspell, ["list"]))
        }

        guard !found.isEmpty else { return nil }
        self.candidates = found
    }

    func isCorrect(_ word: String) -> Bool? {
        if let cached = cache[word] { return cached }

        for candidate in candidates {
            guard let result = run(candidate: candidate, word: word) else { continue }
            cache[word] = result
            return result
        }
        return nil
    }

    private func run(candidate: (executable: URL, arguments: [String]), word: String) -> Bool? {
        let process = Process()
        process.executableURL = candidate.executable
        process.arguments = candidate.arguments

        let input = Pipe()
        let output = Pipe()
        let error = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = error

        do {
            try process.run()
            input.fileHandleForWriting.write(Data((word + "\n").utf8))
            input.fileHandleForWriting.closeFile()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let misspellings = String(data: data, encoding: .utf8)?
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty } ?? []

        return !misspellings.contains(word.lowercased())
    }

    private static func findExecutable(_ name: String) -> URL? {
        let pathEntries = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        let candidates = pathEntries + ["/usr/bin", "/usr/local/bin", "/opt/homebrew/bin"]

        for directory in candidates {
            let path = URL(fileURLWithPath: directory).appendingPathComponent(name).path
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}

// MARK: - Windows Engine

public final class WindowsSpellCheckerEngine: SpellCheckerEngine {
    public var language: String {
        didSet {
            fallbackEngine.language = language
            #if os(Windows)
            configureSystemChecker()
            #endif
        }
    }

    private let fallbackEngine: FallbackCheckerEngine
    #if os(Windows)
    private var checker: UnsafeMutablePointer<WindowsISpellChecker>? = nil
    private var didInitializeCOM = false
    #endif

    public init(language: String = "en_US") {
        self.language = language
        self.fallbackEngine = FallbackCheckerEngine(language: language)
        #if os(Windows)
        configureSystemChecker()
        #endif
    }

    deinit {
        #if os(Windows)
        releaseSystemChecker()
        if didInitializeCOM {
            CoUninitialize()
        }
        #endif
    }

    public func isCorrect(_ word: String) -> Bool {
        if fallbackEngine.isCorrect(word) {
            return true
        }
        #if os(Windows)
        if let systemResult = systemIsCorrect(word) {
            return systemResult
        }
        #endif
        return fallbackEngine.isCorrect(word)
    }

    public func suggestions(for word: String) -> [String] {
        return fallbackEngine.suggestions(for: word)
    }

    public func ignoreWord(_ word: String) {
        #if os(Windows)
        if let checker {
            word.withCString(encodedAs: UTF16.self) { pWord in
                _ = checker.pointee.lpVtbl.pointee.Ignore(UnsafeMutableRawPointer(checker), pWord)
            }
        }
        #endif
        fallbackEngine.ignoreWord(word)
    }

    public func addWordToDictionary(_ word: String) {
        #if os(Windows)
        if let checker {
            word.withCString(encodedAs: UTF16.self) { pWord in
                _ = checker.pointee.lpVtbl.pointee.Add(UnsafeMutableRawPointer(checker), pWord)
            }
        }
        #endif
        fallbackEngine.addWordToDictionary(word)
    }

    #if os(Windows)
    private func configureSystemChecker() {
        releaseSystemChecker()

        let hr = CoInitializeEx(nil, DWORD(2))
        if hr >= 0 {
            didInitializeCOM = true
        } else if hr != HRESULT(bitPattern: 0x80010106) {
            return
        }

        var clsid = spellCheckerFactoryCLSID()
        var iid = spellCheckerFactoryIID()
        var rawFactory: UnsafeMutableRawPointer? = nil
        guard CoCreateInstance(&clsid, nil, DWORD(CLSCTX_INPROC_SERVER.rawValue), &iid, &rawFactory) >= 0,
            let rawFactory
        else {
            return
        }

        let factory = rawFactory.assumingMemoryBound(to: WindowsISpellCheckerFactory.self)
        defer { _ = factory.pointee.lpVtbl.pointee.Release(UnsafeMutableRawPointer(factory)) }

        let tag = bcp47LanguageTag(language)
        var supported = WindowsBool(false)
        let supportHR = tag.withCString(encodedAs: UTF16.self) { pTag in
            factory.pointee.lpVtbl.pointee.IsSupported(UnsafeMutableRawPointer(factory), pTag, &supported)
        }
        guard supportHR >= 0, supported.boolValue else { return }

        var rawChecker: UnsafeMutableRawPointer? = nil
        let createHR = tag.withCString(encodedAs: UTF16.self) { pTag in
            factory.pointee.lpVtbl.pointee.CreateSpellChecker(UnsafeMutableRawPointer(factory), pTag, &rawChecker)
        }
        guard createHR >= 0, let rawChecker else { return }
        checker = rawChecker.assumingMemoryBound(to: WindowsISpellChecker.self)
    }

    private func releaseSystemChecker() {
        if let checker {
            _ = checker.pointee.lpVtbl.pointee.Release(UnsafeMutableRawPointer(checker))
            self.checker = nil
        }
    }

    private func systemIsCorrect(_ word: String) -> Bool? {
        guard let checker else { return nil }

        var rawErrors: UnsafeMutableRawPointer? = nil
        let checkHR = word.withCString(encodedAs: UTF16.self) { pWord in
            checker.pointee.lpVtbl.pointee.Check(UnsafeMutableRawPointer(checker), pWord, &rawErrors)
        }
        guard checkHR >= 0, let rawErrors else { return nil }
        let errors = rawErrors.assumingMemoryBound(to: WindowsIEnumSpellingError.self)
        defer { _ = errors.pointee.lpVtbl.pointee.Release(UnsafeMutableRawPointer(errors)) }

        var rawSpellingError: UnsafeMutableRawPointer? = nil
        let nextHR = errors.pointee.lpVtbl.pointee.Next(UnsafeMutableRawPointer(errors), &rawSpellingError)
        guard nextHR >= 0 else { return nil }

        if let rawSpellingError {
            let spellingError = rawSpellingError.assumingMemoryBound(to: WindowsISpellingError.self)
            _ = spellingError.pointee.lpVtbl.pointee.Release(UnsafeMutableRawPointer(spellingError))
            return false
        }
        return true
    }
    #endif
}

#if os(Windows)
    private struct WindowsISpellingError {
        let lpVtbl: UnsafePointer<WindowsISpellingErrorVtbl>
    }

    private struct WindowsISpellingErrorVtbl {
        let QueryInterface: UnsafeRawPointer?
        let AddRef: UnsafeRawPointer?
        let Release: @convention(c) (UnsafeMutableRawPointer?) -> ULONG
        let getStartIndex: UnsafeRawPointer?
        let getLength: UnsafeRawPointer?
        let getCorrectiveAction: UnsafeRawPointer?
        let getReplacement: UnsafeRawPointer?
    }

    private struct WindowsIEnumSpellingError {
        let lpVtbl: UnsafePointer<WindowsIEnumSpellingErrorVtbl>
    }

    private struct WindowsIEnumSpellingErrorVtbl {
        let QueryInterface: UnsafeRawPointer?
        let AddRef: UnsafeRawPointer?
        let Release: @convention(c) (UnsafeMutableRawPointer?) -> ULONG
        let Next:
            @convention(c) (
                UnsafeMutableRawPointer?,
                UnsafeMutablePointer<UnsafeMutableRawPointer?>?
            ) -> HRESULT
    }

    private struct WindowsISpellChecker {
        let lpVtbl: UnsafePointer<WindowsISpellCheckerVtbl>
    }

    private struct WindowsISpellCheckerVtbl {
        let QueryInterface: UnsafeRawPointer?
        let AddRef: UnsafeRawPointer?
        let Release: @convention(c) (UnsafeMutableRawPointer?) -> ULONG
        let getLanguageTag: UnsafeRawPointer?
        let Check:
            @convention(c) (
                UnsafeMutableRawPointer?,
                UnsafePointer<WCHAR>?,
                UnsafeMutablePointer<UnsafeMutableRawPointer?>?
            ) -> HRESULT
        let Suggest: UnsafeRawPointer?
        let Add: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<WCHAR>?) -> HRESULT
        let Ignore: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<WCHAR>?) -> HRESULT
        let AutoCorrect: UnsafeRawPointer?
        let GetOptionValue: UnsafeRawPointer?
        let getOptionIds: UnsafeRawPointer?
        let getId: UnsafeRawPointer?
        let getLocalizedName: UnsafeRawPointer?
        let addSpellCheckerChanged: UnsafeRawPointer?
        let removeSpellCheckerChanged: UnsafeRawPointer?
        let GetOptionDescription: UnsafeRawPointer?
        let ComprehensiveCheck: UnsafeRawPointer?
    }

    private struct WindowsISpellCheckerFactory {
        let lpVtbl: UnsafePointer<WindowsISpellCheckerFactoryVtbl>
    }

    private struct WindowsISpellCheckerFactoryVtbl {
        let QueryInterface: UnsafeRawPointer?
        let AddRef: UnsafeRawPointer?
        let Release: @convention(c) (UnsafeMutableRawPointer?) -> ULONG
        let getSupportedLanguages: UnsafeRawPointer?
        let IsSupported:
            @convention(c) (
                UnsafeMutableRawPointer?,
                UnsafePointer<WCHAR>?,
                UnsafeMutablePointer<WindowsBool>?
            ) -> HRESULT
        let CreateSpellChecker:
            @convention(c) (
                UnsafeMutableRawPointer?,
                UnsafePointer<WCHAR>?,
                UnsafeMutablePointer<UnsafeMutableRawPointer?>?
            ) -> HRESULT
    }

    private func spellCheckerFactoryCLSID() -> GUID {
        makeGUID(
            data1: 0x7ab36653,
            data2: 0x1796,
            data3: 0x484b,
            data4: (0xbd, 0xfa, 0xe7, 0x4f, 0x1d, 0xb7, 0xc1, 0xdc)
        )
    }

    private func spellCheckerFactoryIID() -> GUID {
        makeGUID(
            data1: 0x8e018a9d,
            data2: 0x2415,
            data3: 0x4677,
            data4: (0xbf, 0x08, 0x79, 0x4e, 0xa6, 0x1f, 0x94, 0xbb)
        )
    }

    private func makeGUID(
        data1: ULONG,
        data2: USHORT,
        data3: USHORT,
        data4: (UCHAR, UCHAR, UCHAR, UCHAR, UCHAR, UCHAR, UCHAR, UCHAR)
    ) -> GUID {
        var guid = GUID()
        guid.Data1 = data1
        guid.Data2 = data2
        guid.Data3 = data3
        guid.Data4 = data4
        return guid
    }
#endif

private func normalizedWord(_ word: String) -> String {
    word.lowercased().trimmingCharacters(in: .punctuationCharacters)
}

private func bcp47LanguageTag(_ language: String) -> String {
    language.replacingOccurrences(of: "_", with: "-")
}
