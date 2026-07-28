import Foundation

extension LogoEngine {
    /// Evaluates UCB LOGO Data Structure Primitives (constructors, selectors, mutators, predicates, queries).
    internal func evaluateDataPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        // ---------------------------------------------------------------------
        // 2.1 Constructors
        // ---------------------------------------------------------------------
        case .word:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 + v2

        case .list:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return "[\(v1) \(v2)]"

        case .sentence:
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

        case .fput:
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

        case .lput:
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

        case .array:
            index += 1
            let count = Int(evaluateExpression(tokens, index: &index)) ?? 1
            let items = Array(repeating: LogoValue.string(""), count: max(1, count))
            return LogoValue.array(items).description

        case .listToArray:
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(val)
            switch parsed {
            case .list(let items): return LogoValue.array(items).description
            default: return LogoValue.array([parsed]).description
            }

        case .arrayToList:
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(val)
            switch parsed {
            case .array(let items): return LogoValue.list(items).description
            default: return LogoValue.list([parsed]).description
            }

        case .combine:
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
            return ""

        case .reverse:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items): return LogoValue.list(items.reversed()).description
            case .array(let items): return LogoValue.array(items.reversed()).description
            case .string(let s): return String(s.reversed())
            }

        case .gensym:
            gensymCounter += 1
            return "G\(gensymCounter)"

        // ---------------------------------------------------------------------
        // 2.2 Data Selectors
        // ---------------------------------------------------------------------
        case .first:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                return items.first?.description ?? ""
            case .string(let s):
                return s.first != nil ? String(s.first!) : ""
            }

        case .last:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                return items.last?.description ?? ""
            case .string(let s):
                return s.last != nil ? String(s.last!) : ""
            }

        case .butFirst:
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

        case .butLast:
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

        case .item:
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

        case .pop:
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

        case .dequeue:
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

        case .remdup:
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
            case .array(let items):
                var unique: [LogoValue] = []
                for item in items {
                    if !unique.contains(item) { unique.append(item) }
                }
                return LogoValue.array(unique).description
            case .string(let s):
                var unique = ""
                for ch in s {
                    if !unique.contains(ch) { unique.append(ch) }
                }
                return unique
            }

        case .isWord:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            if case .string = p { return "1" }
            return "0"

        case .isList:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            if case .list = p { return "1" }
            return "0"

        case .isArray:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            if case .array = p { return "1" }
            return "0"

        case .isNumber:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return Double(v) != nil ? "1" : "0"

        case .isEmpty:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items): return items.isEmpty ? "1" : "0"
            case .string(let s): return s.isEmpty ? "1" : "0"
            }

        case .isEqual:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 == v2 ? "1" : "0"

        case .isNotEqual:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 != v2 ? "1" : "0"

        case .isBefore:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 < v2 ? "1" : "0"

        case .isMember:
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

        case .isSubstring:
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            return haystack.contains(needle) ? "1" : "0"

        case .less:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 < n2 ? "1" : "0"

        case .greater:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 > n2 ? "1" : "0"

        case .lessOrEqual:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 <= n2 ? "1" : "0"

        case .greaterOrEqual:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 >= n2 ? "1" : "0"

        // ---------------------------------------------------------------------
        // Editor Buffer Query Primitives
        // ---------------------------------------------------------------------
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

        // ---------------------------------------------------------------------
        // 4.1 & 4.3 - 4.5 Numeric, Math, Bitwise, Formatting
        // ---------------------------------------------------------------------
        case .sum:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a + b)

        case .difference:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a - b)

        case .product:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a * b)

        case .quotient, .quoted:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let b = Double(evaluateExpression(tokens, index: &index)) ?? 1
                return formatNum(b != 0 ? a / b : 0)
            }
            return formatNum(a != 0 ? 1.0 / a : 0)

        case .power:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(pow(a, b))

        case .remainder:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 1
            return "\(b != 0 ? a % b : 0)"

        case .modulo:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 1
            if b == 0 { return "0" }
            let r = a % b
            return "\(r >= 0 ? r : r + abs(b))"

        case .minus:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(-a)

        case .abs:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(abs(a))

        case .int:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(Int(a))"

        case .round:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(Int(round(a)))"

        case .sqrt:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sqrt(max(0, a)))

        case .exp:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(exp(a))

        case .log10:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 1
            return formatNum(log10(max(0.00001, a)))

        case .ln:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 1
            return formatNum(log(max(0.00001, a)))

        case .arctan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(atan(a) * 180.0 / .pi)

        case .sin:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sin(a * .pi / 180.0))

        case .cos:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(cos(a * .pi / 180.0))

        case .tan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(tan(a * .pi / 180.0))

        case .radArctan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(atan(a))

        case .radSin:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sin(a))

        case .radCos:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(cos(a))

        case .radTan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(tan(a))

        case .iseq:
            index += 1
            let start = Int(evaluateExpression(tokens, index: &index)) ?? 1
            index += 1
            let end = Int(evaluateExpression(tokens, index: &index)) ?? start
            var step = start <= end ? 1 : -1
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let parsedStep = Int(evaluateExpression(tokens, index: &index)) ?? step
                if parsedStep != 0 {
                    step = parsedStep
                }
            }
            let seq = Array(stride(from: start, through: end, by: step))
            return LogoValue.list(seq.map { LogoValue.string("\($0)") }).description

        case .rseq:
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

        case .random:
            index += 1
            let firstVal = Int(evaluateExpression(tokens, index: &index)) ?? 10
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let secondVal = Int(evaluateExpression(tokens, index: &index)) ?? firstVal
                let low = min(firstVal, secondVal)
                let high = max(firstVal, secondVal)
                return "\(Int.random(in: low...high))"
            }
            let upperLimit = max(1, firstVal)
            return "\(Int.random(in: 0..<upperLimit))"

        case .rerandom:
            return "1"

        case .form:
            index += 1
            let val = Double(evaluateExpression(tokens, index: &index)) ?? 0.0
            index += 1
            let width = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let prec = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return String(format: "%*.*f", width, prec, val)

        case .bitAnd:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a & b)"

        case .bitOr:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a | b)"

        case .bitXor:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a ^ b)"

        case .bitNot:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\( ~a )"

        case .ashift, .lshift:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let shift = Int(evaluateExpression(tokens, index: &index)) ?? 0
            if shift >= 0 {
                return "\(a << shift)"
            } else {
                return "\(a >> (-shift))"
            }

        case .trueVal:
            return "1"

        case .falseVal:
            return "0"

        case .andLogic:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) && logoIsTrue(v2)) ? "1" : "0"

        case .orLogic:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) || logoIsTrue(v2)) ? "1" : "0"

        case .xorLogic:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) != logoIsTrue(v2)) ? "1" : "0"

        case .notLogic:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return logoIsTrue(v) ? "0" : "1"

        // ---------------------------------------------------------------------
        // 2.5 Queries & Misc
        // ---------------------------------------------------------------------
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
            let code = Int(evaluateExpression(tokens, index: &index)) ?? 0
            if let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return ""

        case .uppercase:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.uppercased()

        case .lowercase:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return v.lowercased()

        case .member:
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

        case .standout:
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

        case .parse, .runparse:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let toks = tokenize(v)
            return "[" + toks.joined(separator: " ") + "]"

        // ---------------------------------------------------------------------
        // 8.1 & 8.2 Control & Template-based Iteration Primitives
        // ---------------------------------------------------------------------
        case .apply:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            return applyTemplate(templateStr: templateStr, args: items)

        case .invoke:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            var args: [String] = []
            while index + 1 < tokens.count && !tokens[index + 1].hasPrefix("]") && tokens[index + 1] != ")" {
                index += 1
                let arg = evaluateExpression(tokens, index: &index)
                args.append(arg)
            }
            return applyTemplate(templateStr: templateStr, args: args)

        case .foreach:
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                _ = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
            }
            return ""

        case .map:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var results: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                results.append(res)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .mapSe:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var results: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let res = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                let resItems = LogoValue.parse(res).toListItems().map { $0.description }.filter { !$0.isEmpty }
                results.append(contentsOf: resItems)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .filter:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            var filtered: [String] = []
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let condRes = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                if logoIsTrue(condRes) {
                    filtered.append(item)
                }
            }
            return "[" + filtered.joined(separator: " ") + "]"

        case .find:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            if index + 1 < tokens.count { index += 1 }
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            for (i, item) in items.enumerated() {
                let rest = Array(items[(i + 1)...])
                let condRes = applyTemplate(templateStr: templateStr, args: [item], indexInLoop: i + 1, restList: rest)
                if logoIsTrue(condRes) {
                    return item
                }
            }
            return "[]"

        case .reduce:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            guard !items.isEmpty else { return "[]" }
            var acc = items[0]
            for (i, item) in items.dropFirst().enumerated() {
                let rest = Array(items[(i + 2)...])
                acc = applyTemplate(templateStr: templateStr, args: [acc, item], indexInLoop: i + 2, restList: rest)
            }
            return acc

        case .crossmap:
            index += 1
            let templateStr = evaluateExpression(tokens, index: &index)
            index += 1
            let listListStr = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(listListStr)
            var listsOfItems: [[String]] = []
            switch parsed {
            case .list(let subLists):
                for sub in subLists {
                    listsOfItems.append(sub.toListItems().map { $0.description })
                }
            default:
                listsOfItems.append(parsed.toListItems().map { $0.description })
            }

            func cartesianProduct(_ arrays: [[String]]) -> [[String]] {
                guard let first = arrays.first else { return [[]] }
                let subProduct = cartesianProduct(Array(arrays.dropFirst()))
                var res: [[String]] = []
                for f in first {
                    for sub in subProduct {
                        res.append([f] + sub)
                    }
                }
                return res
            }

            let combos = cartesianProduct(listsOfItems)
            var results: [String] = []
            for (i, combo) in combos.enumerated() {
                let res = applyTemplate(templateStr: templateStr, args: combo, indexInLoop: i + 1)
                results.append(res)
            }
            return "[" + results.joined(separator: " ") + "]"

        case .sort:
            index += 1
            guard index < tokens.count else { return "[]" }
            var isDesc = false
            var customTemplate: String? = nil

            let firstToken = tokens[index]
            let firstUpper = unquote(firstToken).uppercased()

            if firstUpper == "DESC" {
                isDesc = true
                index += 1
            } else if firstUpper == "ASC" {
                isDesc = false
                index += 1
            }

            guard index < tokens.count else { return "[]" }
            let targetValStr = evaluateExpression(tokens, index: &index)

            if index + 1 < tokens.count && (tokens[index + 1].hasPrefix("[") || customProcedures[tokens[index + 1].uppercased()] != nil) {
                index += 1
                customTemplate = evaluateExpression(tokens, index: &index)
            }

            let parsed = LogoValue.parse(targetValStr)

            func isLessThan(_ aStr: String, _ bStr: String) -> Bool {
                if let t = customTemplate, !t.isEmpty {
                    let res = applyTemplate(templateStr: t, args: [aStr, bStr])
                    return logoIsTrue(res)
                }
                if let n1 = Double(aStr), let n2 = Double(bStr) {
                    return isDesc ? n1 > n2 : n1 < n2
                }
                return isDesc ? aStr > bStr : aStr < bStr
            }

            switch parsed {
            case .list(let items):
                let sortedItems = items.sorted { isLessThan($0.description, $1.description) }
                return LogoValue.list(sortedItems).description

            case .array(let items):
                let sortedItems = items.sorted { isLessThan($0.description, $1.description) }
                return LogoValue.array(sortedItems).description

            case .string(let s):
                if customTemplate == nil {
                    let sortedChars = isDesc ? Array(s).sorted(by: >) : Array(s).sorted(by: <)
                    return String(sortedChars)
                } else {
                    let sortedChars = Array(s).map { String($0) }.sorted { isLessThan($0, $1) }
                    return sortedChars.joined()
                }
            }

        case .date:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date())

        case .time:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: Date())

        default:
            return nil
        }
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

extension LogoValue {
    internal func toListItems() -> [LogoValue] {
        switch self {
        case .list(let items), .array(let items): return items
        case .string(let s): return [.string(s)]
        }
    }
}
