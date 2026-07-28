import Foundation

struct BoxStyle {
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
        switch str.lowercased() {
        case "double": return .double
        case "round": return .round
        case "ascii": return .ascii
        default: return .single
        }
    }
}

/// LOGO-style Macro Language Engine for se text editor.
///
/// Features and Capabilities:
/// - **Text Editing Commands**: `TYPE`, `DEL`, `BS`, `MOVE`, `MARK`, `CUT`,
///   `PASTE`, `JUSTIFY`, `FIND`, `GOTO`, `BOX`, `LINE`, `VLINE`, `NEWLINE`,
///   `DATE`, `TIME`.
/// - **Classical Turtle Graphics**: `PD`/`PENDOWN`, `PU`/`PENUP`,
///   `FD`/`FORWARD`, `BK`/`BACK`, `RT`/`RIGHT`, `LT`/`LEFT` with 90° cardinal
///   turns & drawing.
/// - **Conditionals**: `IF condition [ ... ]`, `IFELSE condition [ true_block ]
///   [ false_block ]`.
/// - **Expressions & Variables**: Date/time evaluation (`MAKE "i" DATE
///   "YYYY/MM/DD"`), variable assignment and dereferencing (`MAKE "var" val` /
///   `:var`).
/// - **Editor Configuration**: `SET` (`ruler`, `wrap`, `syntax`, `autoreload`,
///   `lang`).
/// - **Arithmetic**: Operators (`+`, `-`, `*`, `/`, `%`) and parenthesized
///   expressions.
/// - **Control Flow & Loops**: `REPEAT expr [ ... ]`.
/// - **Procedure Definitions**: Custom macro procedures (`TO proc ... END`).
/// - **2D Canvas Overlay Box Drawing**: Preserves line indents and background
///   text.
/// - **Smart Line Junction Fusion**: Neighbor-aware 4-directional mask fusion
///   (`┌`, `┐`, `└`, `┘`, `┼`, `┬`, `┴`, `├`, `┤`, `╬`, `╦`, `╩`, `╠`, `╣`).
public final class LogoEngine {
    public var customProcedures: [String: [String]] = [:]
    public var variables: [String: String] = [:]
    public var hasSetStatusMessage: Bool = false

    // Turtle graphics state
    public var isPenDown: Bool = true
    public var heading: Int = 90 // 0 = UP, 90 = RIGHT, 180 = DOWN, 270 = LEFT

    private static let keywords: Set<String> = [
        "MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW",
        "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND",
        "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR",
        "NEWLINE", "NL", "ENTER", "DATE", "TIME", "PD", "PENDOWN", "PU", "PENUP",
        "FD", "FORWARD", "BK", "BACK", "BACKWARD", "RT", "RIGHT", "LT", "LEFT",
        "IF", "IFELSE"
    ]

    private static let singleMasks: [Character: Int] = [
        "│": 5, "─": 10, "┌": 6, "┐": 12, "└": 3, "┘": 9,
        "├": 7, "┤": 13, "┬": 14, "┴": 11, "┼": 15,
        "╵": 1, "╶": 2, "╷": 4, "╴": 8
    ]

    private static let doubleMasks: [Character: Int] = [
        "║": 5, "═": 10, "╔": 6, "╗": 12, "╚": 3, "╝": 9,
        "╠": 7, "╣": 13, "╦": 14, "╩": 11, "╬": 15
    ]

    private static let singleCharForMask: [Int: Character] = [
        1: "│", 2: "─", 3: "└", 4: "│", 5: "│", 6: "┌", 7: "├",
        8: "─", 9: "┘", 10: "─", 11: "┴", 12: "┐", 13: "┤", 14: "┬", 15: "┼"
    ]

    private static let doubleCharForMask: [Int: Character] = [
        1: "║", 2: "═", 3: "╚", 4: "║", 5: "║", 6: "╔", 7: "╠",
        8: "═", 9: "╝", 10: "═", 11: "╩", 12: "╗", 13: "╣", 14: "╦", 15: "╬"
    ]

    public init() {}

    /// Executes LOGO macro script on the editor, creating a single atomic Undo snapshot.
    public func execute(_ script: String, on editor: Editor) {
        let tokens = tokenize(script)
        guard !tokens.isEmpty else { return }

        // Save a single atomic Undo snapshot for the entire macro execution
        editor.saveUndoSnapshot()

        var index = 0
        executeTokens(tokens, index: &index, on: editor)
        editor.buffer.clampCursor()
    }

    /// Tokenizes macro script handling string literals in quotes, comparison operators (==, !=, <=, >=), math operators (+, -, *, /, %), and brackets.
    public func tokenize(_ script: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuote = false

        let delims: Set<Character> = ["[", "]", "(", ")", "+", "-", "*", "/", "%"]

        var i = script.startIndex
        while i < script.endIndex {
            let ch = script[i]
            if ch == "\"" {
                inQuote.toggle()
                current.append(ch)
            } else if !inQuote && (ch == "=" || ch == "!" || ch == ">" || ch == "<") {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                var op = String(ch)
                let nextIdx = script.index(after: i)
                if nextIdx < script.endIndex {
                    let nextCh = script[nextIdx]
                    if nextCh == "=" || nextCh == ">" {
                        op.append(nextCh)
                        i = nextIdx
                    }
                }
                tokens.append(op)
            } else if delims.contains(ch) && !inQuote {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(String(ch))
            } else if ch.isWhitespace && !inQuote {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
            i = script.index(after: i)
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }

    private func evaluateCondition(_ conditionTokens: [String]) -> Bool {
        guard !conditionTokens.isEmpty else { return false }

        // Find comparison operator if present
        let opIndex = conditionTokens.firstIndex { $0 == "==" || $0 == "=" || $0 == "!=" || $0 == "<>" || $0 == "<" || $0 == "<=" || $0 == ">" || $0 == ">=" }

        if let idx = opIndex {
            var leftIdx = 0
            let leftValStr = evaluateExpression(Array(conditionTokens[..<idx]), index: &leftIdx)

            var rightIdx = 0
            let rightValStr = evaluateExpression(Array(conditionTokens[(idx + 1)...]), index: &rightIdx)

            let op = conditionTokens[idx]

            if let num1 = Double(leftValStr), let num2 = Double(rightValStr) {
                switch op {
                case "==", "=": return num1 == num2
                case "!=", "<>": return num1 != num2
                case "<": return num1 < num2
                case "<=": return num1 <= num2
                case ">": return num1 > num2
                case ">=": return num1 >= num2
                default: return false
                }
            } else {
                switch op {
                case "==", "=": return leftValStr == rightValStr
                case "!=", "<>": return leftValStr != rightValStr
                case "<": return leftValStr < rightValStr
                case "<=": return leftValStr <= rightValStr
                case ">": return leftValStr > rightValStr
                case ">=": return leftValStr >= rightValStr
                default: return false
                }
            }
        } else {
            var exprIdx = 0
            let val = evaluateExpression(conditionTokens, index: &exprIdx).lowercased()
            if val == "true" || val == "1" {
                return true
            }
            if let n = Int(val), n != 0 {
                return true
            }
            return false
        }
    }

    private func executeTokens(_ tokens: [String], index: inout Int, on editor: Editor) {
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
                    applySetting(setting, arg: arg, editor: editor)
                }

            case "TYPE", "PRINT":
                index += 1
                if index < tokens.count {
                    let text = evaluateExpression(tokens, index: &index)
                    editor.buffer.insertString(text)
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
                    editor.buffer.delete()
                }

            case "BS", "BACKSPACE":
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    editor.buffer.backspace()
                }

            case "MOVE":
                index += 1
                if index < tokens.count {
                    let dir = tokens[index].uppercased()
                    switch dir {
                    case "UP": editor.moveCursorVirtual(deltaRow: -1)
                    case "DOWN": editor.moveCursorVirtual(deltaRow: 1)
                    case "LEFT": _ = editor.commandRegistry.dispatch(id: .moveLeft, editor: editor)
                    case "RIGHT": _ = editor.commandRegistry.dispatch(id: .moveRight, editor: editor)
                    case "HOME": _ = editor.commandRegistry.dispatch(id: .moveHome, editor: editor)
                    case "END": _ = editor.commandRegistry.dispatch(id: .moveEnd, editor: editor)
                    default: break
                    }
                }

            case "GOTO":
                index += 1
                if index < tokens.count {
                    let lineStr = evaluateExpression(tokens, index: &index)
                    let lineNum = max(1, min(Int(lineStr) ?? 1, editor.buffer.lines.count)) - 1
                    editor.buffer.lineIndex = lineNum
                    editor.buffer.columnIndex = 0

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !LogoEngine.keywords.contains(nextUpper) {
                            index += 1
                            let colStr = evaluateExpression(tokens, index: &index)
                            let colNum = max(1, min(Int(colStr) ?? 1, editor.buffer.lines[lineNum].count + 1)) - 1
                            editor.buffer.columnIndex = colNum
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
                        index += 1
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
                _ = editor.commandRegistry.dispatch(id: .editMark, editor: editor)

            case "CUT":
                _ = editor.commandRegistry.dispatch(id: .editCut, editor: editor)

            case "PASTE", "UNCUT":
                _ = editor.commandRegistry.dispatch(id: .editUncut, editor: editor)

            case "JUSTIFY":
                _ = editor.commandRegistry.dispatch(id: .editJustify, editor: editor)

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

    private func executeTurtleMove(steps: Int, directionHeading: Int, on editor: Editor) {
        let normHeading = ((directionHeading % 360) + 360) % 360

        let deltaRow: Int
        let deltaCol: Int
        let lineChar: Character

        switch normHeading {
        case 0, 360: // UP
            deltaRow = -1; deltaCol = 0; lineChar = "│"
        case 180: // DOWN
            deltaRow = 1; deltaCol = 0; lineChar = "│"
        case 270: // LEFT
            deltaRow = 0; deltaCol = -1; lineChar = "─"
        default: // 90 (RIGHT)
            deltaRow = 0; deltaCol = 1; lineChar = "─"
        }

        for s in 0..<steps {
            let currLine = editor.buffer.lineIndex
            let currCol = editor.buffer.columnIndex

            if isPenDown {
                while editor.buffer.lines.count <= currLine {
                    editor.buffer.lines.append("")
                }

                var lineChars = Array(editor.buffer.lines[currLine])
                while lineChars.count <= currCol {
                    lineChars.append(" ")
                }

                let stepMask: Int
                if normHeading == 90 { // RIGHT
                    stepMask = (steps == 1) ? 10 : ((s == 0) ? 2 : (s == steps - 1 ? 8 : 10))
                } else if normHeading == 270 { // LEFT
                    stepMask = (steps == 1) ? 10 : ((s == 0) ? 8 : (s == steps - 1 ? 2 : 10))
                } else if normHeading == 180 { // DOWN
                    stepMask = (steps == 1) ? 5 : ((s == 0) ? 4 : (s == steps - 1 ? 1 : 5))
                } else { // UP (0)
                    stepMask = (steps == 1) ? 5 : ((s == 0) ? 1 : (s == steps - 1 ? 4 : 5))
                }

                let existing = lineChars[currCol]
                lineChars[currCol] = fuseCharacter(existing: existing, newMask: stepMask, defaultNewChar: lineChar, line: currLine, col: currCol, on: editor)
                editor.buffer.lines[currLine] = String(lineChars)
                editor.buffer.isModified = true
            }

            if s < steps - 1 {
                let nextLine = max(0, currLine + deltaRow)
                let nextCol = max(0, currCol + deltaCol)

                while editor.buffer.lines.count <= nextLine {
                    editor.buffer.lines.append("")
                }
                editor.buffer.lineIndex = nextLine
                editor.buffer.columnIndex = nextCol
            }
        }
    }

    private func getEffectiveMask(existing: Character, line: Int, col: Int, on editor: Editor) -> Int {
        if existing == "─" || existing == "═" {
            let hasLeft = col > 0 && isLineChar(getChar(atLine: line, col: col - 1, on: editor))
            let hasRight = isLineChar(getChar(atLine: line, col: col + 1, on: editor))

            if hasLeft && hasRight { return 10 } // RIGHT + LEFT
            if hasLeft { return 8 } // LEFT
            if hasRight { return 2 } // RIGHT
            return 10
        }

        if existing == "│" || existing == "║" {
            let hasTop = line > 0 && isLineChar(getChar(atLine: line - 1, col: col, on: editor))
            let hasBottom = isLineChar(getChar(atLine: line + 1, col: col, on: editor))

            if hasTop && hasBottom { return 5 } // TOP + BOTTOM
            if hasTop { return 1 } // TOP
            if hasBottom { return 4 } // BOTTOM
            return 5
        }

        return LogoEngine.singleMasks[existing] ?? LogoEngine.doubleMasks[existing] ?? 0
    }

    private func isLineChar(_ ch: Character) -> Bool {
        return LogoEngine.singleMasks[ch] != nil || LogoEngine.doubleMasks[ch] != nil
    }

    private func getChar(atLine line: Int, col: Int, on editor: Editor) -> Character {
        guard line >= 0 && line < editor.buffer.lines.count else { return " " }
        let lineChars = Array(editor.buffer.lines[line])
        guard col >= 0 && col < lineChars.count else { return " " }
        return lineChars[col]
    }

    private func fuseCharacter(existing: Character, newMask: Int, defaultNewChar: Character, line: Int, col: Int, on editor: Editor) -> Character {
        let isDouble = LogoEngine.doubleMasks[existing] != nil || LogoEngine.doubleMasks[defaultNewChar] != nil
        let mask1 = getEffectiveMask(existing: existing, line: line, col: col, on: editor)

        guard mask1 != 0 else { return defaultNewChar }

        let fusedMask = mask1 | newMask
        if isDouble {
            return LogoEngine.doubleCharForMask[fusedMask] ?? defaultNewChar
        } else {
            return LogoEngine.singleCharForMask[fusedMask] ?? defaultNewChar
        }
    }

    private func normalizeDateFormat(_ format: String) -> String {
        var fmt = format
            .replacingOccurrences(of: "YYYY", with: "yyyy")
            .replacingOccurrences(of: "DD", with: "dd")
        if fmt.contains("yyyy") && fmt.contains("mm") {
            fmt = fmt.replacingOccurrences(of: "mm", with: "MM")
        }
        return fmt
    }

    private func normalizeTimeFormat(_ format: String) -> String {
        return format
            .replacingOccurrences(of: "hh", with: "HH")
            .replacingOccurrences(of: "SS", with: "ss")
    }

    private func formatDate(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = normalizeDateFormat(format)
        return formatter.string(from: Date())
    }

    private func formatTime(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = normalizeTimeFormat(format)
        return formatter.string(from: Date())
    }

    private func executeDateCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        let dateStr = evaluateTokenOrCommand(tokens, index: &index)
        editor.buffer.insertString(dateStr)
    }

    private func executeTimeCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        let timeStr = evaluateTokenOrCommand(tokens, index: &index)
        editor.buffer.insertString(timeStr)
    }

    private func executeLineCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        var length = 40
        var styleChar: Character = "─"

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !LogoEngine.keywords.contains(upperFirst) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                if let len = Int(valStr) {
                    length = max(1, min(len, 200))

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !LogoEngine.keywords.contains(nextUpper) && tokens[index + 1] != "]" {
                            index += 1
                            let styleStr = unquote(tokens[index]).lowercased()
                            styleChar = getLineStyleChar(styleStr)
                        }
                    }
                } else {
                    let styleStr = unquote(valStr).lowercased()
                    styleChar = getLineStyleChar(styleStr)
                }
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        let startLine = editor.buffer.lineIndex
        let startCol = editor.buffer.columnIndex

        while editor.buffer.lines.count <= startLine {
            editor.buffer.lines.append("")
        }

        var currentChars = Array(editor.buffer.lines[startLine])
        while currentChars.count < startCol {
            currentChars.append(" ")
        }

        for i in 0..<length {
            let c = startCol + i
            let newMask: Int
            if length == 1 {
                newMask = 10 // RIGHT (2) + LEFT (8)
            } else if i == 0 {
                newMask = 2 // RIGHT (2)
            } else if i == length - 1 {
                newMask = 8 // LEFT (8)
            } else {
                newMask = 10 // RIGHT (2) + LEFT (8)
            }

            if c < currentChars.count {
                let existing = currentChars[c]
                currentChars[c] = fuseCharacter(existing: existing, newMask: newMask, defaultNewChar: styleChar, line: startLine, col: c, on: editor)
            } else {
                currentChars.append(styleChar)
            }
        }

        editor.buffer.lines[startLine] = String(currentChars)
        editor.buffer.columnIndex = startCol + length
        editor.buffer.insertNewline()
    }

    private func getLineStyleChar(_ str: String) -> Character {
        switch str {
        case "double": return "═"
        case "dashed", "ascii", "-": return "-"
        case "hash", "#": return "#"
        case "star", "*": return "*"
        case "dot", ".": return "."
        default: return "─"
        }
    }

    private func executeVlineCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        var height = 5
        var styleChar: Character = "│"

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !LogoEngine.keywords.contains(upperFirst) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                if let h = Int(valStr) {
                    height = max(1, min(h, 100))

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !LogoEngine.keywords.contains(nextUpper) && tokens[index + 1] != "]" {
                            index += 1
                            let styleStr = unquote(tokens[index]).lowercased()
                            styleChar = getVlineStyleChar(styleStr)
                        }
                    }
                } else {
                    let styleStr = unquote(valStr).lowercased()
                    styleChar = getVlineStyleChar(styleStr)
                }
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        let startCol = editor.buffer.columnIndex
        let startLine = editor.buffer.lineIndex

        for i in 0..<height {
            let targetLine = startLine + i
            while editor.buffer.lines.count <= targetLine {
                editor.buffer.lines.append("")
            }

            var lineChars = Array(editor.buffer.lines[targetLine])
            while lineChars.count < startCol {
                lineChars.append(" ")
            }

            let newMask: Int
            if height == 1 {
                newMask = 5 // TOP (1) + BOTTOM (4)
            } else if i == 0 {
                newMask = 4 // BOTTOM (4)
            } else if i == height - 1 {
                newMask = 1 // TOP (1)
            } else {
                newMask = 5 // TOP (1) + BOTTOM (4)
            }

            if startCol < lineChars.count {
                let existing = lineChars[startCol]
                lineChars[startCol] = fuseCharacter(existing: existing, newMask: newMask, defaultNewChar: styleChar, line: targetLine, col: startCol, on: editor)
            } else {
                lineChars.append(styleChar)
            }

            editor.buffer.lines[targetLine] = String(lineChars)
        }

        editor.buffer.lineIndex = startLine + height
        editor.buffer.columnIndex = startCol
        editor.buffer.isModified = true
    }

    private func getVlineStyleChar(_ str: String) -> Character {
        switch str {
        case "double": return "║"
        case "dashed", "ascii", "|": return "|"
        case "hash", "#": return "#"
        case "star", "*": return "*"
        case "dot", ".": return "."
        default: return "│"
        }
    }

    private func executeNewlineCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        var count = 1

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !LogoEngine.keywords.contains(upperFirst) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                count = max(1, min(Int(valStr) ?? 1, 50))
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        for _ in 0..<count {
            editor.buffer.insertNewline()
        }
    }

    private func executeBoxCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        guard index < tokens.count else {
            drawBoxAroundSelection(style: .single, on: editor)
            return
        }

        let firstToken = tokens[index]
        let upperFirst = firstToken.uppercased()

        // Mode 1: BOX SELECTION [style] or BOX with active selection
        if upperFirst == "SELECTION" || (editor.selectionMark != nil && (Int(firstToken) == nil && !firstToken.hasPrefix("\""))) {
            var styleName = ""
            if upperFirst == "SELECTION" {
                if index + 1 < tokens.count {
                    let nextUpper = tokens[index + 1].uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) {
                        index += 1
                        styleName = unquote(tokens[index])
                    }
                }
            } else {
                styleName = unquote(firstToken)
            }
            drawBoxAroundSelection(style: BoxStyle.from(styleName), on: editor)
            return
        }

        // Mode 2: BOX width [height] ["text"] [align] [style]
        if let w = Int(resolveTokenValue(firstToken)) {
            let width = max(3, min(w, 200))
            var height: Int? = nil
            var textContent: String? = nil
            var align: TextAlignment = .left
            var styleName = ""

            // Check if next token is height
            if index + 1 < tokens.count {
                let secondUpper = tokens[index + 1].uppercased()
                if let h = Int(resolveTokenValue(secondUpper)) {
                    index += 1
                    height = max(2, min(h, 100))
                }
            }

            // Check if next token is text or style/align
            while index + 1 < tokens.count {
                let nextUpper = tokens[index + 1].uppercased()
                if LogoEngine.keywords.contains(nextUpper) { break }
                index += 1
                let rawVal = tokens[index]
                let val = unquote(rawVal)
                let valUpper = val.lowercased()

                if valUpper == "left" || valUpper == "center" || valUpper == "centre" || valUpper == "right" {
                    align = TextAlignment.from(val)
                } else if valUpper == "single" || valUpper == "double" || valUpper == "ascii" {
                    styleName = val
                } else if textContent == nil {
                    textContent = val
                }
            }

            if let text = textContent {
                drawBoxAroundText(text, targetWidth: width, targetHeight: height, align: align, style: BoxStyle.from(styleName), on: editor)
            } else {
                drawBoxFrame(width: width, height: height ?? 3, style: BoxStyle.from(styleName), on: editor)
            }
            return
        }

        // Mode 3: BOX "text" [align/style] [style/align]
        let textContent = evaluateExpression(tokens, index: &index)
        var align: TextAlignment = .left
        var styleName = ""

        while index + 1 < tokens.count {
            let nextUpper = tokens[index + 1].uppercased()
            if LogoEngine.keywords.contains(nextUpper) { break }
            index += 1
            let val = unquote(tokens[index])
            let valUpper = val.lowercased()

            if valUpper == "left" || valUpper == "center" || valUpper == "centre" || valUpper == "right" {
                align = TextAlignment.from(val)
            } else {
                styleName = val
            }
        }

        drawBoxAroundText(textContent, targetWidth: nil, targetHeight: nil, align: align, style: BoxStyle.from(styleName), on: editor)
    }

    private func overlayBoxLines(_ boxLines: [String], on editor: Editor) {
        let startLine = editor.buffer.lineIndex
        let startCol = editor.buffer.columnIndex

        for (k, boxLine) in boxLines.enumerated() {
            let targetLine = startLine + k
            while editor.buffer.lines.count <= targetLine {
                editor.buffer.lines.append("")
            }

            let origLineChars = Array(editor.buffer.lines[targetLine])

            // 1. Prefix: characters before startCol (or spaces if orig line is shorter)
            var prefixChars: [Character] = []
            if origLineChars.count >= startCol {
                prefixChars = Array(origLineChars[0..<startCol])
            } else {
                prefixChars = origLineChars
                while prefixChars.count < startCol {
                    prefixChars.append(" ")
                }
            }

            // 2. Box segment characters with Smart Junction Fusion
            var segmentChars = Array(boxLine)
            for i in 0..<segmentChars.count {
                let c = startCol + i
                if c < origLineChars.count {
                    let existing = origLineChars[c]
                    let stepMask: Int
                    if k == 0 {
                        stepMask = (i == 0) ? 6 : (i == segmentChars.count - 1 ? 12 : 10)
                    } else if k == boxLines.count - 1 {
                        stepMask = (i == 0) ? 3 : (i == segmentChars.count - 1 ? 9 : 10)
                    } else {
                        stepMask = (i == 0 || i == segmentChars.count - 1) ? 5 : 0
                    }
                    if stepMask != 0 {
                        segmentChars[i] = fuseCharacter(existing: existing, newMask: stepMask, defaultNewChar: segmentChars[i], line: targetLine, col: c, on: editor)
                    }
                }
            }

            // 3. Suffix: characters at or after startCol (pushed to the right of box)
            var suffixChars: [Character] = []
            if origLineChars.count > startCol {
                suffixChars = Array(origLineChars[startCol..<origLineChars.count])
            }

            let newLineStr = String(prefixChars) + String(segmentChars) + String(suffixChars)
            editor.buffer.lines[targetLine] = newLineStr
        }

        editor.buffer.lineIndex = startLine + boxLines.count
        editor.buffer.columnIndex = startCol
        editor.buffer.isModified = true
    }

    public enum TextAlignment {
        case left, center, right

        public static func from(_ str: String) -> TextAlignment {
            switch str.lowercased() {
            case "center", "centre", "middle": return .center
            case "right": return .right
            default: return .left
            }
        }
    }

    private func drawBoxAroundText(
        _ text: String,
        targetWidth: Int? = nil,
        targetHeight: Int? = nil,
        align: TextAlignment = .left,
        style: BoxStyle = .single,
        on editor: Editor
    ) {
        let unescapedText = text.replacingOccurrences(of: "\\n", with: "\n")
        let rawLines = unescapedText.components(separatedBy: "\n")

        // Determine effective inner content width
        var innerWidth: Int
        if let tw = targetWidth {
            innerWidth = max(1, tw - 4) // Reserve 2 border chars + 2 padding spaces
        } else {
            let maxRawWidth = rawLines.map { $0.displayWidth }.max() ?? 1
            innerWidth = max(1, maxRawWidth)
        }

        // Word-wrap each raw line to fit innerWidth
        var wrappedLines: [String] = []
        for line in rawLines {
            wrappedLines.append(contentsOf: wrapTextLine(line, maxWidth: innerWidth))
        }

        let contentWidth = max(innerWidth, wrappedLines.map { $0.displayWidth }.max() ?? 1)

        // Determine effective height (auto-expand if wrappedLines exceed targetHeight)
        let minMiddleCount = (targetHeight != nil) ? max(1, targetHeight! - 2) : 1
        let middleCount = max(minMiddleCount, wrappedLines.count)

        let topBorder = String(style.topLeft) + String(repeating: style.topChar, count: contentWidth + 2) + String(style.topRight)
        let bottomBorder = String(style.bottomLeft) + String(repeating: style.bottomChar, count: contentWidth + 2) + String(style.bottomRight)

        var boxLines: [String] = [topBorder]

        for k in 0..<middleCount {
            let lineText = (k < wrappedLines.count) ? wrappedLines[k] : ""
            let textW = lineText.displayWidth
            let totalPadding = max(0, contentWidth - textW)

            let leftPadCount: Int
            let rightPadCount: Int
            switch align {
            case .center:
                leftPadCount = totalPadding / 2
                rightPadCount = totalPadding - leftPadCount
            case .right:
                leftPadCount = totalPadding
                rightPadCount = 0
            case .left:
                leftPadCount = 0
                rightPadCount = totalPadding
            }

            let paddedText = String(repeating: " ", count: leftPadCount) + lineText + String(repeating: " ", count: rightPadCount)
            boxLines.append("\(style.sideChar) \(paddedText) \(style.sideChar)")
        }

        boxLines.append(bottomBorder)

        overlayBoxLines(boxLines, on: editor)
    }

    private func wrapTextLine(_ line: String, maxWidth: Int) -> [String] {
        guard maxWidth > 0 else { return [line] }
        if line.displayWidth <= maxWidth { return [line] }

        var result: [String] = []
        let words = line.components(separatedBy: " ")
        var currentChunk = ""

        for word in words {
            let candidate = currentChunk.isEmpty ? word : "\(currentChunk) \(word)"
            if candidate.displayWidth <= maxWidth {
                currentChunk = candidate
            } else {
                if !currentChunk.isEmpty {
                    result.append(currentChunk)
                    currentChunk = ""
                }
                if word.displayWidth > maxWidth {
                    var subChunk = ""
                    var subW = 0
                    for ch in word {
                        let dw = ch.displayWidth
                        if subW + dw > maxWidth && !subChunk.isEmpty {
                            result.append(subChunk)
                            subChunk = ""
                            subW = 0
                        }
                        subChunk.append(ch)
                        subW += dw
                    }
                    if !subChunk.isEmpty {
                        currentChunk = subChunk
                    }
                } else {
                    currentChunk = word
                }
            }
        }
        if !currentChunk.isEmpty {
            result.append(currentChunk)
        }

        return result.isEmpty ? [""] : result
    }

    private func drawBoxFrame(width: Int, height: Int, style: BoxStyle, on editor: Editor) {
        let innerWidth = max(1, width - 2)
        let topBorder = String(style.topLeft) + String(repeating: style.topChar, count: innerWidth) + String(style.topRight)
        let bottomBorder = String(style.bottomLeft) + String(repeating: style.bottomChar, count: innerWidth) + String(style.bottomRight)
        let emptyLine = String(style.sideChar) + String(repeating: " ", count: innerWidth) + String(style.sideChar)

        var boxLines: [String] = [topBorder]
        let middleCount = max(0, height - 2)
        for _ in 0..<middleCount {
            boxLines.append(emptyLine)
        }
        boxLines.append(bottomBorder)

        overlayBoxLines(boxLines, on: editor)
    }

    private func drawBoxAroundSelection(style: BoxStyle, on editor: Editor) {
        guard let mark = editor.selectionMark else {
            drawBoxFrame(width: 10, height: 4, style: style, on: editor)
            return
        }

        let currLine = editor.buffer.lineIndex

        let startLine = min(mark.line, currLine)
        let endLine = max(mark.line, currLine)

        let selectionLines = editor.buffer.lines[startLine...endLine].map { String($0) }
        let maxDisplayWidth = selectionLines.map { $0.displayWidth }.max() ?? 0
        let innerWidth = max(1, maxDisplayWidth)

        let topBorder = String(style.topLeft) + String(repeating: style.topChar, count: innerWidth + 2) + String(style.topRight)
        let bottomBorder = String(style.bottomLeft) + String(repeating: style.bottomChar, count: innerWidth + 2) + String(style.bottomRight)

        var boxLines: [String] = [topBorder]
        for line in selectionLines {
            let padding = String(repeating: " ", count: max(0, innerWidth - line.displayWidth))
            boxLines.append("\(style.sideChar) \(line)\(padding) \(style.sideChar)")
        }
        boxLines.append(bottomBorder)

        // Set lineIndex & columnIndex to start position for overlay
        editor.buffer.lineIndex = startLine
        editor.buffer.columnIndex = min(mark.column, editor.buffer.columnIndex)
        overlayBoxLines(boxLines, on: editor)
        editor.selectionMark = nil
    }

    private func applySetting(_ setting: String, arg: String, editor: Editor) {
        switch setting {
        case "ruler":
            if arg == "off" || arg == "false" {
                editor.displayConfig.showRuler = false
            } else if arg == "on" || arg == "true" {
                editor.displayConfig.showRuler = true
            } else {
                editor.displayConfig.showRuler.toggle()
            }
        case "wrap":
            if arg == "off" || arg == "false" || arg == "none" {
                editor.layoutEngine.wrapColumn = nil
            } else if let w = Int(arg), w > 0 {
                editor.layoutEngine.wrapColumn = w
            } else {
                editor.layoutEngine.wrapColumn = nil
            }
        case "syntax":
            if arg == "off" || arg == "false" {
                editor.displayConfig.enableSyntaxHighlight = false
            } else if arg == "on" || arg == "true" {
                editor.displayConfig.enableSyntaxHighlight = true
            } else {
                editor.displayConfig.enableSyntaxHighlight.toggle()
            }
        case "autoreload":
            if arg == "off" || arg == "false" {
                editor.displayConfig.autoReload = false
            } else if arg == "on" || arg == "true" {
                editor.displayConfig.autoReload = true
            } else {
                editor.displayConfig.autoReload.toggle()
            }
        case "lang":
            if arg == "zh_tw" || arg == "zh" {
                L10n.currentLanguage = .zh_TW
            } else if arg == "en" {
                L10n.currentLanguage = .en
            }
        default:
            break
        }
    }

    /// Evaluates token value or command (DATE, TIME) or binary arithmetic expression (+, -, *, /, %) with parentheses.
    private func evaluateExpression(_ tokens: [String], index: inout Int) -> String {
        guard index < tokens.count else { return "" }

        if tokens[index] == "(" {
            index += 1
        }
        guard index < tokens.count else { return "" }

        var leftVal = evaluateTokenOrCommand(tokens, index: &index)

        // Peek next operator if present
        while index + 1 < tokens.count {
            let op = tokens[index + 1]
            if op == ")" {
                index += 1
                if index + 1 >= tokens.count { break }
                continue
            }

            if op == "+" || op == "-" || op == "*" || op == "/" || op == "%" {
                index += 2
                guard index < tokens.count else { break }
                let rightVal = evaluateTokenOrCommand(tokens, index: &index)

                if let num1 = Double(leftVal), let num2 = Double(rightVal) {
                    let isIntegerMath = !leftVal.contains(".") && !rightVal.contains(".") && Int(leftVal) != nil && Int(rightVal) != nil
                    if isIntegerMath, let n1 = Int(leftVal), let n2 = Int(rightVal) {
                        let resNum: Int
                        switch op {
                        case "+": resNum = n1 + n2
                        case "-": resNum = n1 - n2
                        case "*": resNum = n1 * n2
                        case "/": resNum = (n2 != 0) ? n1 / n2 : 0
                        case "%": resNum = (n2 != 0) ? n1 % n2 : 0
                        default: resNum = 0
                        }
                        leftVal = "\(resNum)"
                    } else {
                        let resDouble: Double
                        switch op {
                        case "+": resDouble = num1 + num2
                        case "-": resDouble = num1 - num2
                        case "*": resDouble = num1 * num2
                        case "/": resDouble = (num2 != 0) ? num1 / num2 : 0.0
                        case "%": resDouble = (num2 != 0) ? num1.truncatingRemainder(dividingBy: num2) : 0.0
                        default: resDouble = 0.0
                        }
                        if resDouble.truncatingRemainder(dividingBy: 1) == 0 {
                            leftVal = "\(Int(resDouble))"
                        } else {
                            leftVal = "\(resDouble)"
                        }
                    }
                } else if op == "+" {
                    // String concatenation
                    leftVal = leftVal + rightVal
                }
            } else {
                break
            }
        }

        if index + 1 < tokens.count && tokens[index + 1] == ")" {
            index += 1
        }

        return leftVal
    }

    private func evaluateTokenOrCommand(_ tokens: [String], index: inout Int) -> String {
        guard index < tokens.count else { return "" }
        let token = tokens[index]
        let upper = token.uppercased()

        if upper == "DATE" {
            var format = "yyyy-MM-dd"
            if index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                let nextUpper = nextToken.uppercased()
                if !LogoEngine.keywords.contains(nextUpper) && nextToken != "]" && nextToken != ")" {
                    index += 1
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                }
            }
            return formatDate(format: format)
        }

        if upper == "TIME" {
            var format = "HH:mm:ss"
            if index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                let nextUpper = nextToken.uppercased()
                if !LogoEngine.keywords.contains(nextUpper) && nextToken != "]" && nextToken != ")" {
                    index += 1
                    let customFmt = unquote(nextToken)
                    if !customFmt.isEmpty {
                        format = customFmt
                    }
                }
            }
            return formatTime(format: format)
        }

        return resolveTokenValue(token)
    }

    private func resolveTokenValue(_ token: String) -> String {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        if clean.hasPrefix(":") {
            let varName = String(clean.dropFirst()).lowercased()
            return variables[varName] ?? ""
        }
        return unquote(clean)
    }

    private func unquote(_ str: String) -> String {
        var result = str
        if result.hasPrefix("\"") {
            result.removeFirst()
        }
        if result.hasSuffix("\"") {
            result.removeLast()
        }
        return result
    }
}
