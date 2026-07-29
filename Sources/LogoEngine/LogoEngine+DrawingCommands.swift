import Foundation

extension LogoEngine {
    /// Executes Logo turtle & box/line drawing statement commands (PD, PU, FD, BK, LT, RT, GOTO, BOX, LINE, TABLE, etc.).
    /// Returns `true` if the primitive was handled by this module, `false` otherwise.
    internal func executeDrawingCommand(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> Bool {
        switch prim {
        case .penDown:
            isPenDown = true
            return true

        case .penUp:
            isPenDown = false
            return true

        case .turnRight:
            index += 1
            var angle = 90
            if index < tokens.count {
                if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                    let valStr = evaluateExpression(tokens, index: &index)
                    angle = Int(valStr) ?? 90
                } else {
                    index -= 1
                }
            } else {
                index -= 1
            }
            heading = (heading + angle) % 360
            return true

        case .turnLeft:
            index += 1
            var angle = 90
            if index < tokens.count {
                if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                    let valStr = evaluateExpression(tokens, index: &index)
                    angle = Int(valStr) ?? 90
                } else {
                    index -= 1
                }
            } else {
                index -= 1
            }
            heading = ((heading - angle) % 360 + 360) % 360
            return true

        case .forward:
            index += 1
            var dist = 1
            if index < tokens.count {
                if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                    let valStr = evaluateExpression(tokens, index: &index)
                    dist = max(1, min(Int(valStr) ?? 1, 200))
                } else {
                    index -= 1
                }
            } else {
                index -= 1
            }
            executeTurtleMove(steps: dist, directionHeading: heading)
            return true

        case .back:
            index += 1
            var dist = 1
            if index < tokens.count {
                if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                    let valStr = evaluateExpression(tokens, index: &index)
                    dist = max(1, min(Int(valStr) ?? 1, 200))
                } else {
                    index -= 1
                }
            } else {
                index -= 1
            }
            executeTurtleMove(steps: dist, directionHeading: (heading + 180) % 360)
            return true

        case .goto:
            guard let delegate = self.delegate else { return false }
            index += 1
            if index < tokens.count {
                let lineStr = evaluateExpression(tokens, index: &index)
                let totalLines = (delegate.logoEngine(self, queryState: .lineCount) as? Int) ?? 0
                let lineNum = max(1, min(Int(lineStr) ?? 1, totalLines)) - 1
                delegate.logoEngine(self, performAction: .updateLineIndex(lineNum))
                delegate.logoEngine(self, performAction: .updateColumnIndex(0))

                if index + 1 < tokens.count {
                    if !LogoEngine.isKeyword(tokens[index + 1]) {
                        index += 1
                        let colStr = evaluateExpression(tokens, index: &index)
                        let lineText = (delegate.logoEngine(self, queryState: .lineAt(lineNum)) as? String) ?? ""
                        let colNum = max(1, min(Int(colStr) ?? 1, lineText.count + 1)) - 1
                        delegate.logoEngine(self, performAction: .updateColumnIndex(colNum))
                    }
                }
            }
            return true

        case .fill:
            index += 1
            executeFillCommand(tokens, index: &index)
            return true

        case .box:
            index += 1
            executeBoxCommand(tokens, index: &index, mode: .insert)
            return true

        case .drawBox:
            index += 1
            executeBoxCommand(tokens, index: &index, mode: .overlay)
            return true

        case .line, .hr:
            index += 1
            executeLineCommand(tokens, index: &index)
            return true

        case .vline, .vhr:
            index += 1
            executeVlineCommand(tokens, index: &index)
            return true

        case .newline:
            index += 1
            executeNewlineCommand(tokens, index: &index)
            return true

        case .table:
            guard let delegate = self.delegate else { return false }
            index += 1
            if index < tokens.count {
                let subcommand = tokens[index].uppercased()
                if subcommand == "BORDER" {
                    if index + 1 < tokens.count && !LogoEngine.isStatementCommand(tokens[index + 1]) && tokens[index + 1] != "]" {
                        index += 1
                        let style = unquote(tokens[index])
                        delegate.logoEngine(self, performAction: .setTableBorderStyle(style))
                        hasSetStatusMessage = true
                    }
                } else if subcommand == "NEXTSTYLE" {
                    delegate.logoEngine(self, performAction: .nextTableBorderStyle)
                    hasSetStatusMessage = true
                } else if !LogoEngine.isStatementCommand(tokens[index]), let rows = Int(evaluateExpression(tokens, index: &index)) {
                    var cols = 3
                    if index + 1 < tokens.count && !LogoEngine.isStatementCommand(tokens[index + 1]) && tokens[index + 1] != "]" {
                        index += 1
                        cols = Int(evaluateExpression(tokens, index: &index)) ?? 3
                    }
                    delegate.logoEngine(self, performAction: .createTable(rows: rows, cols: cols))
                    hasSetStatusMessage = true
                } else {
                    index -= 1
                    delegate.logoEngine(self, performAction: .createTable(rows: 3, cols: 3))
                    hasSetStatusMessage = true
                }
            } else {
                index -= 1
                delegate.logoEngine(self, performAction: .createTable(rows: 3, cols: 3))
                hasSetStatusMessage = true
            }
            return true

        default:
            return false
        }
    }
}
