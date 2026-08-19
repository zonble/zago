import Foundation
import Drawing

public struct LogoToken: Equatable, Sendable {
    public let text: String
    public let sourceRange: Range<Int>

    public init(text: String, sourceRange: Range<Int>) {
        self.text = text
        self.sourceRange = sourceRange
    }
}

/// Shared tokenization rules for LOGO scripts and LOGO value literals.
public enum LogoTokenizer {
    static func tokenizeValueList(_ source: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var depth = 0
        var inQuotedString = false
        var inVerticalBarString = false
        var escaped = false
        var index = source.startIndex
        func flush() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { tokens.append(trimmed) }
            current = ""
        }
        while index < source.endIndex {
            let character = source[index]
            if escaped {
                current.append(character)
                escaped = false
            } else if character == "\\" {
                current.append(character)
                escaped = true
            } else if character == "|" && !inQuotedString {
                inVerticalBarString.toggle()
                current.append(character)
            } else if character == "\"" && !inVerticalBarString {
                if !inQuotedString && hasMatchingMultiWordClosingQuote(in: source, startingAt: index) {
                    inQuotedString = true
                } else if inQuotedString {
                    inQuotedString = false
                }
                current.append(character)
            } else if (character == "[" || character == "{") && !inQuotedString && !inVerticalBarString {
                depth += 1
                current.append(character)
            } else if (character == "]" || character == "}") && !inQuotedString && !inVerticalBarString && depth > 0 {
                depth -= 1
                current.append(character)
            } else if character.isWhitespace && depth == 0 && !inQuotedString && !inVerticalBarString {
                flush()
            } else {
                current.append(character)
            }
            index = source.index(after: index)
        }
        flush()
        return tokens
    }

    public static func tokenize(_ script: String) -> [String] {
        tokenizeTokens(script).map(\.text)
    }

    static func tokenizeTokens(_ script: String) -> [LogoToken] {
        let tokenTexts = tokenizeScript(script)
        var searchStart = script.startIndex
        return tokenTexts.compactMap { text in
            guard let range = script.range(of: text, range: searchStart..<script.endIndex) else { return nil }
            let start = script.distance(from: script.startIndex, to: range.lowerBound)
            let end = script.distance(from: script.startIndex, to: range.upperBound)
            searchStart = range.upperBound
            return LogoToken(text: text, sourceRange: start..<end)
        }
    }

    private static func tokenizeScript(_ script: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        let operatorDelimiters = Set(LogoOperator.allCases.filter(\.isArithmetic).compactMap { $0.rawValue.first })
        let bracketDelimiters: Set<Character> = ["[", "]", "{", "}", "(", ")"]
        let delimiters = bracketDelimiters.union(operatorDelimiters)
        var index = script.startIndex
        func flush() {
            if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }
        while index < script.endIndex {
            let character = script[index]
            if character == "\"" {
                flush()
                current.append(character)
                if hasMatchingMultiWordClosingQuote(in: script, startingAt: index) {
                    index = script.index(after: index)
                    while index < script.endIndex {
                        current.append(script[index])
                        let ch = script[index]
                        index = script.index(after: index)
                        if ch == "\"" { break }
                    }
                    flush()
                } else {
                    index = script.index(after: index)
                    var parenDepth = 0
                    while index < script.endIndex {
                        let ch = script[index]
                        if ch.isWhitespace { break }
                        if ch == "[" || ch == "]" || ch == "{" || ch == "}" { break }
                        if ch == "(" {
                            parenDepth += 1
                        } else if ch == ")" {
                            if parenDepth > 0 {
                                parenDepth -= 1
                            } else {
                                break
                            }
                        }
                        current.append(ch)
                        index = script.index(after: index)
                    }
                    flush()
                }
            } else if character == "|" {
                flush()
                current.append(character)
                index = script.index(after: index)
                var escaped = false
                while index < script.endIndex {
                    let inner = script[index]
                    current.append(inner)
                    index = script.index(after: index)
                    if inner == "\\" && !escaped {
                        escaped = true
                    } else {
                        if inner == "|" && !escaped { break }
                        escaped = false
                    }
                }
                flush()
            } else if character == ";" {
                flush()
                index = script.index(after: index)
                while index < script.endIndex && !script[index].isNewline {
                    index = script.index(after: index)
                }
            } else if character == "-", current.isEmpty,
                let next = script.index(index, offsetBy: 1, limitedBy: script.endIndex), next < script.endIndex,
                script[next].isNumber
            {
                current.append(character)
                index = script.index(after: index)
            } else if current.isEmpty, let dslToken = extractStyleDSLToken(from: script, startingAt: index) {
                tokens.append(dslToken.text)
                index = dslToken.endIndex
            } else if delimiters.contains(character) {
                flush()
                tokens.append(String(character))
                index = script.index(after: index)
            } else if character.isWhitespace {
                flush()
                index = script.index(after: index)
            } else {
                current.append(character)
                index = script.index(after: index)
            }
        }
        flush()
        return tokenizeInfixOperators(tokens)
    }

    private static func extractStyleDSLToken(from script: String, startingAt index: String.Index) -> (text: String, endIndex: String.Index)? {
        var peek = index
        while peek < script.endIndex {
            let ch = script[peek]
            if ch.isWhitespace || ch == "[" || ch == "]" || ch == "{" || ch == "}" || ch == "(" || ch == ";" {
                break
            }
            peek = script.index(after: peek)
        }
        let candidate = String(script[index..<peek])
        guard candidate.count > 1 else { return nil }
        if StyleDSL.parseBoxStyle(candidate) != nil || StyleDSL.parseLineStyle(candidate) != nil {
            return (candidate, peek)
        }
        return nil
    }

    static func tokenizeInfixOperators(_ rawTokens: [String]) -> [String] {
        rawTokens.flatMap { word in
            guard !(word.hasPrefix("\"") || word.hasPrefix("|") || StyleDSL.parseLineStyle(word) != nil || StyleDSL.parseBoxStyle(word) != nil)
            else { return [word] }
            var parts: [String] = []
            var current = ""
            var index = word.startIndex
            while index < word.endIndex {
                let remaining = word[index...]
                if let `operator` = LogoOperator.allCases
                    .filter(\.isComparison)
                    .map(\.rawValue)
                    .sorted(by: { $0.count > $1.count })
                    .first(where: { remaining.hasPrefix($0) })
                {
                    if !current.isEmpty {
                        parts.append(current)
                        current = ""
                    }
                    parts.append(`operator`)
                    index = word.index(index, offsetBy: `operator`.count)
                } else {
                    current.append(word[index])
                    index = word.index(after: index)
                }
            }
            if !current.isEmpty { parts.append(current) }
            return parts
        }
    }

    static func hasMatchingMultiWordClosingQuote(in source: String, startingAt quoteIndex: String.Index) -> Bool {
        var index = source.index(after: quoteIndex)
        var previous: Character = "\""
        var depth = 0
        var sawSpace = false

        while index < source.endIndex {
            let character = source[index]
            if character == "\n" || character == "\r" { return false }
            if character == "[" || character == "{" {
                depth += 1
            } else if (character == "]" || character == "}") && depth > 0 {
                depth -= 1
            } else if character.isWhitespace && depth == 0 {
                sawSpace = true
            } else if character == "\"" && depth == 0 {
                let next = source.index(after: index)
                let nextCharacter: Character = next < source.endIndex ? source[next] : " "
                let startsAnotherWord =
                    (previous.isWhitespace || previous == "[" || previous == "{")
                    && !nextCharacter.isWhitespace && nextCharacter != "]" && nextCharacter != "}"
                if startsAnotherWord && sawSpace { return false }
                if !startsAnotherWord { return true }
            }
            previous = character
            index = source.index(after: index)
        }
        return false
    }
}
