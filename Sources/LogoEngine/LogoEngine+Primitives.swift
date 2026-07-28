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

        if upper == "EQUAL?" || upper == "EQUALP" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            if let n1 = Double(v1), let n2 = Double(v2) {
                return n1 == n2 ? "1" : "0"
            }
            return LogoValue.parse(v1) == LogoValue.parse(v2) ? "1" : "0"
        }

        if upper == "NOTEQUAL?" || upper == "NOTEQUALP" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            if let n1 = Double(v1), let n2 = Double(v2) {
                return n1 != n2 ? "1" : "0"
            }
            return LogoValue.parse(v1) != LogoValue.parse(v2) ? "1" : "0"
        }

        if upper == "BEFORE?" || upper == "BEFOREP" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 < v2 ? "1" : "0"
        }

        if upper == "LESSP" || upper == "LESS?" {
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 < n2 ? "1" : "0"
        }

        if upper == "GREATERP" || upper == "GREATER?" {
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 > n2 ? "1" : "0"
        }

        if upper == "LESSEQUALP" || upper == "LESSEQUAL?" {
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 <= n2 ? "1" : "0"
        }

        if upper == "GREATEREQUALP" || upper == "GREATEREQUAL?" {
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 >= n2 ? "1" : "0"
        }

        // ---------------------------------------------------------------------
        // 4.1 & 4.3 - 4.5 Numeric, Math, Bitwise, Formatting
        // ---------------------------------------------------------------------
        if upper == "SUM" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a + b)
        }

        if upper == "DIFFERENCE" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a - b)
        }

        if upper == "PRODUCT" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a * b)
        }

        if upper == "QUOTED" || upper == "QUOTIENT" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            if index + 1 < tokens.count && !LogoEngine.keywords.contains(tokens[index + 1].uppercased()) && tokens[index + 1] != "]" {
                index += 1
                let b = Double(evaluateExpression(tokens, index: &index)) ?? 1
                return formatNum(b != 0 ? a / b : 0)
            }
            return formatNum(a != 0 ? 1.0 / a : 0)
        }

        if upper == "POWER" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(pow(a, b))
        }

        if upper == "REMAINDER" {
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 1
            return "\(b != 0 ? a % b : 0)"
        }

        if upper == "MODULO" {
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 1
            if b == 0 { return "0" }
            let r = a % b
            return "\(r >= 0 ? r : r + abs(b))"
        }

        if upper == "MINUS" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(-a)
        }

        if upper == "ABS" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(abs(a))
        }

        if upper == "INT" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(Int(a))"
        }

        if upper == "ROUND" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(Int(round(a)))"
        }

        if upper == "SQRT" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sqrt(max(0, a)))
        }

        if upper == "EXP" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(exp(a))
        }

        if upper == "LOG10" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 1
            return formatNum(log10(max(0.00001, a)))
        }

        if upper == "LN" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 1
            return formatNum(log(max(0.00001, a)))
        }

        if upper == "ARCTAN" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(atan(a) * 180.0 / .pi)
        }

        if upper == "SIN" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sin(a * .pi / 180.0))
        }

        if upper == "COS" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(cos(a * .pi / 180.0))
        }

        if upper == "TAN" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(tan(a * .pi / 180.0))
        }

        if upper == "RADARCTAN" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(atan(a))
        }

        if upper == "RADSIN" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sin(a))
        }

        if upper == "RADCOS" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(cos(a))
        }

        if upper == "RADTAN" {
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(tan(a))
        }

        if upper == "ISEQ" {
            index += 1
            let start = Int(evaluateExpression(tokens, index: &index)) ?? 1
            index += 1
            let end = Int(evaluateExpression(tokens, index: &index)) ?? start
            let seq = (start <= end) ? Array(start...end) : Array(stride(from: start, through: end, by: -1))
            return LogoValue.list(seq.map { LogoValue.string("\($0)") }).description
        }

        if upper == "RSEQ" {
            index += 1
            let start = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let end = Double(evaluateExpression(tokens, index: &index)) ?? start
            index += 1
            let count = max(1, Int(evaluateExpression(tokens, index: &index)) ?? 1)
            if count == 1 { return LogoValue.list([LogoValue.string(formatNum(start))]).description }
            let step = (end - start) / Double(count - 1)
            var res: [LogoValue] = []
            for i in 0..<count {
                res.append(LogoValue.string(formatNum(start + Double(i) * step)))
            }
            return LogoValue.list(res).description
        }

        if upper == "RANDOM" {
            index += 1
            let firstVal = Int(evaluateExpression(tokens, index: &index)) ?? 10
            if index + 1 < tokens.count && !LogoEngine.keywords.contains(tokens[index + 1].uppercased()) && tokens[index + 1] != "]" {
                index += 1
                let secondVal = Int(evaluateExpression(tokens, index: &index)) ?? firstVal
                let low = min(firstVal, secondVal)
                let high = max(firstVal, secondVal)
                return "\(Int.random(in: low...high))"
            }
            let upperLimit = max(1, firstVal)
            return "\(Int.random(in: 0..<upperLimit))"
        }

        if upper == "RERANDOM" {
            return "1"
        }

        if upper == "FORM" {
            index += 1
            let val = Double(evaluateExpression(tokens, index: &index)) ?? 0.0
            index += 1
            let width = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let prec = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return String(format: "%*.*f", width, prec, val)
        }

        if upper == "BITAND" {
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a & b)"
        }

        if upper == "BITOR" {
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a | b)"
        }

        if upper == "BITXOR" {
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a ^ b)"
        }

        if upper == "BITNOT" {
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\( ~a )"
        }

        if upper == "ASHIFT" {
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let shift = Int(evaluateExpression(tokens, index: &index)) ?? 0
            if shift >= 0 {
                return "\(a << shift)"
            } else {
                return "\(a >> (-shift))"
            }
        }

        if upper == "LSHIFT" {
            index += 1
            let a = UInt64(bitPattern: Int64(Int(evaluateExpression(tokens, index: &index)) ?? 0))
            index += 1
            let shift = Int(evaluateExpression(tokens, index: &index)) ?? 0
            if shift >= 0 {
                return "\(Int64(bitPattern: a << shift))"
            } else {
                return "\(Int64(bitPattern: a >> (-shift)))"
            }
        }

        // ---------------------------------------------------------------------
        // 5. Logical Operations
        // ---------------------------------------------------------------------
        if upper == "TRUE" {
            return "1"
        }

        if upper == "FALSE" {
            return "0"
        }

        if upper == "AND" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) && logoIsTrue(v2)) ? "1" : "0"
        }

        if upper == "OR" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) || logoIsTrue(v2)) ? "1" : "0"
        }

        if upper == "XOR" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) != logoIsTrue(v2)) ? "1" : "0"
        }

        if upper == "NOT" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return logoIsTrue(v) ? "0" : "1"
        }

        if upper == ".EQ" {
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 == v2 ? "1" : "0"
        }

        if upper == "SUBSTRING?" || upper == "SUBSTRINGP" {
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            return haystack.contains(needle) ? "1" : "0"
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

        if upper == "MEMBER" {
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(haystack)
            switch p {
            case .list(let items):
                if let pos = items.firstIndex(where: { $0.description == needle }) {
                    let tail = Array(items[pos...])
                    return LogoValue.list(tail).description
                }
                return "[]"
            case .array(let items):
                if let pos = items.firstIndex(where: { $0.description == needle }) {
                    let tail = Array(items[pos...])
                    return LogoValue.array(tail).description
                }
                return "{}"
            case .string(let s):
                if let range = s.range(of: needle) {
                    return String(s[range.lowerBound...])
                }
                return ""
            }
        }

        if upper == "STANDOUT" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            var result = ""
            for ch in v {
                if let asciiVal = ch.asciiValue {
                    if asciiVal >= 65 && asciiVal <= 90 { // A-Z
                        let boldScalar = UnicodeScalar(0x1D400 + Int(asciiVal - 65))!
                        result.append(Character(boldScalar))
                    } else if asciiVal >= 97 && asciiVal <= 122 { // a-z
                        let boldScalar = UnicodeScalar(0x1D41A + Int(asciiVal - 97))!
                        result.append(Character(boldScalar))
                    } else if asciiVal >= 48 && asciiVal <= 57 { // 0-9
                        let boldScalar = UnicodeScalar(0x1D7CE + Int(asciiVal - 48))!
                        result.append(Character(boldScalar))
                    } else {
                        result.append(ch)
                    }
                } else {
                    result.append(ch)
                }
            }
            return result
        }

        if upper == "PARSE" || upper == "RUNPARSE" {
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let toks = tokenize(v)
            return "[" + toks.joined(separator: " ") + "]"
        }

        return nil
    }

    internal func formatNum(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 && val >= Double(Int.min) && val <= Double(Int.max) {
            return "\(Int(val))"
        }
        return "\(val)"
    }

    internal func logoIsTrue(_ val: String) -> Bool {
        let clean = val.lowercased().trimmingCharacters(in: .whitespaces)
        if clean == "1" || clean == "true" { return true }
        if clean == "0" || clean == "false" || clean.isEmpty { return false }
        if let d = Double(clean) { return d != 0 }
        return true
    }
}
