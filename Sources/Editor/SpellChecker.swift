import Foundation

/// Spell Checker (^T / F12) manager using platform engines and Markdown context awareness.
public final class SpellChecker {
    public var engine: SpellCheckerEngine
    public private(set) var ignoredWords: Set<String> = []

    public init(language: String = "en_US") {
        #if canImport(AppKit)
            self.engine = AppleSpellCheckerEngine(language: language)
        #elseif os(Windows)
            self.engine = WindowsSpellCheckerEngine(language: language)
        #else
            self.engine = UnixSpellCheckerEngine(language: language)
        #endif
    }

    public func setLanguage(_ language: String) {
        engine.language = language
    }

    public func isCorrect(_ word: String) -> Bool {
        for scalar in word.unicodeScalars {
            // Ignore non-ASCII (e.g. CJK Chinese, Japanese, Korean) or numeric digits
            if scalar.value > 127 || (scalar.value >= 48 && scalar.value <= 57) {
                return true
            }
        }

        let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if cleanWord.isEmpty || cleanWord.count <= 1 { return true }
        if ignoredWords.contains(cleanWord) { return true }
        return engine.isCorrect(word)
    }

    public func ignoreWord(_ word: String) {
        let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        ignoredWords.insert(cleanWord)
        engine.ignoreWord(word)
    }

    public func suggestions(for word: String) -> [String] {
        return engine.suggestions(for: word)
    }

    /// Finds misspelled words in the text buffer starting at (startingLine, startingCol),
    /// applying format-specific code block and inline code skipping based on document syntax or file extension.
    public func findNextMisspelled(
        in buffer: TextBuffer,
        startingAt startingLine: Int = 0,
        startingCol: Int = 0,
        syntaxName: String? = nil
    ) -> MisspelledMatch? {
        guard !buffer.lines.isEmpty else { return nil }

        let normalizedSyntax = (syntaxName ?? detectFormatFromFilePath(buffer.filePath)).lowercased()
        var inCodeBlock = false

        for lIdx in 0..<buffer.lines.count {
            let line = buffer.lines[lIdx]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lowerTrimmed = trimmed.lowercased()

            // Format-specific code block boundary detection
            if normalizedSyntax.contains("org") {
                if lowerTrimmed.hasPrefix("#+begin_src") || lowerTrimmed.hasPrefix("#+begin_example") {
                    inCodeBlock = true
                    continue
                }
                if lowerTrimmed.hasPrefix("#+end_src") || lowerTrimmed.hasPrefix("#+end_example") {
                    inCodeBlock = false
                    continue
                }
            } else if normalizedSyntax.contains("asciidoc") || normalizedSyntax.contains("adoc") {
                if lowerTrimmed.hasPrefix("----") || lowerTrimmed.hasPrefix("....") {
                    inCodeBlock.toggle()
                    continue
                }
            } else if normalizedSyntax.contains("rest") || normalizedSyntax.contains("rst") {
                if lowerTrimmed.hasPrefix(".. code-block::") || lowerTrimmed.hasPrefix(".. code::") {
                    inCodeBlock = true
                    continue
                }
            } else {
                // Default / Markdown
                if lowerTrimmed.hasPrefix("```") || lowerTrimmed.hasPrefix("~~~") {
                    inCodeBlock.toggle()
                    continue
                }
            }

            // Skip lines inside code blocks
            if inCodeBlock { continue }

            // Skip lines before startingLine
            if lIdx < startingLine { continue }

            var currentWord = ""
            var wordStartCol = 0
            var inInlineCode = false

            for (cIdx, ch) in line.enumerated() {
                if lIdx == startingLine && cIdx < startingCol { continue }

                // Format-specific inline code delimiter matching
                let isInlineCodeChar: Bool
                if normalizedSyntax.contains("org") {
                    isInlineCodeChar = (ch == "=" || ch == "~")
                } else if normalizedSyntax.contains("asciidoc") || normalizedSyntax.contains("adoc") {
                    isInlineCodeChar = (ch == "`" || ch == "+")
                } else {
                    isInlineCodeChar = (ch == "`")
                }

                if isInlineCodeChar {
                    if !currentWord.isEmpty {
                        if !isCorrect(currentWord) {
                            return MisspelledMatch(line: lIdx, col: wordStartCol, word: currentWord)
                        }
                        currentWord = ""
                    }
                    inInlineCode.toggle()
                    continue
                }

                if inInlineCode { continue }

                // Only scan ASCII English letters
                if ch.isASCII && ch.isLetter {
                    if currentWord.isEmpty { wordStartCol = cIdx }
                    currentWord.append(ch)
                } else {
                    if !currentWord.isEmpty {
                        if !isCorrect(currentWord) {
                            return MisspelledMatch(line: lIdx, col: wordStartCol, word: currentWord)
                        }
                        currentWord = ""
                    }
                }
            }

            if !currentWord.isEmpty && !isCorrect(currentWord) {
                return MisspelledMatch(line: lIdx, col: wordStartCol, word: currentWord)
            }
        }

        return nil
    }

    private func detectFormatFromFilePath(_ filePath: String?) -> String {
        guard let path = filePath else { return "markdown" }
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "org": return "org-mode"
        case "adoc", "asciidoc": return "asciidoc"
        case "rst", "rest": return "restructuredtext"
        default: return "markdown"
        }
    }
}
