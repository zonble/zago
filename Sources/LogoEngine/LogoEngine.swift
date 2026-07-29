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
    static let doubleRound = BoxStyle(topLeft: "╭", topChar: "═", topRight: "╮", sideChar: "║", bottomLeft: "╰", bottomChar: "═", bottomRight: "╯")
    static let ascii  = BoxStyle(topLeft: "+", topChar: "-", topRight: "+", sideChar: "|", bottomLeft: "+", bottomChar: "-", bottomRight: "+")

    static func from(_ str: String) -> BoxStyle {
        parse(str) ?? .single
    }

    static func isStyleToken(_ token: String) -> Bool {
        parse(token) != nil
    }

    private static func parse(_ token: String) -> BoxStyle? {
        switch token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased() {
        case "single":
            .single
        case "double":
            .double
        case "round", "rounded":
            .round
        case "doubleround", "double-round", "double_round", "rounddouble", "round-double", "round_double":
            .doubleRound
        case "ascii":
            .ascii
        default:
            nil
        }
    }
}

enum BoxAlignment: String, Sendable {
    case left
    case center
    case right

    init?(_ token: String) {
        switch token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased() {
        case "left":
            self = .left
        case "center", "centre":
            self = .center
        case "right":
            self = .right
        default:
            return nil
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

    internal static let statementCommands: Set<LogoPrimitive> = [
        .make, .name, .set, .type, .show, .delete, .backspace, .deleteLine,
        .top, .bottom, .lineStart, .lineEnd, .appendText, .prependText, .changeText,
        .joinLine, .splitLine, .indentLines, .outdentLines,
        .move, .mark, .cut, .uncut, .justify, .goto, .box, .drawBox, .line, .hr, .vline, .vhr, .table,
        .newline, .penDown, .penUp, .forward, .back, .turnRight, .turnLeft,
        .nextBuffer, .prevBuffer, .openBuffer, .closeBuffer, .saveBuffer, .fileSaveAndQuit,
        .setline, .gotoline, .gotocol, .clearBuffer, .ifCondition, .ifElseCondition, .output, .run,
        .repeatLoop, .foreverLoop, .forLoop, .dotimesLoop, .whileLoop,
        .doWhileLoop, .untilLoop, .doUntilLoop, .caseSwitch, .condSwitch,
        .testCondition, .ifTrue, .ifFalse, .stop, .catchTag, .throwTag, .wait,
        .bye, .ignore, .foreach, .to, .exec, .search, .sort, .fill, .end
    ]

    internal static let expressionPrimitives: Set<LogoPrimitive> = [
        .apply, .invoke, .map, .mapSe, .filter, .reduce, .crossmap, .runResult,
        .date, .time, .thing, .word, .list, .sentence, .fput, .lput, .array,
        .listToArray, .arrayToList, .combine, .reverse, .gensym, .first,
        .last, .firsts, .butFirst, .butLast, .butFirsts, .item,
        .pick, .remove, .remdup, .quoted, .split, .setItem,
        .push, .pop, .dequeue, .isWord, .isList, .isArray,
        .isNumber, .isEmpty, .isEqual, .isNotEqual, .isBefore,
        .isMember, .isSubstring, .count, .ascii, .char, .member, .uppercase, .lowercase,
        .standout, .parse, .runparse, .less, .greater, .lessOrEqual, .greaterOrEqual,
        .sum, .min, .max, .difference, .product, .quotient, .power, .remainder, .modulo, .minus, .abs, .int, .round,
        .sqrt, .exp, .log10, .ln, .arctan, .sin, .cos, .tan, .radArctan, .radSin, .radCos, .radTan,
        .iseq, .rseq, .random, .rerandom, .form, .bitAnd, .bitOr, .bitXor, .bitNot, .ashift, .lshift,
        .trueVal, .falseVal, .andLogic, .orLogic, .xorLogic, .notLogic,
        .buffers, .buffer, .getline, .row, .col, .lineCount, .bufferText, .selection, .isModified, .fileName, .find, .sort
    ]

    internal static let keywords: Set<LogoPrimitive> = statementCommands.union(expressionPrimitives)

    internal static func isKeyword(_ token: String) -> Bool {
        guard let prim = LogoPrimitive.from(token) else { return false }
        return keywords.contains(prim)
    }

    internal static func isStatementCommand(_ token: String) -> Bool {
        guard let prim = LogoPrimitive.from(token) else { return false }
        return statementCommands.contains(prim)
    }

    internal func optionalCommandArgument(_ tokens: [String], index: inout Int) -> String? {
        guard index + 1 < tokens.count else { return nil }
        let nextToken = tokens[index + 1]
        guard !LogoEngine.isStatementCommand(nextToken), nextToken != "]", nextToken != ")" else {
            return nil
        }
        index += 1
        return unquote(evaluateExpression(tokens, index: &index))
    }

    public var lastResult: String? = nil
    public var repCount: Int = 0
    public var testResult: Bool? = nil
    public var lastError: String = "[]"
    public var byeFlag: Bool = false
    public var currentThrowTag: String? = nil
    public var currentThrowValue: String? = nil
    internal var procedureCallDepth: Int = 0
    internal let maxProcedureCallDepth: Int = 32

    public weak var delegate: LogoEngineDelegate?

    public init(delegate: LogoEngineDelegate? = nil) {
        self.delegate = delegate
    }

    /// Executes LOGO macro script on the delegate context, creating a single atomic Undo snapshot.
    public func execute(_ script: String) {
        guard let delegate = self.delegate else { return }
        lastResult = nil
        lastError = "[]"
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
        while index < tokens.count && frameReturn == nil && lastError == "[]" {
            let token = tokens[index]

            if token == "]" {
                return
            }

            guard let prim = LogoPrimitive.from(token) else {
                let exprResult = evaluateExpression(tokens, index: &index)
                if !exprResult.isEmpty {
                    lastResult = exprResult
                }
                index += 1
                continue
            }

            switch prim {
            case .output:
                index += 1
                if index < tokens.count {
                    let val = evaluateExpression(tokens, index: &index)
                    frameReturn = val
                    return
                }

            case .make:
                index += 1
                if index < tokens.count {
                    let varName = normalizeVariableName(tokens[index])
                    index += 1
                    let val = evaluateExpression(tokens, index: &index)
                    variables[varName] = val
                }

            case .name:
                index += 1
                if index < tokens.count {
                    let val = evaluateExpression(tokens, index: &index)
                    index += 1
                    if index < tokens.count {
                        let varName = normalizeVariableName(evaluateExpression(tokens, index: &index))
                        variables[varName] = val
                    }
                }

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

            case .set:
                index += 1
                if index < tokens.count {
                    let setting = unquote(tokens[index]).lowercased()
                    var arg = ""
                    if index + 1 < tokens.count {
                        if !LogoEngine.isKeyword(tokens[index + 1]) {
                            index += 1
                            arg = evaluateExpression(tokens, index: &index).lowercased()
                        }
                    }
                    delegate.logoEngine(self, performAction: .applySetting(setting: setting, arg: arg))
                }

            case .fill:
                index += 1
                executeFillCommand(tokens, index: &index)

            case .type:
                index += 1
                while index < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                        index -= 1
                        break
                    }
                    let text = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, performAction: .insertText(text))
                    if index + 1 < tokens.count {
                        if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                            break
                        }
                    }
                    index += 1
                }

            case .show:
                index += 1
                var parts: [String] = []
                while index < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                        index -= 1
                        break
                    }
                    let text = evaluateExpression(tokens, index: &index)
                    parts.append(text)
                    if index + 1 < tokens.count {
                        if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                            break
                        }
                    }
                    index += 1
                }
                let msgText = parts.joined(separator: " ")
                delegate.logoEngine(self, performAction: .setStatusMessage(msgText))
                hasSetStatusMessage = true

            case .delete:
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    delegate.logoEngine(self, performAction: .deleteChar)
                }

            case .backspace:
                index += 1
                let valStr = evaluateExpression(tokens, index: &index)
                let count = Int(valStr) ?? 1
                for _ in 0..<count {
                    delegate.logoEngine(self, performAction: .backspaceChar)
                }

            case .deleteLine:
                index += 1
                var count = 1
                if index < tokens.count {
                    let nextToken = tokens[index]
                    if !LogoEngine.isKeyword(nextToken) && nextToken != "]" {
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

            case .top:
                delegate.logoEngine(self, performAction: .updateLineIndex(0))
                delegate.logoEngine(self, performAction: .updateColumnIndex(0))

            case .bottom:
                let totalLines = (delegate.logoEngine(self, queryState: .lineCount) as? Int) ?? 1
                let lastLine = max(0, totalLines - 1)
                delegate.logoEngine(self, performAction: .updateLineIndex(lastLine))
                delegate.logoEngine(self, performAction: .moveEnd)

            case .lineStart:
                delegate.logoEngine(self, performAction: .moveHome)

            case .lineEnd:
                delegate.logoEngine(self, performAction: .moveEnd)

            case .appendText:
                index += 1
                delegate.logoEngine(self, performAction: .moveEnd)
                while index < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                        index -= 1
                        break
                    }
                    let text = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, performAction: .insertText(text))
                    if index + 1 < tokens.count {
                        if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                            break
                        }
                    }
                    index += 1
                }

            case .prependText:
                index += 1
                delegate.logoEngine(self, performAction: .moveHome)
                while index < tokens.count {
                    if LogoEngine.isStatementCommand(tokens[index]) || tokens[index] == "]" || tokens[index] == ")" {
                        index -= 1
                        break
                    }
                    let text = evaluateExpression(tokens, index: &index)
                    delegate.logoEngine(self, performAction: .insertText(text))
                    if index + 1 < tokens.count {
                        if LogoEngine.isStatementCommand(tokens[index + 1]) || tokens[index + 1] == "]" || tokens[index + 1] == ")" {
                            break
                        }
                    }
                    index += 1
                }

            case .changeText:
                index += 1
                if index < tokens.count {
                    let oldText = evaluateExpression(tokens, index: &index)
                    if index + 1 < tokens.count && !LogoEngine.isStatementCommand(tokens[index + 1]) && tokens[index + 1] != "]" {
                        index += 1
                        let newText = evaluateExpression(tokens, index: &index)
                        delegate.logoEngine(self, performAction: .replaceText(old: oldText, new: newText))
                    }
                }

            case .joinLine:
                let separator = optionalCommandArgument(tokens, index: &index) ?? ""
                delegate.logoEngine(self, performAction: .joinLine(separator: separator))

            case .splitLine:
                delegate.logoEngine(self, performAction: .insertNewline)

            case .indentLines:
                let levels = Int(optionalCommandArgument(tokens, index: &index) ?? "") ?? 1
                delegate.logoEngine(self, performAction: .indentLines(levels: levels))

            case .outdentLines:
                let levels = Int(optionalCommandArgument(tokens, index: &index) ?? "") ?? 1
                delegate.logoEngine(self, performAction: .outdentLines(levels: levels))

            case .table:
                index += 1
                if index < tokens.count {
                    let subcommand = tokens[index].uppercased()
                    if subcommand == "BORDER" {
                        if index + 1 < tokens.count && !LogoEngine.isStatementCommand(tokens[index + 1]) && tokens[index + 1] != "]" {
                            index += 1
                            let style = unquote(tokens[index])
                            delegate.logoEngine(self, performAction: .setTableBorderStyle(style))
                            hasSetStatusMessage = true
                        }
                    } else if subcommand == "NEXTSTYLE" {
                        delegate.logoEngine(self, performAction: .nextTableBorderStyle)
                        hasSetStatusMessage = true
                    } else if !LogoEngine.isStatementCommand(tokens[index]), let rows = Int(evaluateExpression(tokens, index: &index)) {
                        var cols = 3
                        if index + 1 < tokens.count && !LogoEngine.isStatementCommand(tokens[index + 1]) && tokens[index + 1] != "]" {
                            index += 1
                            cols = Int(evaluateExpression(tokens, index: &index)) ?? 3
                        }
                        delegate.logoEngine(self, performAction: .createTable(rows: rows, cols: cols))
                        hasSetStatusMessage = true
                    } else {
                        index -= 1
                        delegate.logoEngine(self, performAction: .createTable(rows: 3, cols: 3))
                        hasSetStatusMessage = true
                    }
                } else {
                    index -= 1
                    delegate.logoEngine(self, performAction: .createTable(rows: 3, cols: 3))
                    hasSetStatusMessage = true
                }

            case .move:
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

            case .goto:
                index += 1
                if index < tokens.count {
                    let lineStr = evaluateExpression(tokens, index: &index)
                    let totalLines = (delegate.logoEngine(self, queryState: .lineCount) as? Int) ?? 0
                    let lineNum = max(1, min(Int(lineStr) ?? 1, totalLines)) - 1
                    delegate.logoEngine(self, performAction: .updateLineIndex(lineNum))
                    delegate.logoEngine(self, performAction: .updateColumnIndex(0))

                    if index + 1 < tokens.count {
                        if !LogoEngine.isKeyword(tokens[index + 1]) {
                            index += 1
                            let colStr = evaluateExpression(tokens, index: &index)
                            let lineText = (delegate.logoEngine(self, queryState: .lineAt(lineNum)) as? String) ?? ""
                            let colNum = max(1, min(Int(colStr) ?? 1, lineText.count + 1)) - 1
                            delegate.logoEngine(self, performAction: .updateColumnIndex(colNum))
                        }
                    }
                }

            case .nextBuffer:
                delegate.logoEngine(self, performAction: .nextBuffer)

            case .prevBuffer:
                delegate.logoEngine(self, performAction: .prevBuffer)

            case .closeBuffer:
                delegate.logoEngine(self, performAction: .closeBuffer)

            case .openBuffer:
                index += 1
                if index < tokens.count {
                    let path = unquote(evaluateExpression(tokens, index: &index))
                    delegate.logoEngine(self, performAction: .openBuffer(path: path))
                }

            case .clearBuffer:
                delegate.logoEngine(self, performAction: .clearBuffer)

            case .saveBuffer:
                let path = optionalCommandArgument(tokens, index: &index)
                delegate.logoEngine(self, performAction: .saveBuffer(path: path))
                hasSetStatusMessage = true

            case .fileSaveAndQuit:
                let path = optionalCommandArgument(tokens, index: &index)
                delegate.logoEngine(self, performAction: .saveAndCloseBuffer(path: path))
                hasSetStatusMessage = true

            case .gotoline:
                index += 1
                if index < tokens.count {
                    let lineStr = evaluateExpression(tokens, index: &index)
                    let row1Based = Int(lineStr) ?? 1
                    delegate.logoEngine(self, performAction: .gotoLine(max(0, row1Based - 1)))
                }

            case .gotocol:
                index += 1
                if index < tokens.count {
                    let colStr = evaluateExpression(tokens, index: &index)
                    let col1Based = Int(colStr) ?? 1
                    delegate.logoEngine(self, performAction: .gotoCol(max(0, col1Based - 1)))
                }

            case .setline:
                index += 1
                if index < tokens.count {
                    let firstVal = evaluateExpression(tokens, index: &index)
                    if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
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

            case .box:
                index += 1
                executeBoxCommand(tokens, index: &index, mode: .insert)

            case .drawBox:
                index += 1
                executeBoxCommand(tokens, index: &index, mode: .overlay)

            case .line, .hr:
                index += 1
                executeLineCommand(tokens, index: &index)

            case .vline, .vhr:
                index += 1
                executeVlineCommand(tokens, index: &index)

            case .newline:
                index += 1
                executeNewlineCommand(tokens, index: &index)

            // Conditional Logic Commands
            case .ifCondition:
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

            case .ifElseCondition:
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
            case .penDown:
                isPenDown = true

            case .penUp:
                isPenDown = false

            case .turnRight:
                index += 1
                var angle = 90
                if index < tokens.count {
                    if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        angle = Int(valStr) ?? 90
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                heading = (heading + angle) % 360

            case .turnLeft:
                index += 1
                var angle = 90
                if index < tokens.count {
                    if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        angle = Int(valStr) ?? 90
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                heading = ((heading - angle) % 360 + 360) % 360

            case .forward:
                index += 1
                var dist = 1
                if index < tokens.count {
                    if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        dist = max(1, min(Int(valStr) ?? 1, 200))
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                executeTurtleMove(steps: dist, directionHeading: heading)

            case .back:
                index += 1
                var dist = 1
                if index < tokens.count {
                    if !LogoEngine.isKeyword(tokens[index]) && tokens[index] != "]" {
                        let valStr = evaluateExpression(tokens, index: &index)
                        dist = max(1, min(Int(valStr) ?? 1, 200))
                    } else {
                        index -= 1
                    }
                } else {
                    index -= 1
                }
                executeTurtleMove(steps: dist, directionHeading: (heading + 180) % 360)

            case .mark:
                delegate.logoEngine(self, performAction: .editMark)

            case .cut:
                delegate.logoEngine(self, performAction: .editCut)

            case .uncut:
                delegate.logoEngine(self, performAction: .editUncut)

            case .justify:
                delegate.logoEngine(self, performAction: .editJustify)

            case .find, .search:
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

            case .run:
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

            case .runResult:
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

            case .repeatLoop:
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

            case .foreverLoop:
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

            case .stop:
                frameReturn = ""
                return

            case .bye:
                byeFlag = true
                return

            case .wait:
                index += 1
                if index < tokens.count {
                    let timeStr = evaluateExpression(tokens, index: &index)
                    if let val = Double(timeStr), val > 0 {
                        delegate.logoEngine(self, performAction: .refreshScreen)
                        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || ProcessInfo.processInfo.processName.contains("XCTest") || ProcessInfo.processInfo.processName.contains("swiftpm-testing-helper")
                        let delay = isTesting ? min(val / 60000.0, 0.001) : val / 60.0
                        Thread.sleep(forTimeInterval: delay)
                    }
                }

            case .testCondition:
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

            case .ifTrue:
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    if testResult == true {
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    }
                }

            case .ifFalse:
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let block = extractBlockTokens(tokens: tokens, index: &index)
                    if testResult == false {
                        var bIdx = 0
                        executeTokens(block, index: &bIdx, frameReturn: &frameReturn)
                    }
                }

            case .ignore:
                index += 1
                if index < tokens.count {
                    _ = evaluateExpression(tokens, index: &index)
                }

            case .catchTag:
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

            case .throwTag:
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

            case .forLoop:
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

            case .dotimesLoop:
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

            case .whileLoop:
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

            case .untilLoop:
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

            case .doWhileLoop:
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

            case .doUntilLoop:
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

            case .caseSwitch:
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

            case .condSwitch:
                index += 1
                if index < tokens.count && tokens[index] == "[" {
                    let clausesBlock = extractBlockTokens(tokens: tokens, index: &index)
                    let result = evaluateCondClauses(clausesBlock: clausesBlock)
                    if let res = result {
                        lastResult = res
                    }
                }

            case .to:
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

            case .exec:
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

            case .end:
                return

            default:
                if let proc = customProcedures[token.uppercased()] {
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
                        if LogoEngine.isKeyword(inner[0]) && firstUpper != "DATE" && firstUpper != "TIME" {
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
        guard procedureCallDepth < maxProcedureCallDepth else {
            let message = "[Procedure recursion limit exceeded: \(proc.name)]"
            lastError = message
            delegate?.logoEngine(self, performAction: .setStatusMessage(message))
            hasSetStatusMessage = true
            return nil
        }

        var args: [String] = []
        for _ in 0..<proc.parameters.count {
            guard lastError == "[]" else { return nil }
            index += 1
            let arg = evaluateExpression(tokens, index: &index)
            args.append(arg)
        }

        var previousParamValues: [String: String?] = [:]
        for (i, param) in proc.parameters.enumerated() {
            previousParamValues[param] = variables[param]
            variables[param] = args[i]
        }
        procedureCallDepth += 1
        defer {
            procedureCallDepth -= 1
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
