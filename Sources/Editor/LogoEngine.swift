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
/// Supports text editing commands (TYPE, DEL, BS, MOVE, MARK, CUT, PASTE, JUSTIFY, FIND, GOTO, BOX, LINE, VLINE, NEWLINE, DATE, TIME),
/// variables (MAKE "var" val / :var), editor settings (SET ruler/wrap/syntax/autoreload/lang),
/// arithmetic (+, -, *, /, %), loops (REPEAT expr [ ... ]), procedure definitions (TO proc ... END),
/// and Smart Line Junction Fusion (auto-fusing crossing lines/boxes into ┼, ┬, ┴, ├, ┤).
public final class LogoEngine {
    public var customProcedures: [String: [String]] = [:]
    public var variables: [String: String] = [:]
    public var hasSetStatusMessage: Bool = false

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

    /// Tokenizes macro script handling string literals in quotes, math operators (+, -, *, /, %), and brackets.
    public func tokenize(_ script: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuote = false

        let delims: Set<Character> = ["[", "]", "(", ")", "+", "-", "*", "/", "%"]

        for ch in script {
            if ch == "\"" {
                inQuote.toggle()
                current.append(ch)
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
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }

    private func executeTokens(_ tokens: [String], index: inout Int, on editor: Editor) {
        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR", "NEWLINE", "NL", "ENTER", "DATE", "TIME"]

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
                        if !keywords.contains(nextUpper) {
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
                    case "LEFT": _ = editor.commandRegistry.dispatch(id: "move.left", editor: editor)
                    case "RIGHT": _ = editor.commandRegistry.dispatch(id: "move.right", editor: editor)
                    case "HOME": _ = editor.commandRegistry.dispatch(id: "move.home", editor: editor)
                    case "END": _ = editor.commandRegistry.dispatch(id: "move.end", editor: editor)
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
                        if !keywords.contains(nextUpper) {
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
                index += 1
                executeDateCommand(tokens, index: &index, on: editor)

            case "TIME":
                index += 1
                executeTimeCommand(tokens, index: &index, on: editor)

            case "MARK":
                _ = editor.commandRegistry.dispatch(id: "edit.mark", editor: editor)

            case "CUT":
                _ = editor.commandRegistry.dispatch(id: "edit.cut", editor: editor)

            case "PASTE", "UNCUT":
                _ = editor.commandRegistry.dispatch(id: "edit.uncut", editor: editor)

            case "JUSTIFY":
                _ = editor.commandRegistry.dispatch(id: "edit.justify", editor: editor)

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

    private func fuseCharacter(existing: Character, newMask: Int, defaultNewChar: Character) -> Character {
        let isDouble = LogoEngine.doubleMasks[existing] != nil || LogoEngine.doubleMasks[defaultNewChar] != nil
        let mask1 = LogoEngine.singleMasks[existing] ?? LogoEngine.doubleMasks[existing] ?? 0

        guard mask1 != 0 else { return defaultNewChar }

        let fusedMask = mask1 | newMask
        if isDouble {
            return LogoEngine.doubleCharForMask[fusedMask] ?? defaultNewChar
        } else {
            return LogoEngine.singleCharForMask[fusedMask] ?? defaultNewChar
        }
    }

    private func executeDateCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        var format = "yyyy-MM-dd"
        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR", "NEWLINE", "NL", "ENTER", "DATE", "TIME"]

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !keywords.contains(upperFirst) && firstToken != "]" {
                let customFmt = unquote(evaluateExpression(tokens, index: &index))
                if !customFmt.isEmpty {
                    format = customFmt
                }
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        let formatter = DateFormatter()
        formatter.dateFormat = format
        let dateStr = formatter.string(from: Date())
        editor.buffer.insertString(dateStr)
    }

    private func executeTimeCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        var format = "HH:mm:ss"
        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR", "NEWLINE", "NL", "ENTER", "DATE", "TIME"]

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !keywords.contains(upperFirst) && firstToken != "]" {
                let customFmt = unquote(evaluateExpression(tokens, index: &index))
                if !customFmt.isEmpty {
                    format = customFmt
                }
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        let formatter = DateFormatter()
        formatter.dateFormat = format
        let timeStr = formatter.string(from: Date())
        editor.buffer.insertString(timeStr)
    }

    private func executeLineCommand(_ tokens: [String], index: inout Int, on editor: Editor) {
        var length = 40
        var styleChar: Character = "─"
        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR", "NEWLINE", "NL", "ENTER", "DATE", "TIME"]

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !keywords.contains(upperFirst) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                if let len = Int(valStr) {
                    length = max(1, min(len, 200))

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !keywords.contains(nextUpper) && tokens[index + 1] != "]" {
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
                currentChars[c] = fuseCharacter(existing: existing, newMask: newMask, defaultNewChar: styleChar)
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
        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR", "NEWLINE", "NL", "ENTER", "DATE", "TIME"]

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !keywords.contains(upperFirst) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                if let h = Int(valStr) {
                    height = max(1, min(h, 100))

                    if index + 1 < tokens.count {
                        let nextUpper = tokens[index + 1].uppercased()
                        if !keywords.contains(nextUpper) && tokens[index + 1] != "]" {
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
                lineChars[startCol] = fuseCharacter(existing: existing, newMask: newMask, defaultNewChar: styleChar)
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
        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR", "NEWLINE", "NL", "ENTER", "DATE", "TIME"]

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !keywords.contains(upperFirst) && firstToken != "]" {
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
        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO", "BOX", "LINE", "HR", "VLINE", "VHR", "NEWLINE", "NL", "ENTER", "DATE", "TIME"]

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
                    if !keywords.contains(nextUpper) {
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

        // Mode 2: BOX width height [style]
        if let w = Int(resolveTokenValue(firstToken)) {
            let width = max(3, min(w, 200))
            var height = 3
            var styleName = ""

            if index + 1 < tokens.count {
                index += 1
                let hStr = evaluateExpression(tokens, index: &index)
                height = max(2, min(Int(hStr) ?? 3, 100))
            }

            if index + 1 < tokens.count {
                let nextUpper = tokens[index + 1].uppercased()
                if !keywords.contains(nextUpper) {
                    index += 1
                    styleName = unquote(tokens[index])
                }
            }

            drawBoxFrame(width: width, height: height, style: BoxStyle.from(styleName), on: editor)
            return
        }

        // Mode 3: BOX "text" [style]
        let textContent = evaluateExpression(tokens, index: &index)
        var styleName = ""
        if index + 1 < tokens.count {
            let nextUpper = tokens[index + 1].uppercased()
            if !keywords.contains(nextUpper) {
                index += 1
                styleName = unquote(tokens[index])
            }
        }

        drawBoxAroundText(textContent, style: BoxStyle.from(styleName), on: editor)
    }

    private func drawBoxAroundText(_ text: String, style: BoxStyle, on editor: Editor) {
        let textLines = text.components(separatedBy: .newlines)
        let maxDisplayWidth = textLines.map { $0.displayWidth }.max() ?? 0
        let innerWidth = max(1, maxDisplayWidth)

        let topBorder = String(style.topLeft) + String(repeating: style.topChar, count: innerWidth + 2) + String(style.topRight)
        let bottomBorder = String(style.bottomLeft) + String(repeating: style.bottomChar, count: innerWidth + 2) + String(style.bottomRight)

        var boxString = topBorder + "\n"
        for line in textLines {
            let padding = String(repeating: " ", count: max(0, innerWidth - line.displayWidth))
            boxString += "\(style.sideChar) \(line)\(padding) \(style.sideChar)\n"
        }
        boxString += bottomBorder

        editor.buffer.insertString(boxString)
    }

    private func drawBoxFrame(width: Int, height: Int, style: BoxStyle, on editor: Editor) {
        let innerWidth = max(1, width - 2)
        let topBorder = String(style.topLeft) + String(repeating: style.topChar, count: innerWidth) + String(style.topRight)
        let bottomBorder = String(style.bottomLeft) + String(repeating: style.bottomChar, count: innerWidth) + String(style.bottomRight)
        let emptyLine = String(style.sideChar) + String(repeating: " ", count: innerWidth) + String(style.sideChar)

        var boxString = topBorder + "\n"
        let middleCount = max(0, height - 2)
        for _ in 0..<middleCount {
            boxString += emptyLine + "\n"
        }
        boxString += bottomBorder

        editor.buffer.insertString(boxString)
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

        // Replace selected lines in buffer
        editor.buffer.lines.replaceSubrange(startLine...endLine, with: boxLines)
        editor.selectionMark = nil
        editor.buffer.lineIndex = startLine + boxLines.count
        editor.buffer.columnIndex = 0
        editor.buffer.isModified = true
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

    /// Evaluates value or binary arithmetic expression (+, -, *, /, %) with parentheses and operator chaining.
    private func evaluateExpression(_ tokens: [String], index: inout Int) -> String {
        guard index < tokens.count else { return "" }

        if tokens[index] == "(" {
            index += 1
        }
        guard index < tokens.count else { return "" }

        let leftToken = tokens[index]
        var leftVal = resolveTokenValue(leftToken)

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
                let rightToken = tokens[index]
                let rightVal = resolveTokenValue(rightToken)

                if let num1 = Int(leftVal), let num2 = Int(rightVal) {
                    let resNum: Int
                    switch op {
                    case "+": resNum = num1 + num2
                    case "-": resNum = num1 - num2
                    case "*": resNum = num1 * num2
                    case "/": resNum = (num2 != 0) ? num1 / num2 : 0
                    case "%": resNum = (num2 != 0) ? num1 % num2 : 0
                    default: resNum = 0
                    }
                    leftVal = "\(resNum)"
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
