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

        guard index < tokens.count else {
            index -= 1
            delegate.logoEngine(self, performAction: .createTable(rows: 3, cols: 3, cellWidth: nil))
            hasSetStatusMessage = true
            return
        }

        var rows: Int = 3
        var cols: Int = 3
        var cellWidth: Int? = nil
        var borderStyle: BorderStyle? = nil
        var isRound: Bool? = nil

        if let parsedRows = parseIntExpressionArgument(
            tokens, index: &index, isBoundary: isArgumentBoundary)
        {
            rows = parsedRows
            if let parsedCols = consumeNextTableIntArgument(tokens, index: &index) {
                cols = parsedCols
            }
        } else {
            // First argument is not an integer (e.g. style name, Style DSL, or boolean/round modifier)
            index -= 1
        }

        while index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if isArgumentBoundary(nextToken) { break }
            var evalIndex = index + 1
            let rawToken = tokens[evalIndex]
            let unquoted = unquote(rawToken)
            let val: String
            if parseRoundModifier(unquoted) != nil || parseBorderStyle(unquoted) != nil
                || BorderStyle.isStyleToken(unquoted) || StyleDSL.parseBoxStyle(unquoted) != nil
            {
                val = unquoted
            } else {
                val = unquote(evaluateExpression(tokens, index: &evalIndex))
            }
            index = evalIndex

            if let boolVal = parseRoundModifier(val) {
                isRound = boolVal
            } else if let b = parseBorderStyle(val) {
                borderStyle = b
            } else if let dsl = StyleDSL.parseBoxStyle(val) {
                borderStyle = dsl.border
                if dsl.rounded || val.hasSuffix(")") {
                    isRound = dsl.rounded
                }
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
    }

    private func parseRoundModifier(_ token: String) -> Bool? {
        let clean = token.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "\"': "))
        if clean == "round" || clean == "rounded" { return true }
        return parseBoolean(token)
    }
}
