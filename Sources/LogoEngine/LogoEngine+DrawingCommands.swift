import Foundation

extension LogoEngine {
    private func isDrawingArgumentBoundary(_ token: String) -> Bool {
        LogoEngine.isKeyword(token) || token == "]" || token == ")"
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

    private func consumeNextDrawingArgument(_ tokens: [String], index: inout Int) -> String? {
        guard index + 1 < tokens.count else { return nil }
        guard !isDrawingArgumentBoundary(tokens[index + 1]) else { return nil }
        index += 1
        return evaluateExpression(tokens, index: &index)
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
            let angle = consumeOptionalDrawingArgument(tokens, index: &index).flatMap(Int.init) ?? 90
            heading = (heading + angle) % 360
            return true

        case .turnLeft:
            let angle = consumeOptionalDrawingArgument(tokens, index: &index).flatMap(Int.init) ?? 90
            heading = ((heading - angle) % 360 + 360) % 360
            return true

        case .setHeading:
            let angle = consumeOptionalDrawingArgument(tokens, index: &index).map(parseHeadingValue) ?? 0
            heading = ((angle % 360) + 360) % 360
            return true

        case .forward:
            let dist = consumeOptionalDrawingArgument(tokens, index: &index)
                .flatMap(Int.init)
                .map { max(1, min($0, 200)) } ?? 1
            executeTurtleMove(steps: dist, directionHeading: heading)
            return true

        case .back:
            let dist = consumeOptionalDrawingArgument(tokens, index: &index)
                .flatMap(Int.init)
                .map { max(1, min($0, 200)) } ?? 1
            executeTurtleMove(steps: dist, directionHeading: (heading + 180) % 360)
            return true

        case .goto:
            guard let delegate = self.delegate else { return false }
            if let lineStr = consumeOptionalDrawingArgument(tokens, index: &index) {
                let totalLines = (delegate.logoEngine(self, queryState: .lineCount) as? Int) ?? 0
                let lineNum = max(1, min(Int(lineStr) ?? 1, totalLines)) - 1
                delegate.logoEngine(self, performAction: .updateLineIndex(lineNum))
                delegate.logoEngine(self, performAction: .updateColumnIndex(0))

                if let colStr = consumeNextDrawingArgument(tokens, index: &index) {
                    let lineText = (delegate.logoEngine(self, queryState: .lineAt(lineNum)) as? String) ?? ""
                    let colNum = max(1, min(Int(colStr) ?? 1, lineText.count + 1)) - 1
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

        default:
            return false
        }
    }

    internal func parseHeadingValue(_ valStr: String) -> Int {
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
            return Int(clean) ?? 0
        }
    }
}
