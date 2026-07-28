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
        "REPEAT", "TO", "END", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR",
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
        "TRUE", "FALSE", "AND", "OR", "XOR", "NOT", "OUTPUT", "OP",
        "RUN", "RUNRESULT", "FOREVER", "REPCOUNT", "#", "TEST", "IFTRUE", "IFT",
        "IFFALSE", "IFF", "STOP", "CATCH", "THROW", "ERROR", "WAIT", "BYE",
        ".MAYBEOUTPUT", "IGNORE", "FOR", "DOTIMES", "DO.WHILE", "WHILE", "DO.UNTIL",
        "UNTIL", "CASE", "COND", "APPLY", "INVOKE", "FOREACH", "MAP", "MAP.SE",
        "FILTER", "FIND", "REDUCE", "CROSSMAP",
        "BUFFERS", "BUFFERLIST", "BUFFER", "SETBUFFER", "NEXTBUFFER", "PREVBUFFER", "OPENBUFFER", "CLOSEBUFFER",
        "LINE", "GETLINE", "ROW", "LINE.NO", "COL", "COL.NO", "LINECOUNT", "LINES", "BUFFERTEXT",
        "SELECTION", "SELECTEDTEXT", "MODIFIED?", "CHANGED?", "FILENAME", "BUFFERNAME", "SETLINE",
        "GOTOLINE", "SETROW", "GOTOCOL", "SETCOL", "CLEARBUFFER", "ERASEBUFFER"
    ]

    internal static let statementCommands: Set<String> = [
        "MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW",
        "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY",
        "DELETELINE", "DELLINE", "KILLLINE", "DL",
        "REPEAT", "TO", "END", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR",
        "NEWLINE", "NL", "ENTER", "PD", "PENDOWN", "PU", "PENUP",
        "FD", "FORWARD", "BK", "BACK", "BACKWARD", "RT", "RIGHT", "LT", "LEFT",
        "NEXTBUFFER", "PREVBUFFER", "OPENBUFFER", "CLOSEBUFFER", "SETLINE", "GOTOLINE", "SETROW",
        "GOTOCOL", "SETCOL", "CLEARBUFFER", "ERASEBUFFER",
        "IF", "IFELSE", "OUTPUT", "OP", "RUN", "RUNRESULT", "FOREVER",
        "TEST", "IFTRUE", "IFT", "IFFALSE", "IFF", "STOP", "CATCH", "THROW",
        "WAIT", "BYE", "IGNORE", "FOR", "DOTIMES", "DO.WHILE", "WHILE", "DO.UNTIL",
        "UNTIL", "CASE", "COND", "APPLY", "INVOKE", "FOREACH", "MAP", "MAP.SE",
        "FILTER", "REDUCE", "CROSSMAP", "SEARCH"
    ]

    public var lastResult: String? = nil
    public var repCount: Int = 0
    public var testResult: Bool? = nil
    public var lastError: String = "[]"
    public var byeFlag: Bool = false
    public var currentThrowTag: String? = nil
    public var currentThrowValue: String? = nil

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
        delegate.logoEngine(self, performAction: .saveUndoSnapshot)

        var index = 0
        var frameReturn: String? = nil
        executeTokens(tokens, index: &index, frameReturn: &frameReturn)
        if let ret = frameReturn, !ret.isEmpty {
            lastResult = ret
        }
        delegate.logoEngine(self, performAction: .clampCursor)
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
                    delegate.logoEngine(self, performAction: .applySetting(setting: setting, arg: arg))
                }

            case "TYPE", "PRINT":
                index += 1
                while index < tokens.count {
                    let nextUpper = tokens[index].uppercased()
                    if LogoEngine.statementCommands.contains(nextUpper) || tokens[index] == "]" || tokens[index] == ")" {
                        index -= 1
                        break
                    }
                    let text = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, performAction: .insertText(text))
                    if index + 1 < tokens.count {
                        let peekUpper = tokens[index + 1].uppercased()
                        if LogoEngine.statementCommands.contains(peekUpper) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                            break
                        }
                    }
                    index += 1
                }

            case "MSG", "MESSAGE", "SHOW":
                index += 1
                var parts: [String] = []
                while index < tokens.count {
                    let nextUpper = tokens[index].uppercased()
                    if LogoEngine.statementCommands.contains(nextUpper) || tokens[index] == "]" || tokens[index] == ")" {
                        index -= 1
                        break
                    }
                    let text = evaluateExpression(tokens, index: &index)
                    parts.append(text)
                    if index + 1 < tokens.count {
                        let peekUpper = tokens[index + 1].uppercased()
                        if LogoEngine.statementCommands.contains(peekUpper) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                            break
                        }
                    }
                    index += 1
                }
                let msgText = parts.joined(separator: " ")
                delegate.logoEngine(self, performAction: .setStatusMessage(msgText))
                hasSetStatusMessage = true

            case "DEL", "DELETE":
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    delegate.logoEngine(self, performAction: .deleteChar)
                }

            case "BS", "BACKSPACE":
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    delegate.logoEngine(self, performAction: .backspaceChar)
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
                    delegate.logoEngine(self, performAction: .deleteLine)
                }

            case "MOVE":
                index += 1
                if index < tokens.count {
                    let dir = tokens[index].uppercased()
                    switch dir {
                    case "UP": delegate.logoEngine(self, performAction: .moveCursorVirtual(-1))
                    case "DOWN": delegate.logoEngine(self, performAction: .moveCursorVirtual(1))
                    case "LEFT": delegate.logoEngine(self, performAction: .moveLeft)
                    case "RIGHT": delegate.logoEngine(self, performAction: .moveRight)
                    case "HOME": delegate.logoEngine(self, performAction: .moveHome)
                    case "END": delegate.logoEngine(self, performAction: .moveEnd)
                    default: break
                    }
                }

            case "GOTO":
                index += 1
                if index < tokens.count {
                    let lineStr = evaluateExpression(tokens, index: &index)
                    let totalLines = (delegate.logoEngine(self, queryState: .lineCount) as? Int) ?? 0
                    let lineNum = max(1, min(Int(lineStr) ?? 1, totalLines)) - 1
                    delegate.logoEngine(self, performAction: .updateLineIndex(lineNum))
                    delegate.logoEngine(self, performAction: .updateColumnIndex(0))

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !LogoEngine.keywords.contains(nextUpper) {
                            index += 1
                            let colStr = evaluateExpression(tokens, index: &index)
                            let lineText = (delegate.logoEngine(self, queryState: .lineAt(lineNum)) as? String) ?? ""
                            let colNum = max(1, min(Int(colStr) ?? 1, lineText.count + 1)) - 1
                            delegate.logoEngine(self, performAction: .updateColumnIndex(colNum))
                        }
                    }
                }

            case "NEXTBUFFER":
                delegate.logoEngine(self, performAction: .nextBuffer)

            case "PREVBUFFER":
                delegate.logoEngine(self, performAction: .prevBuffer)

            case "CLOSEBUFFER":
                delegate.logoEngine(self, performAction: .closeBuffer)

            case "OPENBUFFER":
                index += 1
                if index < tokens.count {
                    let path = unquote(evaluateExpression(tokens, index: &index))
                    delegate.logoEngine(self, performAction: .openBuffer(path: path))
                }

            case "CLEARBUFFER", "ERASEBUFFER":
                delegate.logoEngine(self, performAction: .clearBuffer)

            case "GOTOLINE", "SETROW":
                index += 1
                if index < tokens.count {
                    let lineStr = evaluateExpression(tokens, index: &index)
                    let row1Based = Int(lineStr) ?? 1
                    delegate.logoEngine(self, performAction: .gotoLine(max(0, row1Based - 1)))
                }

            case "GOTOCOL", "SETCOL":
                index += 1
                if index < tokens.count {
                    let colStr = evaluateExpression(tokens, index: &index)
                    let col1Based = Int(colStr) ?? 1
                    delegate.logoEngine(self, performAction: .gotoCol(max(0, col1Based - 1)))
                }

            case "SETLINE":
                index += 1
                if index < tokens.count {
                    let firstVal = evaluateExpression(tokens, index: &index)
                    if index + 1 < tokens.count && !LogoEngine.keywords.contains(tokens[index + 1].uppercased()) && tokens[index + 1] != "]" {
                        let line1Based = Int(firstVal) ?? 1
                        index += 1
                        let textVal = unquote(evaluateExpression(tokens, index: &index))
                        delegate.logoEngine(self, performAction: .setLine(index: max(0, line1Based - 1), text: textVal))
                    } else {
                        let curRow = (delegate.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0
                        let textVal = unquote(firstVal)
                        delegate.logoEngine(self, performAction: .setLine(index: curRow, text: textVal))
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
                delegate.logoEngine(self, performAction: .editMark)

            case "CUT":
                delegate.logoEngine(self, performAction: .editCut)

            case "PASTE", "UNCUT":
                delegate.logoEngine(self, performAction: .editUncut)

            case "JUSTIFY":
                delegate.logoEngine(self, performAction: .editJustify)

            case "FIND", "SEARCH":
                index += 1
                if index < tokens.count {
                    let nextToken = tokens[index]
                    if nextToken.hasPrefix("[") || customProcedures[nextToken.uppercased()] != nil || (index + 1 < tokens.count && tokens[index + 1].hasPrefix("[")) {
                        index -= 1
                        let val = evaluateExpression(tokens, index: &index)
                        lastResult = val
                    } else {
                        let query = evaluateExpression(tokens, index: &index)
                        delegate.logoEngine(self, performAction: .search(query))
                    }
                }

            case "RUN":
                index += 1
                if index < tokens.count {
                    if tokens[index] == "[" {
                        let block = extractBlockTokens(tokens: tokens, index: &index)
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    } else {
                        let scriptStr = evaluateExpression(tokens, index: &index)
                        let block = tokenize(scriptStr)
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    }
                }

            case "RUNRESULT":
                index += 1
                if index < tokens.count {
                    var block: [String] = []
                    if tokens[index] == "[" {
                        block = extractBlockTokens(tokens: tokens, index: &index)
                    } else {
                        let scriptStr = evaluateExpression(tokens, index: &index)
                        block = tokenize(scriptStr)
                    }
                    var bIdx = 0
                    var subReturn: String? = nil
                    executeTokens(block, index: &bIdx, frameReturn: &subReturn)
                    if let r = subReturn, !r.isEmpty {
                        lastResult = "[\(r)]"
                    } else {
                        lastResult = "[]"
                    }
                }

            case "REPEAT":
                index += 1
                let countStr = evaluateExpression(tokens, index: &index)
                let count = Int(countStr) ?? 1
                index += 1 // Advance to "["
                if index < tokens.count && tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    for r in 1...count {
                        repCount = r
                        variables["#"] = "\(r)"
                        variables["repcount"] = "\(r)"
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                        if frameReturn != nil || byeFlag || currentThrowTag != nil { break }
                    }
                }

            case "FOREVER":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    var r = 1
                    while !byeFlag && frameReturn == nil && currentThrowTag == nil {
                        repCount = r
                        variables["#"] = "\(r)"
                        variables["repcount"] = "\(r)"
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                        r += 1
                    }
                }

            case "STOP":
                frameReturn = ""
                return

            case "BYE":
                byeFlag = true
                return

            case "WAIT":
                index += 1
                if index < tokens.count {
                    let timeStr = evaluateExpression(tokens, index: &index)
                    if let val = Double(timeStr), val > 0 {
                        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || ProcessInfo.processInfo.processName.contains("XCTest") || ProcessInfo.processInfo.processName.contains("swiftpm-testing-helper")
                        let delay = isTesting ? min(val / 60000.0, 0.001) : val / 60.0
                        Thread.sleep(forTimeInterval: delay)
                    }
                }

            case "TEST":
                index += 1
                var condTokens: [String] = []
                while index < tokens.count {
                    let upperNext = tokens[index].uppercased()
                    if upperNext == "IFTRUE" || upperNext == "IFT" || upperNext == "IFFALSE" || upperNext == "IFF" || upperNext == "[" || upperNext == "]" {
                        break
                    }
                    condTokens.append(tokens[index])
                    index += 1
                }
                testResult = evaluateCondition(condTokens)
                index -= 1

            case "IFTRUE", "IFT":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    if testResult == true {
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    }
                }

            case "IFFALSE", "IFF":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    if testResult == false {
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    }
                }

            case "IGNORE":
                index += 1
                if index < tokens.count {
                    _ = evaluateExpression(tokens, index: &index)
                }

            case "CATCH":
                index += 1
                if index < tokens.count {
                    let tag = unquote(evaluateExpression(tokens, index: &index)).lowercased()
                    index += 1
                    if index < tokens.count && tokens[index] == "[" {
                        let block = extractBlockTokens(tokens: tokens, index: &index)
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                        if let throwTag = currentThrowTag, throwTag == tag || tag == "error" {
                            let thrownVal = currentThrowValue ?? ""
                            currentThrowTag = nil
                            currentThrowValue = nil
                            if !thrownVal.isEmpty {
                                lastResult = thrownVal
                            }
                        }
                    }
                }

            case "THROW":
                index += 1
                if index < tokens.count {
                    let tag = unquote(evaluateExpression(tokens, index: &index)).lowercased()
                    var thrownVal = ""
                    if index + 1 < tokens.count && !tokens[index + 1].hasPrefix("]") {
                        index += 1
                        thrownVal = evaluateExpression(tokens, index: &index)
                    }
                    currentThrowTag = tag
                    currentThrowValue = thrownVal
                    return
                }

            case "FOR":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let ctrlBlock = extractBlockTokens(tokens: tokens, index: &index)
                    index += 1
                    if index < tokens.count && tokens[index] == "[" {
                        let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                        if !ctrlBlock.isEmpty {
                            let varName = ctrlBlock[0].lowercased()
                            var cIdx = 1
                            let startVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? 1
                            cIdx += 1
                            let limitVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? startVal
                            cIdx += 1
                            var stepVal = 1
                            if cIdx < ctrlBlock.count {
                                stepVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? 1
                            }
                            var cur = startVal
                            while (stepVal > 0 ? cur <= limitVal : cur >= limitVal) && !byeFlag && frameReturn == nil && currentThrowTag == nil {
                                variables[varName] = "\(cur)"
                                var bIdx = 0
                                executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                                cur += stepVal
                            }
                        }
                    }
                }

            case "DOTIMES":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let ctrlBlock = extractBlockTokens(tokens: tokens, index: &index)
                    index += 1
                    if index < tokens.count && tokens[index] == "[" {
                        let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                        if ctrlBlock.count >= 2 {
                            let varName = ctrlBlock[0].lowercased()
                            var cIdx = 1
                            let countVal = Int(evaluateExpression(ctrlBlock, index: &cIdx)) ?? 0
                            for i in 0..<countVal {
                                variables[varName] = "\(i)"
                                var bIdx = 0
                                executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                                if byeFlag || frameReturn != nil || currentThrowTag != nil { break }
                            }
                        }
                    }
                }

            case "WHILE":
                index += 1
                var condTokens: [String] = []
                while index < tokens.count && tokens[index] != "[" {
                    condTokens.append(tokens[index])
                    index += 1
                }
                if index < tokens.count && tokens[index] == "[" {
                    let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                    while evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil {
                        var bIdx = 0
                        executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                    }
                }

            case "UNTIL":
                index += 1
                var condTokens: [String] = []
                while index < tokens.count && tokens[index] != "[" {
                    condTokens.append(tokens[index])
                    index += 1
                }
                if index < tokens.count && tokens[index] == "[" {
                    let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                    while !evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil {
                        var bIdx = 0
                        executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                    }
                }

            case "DO.WHILE":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                    index += 1
                    var condTokens: [String] = []
                    while index < tokens.count && tokens[index] != "]" {
                        condTokens.append(tokens[index])
                        index += 1
                    }
                    repeat {
                        var bIdx = 0
                        executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                    } while evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
                }

            case "DO.UNTIL":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let bodyBlock = extractBlockTokens(tokens: tokens, index: &index)
                    index += 1
                    var condTokens: [String] = []
                    while index < tokens.count && tokens[index] != "]" {
                        condTokens.append(tokens[index])
                        index += 1
                    }
                    repeat {
                        var bIdx = 0
                        executeTokens(bodyBlock, index: &bIdx, frameReturn: &frameReturn)
                    } while !evaluateCondition(condTokens) && !byeFlag && frameReturn == nil && currentThrowTag == nil
                }

            case "CASE":
                index += 1
                let targetVal = unquote(evaluateExpression(tokens, index: &index))
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let clausesBlock = extractBlockTokens(tokens: tokens, index: &index)
                    let result = evaluateCaseClauses(targetVal: targetVal, clausesBlock: clausesBlock)
                    if let res = result {
                        lastResult = res
                    }
                }

            case "COND":
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let clausesBlock = extractBlockTokens(tokens: tokens, index: &index)
                    let result = evaluateCondClauses(clausesBlock: clausesBlock)
                    if let res = result {
                        lastResult = res
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

    internal func extractBlockTokens(tokens: [String], index: inout Int) -> [String] {
        guard index < tokens.count && tokens[index] == "[" else { return [] }
        index += 1
        var depth = 1
        var block: [String] = []
        while index < tokens.count && depth > 0 {
            let t = tokens[index]
            if t == "[" { depth += 1 }
            else if t == "]" {
                depth -= 1
                if depth == 0 { break }
            }
            block.append(t)
            index += 1
        }
        return block
    }

    internal func evaluateCaseClauses(targetVal: String, clausesBlock: [String]) -> String? {
        var idx = 0
        while idx < clausesBlock.count {
            if clausesBlock[idx] == "[" {
                let clause = extractBlockTokens(tokens: clausesBlock, index: &idx)
                if !clause.isEmpty {
                    var cIdx = 0
                    if clause[cIdx].uppercased() == "ELSE" {
                        cIdx += 1
                        return evaluateExpression(clause, index: &cIdx)
                    } else if clause[cIdx] == "[" {
                        let matches = extractBlockTokens(tokens: clause, index: &cIdx)
                        cIdx += 1
                        let isMatch = matches.contains { unquote($0) == targetVal }
                        if isMatch {
                            return evaluateExpression(clause, index: &cIdx)
                        }
                    }
                }
            }
            idx += 1
        }
        return nil
    }

    internal func evaluateCondClauses(clausesBlock: [String]) -> String? {
        var idx = 0
        while idx < clausesBlock.count {
            if clausesBlock[idx] == "[" {
                let clause = extractBlockTokens(tokens: clausesBlock, index: &idx)
                if !clause.isEmpty {
                    var cIdx = 0
                    if clause[cIdx].uppercased() == "ELSE" {
                        cIdx += 1
                        return evaluateExpression(clause, index: &cIdx)
                    } else if clause[cIdx] == "[" {
                        let condTokens = extractBlockTokens(tokens: clause, index: &cIdx)
                        cIdx += 1
                        if evaluateCondition(condTokens) {
                            return evaluateExpression(clause, index: &cIdx)
                        }
                    }
                }
            }
            idx += 1
        }
        return nil
    }

    public func applyTemplate(templateStr: String, args: [String], indexInLoop: Int = 1, restList: [String] = []) -> String {
        let clean = templateStr.trimmingCharacters(in: .whitespacesAndNewlines)

        let prevHash = variables["#"]
        let prevRest = variables["?rest"]
        let prevQuestion = variables["?"]
        defer {
            if let v = prevHash { variables["#"] = v } else { variables.removeValue(forKey: "#") }
            if let v = prevRest { variables["?rest"] = v } else { variables.removeValue(forKey: "?rest") }
            if let v = prevQuestion { variables["?"] = v } else { variables.removeValue(forKey: "?") }
        }

        variables["#"] = "\(indexInLoop)"
        variables["?rest"] = restList.joined(separator: " ")

        if clean.hasPrefix("[") && clean.hasSuffix("]") {
            let tTokens = tokenize(clean)
            var idx = 0
            if !tTokens.isEmpty && tTokens[0] == "[" {
                let inner = extractBlockTokens(tokens: tTokens, index: &idx)
                if !inner.isEmpty && inner[0] == "[" {
                    // Named slot or procedure text form: [[x y] ...]
                    var iIdx = 0
                    let params = extractBlockTokens(tokens: inner, index: &iIdx)
                    iIdx += 1
                    for (i, p) in params.enumerated() {
                        let pName = unquote(p).lowercased()
                        variables[pName] = i < args.count ? args[i] : ""
                    }
                    let bodyTokens = Array(inner[iIdx...])
                    if !bodyTokens.isEmpty && bodyTokens[0] == "[" {
                        // Statement list form: [[x y] [output :x * :y]]
                        var bIdx = 0
                        let stmtBlock = extractBlockTokens(tokens: bodyTokens, index: &bIdx)
                        var subReturn: String? = nil
                        var sIdx = 0
                        executeTokens(stmtBlock, index: &sIdx, frameReturn: &subReturn)
                        return subReturn ?? lastResult ?? ""
                    } else {
                        // Expression form: [[x y] :x * :y]
                        var bIdx = 0
                        return evaluateExpression(bodyTokens, index: &bIdx)
                    }
                } else {
                    // Explicit slot form: [? * ?] or [?1 + ?2] or [? % 2 == 1] or [output ? * ?]
                    variables["?"] = args.first ?? ""
                    for (i, arg) in args.enumerated() {
                        variables["?\(i + 1)"] = arg
                    }
                    if !inner.isEmpty {
                        let firstUpper = inner[0].uppercased()
                        if LogoEngine.keywords.contains(firstUpper) && firstUpper != "DATE" && firstUpper != "TIME" {
                            var subReturn: String? = nil
                            var sIdx = 0
                            executeTokens(inner, index: &sIdx, frameReturn: &subReturn)
                            return subReturn ?? lastResult ?? ""
                        } else {
                            let hasComparison = inner.contains { $0 == "==" || $0 == "!=" || $0 == "<" || $0 == ">" || $0 == "<=" || $0 == ">=" }
                            if hasComparison {
                                return evaluateCondition(inner) ? "1" : "0"
                            } else {
                                var bIdx = 0
                                return evaluateExpression(inner, index: &bIdx)
                            }
                        }
                    }
                    return ""
                }
            }
        }

        // Named procedure form: "sum or "double or sum
        let procName = unquote(clean).uppercased()
        if let proc = customProcedures[procName] {
            let callTokens = [procName] + args
            var cIdx = 0
            return invokeProcedure(proc, tokens: callTokens, index: &cIdx) ?? ""
        } else {
            let callTokens = [procName] + args
            var cIdx = 0
            return evaluateTokenOrCommand(callTokens, index: &cIdx)
        }
    }

    internal func invokeProcedure(_ proc: LogoProcedure, tokens: [String], index: inout Int) -> String? {
        var args: [String] = []
        for _ in 0..<proc.parameters.count {
            index += 1
            let arg = evaluateExpression(tokens, index: &index)
            args.append(arg)
        }

        var previousParamValues: [String: String?] = [:]
        for (i, param) in proc.parameters.enumerated() {
            previousParamValues[param] = variables[param]
            variables[param] = args[i]
        }
        defer {
            for (param, prev) in previousParamValues {
                if let old = prev {
                    variables[param] = old
                } else {
                    variables.removeValue(forKey: param)
                }
            }
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
