import Foundation

/// Shared tokenization rules for LOGO scripts and LOGO value literals.
enum LogoTokenizer {
    static func tokenizeInfixOperators(_ rawTokens: [String]) -> [String] {
        rawTokens.flatMap { token in
            guard !((token.hasPrefix("\"") && token.hasSuffix("\"")) || (token.hasPrefix("|") && token.hasSuffix("|"))) else { return [token] }
            var parts: [String] = []
            var current = ""
            var index = token.startIndex
            while index < token.endIndex {
                let remaining = token[index...]
                if ["==", "!=", "<=", ">="].contains(where: { remaining.hasPrefix($0) }) {
                    if !current.isEmpty { parts.append(current); current = "" }
                    let op = String(remaining.prefix(2)); parts.append(op); index = token.index(index, offsetBy: 2)
                } else if "=<>".contains(token[index]) {
                    if !current.isEmpty { parts.append(current); current = "" }
                    parts.append(String(token[index])); index = token.index(after: index)
                } else { current.append(token[index]); index = token.index(after: index) }
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
                if !startsAnotherWord && sawSpace { return true }
            }
            previous = character
            index = source.index(after: index)
        }
        return false
    }
}
