import Foundation

extension LogoEngine {
    /// Evaluates Editor Buffer Query Primitives (buffers, buffer, row, col, getline, selection, etc.).
    internal func evaluateBufferPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        case .buffers:
            if let list = queryStrings(.bufferList) {
                return LogoValue.list(list.map { LogoValue.string($0) }).description
            }
            return "[]"

        case .buffer:
            let curIdx = queryInteger(.currentBufferIndex) ?? 0
            return "\(curIdx + 1)"

        case .row:
            let row = queryInteger(.currentLineIndex) ?? 0
            return "\(row + 1)"

        case .col:
            let col = queryInteger(.currentColumnIndex) ?? 0
            return "\(col + 1)"

        case .lineCount:
            let count = queryInteger(.lineCount) ?? 0
            return "\(count)"

        case .getline:
            var lineIdx = queryInteger(.currentLineIndex) ?? 0
            if let n1Based = consumeNextIntExpressionArgument(
                tokens, index: &index, isBoundary: Self.isArgumentBoundary)
            {
                lineIdx = max(0, n1Based - 1)
            }
            return queryString(.lineAt(lineIdx)) ?? ""

        case .bufferText:
            return queryString(.bufferText) ?? ""

        case .selection:
            return queryString(.selectionText) ?? ""

        case .isModified:
            let mod = queryBool(.isModified) ?? false
            return mod ? "1" : "0"

        case .fileName:
            return queryString(.fileName) ?? "Untitled"

        default:
            return nil
        }
    }

    internal static func isArgumentBoundary(_ token: String) -> Bool {
        LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
    }
}
