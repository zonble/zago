import Foundation

extension LogoEngine {
    /// Evaluates UCB LOGO Data Structure Primitives (constructors, selectors, mutators, predicates, queries).
    internal func evaluateDataPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count else { return nil }
        let upper = tokens[index].uppercased()

        // ---------------------------------------------------------------------
        // 2.1 Constructors
        // ---------------------------------------------------------------------
        if upper == "WORD" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 + v2
        }

        if upper == "LIST" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return "[\(v1) \(v2)]"
        }

        if upper == "SENTENCE" || upper == "SE" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)

            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)

            var items: [LogoValue] = []
            switch p1 {
            case .list(let listItems), .array(let listItems): items.append(contentsOf: listItems)
            case .string(let s): items.append(.string(s))
            }
            switch p2 {
            case .list(let listItems), .array(let listItems): items.append(contentsOf: listItems)
            case .string(let s): items.append(.string(s))
            }
            return LogoValue.list(items).description
        }

        if upper == "FPUT" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)

            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)

            switch p2 {
            case .list(var items):
                items.insert(p1, at: 0)
                return LogoValue.list(items).description
            case .array(var items):
                items.insert(p1, at: 0)
                return LogoValue.array(items).description
            case .string(let s):
                return v1 + s
            }
        }

        if upper == "LPUT" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)

            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)

            switch p2 {
            case .list(var items):
                items.append(p1)
                return LogoValue.list(items).description
            case .array(var items):
                items.append(p1)
                return LogoValue.array(items).description
            case .string(let s):
                return s + v1
            }
        }

        if upper == "ARRAY" {
            index += 1
            let count = Int(evaluateExpression(tokens, index: &index)) ?? 1
            let items = Array(repeating: LogoValue.string(""), count: max(1, count))
            return LogoValue.array(items).description
        }

        if upper == "LISTTOARRAY" {
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(val)
            switch parsed {
            case .list(let items): return LogoValue.array(items).description
            default: return LogoValue.array([parsed]).description
            }
        }

        if upper == "ARRAYTOLIST" {
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(val)
            switch parsed {
            case .array(let items): return LogoValue.list(items).description
            default: return LogoValue.list([parsed]).description
            }
        }

        if upper == "COMBINE" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            let p2 = LogoValue.parse(v2)
            if case .string(let s) = p2 {
                return v1 + s
            } else if case .list(var items) = p2 {
                items.insert(LogoValue.parse(v1), at: 0)
                return LogoValue.list(items).description
            }
        }

        if upper == "REVERSE" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items): return LogoValue.list(items.reversed()).description
            case .array(let items): return LogoValue.array(items.reversed()).description
            case .string(let s): return String(s.reversed())
            }
        }

        if upper == "GENSYM" {
            gensymCounter += 1
            return "G\(gensymCounter)"
        }

        // ---------------------------------------------------------------------
        // 2.2 Data Selectors
        // ---------------------------------------------------------------------
        if upper == "FIRST" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                return items.first?.description ?? ""
            case .string(let s):
                return s.first != nil ? String(s.first!) : ""
            }
        }

        if upper == "LAST" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                return items.last?.description ?? ""
            case .string(let s):
                return s.last != nil ? String(s.last!) : ""
            }
        }

        if upper == "BUTFIRST" || upper == "BF" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items):
                let rest = items.dropFirst()
                return LogoValue.list(Array(rest)).description
            case .array(let items):
                let rest = items.dropFirst()
                return LogoValue.array(Array(rest)).description
            case .string(let s):
                return String(s.dropFirst())
            }
        }

        if upper == "BUTLAST" || upper == "BL" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items):
                let rest = items.dropLast()
                return LogoValue.list(Array(rest)).description
            case .array(let items):
                let rest = items.dropLast()
                return LogoValue.array(Array(rest)).description
            case .string(let s):
                return String(s.dropLast())
            }
        }

        if upper == "ITEM" {
            index += 1
            let idxVal = Int(evaluateExpression(tokens, index: &index)) ?? 1
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            let zeroIdx = idxVal - 1
            switch p {
            case .list(let items), .array(let items):
                if zeroIdx >= 0 && zeroIdx < items.count {
                    return items[zeroIdx].description
                }
                return ""
            case .string(let s):
                let chars = Array(s)
                if zeroIdx >= 0 && zeroIdx < chars.count {
                    return String(chars[zeroIdx])
                }
                return ""
            }
        }

        if upper == "POP" {
            index += 1
            let varToken = tokens[index]
            let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
            let currentVal = variables[varName] ?? ""
            let parsed = LogoValue.parse(currentVal)
            switch parsed {
            case .list(var items):
                if !items.isEmpty {
                    let popped = items.removeFirst()
                    variables[varName] = LogoValue.list(items).description
                    return popped.description
                }
                return ""
            case .array(var items):
                if !items.isEmpty {
                    let popped = items.removeFirst()
                    variables[varName] = LogoValue.array(items).description
                    return popped.description
                }
                return ""
            case .string(let s):
                if !s.isEmpty {
                    let popped = String(s.first!)
                    variables[varName] = String(s.dropFirst())
                    return popped
                }
                return ""
            }
        }

        if upper == "DEQUEUE" {
            index += 1
            let varToken = tokens[index]
            let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
            let currentVal = variables[varName] ?? ""
            let parsed = LogoValue.parse(currentVal)
            switch parsed {
            case .list(var items):
                if !items.isEmpty {
                    let popped = items.removeFirst()
                    variables[varName] = LogoValue.list(items).description
                    return popped.description
                }
                return ""
            case .string(let s):
                if !s.isEmpty {
                    let popped = String(s.first!)
                    variables[varName] = String(s.dropFirst())
                    return popped
                }
                return ""
            case .array(var items):
                if !items.isEmpty {
                    let popped = items.removeFirst()
                    variables[varName] = LogoValue.array(items).description
                    return popped.description
                }
                return ""
            }
        }

        if upper == "REMDUP" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items):
                var unique: [LogoValue] = []
                for item in items {
                    if !unique.contains(item) { unique.append(item) }
                }
                return LogoValue.list(unique).description
            case .string(let s):
                var uniqueChars: [Character] = []
                for ch in s {
                    if !uniqueChars.contains(ch) { uniqueChars.append(ch) }
                }
                return String(uniqueChars)
            case .array(let items):
                var unique: [LogoValue] = []
                for item in items {
                    if !unique.contains(item) { unique.append(item) }
                }
                return LogoValue.array(unique).description
            }
        }

        // ---------------------------------------------------------------------
        // 2.4 Predicates
        // ---------------------------------------------------------------------
        if upper == "WORD?" || upper == "WORDP" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            return p.isWord ? "1" : "0"
        }

        if upper == "LIST?" || upper == "LISTP" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            return p.isList ? "1" : "0"
        }

        if upper == "ARRAY?" || upper == "ARRAYP" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            return p.isArray ? "1" : "0"
        }

        if upper == "NUMBER?" || upper == "NUMBERP" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            return p.isNumber ? "1" : "0"
        }

        if upper == "EMPTY?" || upper == "EMPTYP" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            return p.isEmpty ? "1" : "0"
        }

        if upper == "MEMBER?" || upper == "MEMBERP" {
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(haystack)
            switch p {
            case .list(let items), .array(let items):
                return items.map { $0.description }.contains(needle) ? "1" : "0"
            case .string(let s):
                return s.contains(needle) ? "1" : "0"
            }
        }

        // ---------------------------------------------------------------------
        // 2.5 Queries
        // ---------------------------------------------------------------------
        if upper == "COUNT" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items): return "\(items.count)"
            case .string(let s): return "\(s.count)"
            }
        }

        if upper == "ASCII" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            if let first = v.utf8.first {
                return "\(first)"
            }
            return "0"
        }

        if upper == "CHAR" {
            index += 1
            let code = Int(evaluateExpression(tokens, index: &index)) ?? 0
            if let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""
        }

        if upper == "UPPERCASE" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.uppercased()
        }

        if upper == "LOWERCASE" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.lowercased()
        }

        return nil
    }
}
