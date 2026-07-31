import Foundation

extension LogoEngine {
    private func isExpressionArgumentBoundary(_ token: String) -> Bool {
        LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
    }

    private func consumeOptionalEditingIntArgument(_ tokens: [String], index: inout Int) -> Int? {
        index += 1
        guard index < tokens.count else {
            index -= 1
            return nil
        }
        guard !isExpressionArgumentBoundary(tokens[index]) else {
            index -= 1
            return nil
        }
        guard let value = parseUnquotedIntArgument(tokens, index: &index) else {
            return nil
        }
        return value
    }

    private func consumeExpressionArguments(
        _ tokens: [String],
        index: inout Int,
        consume: (String) -> Void
    ) {
        var consumedAny = false

        while index < tokens.count {
            if isExpressionArgumentBoundary(tokens[index]) {
                if !consumedAny { index -= 1 }
                break
            }

            let value = evaluateExpression(tokens, index: &index)
            consume(value)
            consumedAny = true

            guard index + 1 < tokens.count else { break }
            guard !isExpressionArgumentBoundary(tokens[index + 1]) else { break }
            index += 1
        }
    }

    /// Executes Logo editor text manipulation and buffer management statement commands (.type, .show, .move, .cut, etc.).
    /// Returns `true` if the primitive was handled by this module, `false` otherwise.
    internal func executeEditingCommand(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> Bool {
        guard let delegate = self.delegate else { return false }

        switch prim {
        case .type:
            index += 1
            consumeExpressionArguments(tokens, index: &index) { text in
                delegate.logoEngine(self, performAction: .insertText(text))
            }
            return true

        case .show:
            index += 1
            var parts: [String] = []
            consumeExpressionArguments(tokens, index: &index) { text in
                parts.append(text)
            }
            let msgText = parts.joined(separator: " ")
            delegate.logoEngine(self, performAction: .setStatusMessage(msgText))
            hasSetStatusMessage = true
            return true

        case .delete:
            let count = consumeOptionalEditingIntArgument(tokens, index: &index) ?? 1
            for _ in 0..<count {
                delegate.logoEngine(self, performAction: .deleteChar)
            }
            return true

        case .backspace:
            let count = consumeOptionalEditingIntArgument(tokens, index: &index) ?? 1
            for _ in 0..<count {
                delegate.logoEngine(self, performAction: .backspaceChar)
            }
            return true

        case .deleteLine:
            index += 1
            var count = 1
            if index < tokens.count {
                let nextToken = tokens[index]
                if !LogoEngine.isKeyword(nextToken) && nextToken != "]" {
                    if let parsedCount = parseUnquotedIntArgument(tokens, index: &index) {
                        count = max(1, min(parsedCount, 1000))
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
            } else {
                index -= 1
            }
            for _ in 0..<count {
                delegate.logoEngine(self, performAction: .deleteLine)
            }
            return true

        case .top:
            delegate.logoEngine(self, performAction: .updateLineIndex(0))
            delegate.logoEngine(self, performAction: .updateColumnIndex(0))
            return true

        case .bottom:
            let totalLines = (delegate.logoEngine(self, queryState: .lineCount) as? Int) ?? 1
            let lastLine = max(0, totalLines - 1)
            delegate.logoEngine(self, performAction: .updateLineIndex(lastLine))
            delegate.logoEngine(self, performAction: .moveEnd)
            return true

        case .lineStart:
            delegate.logoEngine(self, performAction: .moveHome)
            return true

        case .lineEnd:
            delegate.logoEngine(self, performAction: .moveEnd)
            return true

        case .appendText:
            index += 1
            delegate.logoEngine(self, performAction: .moveEnd)
            consumeExpressionArguments(tokens, index: &index) { text in
                delegate.logoEngine(self, performAction: .insertText(text))
            }
            return true

        case .prependText:
            index += 1
            delegate.logoEngine(self, performAction: .moveHome)
            consumeExpressionArguments(tokens, index: &index) { text in
                delegate.logoEngine(self, performAction: .insertText(text))
            }
            return true

        case .changeText:
            index += 1
            if index < tokens.count {
                let oldText = evaluateExpression(tokens, index: &index)
                if index + 1 < tokens.count && !LogoEngine.isStatementCommand(tokens[index + 1]) && tokens[index + 1] != "]" {
                    index += 1
                    let newText = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, performAction: .replaceText(old: oldText, new: newText))
                }
            }
            return true

        case .joinLine:
            let separator = optionalCommandArgument(tokens, index: &index) ?? ""
            delegate.logoEngine(self, performAction: .joinLine(separator: separator))
            return true

        case .splitLine:
            delegate.logoEngine(self, performAction: .insertNewline)
            return true

        case .indentLines:
            let levels = consumeOptionalEditingIntArgument(tokens, index: &index) ?? 1
            delegate.logoEngine(self, performAction: .indentLines(levels: levels))
            return true

        case .outdentLines:
            let levels = consumeOptionalEditingIntArgument(tokens, index: &index) ?? 1
            delegate.logoEngine(self, performAction: .outdentLines(levels: levels))
            return true

        case .move:
            index += 1
            if index < tokens.count {
                let dir = tokens[index].uppercased()
                switch dir {
                case "UP": delegate.logoEngine(self, performAction: .moveCursorVirtual(-1))
                case "DOWN": delegate.logoEngine(self, performAction: .moveCursorVirtual(1))
                case "LEFT": delegate.logoEngine(self, performAction: .moveLeft)
                case "RIGHT": delegate.logoEngine(self, performAction: .moveRight)
                case "HOME": delegate.logoEngine(self, performAction: .moveHome)
                case "END": delegate.logoEngine(self, performAction: .moveEnd)
                default: break
                }
            }
            return true

        case .mark:
            delegate.logoEngine(self, performAction: .editMark)
            return true

        case .cut:
            delegate.logoEngine(self, performAction: .editCut)
            return true

        case .uncut:
            delegate.logoEngine(self, performAction: .editUncut)
            return true

        case .justify:
            delegate.logoEngine(self, performAction: .editJustify)
            return true

        case .find, .search:
            index += 1
            if index < tokens.count {
                let nextToken = tokens[index]
                if nextToken.hasPrefix("[") || customProcedures[nextToken.uppercased()] != nil || (index + 1 < tokens.count && tokens[index + 1].hasPrefix("[")) {
                    index -= 1
                    let val = evaluateExpression(tokens, index: &index)
                    lastResult = val
                } else {
                    let query = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, performAction: .search(query))
                }
            }
            return true

        case .clearBuffer:
            delegate.logoEngine(self, performAction: .clearBuffer)
            return true

        case .gotoline:
            if let row1Based = consumeOptionalEditingIntArgument(tokens, index: &index) {
                delegate.logoEngine(self, performAction: .gotoLine(max(0, row1Based - 1)))
            }
            return true

        case .gotocol:
            if let col1Based = consumeOptionalEditingIntArgument(tokens, index: &index) {
                delegate.logoEngine(self, performAction: .gotoCol(max(0, col1Based - 1)))
            }
            return true

        case .setline:
            index += 1
            if index < tokens.count {
                let firstVal = evaluateExpression(tokens, index: &index)
                if !isQuotedWordToken(tokens[index]), let line1Based = Int(firstVal),
                   index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                    index += 1
                    let textVal = unquote(evaluateExpression(tokens, index: &index))
                    delegate.logoEngine(self, performAction: .setLine(index: max(0, line1Based - 1), text: textVal))
                } else {
                    let curRow = (delegate.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0
                    let textVal = unquote(firstVal)
                    delegate.logoEngine(self, performAction: .setLine(index: curRow, text: textVal))
                }
            }
            return true

        default:
            return false
        }
    }
}
