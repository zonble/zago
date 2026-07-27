import Foundation

/// LOGO-style Macro Language Engine for se text editor.
/// Supports text editing commands (TYPE, DEL, BS, MOVE, MARK, CUT, PASTE, JUSTIFY, FIND),
/// variables (MAKE "var" val / :var), editor settings (SET ruler/wrap/syntax/autoreload/lang),
/// arithmetic (+, -, *, /, %), loops (REPEAT expr [ ... ]), and procedure definitions (TO proc ... END).
public final class LogoEngine {
    public var customProcedures: [String: [String]] = [:]
    public var variables: [String: String] = [:]
    public var hasSetStatusMessage: Bool = false

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
                        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC"]
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
                        let keywords: Set<String> = ["MAKE", "VAR", "SET", "TYPE", "PRINT", "MSG", "MESSAGE", "SHOW", "DEL", "BS", "MOVE", "MARK", "CUT", "PASTE", "JUSTIFY", "FIND", "REPEAT", "TO", "EXEC", "GOTO"]
                        if !keywords.contains(nextUpper) {
                            index += 1
                            let colStr = evaluateExpression(tokens, index: &index)
                            let colNum = max(1, min(Int(colStr) ?? 1, editor.buffer.lines[lineNum].count + 1)) - 1
                            editor.buffer.columnIndex = colNum
                        }
                    }
                }

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
