import Foundation

extension LogoEngine {
    private func normalizeProcedureName(_ raw: String) -> String {
        unquote(raw.trimmingCharacters(in: CharacterSet(charactersIn: "()"))).uppercased()
    }

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
            func createMDArray(dims: [Int]) -> LogoValue {
                guard let first = dims.first else { return .string("0") }
                let count = max(0, first)
                if count == 0 { return .array([]) }
                let rest = Array(dims.dropFirst())
                if rest.isEmpty {
                    let items = Array(repeating: LogoValue.string("0"), count: count)
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
            return switch parsed {
            case .list(let items): LogoValue.array(items).description
            default: LogoValue.array([parsed]).description
            }

        case .arrayToList:
            index += 1
            let val = evaluateExpression(tokens, index: &index)
            let parsed = LogoValue.parse(val)
            return switch parsed {
            case .array(let items): LogoValue.list(items).description
            default: LogoValue.list([parsed]).description
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
            return switch p {
            case .list(let items): LogoValue.list(items.reversed()).description
            case .array(let items): LogoValue.array(items.reversed()).description
            case .string(let s): String(s.reversed())
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

            let delimStr = unquote(delimVal)
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
                } else {
                    indices = idxVal.split(separator: " ").compactMap { Int($0) }
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

        case .pprop:
            index += 1
            let nameVal = evaluateExpression(tokens, index: &index)
            index += 1
            let propVal = evaluateExpression(tokens, index: &index)
            index += 1
            let valStr = evaluateExpression(tokens, index: &index)
            let name = unquote(nameVal).lowercased()
            let propName = unquote(propVal).lowercased()
            let val = LogoValue.parse(valStr)
            if propertyLists[name] == nil {
                propertyLists[name] = [:]
            }
            propertyLists[name]?[propName] = val
            return val.description

        case .gprop:
            index += 1
            let nameVal = evaluateExpression(tokens, index: &index)
            index += 1
            let propVal = evaluateExpression(tokens, index: &index)
            let name = unquote(nameVal).lowercased()
            let propName = unquote(propVal).lowercased()
            if let val = propertyLists[name]?[propName] {
                return val.description
            }
            return "[]"

        case .remprop:
            index += 1
            let nameVal = evaluateExpression(tokens, index: &index)
            index += 1
            let propVal = evaluateExpression(tokens, index: &index)
            let name = unquote(nameVal).lowercased()
            let propName = unquote(propVal).lowercased()
            propertyLists[name]?.removeValue(forKey: propName)
            if propertyLists[name]?.isEmpty == true {
                propertyLists.removeValue(forKey: name)
            }
            return ""

        case .plist:
            index += 1
            let nameVal = evaluateExpression(tokens, index: &index)
            let name = unquote(nameVal).lowercased()
            guard let props = propertyLists[name], !props.isEmpty else {
                return "[]"
            }
            var items: [LogoValue] = []
            for (k, v) in props {
                items.append(.string(k))
                items.append(v)
            }
            return LogoValue.list(items).description

        case .plists:
            let keys = Array(propertyLists.keys.filter { !(propertyLists[$0]?.isEmpty ?? true) }).sorted()
            return LogoValue.list(keys.map { .string($0) }).description

        case .error:
            if let err = lastError {
                return err.toLogoListString
            }
            return "[]"

        case .names:
            let keys = Array(variables.keys).sorted()
            return LogoValue.list(keys.map { .string($0) }).description

        case .procedures:
            let keys = Array(customProcedures.keys).sorted()
            return LogoValue.list(keys.map { .string($0) }).description

        case .primitives:
            let keys = LogoPrimitive.keywordAliases
            return LogoValue.list(keys.map { .string($0) }).description

        case .contents:
            let procs = LogoValue.list(Array(customProcedures.keys).sorted().map { .string($0) })
            let vars = LogoValue.list(Array(variables.keys).sorted().map { .string($0) })
            let plists = LogoValue.list(Array(propertyLists.keys.filter { !(propertyLists[$0]?.isEmpty ?? true) }).sorted().map { .string($0) })
            return LogoValue.list([procs, vars, plists]).description

        case .text:
            index += 1
            let nameVal = evaluateExpression(tokens, index: &index)
            let name = unquote(nameVal).uppercased()
            guard let proc = customProcedures[name] else { return "[]" }
            let paramsList = LogoValue.list(proc.parameters.map { .string(":" + $0) })
            let bodyList = LogoValue.list(proc.bodyTokens.map { .string($0) })
            return LogoValue.list([paramsList, bodyList]).description

        case .arity:
            index += 1
            let nameVal = evaluateExpression(tokens, index: &index)
            let name = unquote(nameVal).uppercased()
            if let proc = customProcedures[name] {
                return "\(proc.parameters.count)"
            }
            return "1"

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

        case .member:
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            let p = LogoValue.parse(haystack)
            let target = LogoValue.parse(needle).description
            switch p {
            case .list(let items):
                guard let matchIndex = items.firstIndex(where: { $0.description == target }) else { return "" }
                return LogoValue.list(Array(items[matchIndex...])).description
            case .array(let items):
                guard let matchIndex = items.firstIndex(where: { $0.description == target }) else { return "" }
                return LogoValue.array(Array(items[matchIndex...])).description
            case .string(let s):
                guard let range = s.range(of: target) else { return "" }
                return String(s[range.lowerBound...])
            }

        case .parse, .runparse:
            index += 1
            let script = evaluateExpression(tokens, index: &index)
            return "[" + tokenize(script).joined(separator: " ") + "]"

        case .isSubstring:
            index += 1
            let needle = evaluateExpression(tokens, index: &index)
            index += 1
            let haystack = evaluateExpression(tokens, index: &index)
            return haystack.contains(needle) ? "true" : "false"

        case .isProcedure:
            index += 1
            let name = normalizeProcedureName(evaluateExpression(tokens, index: &index))
            let exists = LogoPrimitive.from(name) != nil || customProcedures[name] != nil
            return exists ? "true" : "false"

        case .isPrimitive:
            index += 1
            let name = normalizeProcedureName(evaluateExpression(tokens, index: &index))
            return LogoPrimitive.from(name) != nil ? "true" : "false"

        case .isDefined:
            index += 1
            let name = normalizeProcedureName(evaluateExpression(tokens, index: &index))
            return customProcedures[name] != nil ? "true" : "false"

        case .isName:
            index += 1
            let name = normalizeVariableName(evaluateExpression(tokens, index: &index))
            return variables[name] != nil ? "true" : "false"

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

        case .indexof:
            index += 1
            let needle = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let haystack = unquote(evaluateExpression(tokens, index: &index))
            var startFrom = 1
            if index + 1 < tokens.count && !Self.isArgumentBoundary(tokens[index + 1]) {
                var nextIdx = index + 1
                if let startVal = Int(evaluateExpression(tokens, index: &nextIdx)), startVal > 0 {
                    index = nextIdx
                    startFrom = startVal
                }
            }
            let chars = Array(haystack)
            if startFrom <= chars.count {
                let searchSub = String(chars[(startFrom - 1)...])
                if let range = searchSub.range(of: needle) {
                    let offset = searchSub.distance(from: searchSub.startIndex, to: range.lowerBound)
                    return "\(startFrom + offset)"
                }
            }
            return "0"

        case .lastindexof:
            index += 1
            let needle = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let haystack = unquote(evaluateExpression(tokens, index: &index))
            if let range = haystack.range(of: needle, options: .backwards) {
                let idx = haystack.distance(from: haystack.startIndex, to: range.lowerBound) + 1
                return "\(idx)"
            }
            return "0"

        case .indexesof:
            index += 1
            let needle = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let haystack = unquote(evaluateExpression(tokens, index: &index))
            guard !needle.isEmpty else { return "[]" }
            var matches: [Int] = []
            var searchRange = haystack.startIndex..<haystack.endIndex
            while let range = haystack.range(of: needle, options: [], range: searchRange) {
                let idx = haystack.distance(from: haystack.startIndex, to: range.lowerBound) + 1
                matches.append(idx)
                searchRange = range.upperBound..<haystack.endIndex
            }
            return LogoValue.list(matches.map { LogoValue.string("\($0)") }).description

        case .contains:
            index += 1
            let needle = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let haystack = unquote(evaluateExpression(tokens, index: &index))
            return haystack.contains(needle) ? "true" : "false"

        case .startswith:
            index += 1
            let prefix = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let string = unquote(evaluateExpression(tokens, index: &index))
            return string.hasPrefix(prefix) ? "true" : "false"

        case .endswith:
            index += 1
            let suffix = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let string = unquote(evaluateExpression(tokens, index: &index))
            return string.hasSuffix(suffix) ? "true" : "false"

        case .substring:
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let startVal = Int(evaluateExpression(tokens, index: &index)) ?? 1
            var lengthVal: Int? = nil
            if index + 1 < tokens.count && !Self.isArgumentBoundary(tokens[index + 1]) {
                var nextIdx = index + 1
                if let len = Int(evaluateExpression(tokens, index: &nextIdx)), len >= 0 {
                    index = nextIdx
                    lengthVal = len
                }
            }
            let chars = Array(str)
            let zeroStart = max(0, startVal - 1)
            guard zeroStart < chars.count else { return "" }
            let maxLen = chars.count - zeroStart
            let effectiveLen = min(lengthVal ?? maxLen, maxLen)
            return String(chars[zeroStart..<(zeroStart + effectiveLen)])

        case .replace:
            index += 1
            let target = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let replacement = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            return str.replacingOccurrences(of: target, with: replacement)

        case .trim:
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            return str.trimmingCharacters(in: .whitespacesAndNewlines)

        case .repeatstr:
            index += 1
            let countVal = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            guard countVal > 0 else { return "" }
            return String(repeating: str, count: countVal)

        case .join:
            index += 1
            let delim = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            return items.joined(separator: delim)

        case .lines:
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            let lineItems = str.components(separatedBy: .newlines)
            return LogoValue.list(lineItems.map { LogoValue.string($0) }).description

        case .unlines:
            index += 1
            let listStr = evaluateExpression(tokens, index: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            return items.joined(separator: "\n")

        case .format:
            index += 1
            let pattern = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let argVal = evaluateExpression(tokens, index: &index)
            let rawArgs = LogoValue.parse(argVal).toListItems().map { $0.description }
            return formatStringPattern(pattern: pattern, args: rawArgs)

        case .padleft:
            index += 1
            let arg1 = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let arg2 = unquote(evaluateExpression(tokens, index: &index))
            var str = ""
            var width = 0
            var padChar = " "

            if let w1 = Int(arg1) {
                width = w1
                if index + 1 < tokens.count && !Self.isArgumentBoundary(tokens[index + 1]) {
                    padChar = arg2
                    index += 1
                    str = unquote(evaluateExpression(tokens, index: &index))
                } else {
                    str = arg2
                }
            } else {
                str = arg1
                width = Int(arg2) ?? 0
                if index + 1 < tokens.count && !Self.isArgumentBoundary(tokens[index + 1]) {
                    var nextIdx = index + 1
                    let chCandidate = unquote(evaluateExpression(tokens, index: &nextIdx))
                    if !chCandidate.isEmpty && chCandidate.count == 1 {
                        index = nextIdx
                        padChar = chCandidate
                    }
                }
            }

            let currentWidth = str.reduce(0) { $0 + $1.displayWidth }
            if currentWidth >= width { return str }
            let padCount = width - currentWidth
            return String(repeating: padChar, count: padCount) + str

        case .padright:
            index += 1
            let arg1 = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let arg2 = unquote(evaluateExpression(tokens, index: &index))
            var str = ""
            var width = 0
            var padChar = " "

            if let w1 = Int(arg1) {
                width = w1
                if index + 1 < tokens.count && !Self.isArgumentBoundary(tokens[index + 1]) {
                    padChar = arg2
                    index += 1
                    str = unquote(evaluateExpression(tokens, index: &index))
                } else {
                    str = arg2
                }
            } else {
                str = arg1
                width = Int(arg2) ?? 0
                if index + 1 < tokens.count && !Self.isArgumentBoundary(tokens[index + 1]) {
                    var nextIdx = index + 1
                    let chCandidate = unquote(evaluateExpression(tokens, index: &nextIdx))
                    if !chCandidate.isEmpty && chCandidate.count == 1 {
                        index = nextIdx
                        padChar = chCandidate
                    }
                }
            }

            let currentWidth = str.reduce(0) { $0 + $1.displayWidth }
            if currentWidth >= width { return str }
            let padCount = width - currentWidth
            return str + String(repeating: padChar, count: padCount)

        case .regexMatch:
            index += 1
            let pattern = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(str.startIndex..., in: str)
                return regex.firstMatch(in: str, range: range) != nil ? "true" : "false"
            }
            return "false"

        case .regexReplace:
            index += 1
            let pattern = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let replacement = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(str.startIndex..., in: str)
                return regex.stringByReplacingMatches(in: str, range: range, withTemplate: replacement)
            }
            return str

        case .regexFind:
            index += 1
            let pattern = unquote(evaluateExpression(tokens, index: &index))
            index += 1
            let str = unquote(evaluateExpression(tokens, index: &index))
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(str.startIndex..., in: str)
                let matches = regex.matches(in: str, range: range)
                let items = matches.compactMap { match -> String? in
                    guard let r = Range(match.range, in: str) else { return nil }
                    return String(str[r])
                }
                return LogoValue.list(items.map { LogoValue.string($0) }).description
            }
            return "[]"

        default:
            return nil
        }
    }

    private func formatStringPattern(pattern: String, args: [String]) -> String {
        var result = ""
        var argIndex = 0
        let chars = Array(pattern)
        var i = 0

        while i < chars.count {
            if chars[i] == "%" && i + 1 < chars.count {
                i += 1
                if chars[i] == "%" {
                    result.append("%")
                    i += 1
                    continue
                }

                var posDigits = ""
                let posStart = i
                while i < chars.count && chars[i].isNumber {
                    posDigits.append(chars[i])
                    i += 1
                }
                if !posDigits.isEmpty, let posIdx = Int(posDigits), posIdx > 0,
                    i == chars.count || !("sSdfxX".contains(chars[i]))
                {
                    let targetVal = posIdx <= args.count ? args[posIdx - 1] : ""
                    result.append(targetVal)
                    continue
                } else {
                    i = posStart
                }

                var specifier = "%"
                while i < chars.count {
                    let ch = chars[i]
                    specifier.append(ch)
                    i += 1
                    if "sSdfxX".contains(ch) {
                        break
                    }
                }

                let currentArg = argIndex < args.count ? args[argIndex] : ""
                argIndex += 1

                let lastChar = specifier.last ?? "s"
                let trimmedArg = currentArg.trimmingCharacters(in: .whitespacesAndNewlines)
                if lastChar == "d" || lastChar == "D" {
                    let intVal = Int(trimmedArg) ?? Int(Double(trimmedArg) ?? 0.0)
                    result.append(String(format: specifier, CInt(intVal)))
                } else if lastChar == "x" || lastChar == "X" {
                    let intVal = Int(trimmedArg) ?? Int(Double(trimmedArg) ?? 0.0)
                    result.append(String(format: specifier, CInt(intVal)))
                } else if lastChar == "f" {
                    let dblVal = Double(trimmedArg) ?? 0.0
                    result.append(String(format: specifier, dblVal))
                } else {
                    if specifier.contains("-") || specifier.contains("0") || specifier.count > 2 {
                        let widthStr = specifier.dropFirst().dropLast()
                        let alignLeft = widthStr.hasPrefix("-")
                        let cleanWidth = Int(widthStr.replacingOccurrences(of: "-", with: "")) ?? 0
                        let dispW = currentArg.reduce(0) { $0 + $1.displayWidth }
                        if dispW < cleanWidth {
                            let pad = String(repeating: " ", count: cleanWidth - dispW)
                            result.append(alignLeft ? currentArg + pad : pad + currentArg)
                        } else {
                            result.append(currentArg)
                        }
                    } else {
                        result.append(currentArg)
                    }
                }
            } else {
                result.append(chars[i])
                i += 1
            }
        }
        return result
    }
}
