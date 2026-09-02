import Foundation

extension LogoEngine {
    private func consumeOptionalDrawingIntArgument(_ tokens: [String], index: inout Int) -> Int? {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let value = reader.nextOptionalInteger() else { return nil }
        reader.commit(to: &index)
        return value
    }

    private func consumeNextDrawingIntArgument(_ tokens: [String], index: inout Int) -> Int? {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let value = reader.nextOptionalInteger() else { return nil }
        reader.commit(to: &index)
        return value
    }

    private func isHeadingDirectionToken(_ token: String) -> Bool {
        parseHeading(token) != nil
    }

    private func consumeOptionalHeadingArgument(_ tokens: [String], index: inout Int) -> String? {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let nextToken = reader.peekToken() else { return nil }
        if isHeadingDirectionToken(nextToken) {
            _ = reader.nextRawToken()
            reader.commit(to: &index)
            return nextToken
        }
        guard !isArgumentBoundary(nextToken) else { return nil }
        let evaluated = reader.nextExpression()
        if parseHeading(evaluated) != nil {
            reader.commit(to: &index)
            return evaluated
        }
        return nil
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
            heading = heading.turnedRight
            return true

        case .turnLeft:
            heading = heading.turnedLeft
            return true

        case .setHeading:
            if let dirStr = consumeOptionalHeadingArgument(tokens, index: &index),
                let dir = parseHeading(dirStr)
            {
                heading = dir
            }
            return true

        case .forward:
            let dist =
                consumeOptionalDrawingIntArgument(tokens, index: &index)
                .map { max(1, min($0, 200)) } ?? 1
            executeTurtleMove(steps: dist, heading: heading)
            return true

        case .back:
            let dist =
                consumeOptionalDrawingIntArgument(tokens, index: &index)
                .map { max(1, min($0, 200)) } ?? 1
            executeTurtleMove(steps: dist, heading: heading.opposite)
            return true

        case .goto:
            guard let delegate = self.delegate else { return false }
            if let row1Based = consumeOptionalDrawingIntArgument(tokens, index: &index) {
                let lineNum = max(1, row1Based) - 1
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

        case .inset:
            index += 1
            executeInsetCommand(tokens, index: &index)
            return true

        case .box:
            index += 1
            executeBoxCommand(tokens, index: &index, mode: .insert)
            return true

        case .drawBox:
            index += 1
            executeBoxCommand(tokens, index: &index, mode: .overlay)
            return true

        case .frame:
            index += 1
            executeFrameCommand(tokens, index: &index)
            return true

        case .line:
            index += 1
            executeLineCommand(tokens, index: &index)
            return true

        case .vline:
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
}
