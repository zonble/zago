import Foundation

extension LogoEngine {
    /// Executes Logo variable manipulation statement commands (.make, .name,
    /// .setItem, .setFirst, etc.). Returns `true` if the primitive was handled
    /// by this module, `false` otherwise.
    internal func executeVariableCommand(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> Bool {
        switch prim {
        case .make:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if let rawName = reader.nextRawToken() {
                let varName = normalizeVariableName(rawName)
                let val = reader.nextExpression()
                variables[varName] = val
            }
            reader.commit(to: &index)
            return true

        case .name:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let val = reader.nextExpression()
            if let rawName = reader.nextOptionalExpression() {
                let varName = normalizeVariableName(rawName)
                variables[varName] = val
            }
            reader.commit(to: &index)
            return true

        case .setItem:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let idxVal = reader.nextInteger(default: 1)
            if let target = reader.nextRawExpression() {
                let rawToken = target.raw
                let varName = rawToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                let targetVal = target.value

                if let newVal = reader.nextOptionalExpression() {

                    let sourceVal = variables[varName] ?? targetVal
                    let parsed = LogoValue.parse(sourceVal)
                    let zeroIdx = idxVal - 1
                    var resultStr: String? = nil

                    switch parsed {
                    case .list(var items):
                        if zeroIdx >= 0 && zeroIdx < items.count {
                            items[zeroIdx] = parseLogoValuePreservingWhitespace(newVal)
                            resultStr = LogoValue.list(items).description
                        }
                    case .array(var items):
                        if zeroIdx >= 0 && zeroIdx < items.count {
                            items[zeroIdx] = parseLogoValuePreservingWhitespace(newVal)
                            resultStr = LogoValue.array(items).description
                        }
                    case .measurement(let v, let u, _):
                        var items: [LogoValue] = [.string(LogoMeasurementConverter.formatResult(v)), .string(u)]
                        if zeroIdx >= 0 && zeroIdx < items.count {
                            items[zeroIdx] = parseLogoValuePreservingWhitespace(newVal)
                            resultStr = LogoValue.list(items).description
                        }
                    case .string(var s):
                        if zeroIdx >= 0 && zeroIdx < s.count {
                            let strIdx = s.index(s.startIndex, offsetBy: zeroIdx)
                            s.replaceSubrange(strIdx...strIdx, with: newVal)
                            resultStr = s
                        }
                    }

                    if let res = resultStr {
                        if variables[varName] != nil || rawToken.hasPrefix(":") || rawToken.hasPrefix("\"") {
                            variables[varName] = res
                        }
                        lastResult = res
                    }
                }
            }
            reader.commit(to: &index)
            return true

        case .setFirst:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if let varToken = reader.nextRawToken() {
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                let newVal = reader.nextExpression()

                if let currentValStr = variables[varName] {
                    let parsed = LogoValue.parse(currentValStr)
                    let newElem = parseLogoValuePreservingWhitespace(newVal)
                    switch parsed {
                    case .list(var items):
                        if items.isEmpty {
                            items = [newElem]
                        } else {
                            items[0] = newElem
                        }
                        variables[varName] = LogoValue.list(items).description
                    case .array(var items):
                        if items.isEmpty {
                            items = [newElem]
                        } else {
                            items[0] = newElem
                        }
                        variables[varName] = LogoValue.array(items).description
                    case .measurement(_, let u, _):
                        variables[varName] = LogoValue.list([newElem, .string(u)]).description
                    case .string(var s):
                        if s.isEmpty {
                            s = newVal
                        } else {
                            s.replaceSubrange(s.startIndex...s.startIndex, with: newVal)
                        }
                        variables[varName] = s
                    }
                }
            }
            reader.commit(to: &index)
            return true

        case .setBFL:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if let varToken = reader.nextRawToken() {
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                let newVal = reader.nextExpression()

                if let currentValStr = variables[varName] {
                    let parsed = LogoValue.parse(currentValStr)
                    let newTailParsed = LogoValue.parse(newVal)
                    switch parsed {
                    case .list(let items):
                        let head = items.first ?? .string("")
                        var tailItems: [LogoValue] = []
                        switch newTailParsed {
                        case .list(let t), .array(let t): tailItems = t
                        case .measurement(let v, let u, _):
                            tailItems = [.string(LogoMeasurementConverter.formatResult(v)), .string(u)]
                        case .string(let s): tailItems = [.string(s)]
                        }
                        variables[varName] = LogoValue.list([head] + tailItems).description
                    case .array(let items):
                        let head = items.first ?? .string("")
                        var tailItems: [LogoValue] = []
                        switch newTailParsed {
                        case .list(let t), .array(let t): tailItems = t
                        case .measurement(let v, let u, _):
                            tailItems = [.string(LogoMeasurementConverter.formatResult(v)), .string(u)]
                        case .string(let s): tailItems = [.string(s)]
                        }
                        variables[varName] = LogoValue.array([head] + tailItems).description
                    case .measurement(let v, _, _):
                        var tailItems: [LogoValue] = []
                        switch newTailParsed {
                        case .list(let t), .array(let t): tailItems = t
                        case .measurement(let mv, let mu, _):
                            tailItems = [.string(LogoMeasurementConverter.formatResult(mv)), .string(mu)]
                        case .string(let s): tailItems = [.string(s)]
                        }
                        variables[varName] =
                            LogoValue.list([.string(LogoMeasurementConverter.formatResult(v))] + tailItems).description
                    case .string(let s):
                        let head = s.prefix(1)
                        variables[varName] = String(head) + newVal
                    }
                }
            }
            reader.commit(to: &index)
            return true

        case .mdsetItem:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let idxVal = reader.nextExpression()
            if let varToken = reader.nextRawToken() {
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                let newVal = reader.nextExpression()

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

                if let currentValStr = variables[varName] {
                    var rootVal = LogoValue.parse(currentValStr)

                    func updateNested(value: LogoValue, path: [Int], replacement: LogoValue) -> LogoValue {
                        guard let firstIdx = path.first else { return replacement }
                        let zeroIdx = firstIdx - 1
                        let tail = Array(path.dropFirst())

                        switch value {
                        case .list(var items):
                            if zeroIdx >= 0 && zeroIdx < items.count {
                                items[zeroIdx] = updateNested(
                                    value: items[zeroIdx], path: tail, replacement: replacement)
                                return .list(items)
                            }
                        case .array(var items):
                            if zeroIdx >= 0 && zeroIdx < items.count {
                                items[zeroIdx] = updateNested(
                                    value: items[zeroIdx], path: tail, replacement: replacement)
                                return .array(items)
                            }
                        case .measurement(let v, let u, _):
                            var items: [LogoValue] = [.string(LogoMeasurementConverter.formatResult(v)), .string(u)]
                            if zeroIdx >= 0 && zeroIdx < items.count {
                                items[zeroIdx] = updateNested(
                                    value: items[zeroIdx], path: tail, replacement: replacement)
                                return .list(items)
                            }
                        case .string(var s):
                            if tail.isEmpty && zeroIdx >= 0 && zeroIdx < s.count {
                                let strIdx = s.index(s.startIndex, offsetBy: zeroIdx)
                                s.replaceSubrange(strIdx...strIdx, with: replacement.description)
                                return .string(s)
                            }
                        }
                        return value
                    }

                    rootVal = updateNested(
                        value: rootVal, path: indices, replacement: parseLogoValuePreservingWhitespace(newVal))
                    variables[varName] = rootVal.description
                }
            }
            reader.commit(to: &index)
            return true

        case .fput, .push:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if let varToken = reader.nextRawToken() {
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                let itemVal = reader.nextExpression()

                let currentVal = variables[varName] ?? ""
                let parsed = LogoValue.parse(currentVal)
                switch parsed {
                case .list(var items):
                    items.insert(LogoValue.parse(itemVal), at: 0)
                    variables[varName] = LogoValue.list(items).description
                case .array(var items):
                    items.insert(LogoValue.parse(itemVal), at: 0)
                    variables[varName] = LogoValue.array(items).description
                case .measurement(let v, let u, _):
                    variables[varName] =
                        LogoValue.list([
                            LogoValue.parse(itemVal), .string(LogoMeasurementConverter.formatResult(v)), .string(u),
                        ]).description
                case .string(let s):
                    variables[varName] = itemVal + s
                }
            }
            reader.commit(to: &index)
            return true

        case .lput:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if let varToken = reader.nextRawToken() {
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                let itemVal = reader.nextExpression()

                let currentVal = variables[varName] ?? ""
                let parsed = LogoValue.parse(currentVal)
                switch parsed {
                case .list(var items):
                    items.append(LogoValue.parse(itemVal))
                    variables[varName] = LogoValue.list(items).description
                case .array(var items):
                    items.append(LogoValue.parse(itemVal))
                    variables[varName] = LogoValue.array(items).description
                case .measurement(let v, let u, _):
                    variables[varName] =
                        LogoValue.list([
                            .string(LogoMeasurementConverter.formatResult(v)), .string(u), LogoValue.parse(itemVal),
                        ]).description
                case .string(let s):
                    variables[varName] = s + itemVal
                }
            }
            reader.commit(to: &index)
            return true

        case .dequeue:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let varToken = reader.nextRawToken() else { return true }
            reader.commit(to: &index)
            let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
            let currentVal = variables[varName] ?? ""
            let parsed = LogoValue.parse(currentVal)
            switch parsed {
            case .list(var items):
                if !items.isEmpty {
                    items.removeFirst()
                    variables[varName] = LogoValue.list(items).description
                }
            case .string(let s):
                if !s.isEmpty {
                    variables[varName] = String(s.dropFirst())
                }
            case .array(var items):
                if !items.isEmpty {
                    items.removeFirst()
                    variables[varName] = LogoValue.array(items).description
                }
            case .measurement(_, let u, _):
                variables[varName] = LogoValue.list([.string(u)]).description
            }
            return true

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
            return true

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
            return true

        case .define:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let nameVal = reader.nextExpression()
            let specVal = reader.nextExpression()
            reader.commit(to: &index)
            let name = unquote(nameVal).uppercased()
            if isReservedProcedureName(name) {
                let errorMessage = "[LOGO Error: \(name) is a reserved word/operator and cannot be redefined]"
                reportError(LogoError(code: 1, message: errorMessage), token: name)
                return true
            }
            let parsed = LogoValue.parse(specVal)
            if case .list(let subLists) = parsed, subLists.count >= 2 {
                var params: [String] = []
                var docstring: String? = nil
                var bodyTokens: [String] = []
                if case .list(let paramItems) = subLists[0] {
                    params = paramItems.map { $0.description.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")) }
                } else if case .string(let s) = subLists[0], !s.isEmpty {
                    params = [s.trimmingCharacters(in: CharacterSet(charactersIn: ":\""))]
                }

                if subLists.count >= 3 {
                    if case .string(let doc) = subLists[1] {
                        docstring = doc
                    }
                    if case .list(let bodyItems) = subLists[2] {
                        bodyTokens = bodyItems.map { $0.description }
                    } else if case .string(let s) = subLists[2] {
                        bodyTokens = LogoTokenizer.tokenize(s)
                    }
                } else {
                    if case .list(let bodyItems) = subLists[1] {
                        bodyTokens = bodyItems.map { $0.description }
                    } else if case .string(let s) = subLists[1] {
                        bodyTokens = LogoTokenizer.tokenize(s)
                    }
                }

                customProcedures[name] = LogoProcedure(
                    name: name, parameters: params, docstring: docstring, bodyTokenTexts: bodyTokens)
            }
            return true

        case .erase:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            if reader.peekToken() != nil {
                let targetRaw = unquote(reader.nextExpression())
                let targetUpper = targetRaw.uppercased()
                let targetLower = targetRaw.lowercased()
                customProcedures.removeValue(forKey: targetUpper)
                variables.removeValue(forKey: targetLower)
                propertyLists.removeValue(forKey: targetLower)
            }
            reader.commit(to: &index)
            return true

        case .erps:
            customProcedures.removeAll()
            return true

        case .erns:
            variables.removeAll()
            return true

        case .erall:
            customProcedures.removeAll()
            variables.removeAll()
            propertyLists.removeAll()
            return true

        case .local:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            while let t = reader.peekToken() {
                if LogoEngine.isArgumentBoundary(t) { break }
                _ = reader.nextRawToken()
                let varName = unquote(t).trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                if !varName.isEmpty {
                    variables.declareLocal(varName)
                }
            }
            reader.commit(to: &index)
            return true

        case .pons:
            let systemKeys: Set<String> = ["zago.author", "zago.version", "zago.repository"]
            let keys = Array(variables.keys.filter { !systemKeys.contains($0) }).sorted()
            let res = LogoValue.list(keys.map { .string($0) }).description
            lastResult = res
            return true

        case .pops:
            let keys = Array(customProcedures.keys).sorted()
            let res = LogoValue.list(keys.map { .string($0) }).description
            lastResult = res
            return true

        case .povas:
            let systemKeys: Set<String> = ["zago.author", "zago.version", "zago.repository"]
            let procs = LogoValue.list(Array(customProcedures.keys).sorted().map { .string($0) })
            let vars = LogoValue.list(
                Array(variables.keys.filter { !systemKeys.contains($0) }).sorted().map { .string($0) })
            let res = LogoValue.list([procs, vars]).description
            lastResult = res
            return true

        default:
            return false
        }
    }
}
