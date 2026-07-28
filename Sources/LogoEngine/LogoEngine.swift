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

/// LOGO-style Macro Language Engine for text editors.
public final class LogoEngine {
    public var customProcedures: [String: [String]] = [:]
    public var variables: [String: String] = [:]
    public var hasSetStatusMessage: Bool = false
    internal var gensymCounter: Int = 0

    // Turtle graphics state
    public var isPenDown: Bool = true
    public var heading: Int = 90 // 0 = UP, 90 = RIGHT, 180 = DOWN, 270 = LEFT

    internal static let keywords: Set<String> = [
        "MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW",
        "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND",
        "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR",
        "NEWLINE", "NL", "ENTER", "DATE", "TIME", "PD", "PENDOWN", "PU", "PENUP",
        "FD", "FORWARD", "BK", "BACK", "BACKWARD", "RT", "RIGHT", "LT", "LEFT",
        "IF", "IFELSE", "WORD", "LIST", "SENTENCE", "SE", "FPUT", "LPUT", "ARRAY",
        "LISTTOARRAY", "ARRAYTOLIST", "COMBINE", "REVERSE", "GENSYM", "FIRST",
        "LAST", "FIRSTS", "BUTFIRST", "BF", "BUTLAST", "BL", "BUTFIRSTS", "BFS",
        "ITEM", "PICK", "REMOVE", "REMDUP", "QUOTED", "SPLIT", "SETITEM",
        ".SETFIRST", ".SETBF", "PUSH", "POP", "QUEUE", "DEQUEUE", "WORD?", "WORDP",
        "LIST?", "LISTP", "ARRAY?", "ARRAYP", "NUMBER?", "NUMBERP", "EMPTY?", "EMPTYP",
        "EQUAL?", "EQUALP", "NOTEQUAL?", "NOTEQUALP", "MEMBER?", "MEMBERP", "SUBSTRING?",
        "SUBSTRINGP", "COUNT", "ASCII", "CHAR", "MEMBER", "UPPERCASE", "LOWERCASE"
    ]

    public init() {}

    /// Executes LOGO macro script on the editor context, creating a single atomic Undo snapshot.
    public func execute(_ script: String, on editor: LogoEditorContext) {
        let tokens = tokenize(script)
        guard !tokens.isEmpty else { return }

        // Save a single atomic Undo snapshot for the entire macro execution
        editor.saveUndoSnapshot()

        var index = 0
        executeTokens(tokens, index: &index, on: editor)
        editor.clampCursor()
    }

    internal func executeTokens(_ tokens: [String], index: inout Int, on editor: LogoEditorContext) {
        while index < tokens.count {
            let token = tokens[index]
            let upper = token.uppercased()

            if token == "]" {
                return
            }

            switch upper {
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
                    case .string(let s):
                        var chars = Array(s)
                        if zeroIdx >= 0 && zeroIdx < chars.count, let firstCh = newVal.first {
                            chars[zeroIdx] = firstCh
                            variables[varName] = String(chars)
                        }
                    }
                }

            case "PUSH":
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

            case "QUEUE":
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
                    editor.applySetting(setting, arg: arg)
                }

            case "TYPE", "PRINT":
                index += 1
                if index < tokens.count {
                    let text = evaluateExpression(tokens, index: &index)
                    editor.insertString(text)
                }

            case "MSG", "MESSAGE", "SHOW":
                index += 1
                if index < tokens.count {
                    let msgText = evaluateExpression(tokens, index: &index)
                    editor.setStatusMessage(msgText)
                    hasSetStatusMessage = true
                }

            case "DEL", "DELETE":
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    editor.delete()
                }

            case "BS", "BACKSPACE":
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    editor.backspace()
                }

            case "MOVE":
                index += 1
                if index < tokens.count {
                    let dir = tokens[index].uppercased()
                    switch dir {
                    case "UP": editor.moveCursorVirtual(deltaRow: -1)
                    case "DOWN": editor.moveCursorVirtual(deltaRow: 1)
                    case "LEFT": editor.dispatchCommand(.moveLeft)
                    case "RIGHT": editor.dispatchCommand(.moveRight)
                    case "HOME": editor.dispatchCommand(.moveHome)
                    case "END": editor.dispatchCommand(.moveEnd)
                    default: break
                    }
                }

            case "GOTO":
                index += 1
                if index < tokens.count {
                    let lineStr = evaluateExpression(tokens, index: &index)
                    let lineNum = max(1, min(Int(lineStr) ?? 1, editor.lineCount)) - 1
                    editor.lineIndex = lineNum
                    editor.columnIndex = 0

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !LogoEngine.keywords.contains(nextUpper) {
                            index += 1
                            let colStr = evaluateExpression(tokens, index: &index)
                            let lineText = editor.getLine(at: lineNum)
                            let colNum = max(1, min(Int(colStr) ?? 1, lineText.count + 1)) - 1
                            editor.columnIndex = colNum
                        }
                    }
                }

            case "BOX":
                index += 1
                executeBoxCommand(tokens, index: &index, on: editor)

            case "LINE", "HR":
                index += 1
                executeLineCommand(tokens, index: &index, on: editor)

            case "VLINE", "VHR":
                index += 1
                executeVlineCommand(tokens, index: &index, on: editor)

            case "NEWLINE", "NL", "ENTER":
                index += 1
                executeNewlineCommand(tokens, index: &index, on: editor)

            case "DATE":
                executeDateCommand(tokens, index: &index, on: editor)

            case "TIME":
                executeTimeCommand(tokens, index: &index, on: editor)

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
                        executeTokens(tokens, index: &index, on: editor)
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
                    index += 1 // Advance past first "["
                    if isTrue {
                        executeTokens(tokens, index: &index, on: editor)
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
                        while index < tokens.count && depth > 0 {
                            if tokens[index] == "[" { depth += 1 }
                            else if tokens[index] == "]" { depth -= 1 }
                            if depth == 0 { break }
                            index += 1
                        }
                        index += 1 // Advance past first "]"
                        if index < tokens.count && tokens[index] == "[" {
                            index += 1 // Advance past second "["
                            executeTokens(tokens, index: &index, on: editor)
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
                executeTurtleMove(steps: dist, directionHeading: heading, on: editor)

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
                executeTurtleMove(steps: dist, directionHeading: (heading + 180) % 360, on: editor)

            case "MARK":
                editor.dispatchCommand(.editMark)

            case "CUT":
                editor.dispatchCommand(.editCut)

            case "PASTE", "UNCUT":
                editor.dispatchCommand(.editUncut)

            case "JUSTIFY":
                editor.dispatchCommand(.editJustify)

            case "FIND", "SEARCH":
                index += 1
                if index < tokens.count {
                    let query = evaluateExpression(tokens, index: &index)
                    editor.performSearch(query: query)
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
                        executeTokens(tokens, index: &bodyIndex, on: editor)
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
                    var procTokens: [String] = []
                    while index < tokens.count && tokens[index].uppercased() != "END" {
                        procTokens.append(tokens[index])
                        index += 1
                    }
                    customProcedures[procName] = procTokens
                }

            case "EXEC":
                index += 1
                if index < tokens.count {
                    let procName = tokens[index].uppercased()
                    if let procTokens = customProcedures[procName] {
                        var procIndex = 0
                        executeTokens(procTokens, index: &procIndex, on: editor)
                    }
                }

            default:
                if let procTokens = customProcedures[upper] {
                    var procIndex = 0
                    executeTokens(procTokens, index: &procIndex, on: editor)
                }
            }

            index += 1
        }
    }
}
