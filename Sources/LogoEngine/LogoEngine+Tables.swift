import Foundation

extension LogoEngine {
    private func isTableArgumentBoundary(_ token: String) -> Bool {
        LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
    }

    private func consumeNextTableArgument(_ tokens: [String], index: inout Int) -> String? {
        guard index + 1 < tokens.count else { return nil }
        guard !isTableArgumentBoundary(tokens[index + 1]) else { return nil }
        index += 1
        return evaluateExpression(tokens, index: &index)
    }

    private func consumeNextTableBorderStyle(_ tokens: [String], index: inout Int) -> String? {
        guard index + 1 < tokens.count else { return nil }
        guard !isTableArgumentBoundary(tokens[index + 1]) else { return nil }

        let start = index + 1
        let singleToken = unquote(tokens[start])

        if start + 2 < tokens.count, tokens[start + 1] == "-" {
            let hyphenated = "\(singleToken)-\(unquote(tokens[start + 2]))"
            if BorderStyle.isStyleToken(hyphenated) {
                index = start + 2
                return hyphenated
            }
        }

        if BorderStyle.isStyleToken(singleToken) {
            index = start
            return singleToken
        }

        index = start
        return singleToken
    }

    internal func executeTableCommand(_ tokens: [String], index: inout Int) {
        guard let delegate = self.delegate else { return }

        func createDefaultTable() {
            delegate.logoEngine(self, performAction: .createTable(rows: 3, cols: 3, cellWidth: nil))
            hasSetStatusMessage = true
        }

        guard index < tokens.count else {
            index -= 1
            createDefaultTable()
            return
        }

        let subcommand = tokens[index].uppercased()
        if subcommand == "BORDER" {
            if let style = consumeNextTableBorderStyle(tokens, index: &index) {
                delegate.logoEngine(self, performAction: .setBorderStyle(style))
                hasSetStatusMessage = true
            }
        } else if subcommand == "NEXTSTYLE" {
            delegate.logoEngine(self, performAction: .nextBorderStyle)
            hasSetStatusMessage = true
        } else if !LogoEngine.isStatementCommand(tokens[index]), let rows = Int(evaluateExpression(tokens, index: &index)) {
            let cols = consumeNextTableArgument(tokens, index: &index).flatMap(Int.init) ?? 3
            let cellWidth = consumeNextTableArgument(tokens, index: &index).flatMap(Int.init)
            delegate.logoEngine(self, performAction: .createTable(rows: rows, cols: cols, cellWidth: cellWidth))
            hasSetStatusMessage = true
        } else {
            index -= 1
            createDefaultTable()
        }
    }
}
