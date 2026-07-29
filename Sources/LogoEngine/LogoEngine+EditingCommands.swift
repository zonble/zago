import Foundation

extension LogoEngine {
    /// Executes Logo editor text manipulation and buffer management statement commands (.type, .show, .move, .cut, etc.).
    /// Returns `true` if the primitive was handled by this module, `false` otherwise.
    internal func executeEditingCommand(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> Bool {
        guard let delegate = self.delegate else { return false }

        switch prim {
        case .set:
            index += 1
            if index < tokens.count {
                let setting = unquote(tokens[index]).lowercased()
                var arg = ""
                if index + 1 < tokens.count {
                    if !LogoEngine.isKeyword(tokens[index + 1]) {
                        index += 1
                        arg = evaluateExpression(tokens, index: &index).lowercased()
                    }
                }
                delegate.logoEngine(self, performAction: .applySetting(setting: setting, arg: arg))
            }
            return true

        case .type:
            index += 1
            while index < tokens.count {
                if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                    index -= 1
                    break
                }
                let text = evaluateExpression(tokens, index: &index)
                delegate.logoEngine(self, performAction: .insertText(text))
                if index + 1 < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                        break
                    }
                    index += 1
                }
            }
            return true

        case .show:
            index += 1
            var parts: [String] = []
            while index < tokens.count {
                if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                    index -= 1
                    break
                }
                let text = evaluateExpression(tokens, index: &index)
                parts.append(text)
                if index + 1 < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                        break
                    }
                    index += 1
                }
            }
            let msgText = parts.joined(separator: " ")
            delegate.logoEngine(self, performAction: .setStatusMessage(msgText))
            hasSetStatusMessage = true
            return true

        case .delete:
            index += 1
            let valStr = evaluateExpression(tokens, index: &index)
            let count = Int(valStr) ?? 1
            for _ in 0..<count {
                delegate.logoEngine(self, performAction: .deleteChar)
            }
            return true

        case .backspace:
            index += 1
            let valStr = evaluateExpression(tokens, index: &index)
            let count = Int(valStr) ?? 1
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
                    let valStr = evaluateExpression(tokens, index: &index)
                    count = max(1, min(Int(valStr) ?? 1, 1000))
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
            while index < tokens.count {
                if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                    index -= 1
                    break
                }
                let text = evaluateExpression(tokens, index: &index)
                delegate.logoEngine(self, performAction: .insertText(text))
                if index + 1 < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                        break
                    }
                }
                index += 1
            }
            return true

        case .prependText:
            index += 1
            delegate.logoEngine(self, performAction: .moveHome)
            while index < tokens.count {
                if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                    index -= 1
                    break
                }
                let text = evaluateExpression(tokens, index: &index)
                delegate.logoEngine(self, performAction: .insertText(text))
                if index + 1 < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                        break
                    }
                }
                index += 1
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
            let levels = Int(optionalCommandArgument(tokens, index: &index) ?? "") ?? 1
            delegate.logoEngine(self, performAction: .indentLines(levels: levels))
            return true

        case .outdentLines:
            let levels = Int(optionalCommandArgument(tokens, index: &index) ?? "") ?? 1
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

        case .nextBuffer:
            delegate.logoEngine(self, performAction: .nextBuffer)
            return true

        case .prevBuffer:
            delegate.logoEngine(self, performAction: .prevBuffer)
            return true

        case .closeBuffer:
            delegate.logoEngine(self, performAction: .closeBuffer)
            return true

        case .openBuffer:
            index += 1
            if index < tokens.count {
                let path = unquote(evaluateExpression(tokens, index: &index))
                delegate.logoEngine(self, performAction: .openBuffer(path: path))
            }
            return true

        case .clearBuffer:
            delegate.logoEngine(self, performAction: .clearBuffer)
            return true

        case .saveBuffer:
            let path = optionalCommandArgument(tokens, index: &index)
            delegate.logoEngine(self, performAction: .saveBuffer(path: path))
            hasSetStatusMessage = true
            return true

        case .fileSaveAndQuit:
            let path = optionalCommandArgument(tokens, index: &index)
            delegate.logoEngine(self, performAction: .saveAndCloseBuffer(path: path))
            hasSetStatusMessage = true
            return true

        case .gotoline:
            index += 1
            if index < tokens.count {
                let lineStr = evaluateExpression(tokens, index: &index)
                let row1Based = Int(lineStr) ?? 1
                delegate.logoEngine(self, performAction: .gotoLine(max(0, row1Based - 1)))
            }
            return true

        case .gotocol:
            index += 1
            if index < tokens.count {
                let colStr = evaluateExpression(tokens, index: &index)
                let col1Based = Int(colStr) ?? 1
                delegate.logoEngine(self, performAction: .gotoCol(max(0, col1Based - 1)))
            }
            return true

        case .setline:
            index += 1
            if index < tokens.count {
                let firstVal = evaluateExpression(tokens, index: &index)
                if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                    let line1Based = Int(firstVal) ?? 1
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
