import Foundation

public struct BoxStyle: Sendable {
    let topLeft: Character
    let topChar: Character
    let topRight: Character
    let sideChar: Character
    let bottomLeft: Character
    let bottomChar: Character
    let bottomRight: Character

    static let single = BoxStyle(topLeft: "┌", topChar: "─", topRight: "┐", sideChar: "│", bottomLeft: "└", bottomChar: "─", bottomRight: "┘")
    static let double = BoxStyle(topLeft: "╔", topChar: "═", topRight: "╗", sideChar: "║", bottomLeft: "╚", bottomChar: "═", bottomRight: "╝")
    static let round  = BoxStyle(topLeft: "╭", topChar: "─", topRight: "╮", sideChar: "│", bottomLeft: "╰", bottomChar: "─", bottomRight: "╯")
    static let ascii  = BoxStyle(topLeft: "+", topChar: "-", topRight: "+", sideChar: "|", bottomLeft: "+", bottomChar: "-", bottomRight: "+")

    static func from(_ str: String) -> BoxStyle {
        let clean = str.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "double": return .double
        case "round": return .round
        case "ascii": return .ascii
        default: return .single
        }
    }
}

public struct LogoProcedure: Sendable {
    public let name: String
    public let parameters: [String]
    public let bodyTokens: [String]

    public init(name: String, parameters: [String], bodyTokens: [String]) {
        self.name = name
        self.parameters = parameters
        self.bodyTokens = bodyTokens
    }
}

/// LOGO-style Macro Language Engine for text editors.
public final class LogoEngine {
    public var customProcedures: [String: LogoProcedure] = [:]
    public var variables: [String: String] = [:]
    public var hasSetStatusMessage: Bool = false
    internal var gensymCounter: Int = 0

    // Turtle graphics state
    public var isPenDown: Bool = true
    public var heading: Int = 90 // 0 = UP, 90 = RIGHT, 180 = DOWN, 270 = LEFT

    internal static let keywords: Set<String> = [
        "MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW",
        "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND",
        "DELETELINE", "DELLINE", "KILLLINE", "DL",
        "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR",
        "NEWLINE", "NL", "ENTER", "DATE", "TIME", "PD", "PENDOWN", "PU", "PENUP",
        "FD", "FORWARD", "BK", "BACK", "BACKWARD", "RT", "RIGHT", "LT", "LEFT",
        "IF", "IFELSE", "WORD", "LIST", "SENTENCE", "SE", "FPUT", "LPUT", "ARRAY",
        "LISTTOARRAY", "ARRAYTOLIST", "COMBINE", "REVERSE", "GENSYM", "FIRST",
        "LAST", "FIRSTS", "BUTFIRST", "BF", "BUTLAST", "BL", "BUTFIRSTS", "BFS",
        "ITEM", "PICK", "REMOVE", "REMDUP", "QUOTED", "SPLIT", "SETITEM",
        ".SETFIRST", ".SETBF", "PUSH", "POP", "QUEUE", "DEQUEUE", "WORD?", "WORDP",
        "LIST?", "LISTP", "ARRAY?", "ARRAYP", "NUMBER?", "NUMBERP", "EMPTY?", "EMPTYP",
        "EQUAL?", "EQUALP", "NOTEQUAL?", "NOTEQUALP", "BEFORE?", "BEFOREP", ".EQ",
        "MEMBER?", "MEMBERP", "SUBSTRING?", "SUBSTRINGP", "COUNT", "ASCII", "CHAR", "MEMBER", "UPPERCASE", "LOWERCASE",
        "STANDOUT", "PARSE", "RUNPARSE",
        "LESSP", "LESS?", "GREATERP", "GREATER?", "LESSEQUALP", "LESSEQUAL?", "GREATEREQUALP", "GREATEREQUAL?",
        "SUM", "DIFFERENCE", "PRODUCT", "QUOTIENT", "POWER", "REMAINDER", "MODULO", "MINUS", "ABS", "INT", "ROUND",
        "SQRT", "EXP", "LOG10", "LN", "ARCTAN", "SIN", "COS", "TAN", "RADARCTAN", "RADSIN", "RADCOS", "RADTAN",
        "ISEQ", "RSEQ", "RANDOM", "RERANDOM", "FORM", "BITAND", "BITOR", "BITXOR", "BITNOT", "ASHIFT", "LSHIFT",
        "TRUE", "FALSE", "AND", "OR", "XOR", "NOT", "OUTPUT", "OP"
    ]

    public var lastResult: String? = nil

    public weak var delegate: LogoEngineDelegate?

    public init(delegate: LogoEngineDelegate? = nil) {
        self.delegate = delegate
    }

    /// Executes LOGO macro script on the delegate context, creating a single atomic Undo snapshot.
    public func execute(_ script: String) {
        guard let delegate = self.delegate else { return }
        lastResult = nil
        hasSetStatusMessage = false

        let tokens = tokenize(script)
        guard !tokens.isEmpty else { return }

        // Save a single atomic Undo snapshot for the entire macro execution
        delegate.logoEngineDidRequestSaveUndoSnapshot(self)

        var index = 0
        var frameReturn: String? = nil
        executeTokens(tokens, index: &index, frameReturn: &frameReturn)
        if let ret = frameReturn, !ret.isEmpty {
            lastResult = ret
        }
        delegate.logoEngineDidRequestClampCursor(self)
    }

    internal func executeTokens(_ tokens: [String], index: inout Int, frameReturn: inout String?) {
        guard let delegate = self.delegate else { return }
        while index < tokens.count && frameReturn == nil {
            let token = tokens[index]
            let upper = token.uppercased()

            if token == "]" {
                return
            }

            switch upper {
            case "OUTPUT", "OP":
                index += 1
                if index < tokens.count {
                    let val = evaluateExpression(tokens, index: &index)
                    frameReturn = val
                    return
                }

            case "MAKE", "VAR":
                index += 1
                if index < tokens.count {
                    let varName = unquote(tokens[index]).lowercased()
                    index += 1
                    let val = evaluateExpression(tokens, index: &index)
                    variables[varName] = val
                }

            case "SETITEM":
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

            case ".SETFIRST":
                index += 1
                if index < tokens.count {
                    let varToken = tokens[index]
                    let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                    index += 1
                    let newVal = evaluateExpression(tokens, index: &index)

                    let currentVal = variables[varName] ?? ""
                    let parsed = LogoValue.parse(currentVal)
                    switch parsed {
                    case .list(var items):
                        if !items.isEmpty {
                            items[0] = LogoValue.parse(newVal)
                            variables[varName] = LogoValue.list(items).description
                        }
                    case .array(var items):
                        if !items.isEmpty {
                            items[0] = LogoValue.parse(newVal)
                            variables[varName] = LogoValue.array(items).description
                        }
                    case .string(var s):
                        if !s.isEmpty {
                            s.replaceSubrange(s.startIndex...s.startIndex, with: newVal)
                            variables[varName] = s
                        }
                    }
                }

            case ".SETBF":
                index += 1
                if index < tokens.count {
                    let varToken = tokens[index]
                    let varName = varToken.trimmingCharacters(in: CharacterSet(charactersIn: ":\"")).lowercased()
                    index += 1
                    let newVal = evaluateExpression(tokens, index: &index)

                    let currentVal = variables[varName] ?? ""
                    let parsed = LogoValue.parse(currentVal)
                    let newParsed = LogoValue.parse(newVal)
                    switch (parsed, newParsed) {
                    case (.list(let items), .list(let newTail)):
                        if !items.isEmpty {
                            let head = items[0]
                            variables[varName] = LogoValue.list([head] + newTail).description
                        }
                    case (.array(let items), .array(let newTail)):
                        if !items.isEmpty {
                            let head = items[0]
                            variables[varName] = LogoValue.array([head] + newTail).description
                        }
                    default:
                        break
                    }
                }

            case "PUSH", "FPUT":
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

            case "QUEUE", "LPUT":
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

            case "SET":
                index += 1
                if index < tokens.count {
                    let setting = unquote(tokens[index]).lowercased()
                    var arg = ""
                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !LogoEngine.keywords.contains(nextUpper) {
                            index += 1
                            arg = evaluateExpression(tokens, index: &index).lowercased()
                        }
                    }
                    delegate.logoEngine(self, didApplySetting: setting, arg: arg)
                }

            case "TYPE", "PRINT":
                index += 1
                if index < tokens.count {
                    let text = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, didRequestInsertText: text)
                }

            case "MSG", "MESSAGE", "SHOW":
                index += 1
                if index < tokens.count {
                    let msgText = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, didRequestSetStatusMessage: msgText)
                    hasSetStatusMessage = true
                }

            case "DEL", "DELETE":
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    delegate.logoEngineDidRequestDelete(self)
                }

            case "BS", "BACKSPACE":
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    delegate.logoEngineDidRequestBackspace(self)
                }

            case "DELETELINE", "DELLINE", "KILLLINE", "DL":
                index += 1
                var count = 1
                if index < tokens.count {
                    let nextToken = tokens[index]
                    let nextUpper = nextToken.uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) && nextToken != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        count = max(1, min(Int(valStr) ?? 1, 1000))
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                for _ in 0..<count {
                    delegate.logoEngineDidRequestDeleteLine(self)
                }

            case "MOVE":
                index += 1
                if index < tokens.count {
                    let dir = tokens[index].uppercased()
                    switch dir {
                    case "UP": delegate.logoEngine(self, didRequestMoveCursorVirtual: -1)
                    case "DOWN": delegate.logoEngine(self, didRequestMoveCursorVirtual: 1)
                    case "LEFT": delegate.logoEngine(self, didRequestDispatchCommand: .moveLeft)
                    case "RIGHT": delegate.logoEngine(self, didRequestDispatchCommand: .moveRight)
                    case "HOME": delegate.logoEngine(self, didRequestDispatchCommand: .moveHome)
                    case "END": delegate.logoEngine(self, didRequestDispatchCommand: .moveEnd)
                    default: break
                    }
                }

            case "GOTO":
                index += 1
                if index < tokens.count {
                    let lineStr = evaluateExpression(tokens, index: &index)
                    let lineNum = max(1, min(Int(lineStr) ?? 1, delegate.logoEngineLineCount(self))) - 1
                    delegate.logoEngine(self, didUpdateLineIndex: lineNum)
                    delegate.logoEngine(self, didUpdateColumnIndex: 0)

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !LogoEngine.keywords.contains(nextUpper) {
                            index += 1
                            let colStr = evaluateExpression(tokens, index: &index)
                            let lineText = delegate.logoEngine(self, lineAt: lineNum)
                            let colNum = max(1, min(Int(colStr) ?? 1, lineText.count + 1)) - 1
                            delegate.logoEngine(self, didUpdateColumnIndex: colNum)
                        }
                    }
                }

            case "BOX":
                index += 1
                executeBoxCommand(tokens, index: &index)

            case "LINE", "HR":
                index += 1
                executeLineCommand(tokens, index: &index)

            case "VLINE", "VHR":
                index += 1
                executeVlineCommand(tokens, index: &index)

            case "NEWLINE", "NL", "ENTER":
                index += 1
                executeNewlineCommand(tokens, index: &index)

            // Conditional Logic Commands
            case "IF":
                index += 1
                var condTokens: [String] = []
                while index < tokens.count && tokens[index] != "[" {
                    condTokens.append(tokens[index])
                    index += 1
                }

                let isTrue = evaluateCondition(condTokens)

                if index < tokens.count && tokens[index] == "[" {
                    index += 1
                    if isTrue {
                        executeTokens(tokens, index: &index, frameReturn: &frameReturn)
                        if frameReturn != nil { return }
                    } else {
                        var depth = 1
                        while index < tokens.count && depth > 0 {
                            if tokens[index] == "[" { depth += 1 }
                            else if tokens[index] == "]" { depth -= 1 }
                            if depth == 0 { break }
                            index += 1
                        }
                    }
                }

            case "IFELSE":
                index += 1
                var condTokens: [String] = []
                while index < tokens.count && tokens[index] != "[" {
                    condTokens.append(tokens[index])
                    index += 1
                }

                let isTrue = evaluateCondition(condTokens)

                if index < tokens.count && tokens[index] == "[" {
                    if isTrue {
                        index += 1 // Advance past first "["
                        executeTokens(tokens, index: &index, frameReturn: &frameReturn)
                        if frameReturn != nil { return }
                        index += 1 // Advance past first "]"
                        if index < tokens.count && tokens[index] == "[" {
                            var depth = 1
                            index += 1
                            while index < tokens.count && depth > 0 {
                                if tokens[index] == "[" { depth += 1 }
                                else if tokens[index] == "]" { depth -= 1 }
                                if depth == 0 { break }
                                index += 1
                            }
                        }
                    } else {
                        var depth = 1
                        index += 1 // Advance past first "["
                        while index < tokens.count && depth > 0 {
                            if tokens[index] == "[" { depth += 1 }
                            else if tokens[index] == "]" { depth -= 1 }
                            if depth == 0 { break }
                            index += 1
                        }
                        index += 1 // Advance past first "]"
                        if index < tokens.count && tokens[index] == "[" {
                            index += 1 // Advance past second "["
                            executeTokens(tokens, index: &index, frameReturn: &frameReturn)
                            if frameReturn != nil { return }
                        }
                    }
                }

            // Turtle Graphics Commands
            case "PD", "PENDOWN":
                isPenDown = true

            case "PU", "PENUP":
                isPenDown = false

            case "RT", "RIGHT":
                index += 1
                var angle = 90
                if index < tokens.count {
                    let nextUpper = tokens[index].uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        angle = Int(valStr) ?? 90
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                heading = (heading + angle) % 360

            case "LT", "LEFT":
                index += 1
                var angle = 90
                if index < tokens.count {
                    let nextUpper = tokens[index].uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        angle = Int(valStr) ?? 90
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                heading = ((heading - angle) % 360 + 360) % 360

            case "FD", "FORWARD":
                index += 1
                var dist = 1
                if index < tokens.count {
                    let nextUpper = tokens[index].uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        dist = max(1, min(Int(valStr) ?? 1, 200))
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                executeTurtleMove(steps: dist, directionHeading: heading)

            case "BK", "BACK", "BACKWARD":
                index += 1
                var dist = 1
                if index < tokens.count {
                    let nextUpper = tokens[index].uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        dist = max(1, min(Int(valStr) ?? 1, 200))
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                executeTurtleMove(steps: dist, directionHeading: (heading + 180) % 360)

            case "MARK":
                delegate.logoEngine(self, didRequestDispatchCommand: .editMark)

            case "CUT":
                delegate.logoEngine(self, didRequestDispatchCommand: .editCut)

            case "PASTE", "UNCUT":
                delegate.logoEngine(self, didRequestDispatchCommand: .editUncut)

            case "JUSTIFY":
                delegate.logoEngine(self, didRequestDispatchCommand: .editJustify)

            case "FIND", "SEARCH":
                index += 1
                if index < tokens.count {
                    let query = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, didRequestSearch: query)
                }

            case "REPEAT":
                index += 1
                let countStr = evaluateExpression(tokens, index: &index)
                let count = Int(countStr) ?? 1
                index += 1 // Advance to "["
                if index < tokens.count && tokens[index] == "[" {
                    index += 1
                    let bodyStartIndex = index
                    for r in 0..<count {
                        var bodyIndex = bodyStartIndex
                        executeTokens(tokens, index: &bodyIndex, frameReturn: &frameReturn)
                        if frameReturn != nil { return }
                        if r == count - 1 {
                            index = bodyIndex
                        }
                    }
                }

            case "TO":
                index += 1
                if index < tokens.count {
                    let procName = tokens[index].uppercased()
                    index += 1
                    var params: [String] = []
                    while index < tokens.count && tokens[index].hasPrefix(":") {
                        let paramName = String(tokens[index].dropFirst()).lowercased()
                        params.append(paramName)
                        index += 1
                    }
                    var procTokens: [String] = []
                    while index < tokens.count && tokens[index].uppercased() != "END" {
                        procTokens.append(tokens[index])
                        index += 1
                    }
                    customProcedures[procName] = LogoProcedure(name: procName, parameters: params, bodyTokens: procTokens)
                }

            case "EXEC":
                index += 1
                if index < tokens.count {
                    let procName = tokens[index].uppercased()
                    if let proc = customProcedures[procName] {
                        let ret = invokeProcedure(proc, tokens: tokens, index: &index)
                        if let r = ret, !r.isEmpty {
                            lastResult = r
                        }
                    }
                }

            default:
                if let proc = customProcedures[upper] {
                    let ret = invokeProcedure(proc, tokens: tokens, index: &index)
                    if let r = ret, !r.isEmpty {
                        lastResult = r
                    }
                } else {
                    let exprResult = evaluateExpression(tokens, index: &index)
                    if !exprResult.isEmpty {
                        lastResult = exprResult
                    }
                }
            }

            index += 1
        }
    }

    internal func invokeProcedure(_ proc: LogoProcedure, tokens: [String], index: inout Int) -> String? {
        var args: [String] = []
        for _ in 0..<proc.parameters.count {
            index += 1
            let arg = evaluateExpression(tokens, index: &index)
            args.append(arg)
        }

        let oldVars = variables
        defer { variables = oldVars }

        for (i, param) in proc.parameters.enumerated() {
            variables[param] = args[i]
        }

        var procIndex = 0
        var procReturn: String? = nil
        executeTokens(proc.bodyTokens, index: &procIndex, frameReturn: &procReturn)
        if let ret = procReturn, !ret.isEmpty {
            lastResult = ret
        }
        return procReturn
    }
}
