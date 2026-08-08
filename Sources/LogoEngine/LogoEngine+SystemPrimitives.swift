import Foundation
import TextTransform

extension LogoEngine {
    /// System & Environment Primitives Evaluator (`evaluateSystemPrimitives`)
    ///
    /// ### Role & Architecture:
    /// - **Role**: Evaluates system state, environment queries, date/time formatting, and character code primitives.
    /// - **Primitives**: `DATE`, `TIME`, `ASCII`, `CHAR`, `STANDOUT`, `COUNT`, `SORT`
    /// - **Return Type**: `String?` (evaluated result string or `nil`).
    internal func evaluateSystemPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        case .date:
            index += 1
            var format = "yyyy-MM-dd"
            if index < tokens.count {
                let nextToken = tokens[index]
                if !LogoEngine.isKeyword(nextToken) && nextToken != "]" && nextToken != ")" {
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                } else {
                    index -= 1
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            let value = formatter.string(from: Date())
            setLastExpressionDateTime(value)
            return value

        case .time:
            index += 1
            var format = "HH:mm:ss"
            if index < tokens.count {
                let nextToken = tokens[index]
                if !LogoEngine.isKeyword(nextToken) && nextToken != "]" && nextToken != ")" {
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                } else {
                    index -= 1
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            let value = formatter.string(from: Date())
            setLastExpressionDateTime(value)
            return value

        case .count:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            let res: String
            switch p {
            case .list(let items), .array(let items): res = "\(items.count)"
            case .string(let s): res = "\(s.count)"
            }
            setLastExpressionString(res)
            return res

        case .ascii:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let cleanStr = unquote(v)
            if let firstScalar = cleanStr.unicodeScalars.first {
                return "\(firstScalar.value)"
            }
            return "0"

        case .char:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            if let code = Int(v), let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""

        case .standout:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return "**\(v)**"

        case .translit:
            index += 1
            let transformId = unquote(evaluateExpression(tokens, index: &index))
            if index + 1 < tokens.count {
                index += 1
            }
            let inputText = unquote(evaluateExpression(tokens, index: &index))
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
            return "\(heading)"

        case .readWord:
            index += 1
            var prompt = ""
            if index < tokens.count && !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]"
                && tokens[index] != ")"
            {
                prompt = unquote(evaluateExpression(tokens, index: &index))
            } else {
                index -= 1
            }
            return delegate?.logoEngine(self, readWordWithPrompt: prompt) ?? ""

        case .readChar:
            index += 1
            var prompt = ""
            if index < tokens.count && !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]"
                && tokens[index] != ")"
            {
                prompt = unquote(evaluateExpression(tokens, index: &index))
            } else {
                index -= 1
            }
            return delegate?.logoEngine(self, readCharWithPrompt: prompt) ?? ""

        default:
            return nil
        }
    }

    private func applyFixedTextTransform(_ transformId: String, _ tokens: [String], index: inout Int) -> String {
        index += 1
        let inputText = unquote(evaluateExpression(tokens, index: &index))
        return applyTextTransform(transformId, to: inputText)
    }

    private func applyTextTransform(_ transformId: String, to inputText: String) -> String {
        do {
            return try TextTransformer.apply(transformId, to: inputText)
        } catch {
            let message = "[\(error)]"
            lastError = message
            delegate?.logoEngine(self, performAction: .setStatusMessage(message))
            hasSetStatusMessage = true
            return ""
        }
    }

    private func applyTextCount(_ tokens: [String], index: inout Int, count: (String) -> Int) -> String {
        index += 1
        let inputText = unquote(evaluateExpression(tokens, index: &index))
        return "\(count(inputText))"
    }
}
