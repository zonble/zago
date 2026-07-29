import Foundation

extension LogoEngine {
    /// Evaluates Editor Buffer Query Primitives (buffers, buffer, row, col, getline, selection, etc.).
    internal func evaluateBufferPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        case .buffers:
            if let list = delegate?.logoEngine(self, queryState: .bufferList) as? [String] {
                return LogoValue.list(list.map { LogoValue.string($0) }).description
            }
            return "[]"

        case .buffer:
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let targetVal = evaluateExpression(tokens, index: &index)
                if let idx1Based = Int(targetVal) {
                    delegate?.logoEngine(self, performAction: .switchBuffer(index: max(0, idx1Based - 1)))
                }
            }
            let curIdx = (delegate?.logoEngine(self, queryState: .currentBufferIndex) as? Int) ?? 0
            return "\(curIdx + 1)"

        case .row:
            let row = (delegate?.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0
            return "\(row + 1)"

        case .col:
            let col = (delegate?.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
            return "\(col + 1)"

        case .lineCount:
            let count = (delegate?.logoEngine(self, queryState: .lineCount) as? Int) ?? 0
            return "\(count)"

        case .getline:
            var lineIdx = (delegate?.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let nStr = evaluateExpression(tokens, index: &index)
                if let n1Based = Int(nStr) {
                    lineIdx = max(0, n1Based - 1)
                }
            }
            return (delegate?.logoEngine(self, queryState: .lineAt(lineIdx)) as? String) ?? ""

        case .bufferText:
            return (delegate?.logoEngine(self, queryState: .bufferText) as? String) ?? ""

        case .selection:
            return (delegate?.logoEngine(self, queryState: .selectionText) as? String) ?? ""

        case .isModified:
            let mod = (delegate?.logoEngine(self, queryState: .isModified) as? Bool) ?? false
            return mod ? "1" : "0"

        case .fileName:
            return (delegate?.logoEngine(self, queryState: .fileName) as? String) ?? "Untitled"

        default:
            return nil
        }
    }
}
