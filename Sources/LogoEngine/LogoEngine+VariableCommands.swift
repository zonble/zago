import Foundation

extension LogoEngine {
    /// Executes Logo variable manipulation statement commands (.make, .name, .setItem, .setFirst, etc.).
    /// Returns `true` if the primitive was handled by this module, `false` otherwise.
    internal func executeVariableCommand(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> Bool {
        switch prim {
        case .make:
            index += 1
            if index < tokens.count {
                let varName = normalizeVariableName(tokens[index])
                index += 1
                let val = evaluateExpression(tokens, index: &index)
                variables[varName] = val
                variableValues[varName] = runtimeValueForLastExpression(fallback: val)
            }
            return true

        case .name:
            index += 1
            if index < tokens.count {
                let val = evaluateExpression(tokens, index: &index)
                let runtimeValue = runtimeValueForLastExpression(fallback: val)
                index += 1
                if index < tokens.count {
                    let varName = normalizeVariableName(evaluateExpression(tokens, index: &index))
                    variables[varName] = val
                    variableValues[varName] = runtimeValue
                }
            }
            return true

        case .setItem:
            index += 1
            let idxVal = Int(evaluateExpression(tokens, index: &index)) ?? 1
            if index + 1 < tokens.count {
                index += 1
                let varToken = tokens[index]
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                index += 1
                let newVal = evaluateExpression(tokens, index: &index)

                let currentVal = variables[varName] ?? ""
                let parsed = LogoValue.parse(currentVal)
                let zeroIdx = idxVal - 1
                switch parsed {
                case .list(var items):
                    if zeroIdx >= 0 && zeroIdx < items.count {
                        items[zeroIdx] = LogoValue.parse(newVal)
                        variables[varName] = LogoValue.list(items).description
                    }
                case .array(var items):
                    if zeroIdx >= 0 && zeroIdx < items.count {
                        items[zeroIdx] = LogoValue.parse(newVal)
                        variables[varName] = LogoValue.array(items).description
                    }
                case .string(var s):
                    if zeroIdx >= 0 && zeroIdx < s.count {
                        let strIdx = s.index(s.startIndex, offsetBy: zeroIdx)
                        s.replaceSubrange(strIdx...strIdx, with: newVal)
                        variables[varName] = s
                    }
                }
            }
            return true

        case .setFirst:
            if index + 1 < tokens.count {
                index += 1
                let varToken = tokens[index]
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                index += 1
                let newVal = evaluateExpression(tokens, index: &index)

                if let currentValStr = variables[varName] {
                    let parsed = LogoValue.parse(currentValStr)
                    let newElem = LogoValue.parse(newVal)
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
            return true

        case .setBFL:
            if index + 1 < tokens.count {
                index += 1
                let varToken = tokens[index]
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                index += 1
                let newVal = evaluateExpression(tokens, index: &index)

                if let currentValStr = variables[varName] {
                    let parsed = LogoValue.parse(currentValStr)
                    let newTailParsed = LogoValue.parse(newVal)
                    switch parsed {
                    case .list(let items):
                        let head = items.first ?? .string("")
                        var tailItems: [LogoValue] = []
                        switch newTailParsed {
                        case .list(let t), .array(let t): tailItems = t
                        case .string(let s): tailItems = [.string(s)]
                        }
                        variables[varName] = LogoValue.list([head] + tailItems).description
                    case .array(let items):
                        let head = items.first ?? .string("")
                        var tailItems: [LogoValue] = []
                        switch newTailParsed {
                        case .list(let t), .array(let t): tailItems = t
                        case .string(let s): tailItems = [.string(s)]
                        }
                        variables[varName] = LogoValue.array([head] + tailItems).description
                    case .string(let s):
                        let head = s.prefix(1)
                        variables[varName] = String(head) + newVal
                    }
                }
            }
            return true

        case .mdsetItem:
            index += 1
            let idxVal = evaluateExpression(tokens, index: &index)
            if index + 1 < tokens.count {
                index += 1
                let varToken = tokens[index]
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                index += 1
                let newVal = evaluateExpression(tokens, index: &index)

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
                        guard let head = path.first else { return replacement }
                        let zeroIdx = head - 1
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
                        case .string(var s):
                            if tail.isEmpty && zeroIdx >= 0 && zeroIdx < s.count {
                                let strIdx = s.index(s.startIndex, offsetBy: zeroIdx)
                                s.replaceSubrange(strIdx...strIdx, with: replacement.description)
                                return .string(s)
                            }
                        }
                        return value
                    }

                    rootVal = updateNested(value: rootVal, path: indices, replacement: LogoValue.parse(newVal))
                    variables[varName] = rootVal.description
                }
            }
            return true

        case .fput, .push:
            index += 1
            if index < tokens.count {
                let varToken = tokens[index]
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                index += 1
                let itemVal = evaluateExpression(tokens, index: &index)

                let currentVal = variables[varName] ?? ""
                let parsed = LogoValue.parse(currentVal)
                switch parsed {
                case .list(var items):
                    items.insert(LogoValue.parse(itemVal), at: 0)
                    variables[varName] = LogoValue.list(items).description
                case .array(var items):
                    items.insert(LogoValue.parse(itemVal), at: 0)
                    variables[varName] = LogoValue.array(items).description
                case .string(let s):
                    variables[varName] = itemVal + s
                }
            }
            return true

        case .lput, .dequeue:
            index += 1
            if index < tokens.count {
                let varToken = tokens[index]
                let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                index += 1
                let itemVal = evaluateExpression(tokens, index: &index)

                let currentVal = variables[varName] ?? ""
                let parsed = LogoValue.parse(currentVal)
                switch parsed {
                case .list(var items):
                    items.append(LogoValue.parse(itemVal))
                    variables[varName] = LogoValue.list(items).description
                case .array(var items):
                    items.append(LogoValue.parse(itemVal))
                    variables[varName] = LogoValue.array(items).description
                case .string(let s):
                    variables[varName] = s + itemVal
                }
            }
            return true

        default:
            return false
        }
    }
}
