import Foundation

extension LogoEngine {
    /// Evaluates UCB LOGO Data Structure Primitives (constructors, selectors, mutators, predicates, queries).
    internal func evaluateDataStructurePrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        // ---------------------------------------------------------------------
        // 2.1 Constructors
        // ---------------------------------------------------------------------
        case .thing:
            index += 1
            let name = evaluateExpression(tokens, index: &index)
            return variables[normalizeVariableName(name)] ?? ""

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

        case .mdarray:
            index += 1
            let sizeVal = evaluateExpression(tokens, index: &index)
            let sizeList = LogoValue.parse(sizeVal)
            var dimensions: [Int] = []
            switch sizeList {
            case .list(let items), .array(let items):
                dimensions = items.compactMap { Int($0.description) }
            default:
                if let single = Int(sizeVal) {
                    dimensions = [single]
                }
            }
            let _ = optionalCommandArgument(tokens, index: &index)

            func createMDArray(dims: [Int]) -> LogoValue {
                guard let first = dims.first else { return .string("") }
                let count = max(1, first)
                let rest = Array(dims.dropFirst())
                if rest.isEmpty {
                    let items = Array(repeating: LogoValue.string(""), count: count)
                    return .array(items)
                } else {
                    let inner = createMDArray(dims: rest)
                    let items = Array(repeating: inner, count: count)
                    return .array(items)
                }
            }

            return createMDArray(dims: dimensions).description

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

        case .firsts:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                let firstItems = items.map { item -> LogoValue in
                    switch item {
                    case .list(let subItems), .array(let subItems):
                        return subItems.first ?? .string("")
                    case .string(let s):
                        return s.first != nil ? .string(String(s.first!)) : .string("")
                    }
                }
                return LogoValue.list(firstItems).description
            case .string(let s):
                let firstItems = s.map { LogoValue.string(String($0)) }
                return LogoValue.list(firstItems).description
            }

        case .butFirsts:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                let bfItems = items.map { item -> LogoValue in
                    switch item {
                    case .list(let subItems):
                        return .list(Array(subItems.dropFirst()))
                    case .array(let subItems):
                        return .array(Array(subItems.dropFirst()))
                    case .string(let s):
                        return .string(String(s.dropFirst()))
                    }
                }
                return LogoValue.list(bfItems).description
            case .string(let s):
                return String(s.dropFirst())
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

        case .pick:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                guard !items.isEmpty else { return "" }
                let randomIdx = Int.random(in: 0..<items.count)
                return items[randomIdx].description
            case .string(let s):
                guard !s.isEmpty else { return "" }
                let randomIdx = Int.random(in: 0..<s.count)
                let strIdx = s.index(s.startIndex, offsetBy: randomIdx)
                return String(s[strIdx])
            }

        case .remove:
            index += 1
            let thing = evaluateExpression(tokens, index: &index)
            index += 1
            let dataVal = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(dataVal)
            let targetStr = LogoValue.parse(thing).description

            switch p {
            case .list(let items):
                let filtered = items.filter { $0.description != targetStr }
                return LogoValue.list(filtered).description
            case .array(let items):
                let filtered = items.filter { $0.description != targetStr }
                return LogoValue.array(filtered).description
            case .string(let s):
                if targetStr.count == 1, let targetChar = targetStr.first {
                    let filtered = s.filter { $0 != targetChar }
                    return String(filtered)
                } else {
                    let filtered = s.replacingOccurrences(of: targetStr, with: "")
                    return filtered
                }
            }

        case .remdup:
            index += 1
            let dataVal = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(dataVal)

            switch p {
            case .list(let items):
                var seen = Set<String>()
                var result: [LogoValue] = []
                for item in items {
                    let desc = item.description
                    if !seen.contains(desc) {
                        seen.insert(desc)
                        result.append(item)
                    }
                }
                return LogoValue.list(result).description
            case .array(let items):
                var seen = Set<String>()
                var result: [LogoValue] = []
                for item in items {
                    let desc = item.description
                    if !seen.contains(desc) {
                        seen.insert(desc)
                        result.append(item)
                    }
                }
                return LogoValue.array(result).description
            case .string(let s):
                var seen = Set<Character>()
                var result = ""
                for ch in s {
                    if !seen.contains(ch) {
                        seen.insert(ch)
                        result.append(ch)
                    }
                }
                return result
            }

        case .split:
            index += 1
            let delimVal = evaluateExpression(tokens, index: &index)
            index += 1
            let dataVal = evaluateExpression(tokens, index: &index)

            let delimStr = LogoValue.parse(delimVal).description
            let dataParsed = LogoValue.parse(dataVal)

            switch dataParsed {
            case .list(let items):
                var result: [LogoValue] = []
                var currentChunk: [LogoValue] = []
                for item in items {
                    if item.description == delimStr {
                        result.append(.list(currentChunk))
                        currentChunk = []
                    } else {
                        currentChunk.append(item)
                    }
                }
                result.append(.list(currentChunk))
                return LogoValue.list(result).description

            case .array(let items):
                var result: [LogoValue] = []
                var currentChunk: [LogoValue] = []
                for item in items {
                    if item.description == delimStr {
                        result.append(.array(currentChunk))
                        currentChunk = []
                    } else {
                        currentChunk.append(item)
                    }
                }
                result.append(.array(currentChunk))
                return LogoValue.array(result).description

            case .string(let s):
                let parts = s.components(separatedBy: delimStr)
                let nonSpaceParts = parts.filter { !$0.isEmpty }
                let listItems = nonSpaceParts.map { LogoValue.string($0) }
                return LogoValue.list(listItems).description
            }

        case .quoted:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(v)
            let s = parsed.description
            if s.hasPrefix("\"") {
                return s
            }
            return "\"" + s

        case .mditem:
            index += 1
            let idxVal = evaluateExpression(tokens, index: &index)
            index += 1
            let dataVal = evaluateExpression(tokens, index: &index)

            let indicesList = LogoValue.parse(idxVal)
            var indices: [Int] = []
            switch indicesList {
            case .list(let items), .array(let items):
                indices = items.compactMap { Int($0.description) }
            default:
                if let single = Int(idxVal) {
                    indices = [single]
                }
            }

            var currentVal = LogoValue.parse(dataVal)
            for idx in indices {
                let zeroIdx = idx - 1
                switch currentVal {
                case .list(let items), .array(let items):
                    guard zeroIdx >= 0 && zeroIdx < items.count else { return "" }
                    currentVal = items[zeroIdx]
                case .string(let s):
                    guard zeroIdx >= 0 && zeroIdx < s.count else { return "" }
                    let strIdx = s.index(s.startIndex, offsetBy: zeroIdx)
                    currentVal = .string(String(s[strIdx]))
                }
            }
            return currentVal.description

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

        case .isWord:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            if case .string = p { return "true" }
            return "false"

        case .isList:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            if case .list = p { return "true" }
            return "false"

        case .isArray:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            if case .array = p { return "true" }
            return "false"

        case .isNumber:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return Double(v) != nil ? "true" : "false"

        case .isEmpty:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items): return items.isEmpty ? "true" : "false"
            case .string(let s): return s.isEmpty ? "true" : "false"
            }

        case .isEqual:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            if v1 == v2 { return "true" }
            if let d1 = Double(v1), let d2 = Double(v2) {
                return d1 == d2 ? "true" : "false"
            }
            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)
            return p1 == p2 ? "true" : "false"

        case .isNotEqual:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            if v1 == v2 { return "false" }
            if let d1 = Double(v1), let d2 = Double(v2) {
                return d1 != d2 ? "true" : "false"
            }
            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)
            return p1 != p2 ? "true" : "false"

        case .isIdentityEqual:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 == v2 ? "true" : "false"

        case .isBefore:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return v1 < v2 ? "true" : "false"

        case .isMember:
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(haystack)
            switch p {
            case .list(let items), .array(let items):
                return items.map { $0.description }.contains(needle) ? "true" : "false"
            case .string(let s):
                return s.contains(needle) ? "true" : "false"
            }

        case .isSubstring:
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            return haystack.contains(needle) ? "true" : "false"

        case .less:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 < n2 ? "true" : "false"

        case .greater:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 > n2 ? "true" : "false"

        case .lessOrEqual:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 <= n2 ? "true" : "false"

        case .greaterOrEqual:
            index += 1
            let n1 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let n2 = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return n1 >= n2 ? "true" : "false"

        default:
            return nil
        }
    }
}
