import Foundation

extension LogoEngine {
    private func consumeNextTableIntArgument(_ tokens: [String], index: inout Int) -> Int? {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let value = reader.nextOptionalInteger() else { return nil }
        reader.commit(to: &index)
        return value
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

        if let rows = parseIntExpressionArgument(
            tokens, index: &index, isBoundary: isArgumentBoundary)
        {
            let cols = consumeNextTableIntArgument(tokens, index: &index) ?? 3
            var cellWidth: Int? = nil
            var borderStyle: BorderStyle? = nil
            var isRound: Bool? = nil

            while index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if isArgumentBoundary(nextToken) { break }
                var evalIndex = index + 1
                let rawToken = tokens[evalIndex]
                let unquoted = unquote(rawToken)
                let val: String
                let resolved = pluginRegistry.resolveKeyword(unquoted, domain: .borderStyle) ?? unquoted
                if BorderStyle.isStyleToken(resolved) || parseBoolean(unquoted) != nil || StyleDSL.parseBoxStyle(unquoted) != nil {
                    val = unquoted
                } else {
                    val = unquote(evaluateExpression(tokens, index: &evalIndex))
                }
                index = evalIndex

                let resolvedVal = pluginRegistry.resolveKeyword(val, domain: .borderStyle) ?? val
                if let dsl = StyleDSL.parseBoxStyle(resolvedVal) {
                    borderStyle = dsl.border
                    isRound = dsl.rounded
                } else if let b = BorderStyle(resolvedVal) {
                    borderStyle = b
                } else if let boolVal = parseBoolean(val) {
                    isRound = boolVal
                } else if let intVal = Int(val), cellWidth == nil {
                    cellWidth = intVal
                }
            }

            delegate.logoEngine(
                self,
                performAction: .createTable(
                    rows: rows,
                    cols: cols,
                    cellWidth: cellWidth,
                    borderStyle: borderStyle,
                    rounded: isRound
                )
            )
            hasSetStatusMessage = true
        } else {
            if index >= tokens.count || isArgumentBoundary(tokens[index]) {
                index -= 1
            }
            createDefaultTable()
        }
    }
}
