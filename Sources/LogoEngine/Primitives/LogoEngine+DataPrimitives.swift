import Foundation

extension LogoEngine {
    private func normalizeProcedureName(_ raw: String) -> String {
        unquote(raw.trimmingCharacters(in: CharacterSet(charactersIn: "()"))).uppercased()
    }

    /// Evaluates UCB LOGO Data Structure Primitives (constructors, selectors, mutators, predicates, queries).
    internal func evaluateDataStructurePrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = parsePrimitive(tokens[index]) else { return nil }

        switch prim {
        // ---------------------------------------------------------------------
        // 2.1 Constructors
        // ---------------------------------------------------------------------
        case .thing:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let name = reader.nextExpression()
            reader.commit(to: &index)
            return variables[normalizeVariableName(name)] ?? ""

        case .word:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            return v1 + v2

        case .list:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            return "[\(v1) \(v2)]"

        case .sentence:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)

            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)

            var items: [LogoValue] = []
            switch p1 {
            case .list(let listItems), .array(let listItems): items.append(contentsOf: listItems)
            case .measurement(let v, let u, _):
                items.append(contentsOf: [.string(LogoMeasurementConverter.formatResult(v)), .string(u)])
            case .date: items.append(.string(p1.stringValue))
            case .string(let s): items.append(.string(s))
            }
            switch p2 {
            case .list(let listItems), .array(let listItems): items.append(contentsOf: listItems)
            case .measurement(let v, let u, _):
                items.append(contentsOf: [.string(LogoMeasurementConverter.formatResult(v)), .string(u)])
            case .date: items.append(.string(p2.stringValue))
            case .string(let s): items.append(.string(s))
            }
            return LogoValue.list(items).description

        case .fput:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)

            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)

            switch p2 {
            case .list(var items):
                items.insert(p1, at: 0)
                return LogoValue.list(items).description
            case .array(var items):
                items.insert(p1, at: 0)
                return LogoValue.array(items).description
            case .measurement(let v, let u, _):
                return LogoValue.list([p1, .string(LogoMeasurementConverter.formatResult(v)), .string(u)]).description
            case .date:
                return LogoValue.list([p1, p2]).description
            case .string(let s):
                return v1 + s
            }

        case .lput:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)

            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)

            switch p2 {
            case .list(var items):
                items.append(p1)
                return LogoValue.list(items).description
            case .array(var items):
                items.append(p1)
                return LogoValue.array(items).description
            case .measurement(let v, let u, _):
                return LogoValue.list([.string(LogoMeasurementConverter.formatResult(v)), .string(u), p1]).description
            case .date:
                return LogoValue.list([p2, p1]).description
            case .string(let s):
                return s + v1
            }

        case .array:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let sizeVal = reader.nextExpression()
            reader.commit(to: &index)
            let sizeList = LogoValue.parse(sizeVal)
            var dimensions: [Int] = []
            switch sizeList {
            case .list(let items), .array(let items):
                dimensions = items.compactMap { Int($0.description) }
            case .measurement(let v, _, _):
                dimensions = [Int(v)]
            case .date:
                break
            case .string(let s):
                if let single = Int(s) {
                    dimensions = [single]
                } else {
                    dimensions = s.split(separator: " ").compactMap { Int($0) }
                }
            }
            guard !dimensions.isEmpty else { return "{}" }

            let totalElements = dimensions.reduce(1, *)
            let items = Array(repeating: LogoValue.string(""), count: max(1, totalElements))
            return LogoValue.array(items).description

        case .mdarray:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let sizeVal = reader.nextExpression()
            reader.commit(to: &index)
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
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let val = reader.nextExpression()
            reader.commit(to: &index)
            let parsed = LogoValue.parse(val)
            return switch parsed {
            case .list(let items): LogoValue.array(items).description
            default: LogoValue.array([parsed]).description
            }

        case .arrayToList:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let val = reader.nextExpression()
            reader.commit(to: &index)
            let parsed = LogoValue.parse(val)
            return switch parsed {
            case .array(let items): LogoValue.list(items).description
            default: LogoValue.list([parsed]).description
            }

        case .combine:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            let p2 = LogoValue.parse(v2)
            if case .string(let s) = p2 {
                return v1 + s
            } else if case .list(var items) = p2 {
                items.insert(LogoValue.parse(v1), at: 0)
                return LogoValue.list(items).description
            }
            return ""

        case .reverse:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            return switch p {
            case .list(let items): LogoValue.list(items.reversed()).description
            case .array(let items): LogoValue.array(items.reversed()).description
            case .measurement(let v, let u, _):
                LogoValue.list([.string(u), .string(LogoMeasurementConverter.formatResult(v))]).description
            case .date: p.description
            case .string(let s): String(s.reversed())
            }

        case .gensym:
            gensymCounter += 1
            return "G\(gensymCounter)"

        // ---------------------------------------------------------------------
        // 2.2 Data Selectors
        // ---------------------------------------------------------------------
        case .first:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                return items.first?.description ?? ""
            case .measurement(let v, _, _):
                return LogoMeasurementConverter.formatResult(v)
            case .date:
                return p.description
            case .string(let s):
                return s.first != nil ? String(s.first!) : ""
            }

        case .last:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                return items.last?.description ?? ""
            case .measurement(_, let u, _):
                return u
            case .date:
                return p.description
            case .string(let s):
                return s.last != nil ? String(s.last!) : ""
            }

        case .firsts:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                let firstItems = items.map { item -> LogoValue in
                    switch item {
                    case .list(let subItems), .array(let subItems):
                        return subItems.first ?? .string("")
                    case .measurement(let v, _, _):
                        return .string(LogoMeasurementConverter.formatResult(v))
                    case .date:
                        return .string(item.description)
                    case .string(let s):
                        return s.first != nil ? .string(String(s.first!)) : .string("")
                    }
                }
                return LogoValue.list(firstItems).description
            case .measurement(let v, _, _):
                return LogoValue.list([.string(LogoMeasurementConverter.formatResult(v))]).description
            case .date:
                return p.description
            case .string(let s):
                let firstItems = s.map { LogoValue.string(String($0)) }
                return LogoValue.list(firstItems).description
            }

        case .butFirsts:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                let bfItems = items.map { item -> LogoValue in
                    switch item {
                    case .list(let subItems):
                        return .list(Array(subItems.dropFirst()))
                    case .array(let subItems):
                        return .array(Array(subItems.dropFirst()))
                    case .measurement(_, let u, _):
                        return .list([.string(u)])
                    case .date:
                        return .string("")
                    case .string(let s):
                        return .string(String(s.dropFirst()))
                    }
                }
                return LogoValue.list(bfItems).description
            case .measurement(_, let u, _):
                return LogoValue.list([.string(u)]).description
            case .date:
                return ""
            case .string(let s):
                return String(s.dropFirst())
            }

        case .butFirst:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items):
                let rest = items.dropFirst()
                return LogoValue.list(Array(rest)).description
            case .array(let items):
                let rest = items.dropFirst()
                return LogoValue.array(Array(rest)).description
            case .measurement(_, let u, _):
                return LogoValue.list([.string(u)]).description
            case .date:
                return ""
            case .string(let s):
                return String(s.dropFirst())
            }

        case .butLast:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items):
                let rest = items.dropLast()
                return LogoValue.list(Array(rest)).description
            case .array(let items):
                let rest = items.dropLast()
                return LogoValue.array(Array(rest)).description
            case .measurement(let v, _, _):
                return LogoValue.list([.string(LogoMeasurementConverter.formatResult(v))]).description
            case .date:
                return ""
            case .string(let s):
                return String(s.dropLast())
            }

        case .item:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let idxVal = reader.nextInteger(default: 1)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            let zeroIdx = idxVal - 1
            switch p {
            case .list(let items), .array(let items):
                if zeroIdx >= 0 && zeroIdx < items.count {
                    return items[zeroIdx].description
                }
                return ""
            case .measurement(let v, let u, _):
                if zeroIdx == 0 { return LogoMeasurementConverter.formatResult(v) }
                if zeroIdx == 1 { return u }
                return ""
            case .date:
                return zeroIdx == 0 ? p.description : ""
            case .string(let s):
                let chars = Array(s)
                if zeroIdx >= 0 && zeroIdx < chars.count {
                    return String(chars[zeroIdx])
                }
                return ""
            }

        case .pick:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items):
                guard !items.isEmpty else { return "" }
                let randomIdx = Int.random(in: 0..<items.count)
                return items[randomIdx].description
            case .measurement(let v, let u, _):
                return Bool.random() ? LogoMeasurementConverter.formatResult(v) : u
            case .date:
                return p.description
            case .string(let s):
                guard !s.isEmpty else { return "" }
                let randomIdx = Int.random(in: 0..<s.count)
                let strIdx = s.index(s.startIndex, offsetBy: randomIdx)
                return String(s[strIdx])
            }

        case .remove:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let thing = reader.nextExpression()
            let dataVal = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(dataVal)
            let targetStr = LogoValue.parse(thing).description

            switch p {
            case .list(let items):
                let filtered = items.filter { $0.description != targetStr }
                return LogoValue.list(filtered).description
            case .array(let items):
                let filtered = items.filter { $0.description != targetStr }
                return LogoValue.array(filtered).description
            case .measurement(let v, let u, _):
                let items: [LogoValue] = [.string(LogoMeasurementConverter.formatResult(v)), .string(u)]
                return LogoValue.list(items.filter { $0.description != targetStr }).description
            case .date:
                return p.description == targetStr ? "" : p.description
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
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let dataVal = reader.nextExpression()
            reader.commit(to: &index)
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
            case .measurement, .date:
                return p.description
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
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let delimVal = reader.nextExpression()
            let dataVal = reader.nextExpression()
            reader.commit(to: &index)

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

            case .measurement(let v, let u, _):
                let items: [LogoValue] = [.string(LogoMeasurementConverter.formatResult(v)), .string(u)]
                return LogoValue.list(items).description

            case .date:
                return LogoValue.list([dataParsed]).description

            case .string(let s):
                if delimStr.isEmpty {
                    return LogoValue.list(s.map { LogoValue.string(String($0)) }).description
                }
                let parts = s.components(separatedBy: delimStr)
                let nonSpaceParts = parts.filter { !$0.isEmpty }
                let listItems = nonSpaceParts.map { LogoValue.string($0) }
                return LogoValue.list(listItems).description
            }

        case .quoted:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let parsed = LogoValue.parse(v)
            let s = parsed.description
            if s.hasPrefix("\"") {
                return s
            }
            return "\"" + s

        case .mditem:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let idxVal = reader.nextExpression()
            let dataVal = reader.nextExpression()
            reader.commit(to: &index)

            let indicesList = LogoValue.parse(idxVal)
            var indices: [Int] = []
            switch indicesList {
            case .list(let items), .array(let items):
                indices = items.compactMap { Int($0.description) }
            case .measurement(let v, _, _):
                indices = [Int(v)]
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
                case .measurement(let v, let u, _):
                    if zeroIdx == 0 {
                        currentVal = .string(LogoMeasurementConverter.formatResult(v))
                    } else if zeroIdx == 1 {
                        currentVal = .string(u)
                    } else {
                        return ""
                    }
                case .date:
                    if zeroIdx == 0 {
                        currentVal = .string(currentVal.description)
                    } else {
                        return ""
                    }
                case .string(let s):
                    guard zeroIdx >= 0 && zeroIdx < s.count else { return "" }
                    let strIdx = s.index(s.startIndex, offsetBy: zeroIdx)
                    currentVal = .string(String(s[strIdx]))
                }
            }
            return currentVal.description

        case .pop:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let varToken = reader.nextRawToken() else { return "" }
            reader.commit(to: &index)
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
            case .measurement(let v, let u, _):
                variables[varName] = LogoValue.list([.string(u)]).description
                return LogoMeasurementConverter.formatResult(v)
            case .date:
                variables[varName] = ""
                return parsed.description
            case .string(let s):
                if !s.isEmpty {
                    let popped = String(s.first!)
                    variables[varName] = String(s.dropFirst())
                    return popped
                }
                return ""
            }

        case .dequeue:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let varToken = reader.nextRawToken() else { return "" }
            reader.commit(to: &index)
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
            case .measurement(let v, let u, _):
                variables[varName] = LogoValue.list([.string(u)]).description
                return LogoMeasurementConverter.formatResult(v)
            case .date:
                variables[varName] = ""
                return parsed.description
            case .string(let s):
                if !s.isEmpty {
                    let popped = String(s.first!)
                    variables[varName] = String(s.dropFirst())
                    return popped
                }
                return ""
            }

        case .pprop:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let nameVal = reader.nextExpression()
            let propVal = reader.nextExpression()
            let valStr = reader.nextExpression()
            reader.commit(to: &index)
            let name = unquote(nameVal).lowercased()
            let propName = unquote(propVal).lowercased()
            let val = LogoValue.parse(valStr)
            if propertyLists[name] == nil {
                propertyLists[name] = [:]
            }
            propertyLists[name]?[propName] = val
            return val.description

        case .gprop:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let nameVal = reader.nextExpression()
            let propVal = reader.nextExpression()
            reader.commit(to: &index)
            let name = unquote(nameVal).lowercased()
            let propName = unquote(propVal).lowercased()
            if let val = propertyLists[name]?[propName] {
                return val.description
            }
            return "[]"

        case .remprop:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let nameVal = reader.nextExpression()
            let propVal = reader.nextExpression()
            reader.commit(to: &index)
            let name = unquote(nameVal).lowercased()
            let propName = unquote(propVal).lowercased()
            propertyLists[name]?.removeValue(forKey: propName)
            if propertyLists[name]?.isEmpty == true {
                propertyLists.removeValue(forKey: name)
            }
            return ""

        case .plist:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let nameVal = reader.nextExpression()
            reader.commit(to: &index)
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
            let systemKeys: Set<String> = ["author", "version", "repository"]
            let keys = Array(variables.keys.filter { !systemKeys.contains($0) }).sorted()
            return LogoValue.list(keys.map { .string($0) }).description

        case .procedures:
            let keys = Array(customProcedures.keys).sorted()
            return LogoValue.list(keys.map { .string($0) }).description

        case .primitives:
            let keys = LogoPrimitive.keywordAliases
            return LogoValue.list(keys.map { .string($0) }).description

        case .contents:
            let systemKeys: Set<String> = ["author", "version", "repository"]
            let procs = LogoValue.list(Array(customProcedures.keys).sorted().map { .string($0) })
            let vars = LogoValue.list(
                Array(variables.keys.filter { !systemKeys.contains($0) }).sorted().map { .string($0) })
            let plists = LogoValue.list(
                Array(propertyLists.keys.filter { !(propertyLists[$0]?.isEmpty ?? true) }).sorted().map { .string($0) })
            return LogoValue.list([procs, vars, plists]).description

        case .text:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let nextToken = reader.peekToken() else { return "[]" }
            let upper = unquote(nextToken).uppercased()
            let name: String
            if customProcedures[upper] != nil {
                _ = reader.nextRawToken()
                name = upper
            } else {
                name = unquote(reader.nextExpression()).uppercased()
            }
            reader.commit(to: &index)
            guard let proc = customProcedures[name] else { return "[]" }
            let paramsList = LogoValue.list(proc.parameters.map { .string(":" + $0) })
            let bodyList = LogoValue.list(proc.bodyTokens.map { .string($0.text) })
            return LogoValue.list([paramsList, bodyList]).description

        case .arity:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let nextToken = reader.peekToken() else { return "1" }
            let upper = unquote(nextToken).uppercased()
            let name: String
            if customProcedures[upper] != nil {
                _ = reader.nextRawToken()
                name = upper
            } else {
                name = unquote(reader.nextExpression()).uppercased()
            }
            reader.commit(to: &index)
            if let proc = customProcedures[name] {
                return "\(proc.parameters.count)"
            }
            return "1"

        case .doc:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let nextToken = reader.peekToken() else { return "" }
            let upper = unquote(nextToken).uppercased()
            let name: String
            if customProcedures[upper] != nil || LogoPrimitive.from(upper) != nil {
                _ = reader.nextRawToken()
                name = upper
            } else {
                name = unquote(reader.nextExpression()).uppercased()
            }
            reader.commit(to: &index)
            if let proc = customProcedures[name] {
                return proc.docstring ?? ""
            }
            if let prim = LogoPrimitive.from(name) {
                return prim.meta.description
            }
            return ""

        case .isWord:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            let isWord =
                switch p {
                case .string: true
                default: false
                }
            return isWord.logoString

        case .isList:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            let isList =
                switch p {
                case .list: true
                default: false
                }
            return isList.logoString

        case .isArray:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            let isArray =
                switch p {
                case .array: true
                default: false
                }
            return isArray.logoString

        case .isNumber:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            return (Double(v) != nil).logoString

        case .isEmpty:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(v)
            switch p {
            case .list(let items), .array(let items): return items.isEmpty.logoString
            case .measurement, .date: return false.logoString
            case .string(let s): return s.isEmpty.logoString
            }

        case .isEqual:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            if v1 == v2 { return true.logoString }
            if let d1 = Double(v1), let d2 = Double(v2) {
                return (d1 == d2).logoString
            }
            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)
            return (p1 == p2).logoString

        case .isNotEqual:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            if v1 == v2 { return false.logoString }
            if let d1 = Double(v1), let d2 = Double(v2) {
                return (d1 != d2).logoString
            }
            let p1 = LogoValue.parse(v1)
            let p2 = LogoValue.parse(v2)
            return (p1 != p2).logoString

        case .isIdentityEqual:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            return (v1 == v2).logoString

        case .isBefore:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            return (v1 < v2).logoString

        case .isMember:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let needle = reader.nextExpression()
            let haystack = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(haystack)
            switch p {
            case .list(let items), .array(let items):
                return items.map { $0.description }.contains(needle).logoString
            case .measurement(let v, let u, _):
                return (needle == LogoMeasurementConverter.formatResult(v) || needle == u).logoString
            case .date:
                return (needle == p.description).logoString
            case .string(let s):
                return s.contains(needle).logoString
            }

        case .member:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let needle = reader.nextExpression()
            let haystack = reader.nextExpression()
            reader.commit(to: &index)
            let p = LogoValue.parse(haystack)
            let target = LogoValue.parse(needle).description
            switch p {
            case .list(let items):
                guard let matchIndex = items.firstIndex(where: { $0.description == target }) else { return "" }
                return LogoValue.list(Array(items[matchIndex...])).description
            case .array(let items):
                guard let matchIndex = items.firstIndex(where: { $0.description == target }) else { return "" }
                return LogoValue.array(Array(items[matchIndex...])).description
            case .measurement(let v, let u, _):
                let strV = LogoMeasurementConverter.formatResult(v)
                if target == strV {
                    return LogoValue.list([.string(strV), .string(u)]).description
                } else if target == u {
                    return LogoValue.list([.string(u)]).description
                }
                return ""
            case .date:
                return p.description == target ? p.description : ""
            case .string(let s):
                guard let range = s.range(of: target) else { return "" }
                return String(s[range.lowerBound...])
            }

        case .parse, .runparse:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let script = reader.nextExpression()
            reader.commit(to: &index)
            return "[" + LogoTokenizer.tokenize(script).joined(separator: " ") + "]"

        case .isSubstring:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let needle = reader.nextExpression()
            let haystack = reader.nextExpression()
            reader.commit(to: &index)
            return haystack.contains(needle).logoString

        case .isProcedure:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let name = normalizeProcedureName(reader.nextExpression())
            reader.commit(to: &index)
            let exists = LogoPrimitive.from(name) != nil || customProcedures[name] != nil
            return exists.logoString

        case .isPrimitive:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let name = normalizeProcedureName(reader.nextExpression())
            reader.commit(to: &index)
            return (LogoPrimitive.from(name) != nil).logoString

        case .isDefined:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let name = normalizeProcedureName(reader.nextExpression())
            reader.commit(to: &index)
            return (customProcedures[name] != nil).logoString

        case .isName:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let name = normalizeVariableName(reader.nextExpression())
            reader.commit(to: &index)
            return (variables[name] != nil).logoString

        case .less:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let n1 = reader.nextDouble()
            let n2 = reader.nextDouble()
            reader.commit(to: &index)
            return (n1 < n2).logoString

        case .greater:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let n1 = reader.nextDouble()
            let n2 = reader.nextDouble()
            reader.commit(to: &index)
            return (n1 > n2).logoString

        case .lessOrEqual:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let n1 = reader.nextDouble()
            let n2 = reader.nextDouble()
            reader.commit(to: &index)
            return (n1 <= n2).logoString

        case .greaterOrEqual:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let n1 = reader.nextDouble()
            let n2 = reader.nextDouble()
            reader.commit(to: &index)
            return (n1 >= n2).logoString

        case .indexof:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let needle = unquote(reader.nextExpression())
            let haystack = unquote(reader.nextExpression())
            let startFrom = max(1, reader.nextOptionalExpression().flatMap { Int($0) } ?? 1)
            reader.commit(to: &index)
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
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let needle = unquote(reader.nextExpression())
            let haystack = unquote(reader.nextExpression())
            reader.commit(to: &index)
            if let range = haystack.range(of: needle, options: .backwards) {
                let idx = haystack.distance(from: haystack.startIndex, to: range.lowerBound) + 1
                return "\(idx)"
            }
            return "0"

        case .indexesof:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let needle = unquote(reader.nextExpression())
            let haystack = unquote(reader.nextExpression())
            reader.commit(to: &index)
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
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let needle = unquote(reader.nextExpression())
            let haystack = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return haystack.contains(needle).logoString

        case .startswith:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let prefix = unquote(reader.nextExpression())
            let string = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return string.hasPrefix(prefix).logoString

        case .endswith:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let suffix = unquote(reader.nextExpression())
            let string = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return string.hasSuffix(suffix).logoString

        case .substring:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let str = unquote(reader.nextExpression())
            let startVal = reader.nextInteger(default: 1)
            let endOrLengthVal = reader.nextOptionalExpression().flatMap(Int.init)
            reader.commit(to: &index)
            let chars = Array(str)
            let zeroStart = max(0, startVal - 1)
            guard zeroStart < chars.count else { return "" }
            let maxLen = chars.count - zeroStart
            let requestedLen: Int
            if let endOrLengthVal {
                requestedLen = endOrLengthVal >= startVal ? endOrLengthVal - startVal + 1 : endOrLengthVal
            } else {
                requestedLen = maxLen
            }
            let effectiveLen = min(max(0, requestedLen), maxLen)
            return String(chars[zeroStart..<(zeroStart + effectiveLen)])

        case .replace:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let target = unquote(reader.nextExpression())
            let replacement = unquote(reader.nextExpression())
            let str = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return str.replacingOccurrences(of: target, with: replacement)

        case .trim:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let str = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return str.trimmingCharacters(in: .whitespacesAndNewlines)

        case .repeatstr:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let countVal = reader.nextInteger()
            let str = unquote(reader.nextExpression())
            reader.commit(to: &index)
            guard countVal > 0 else { return "" }
            return String(repeating: str, count: countVal)

        case .join:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let delim = unquote(reader.nextExpression())
            let listStr = reader.nextExpression()
            reader.commit(to: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            return items.joined(separator: delim)

        case .lines:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let str = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let lineItems = str.components(separatedBy: .newlines)
            return LogoValue.list(lineItems.map { LogoValue.string($0) }).description

        case .unlines:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let listStr = reader.nextExpression()
            reader.commit(to: &index)
            let items = LogoValue.parse(listStr).toListItems().map { $0.description }
            return items.joined(separator: "\n")

        case .format:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let pattern = unquote(reader.nextExpression())
            let expectedArgCount = LogoStringFormatter.argumentCount(for: pattern)
            var rawArgs: [String] = []
            while rawArgs.count < expectedArgCount, let argVal = reader.nextOptionalExpression() {
                let parsedArg = LogoValue.parse(argVal)
                switch parsedArg {
                case .list(let items), .array(let items):
                    rawArgs.append(contentsOf: items.map { $0.description })
                case .measurement(let v, let u, _):
                    rawArgs.append(contentsOf: [LogoMeasurementConverter.formatResult(v), u])
                case .date:
                    rawArgs.append(parsedArg.description)
                case .string:
                    rawArgs.append(argVal)
                }
            }
            reader.commit(to: &index)
            return LogoStringFormatter.format(pattern: pattern, args: rawArgs)

        case .padleft, .padright:
            let isRight = prim == .padright
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let arg1 = unquote(reader.nextExpression())
            let arg2 = unquote(reader.nextExpression())
            var str = ""
            var width = 0
            var padChar = " "

            if let arg3 = reader.nextOptionalExpression().map(unquote) {

                if arg2.count == 1 && arg3.count != 1, let w1 = Int(arg1) {
                    width = w1
                    padChar = arg2
                    str = arg3
                } else if let w2 = Int(arg2) {
                    str = arg1
                    width = w2
                    padChar = arg3
                } else if let w1 = Int(arg1) {
                    width = w1
                    padChar = arg2
                    str = arg3
                } else {
                    str = arg1
                    width = Int(arg2) ?? 0
                }
            } else {
                if let w2 = Int(arg2) {
                    str = arg1
                    width = w2
                } else if let w1 = Int(arg1) {
                    width = w1
                    str = arg2
                } else {
                    str = arg1
                    width = Int(arg2) ?? 0
                }
            }

            reader.commit(to: &index)
            if padChar.isEmpty { padChar = " " }
            let currentWidth = str.reduce(0) { $0 + $1.displayWidth }
            if currentWidth >= width { return str }
            let padCount = width - currentWidth
            let padding = String(repeating: padChar, count: padCount)
            return isRight ? (str + padding) : (padding + str)

        case .regexMatch:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let pattern = unquote(reader.nextExpression())
            let str = unquote(reader.nextExpression())
            reader.commit(to: &index)
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(str.startIndex..., in: str)
                return (regex.firstMatch(in: str, range: range) != nil).logoString
            }
            return false.logoString

        case .regexReplace:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let pattern = unquote(reader.nextExpression())
            let replacement = unquote(reader.nextExpression())
            let str = unquote(reader.nextExpression())
            reader.commit(to: &index)
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(str.startIndex..., in: str)
                return regex.stringByReplacingMatches(in: str, range: range, withTemplate: replacement)
            }
            return str

        case .regexFind:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let pattern = unquote(reader.nextExpression())
            let str = unquote(reader.nextExpression())
            reader.commit(to: &index)
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
}
