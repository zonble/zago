import Foundation
import TextTransform

private func systemOptionalArgumentBoundary(_ token: String) -> Bool {
    LogoEngine.isKeyword(token) || token == "]" || token == ")"
}

extension LogoEngine {
    /// System & Environment Primitives Evaluator (`evaluateSystemPrimitives`)
    ///
    /// Evaluates system state, character operations, text analysis/transformation, and console input primitives.
    internal func evaluateSystemPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = parsePrimitive(tokens[index]) else { return nil }

        switch prim {
        case .count:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            let res: String
            switch p {
            case .list(let items), .array(let items): res = "\(items.count)"
            case .measurement: res = "2"
            case .date: res = "\(p.stringValue.count)"
            case .string(let s): res = "\(s.count)"
            }
            setLastExpressionString(res)
            return res

        case .ascii:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let cleanStr = unquote(v)
            if let firstScalar = cleanStr.unicodeScalars.first {
                return "\(firstScalar.value)"
            }
            return "0"

        case .char:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            if let code = Int(v), let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""

        case .standout:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            return "**\(v)**"

        case .translit:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let transformId = unquote(reader.nextExpression())
            let inputText = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return applyTextTransform(transformId, to: inputText)

        case .transformToHans:
            return applyFixedTextTransform("Hant-Hans", tokens, index: &index)

        case .transformToHant:
            return applyFixedTextTransform("Hans-Hant", tokens, index: &index)

        case .transformToLatin:
            return applyFixedTextTransform("Any-Latin", tokens, index: &index)

        case .transformToHiragana:
            return applyFixedTextTransform("Any-Hiragana", tokens, index: &index)

        case .transformToKatakana:
            return applyFixedTextTransform("Any-Katakana", tokens, index: &index)

        case .transformToRomaji:
            return applyFixedTextTransform("Any-Latin", tokens, index: &index)

        case .spacingCJK:
            return applyFixedTextTransform("Zago-CJK-Spacing", tokens, index: &index)

        case .charCount:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.characterCount(in: $0) }

        case .charCountCJK:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.cjkCharacterCount(in: $0) }

        case .charCountWords:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.wordCount(in: $0) }

        case .charCountEmoji:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.emojiCount(in: $0) }

        case .charCountLines:
            return applyTextCount(tokens, index: &index) { TextAnalyzer.lineCount(in: $0) }

        case .headingPrimitive:
            return heading.rawValue

        case .readWord:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            var prompt = ""
            if let value = reader.nextOptionalExpression(isBoundary: systemOptionalArgumentBoundary) {
                prompt = unquote(value)
            }
            reader.commit(to: &index)
            guard let value = delegate?.logoEngine(self, readWordWithPrompt: prompt) else {
                reportError(LogoError(code: 1, message: "[LOGO Error: Stopped by user]"), token: "READWORD")
                return ""
            }
            return value

        case .readChar:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            var prompt = ""
            if let value = reader.nextOptionalExpression(isBoundary: systemOptionalArgumentBoundary) {
                prompt = unquote(value)
            }
            reader.commit(to: &index)
            guard let value = delegate?.logoEngine(self, readCharWithPrompt: prompt) else {
                reportError(LogoError(code: 1, message: "[LOGO Error: Stopped by user]"), token: "READCHAR")
                return ""
            }
            return value

        default:
            return nil
        }
    }

    private func applyFixedTextTransform(_ transformId: String, _ tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        let inputText = unquote(reader.nextExpression())
        reader.commit(to: &index)
        return applyTextTransform(transformId, to: inputText)
    }

    private func applyTextTransform(_ transformId: String, to inputText: String) -> String {
        do {
            return try TextTransformer.apply(transformId, to: inputText)
        } catch {
            let message = "[\(error)]"
            lastError = LogoError(code: 1, message: message)
            delegate?.logoEngine(self, performAction: .setStatusMessage(message))
            hasSetStatusMessage = true
            return ""
        }
    }

    private func applyTextCount(_ tokens: [String], index: inout Int, count: (String) -> Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        let inputText = unquote(reader.nextExpression())
        reader.commit(to: &index)
        return "\(count(inputText))"
    }
}
