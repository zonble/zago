import Foundation

extension LogoEngine {
    private func isDrawingArgumentBoundary(_ token: String) -> Bool {
        LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
    }

    private func consumeOptionalDrawingArgument(_ tokens: [String], index: inout Int) -> String? {
        index += 1
        guard index < tokens.count else {
            index -= 1
            return nil
        }
        guard !isDrawingArgumentBoundary(tokens[index]) else {
            index -= 1
            return nil
        }
        return evaluateExpression(tokens, index: &index)
    }

    private func consumeOptionalDrawingIntArgument(_ tokens: [String], index: inout Int) -> Int? {
        consumeOptionalIntExpressionArgument(tokens, index: &index, isBoundary: isDrawingArgumentBoundary)
    }

    private func consumeNextDrawingIntArgument(_ tokens: [String], index: inout Int) -> Int? {
        consumeNextIntExpressionArgument(tokens, index: &index, isBoundary: isDrawingArgumentBoundary)
    }

    private func isHeadingDirectionToken(_ token: String) -> Bool {
        switch unquote(token).trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "UP", "TOP", "RIGHT", "DOWN", "BOTTOM", "LEFT":
            return true
        default:
            return false
        }
    }

    private func consumeOptionalHeadingArgument(_ tokens: [String], index: inout Int) -> String? {
        index += 1
        guard index < tokens.count else {
            index -= 1
            return nil
        }
        if isHeadingDirectionToken(tokens[index]) {
            return tokens[index]
        }
        guard !isDrawingArgumentBoundary(tokens[index]) else {
            index -= 1
            return nil
        }
        let evaluated = evaluateExpression(tokens, index: &index)
        if parseHeadingValue(evaluated) != nil {
            return evaluated
        } else {
            index -= 1
            return nil
        }
    }

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
            heading = (heading + 90) % 360
            return true

        case .turnLeft:
            heading = ((heading - 90) % 360 + 360) % 360
            return true

        case .setHeading:
            if let dirStr = consumeOptionalHeadingArgument(tokens, index: &index),
                let angle = parseHeadingValue(dirStr)
            {
                heading = ((angle % 360) + 360) % 360
            }
            return true

        case .forward:
            let dist =
                consumeOptionalDrawingIntArgument(tokens, index: &index)
                .map { max(1, min($0, 200)) } ?? 1
            executeTurtleMove(steps: dist, directionHeading: heading)
            return true

        case .back:
            let dist =
                consumeOptionalDrawingIntArgument(tokens, index: &index)
                .map { max(1, min($0, 200)) } ?? 1
            executeTurtleMove(steps: dist, directionHeading: (heading + 180) % 360)
            return true

        case .goto:
            guard let delegate = self.delegate else { return false }
            if let row1Based = consumeOptionalDrawingIntArgument(tokens, index: &index) {
                let totalLines = (delegate.logoEngine(self, queryState: .lineCount) as? Int) ?? 0
                let lineNum = max(1, min(row1Based, totalLines)) - 1
                delegate.logoEngine(self, performAction: .updateLineIndex(lineNum))
                delegate.logoEngine(self, performAction: .updateColumnIndex(0))

                if let col1Based = consumeNextDrawingIntArgument(tokens, index: &index) {
                    let colNum = max(1, col1Based) - 1
                    delegate.logoEngine(self, performAction: .updateColumnIndex(colNum))
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
            index += 1
            executeTableCommand(tokens, index: &index)
            return true

        case .diagram:
            index += 1
            executeDiagramCommand(tokens, index: &index)
            return true

        default:
            return false
        }
    }

    private func executeDiagramCommand(_ tokens: [String], index: inout Int) {
        let arg: String?
        if index < tokens.count && !isDrawingArgumentBoundary(tokens[index]) {
            arg = unquote(evaluateExpression(tokens, index: &index))
        } else {
            arg = nil
        }
        delegate?.logoEngine(self, performAction: .insertDiagramSnippet(type: arg))
    }

    internal func parseHeadingValue(_ valStr: String) -> Int? {
        let clean = unquote(valStr).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch clean {
        case "UP", "TOP":
            return 0
        case "RIGHT":
            return 90
        case "DOWN", "BOTTOM":
            return 180
        case "LEFT":
            return 270
        default:
            return nil
        }
    }
}
