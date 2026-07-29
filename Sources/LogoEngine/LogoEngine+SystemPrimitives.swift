import Foundation

extension LogoEngine {
    /// System & Environment Primitives Evaluator (`evaluateSystemPrimitives`)
    ///
    /// ### Role & Architecture:
    /// - **Role**: Evaluates system state, environment queries, date/time formatting, and character code primitives.
    /// - **Primitives**: `DATE`, `TIME`, `ASCII`, `CHAR`, `STANDOUT`, `COUNT`, `SORT`
    /// - **Return Type**: `String?` (evaluated result string or `nil`).
    internal func evaluateSystemPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        case .date:
            index += 1
            var format = "yyyy-MM-dd"
            if index < tokens.count {
                let nextToken = tokens[index]
                if !LogoEngine.isKeyword(nextToken) && nextToken != "]" && nextToken != ")" {
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                } else {
                    index -= 1
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: Date())

        case .time:
            index += 1
            var format = "HH:mm:ss"
            if index < tokens.count {
                let nextToken = tokens[index]
                if !LogoEngine.isKeyword(nextToken) && nextToken != "]" && nextToken != ")" {
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                } else {
                    index -= 1
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: Date())

        case .count:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items): return "\(items.count)"
            case .string(let s): return "\(s.count)"
            }

        case .ascii:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            if let first = v.utf8.first {
                return "\(first)"
            }
            return "0"

        case .char:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            if let code = Int(v), let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""

        case .standout:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return "**\(v)**"

        default:
            return nil
        }
    }
}
