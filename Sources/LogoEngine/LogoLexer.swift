import Foundation

/// Shared lexical rules for LOGO scripts and LOGO value literals.
enum LogoLexer {
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
