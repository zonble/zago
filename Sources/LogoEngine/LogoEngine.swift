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
        .bye, .ignore, .foreach, .to, .exec, .search, .sort, .fill, .end, .mdsetItem, .setFirst, .setBFL
    ]

    internal static let expressionPrimitives: Set<LogoPrimitive> = [
        .apply, .invoke, .map, .mapSe, .filter, .reduce, .crossmap, .runResult,
        .date, .time, .thing, .word, .list, .sentence, .fput, .lput, .array, .mdarray,
        .listToArray, .arrayToList, .combine, .reverse, .gensym, .first,
        .last, .firsts, .butFirst, .butLast, .butFirsts, .item, .mditem,
        .pick, .remove, .remdup, .quoted, .split, .setItem,
        .push, .pop, .dequeue, .isWord, .isList, .isArray,
        .isNumber, .isEmpty, .isEqual, .isNotEqual, .isIdentityEqual, .isBefore,
        .isMember, .isSubstring, .count, .ascii, .char, .member, .uppercase, .lowercase,
        .standout, .parse, .runparse, .less, .greater, .lessOrEqual, .greaterOrEqual,
        .sum, .min, .max, .difference, .product, .quotient, .power, .remainder, .modulo, .minus, .abs, .int, .round,
        .sqrt, .exp, .log10, .ln, .arctan, .sin, .cos, .tan, .radArctan, .radSin, .radCos, .radTan,
        .iseq, .rseq, .random, .rerandom, .form, .bitAnd, .bitOr, .bitXor, .bitNot, .ashift, .lshift,
        .trueVal, .falseVal, .andLogic, .orLogic, .xorLogic, .notLogic,
        .buffers, .buffer, .getline, .row, .col, .lineCount, .bufferText, .selection, .isModified, .fileName, .find, .sort
    ]

    internal static let keywords: Set<LogoPrimitive> = statementCommands.union(expressionPrimitives)

    internal static let variadicPrimitives: Set<LogoPrimitive> = [
        .word, .list, .sentence, .sum, .product, .min, .max, .andLogic, .orLogic
    ]

    internal static func isKeyword(_ token: String) -> Bool {
        guard let prim = LogoPrimitive.from(token) else { return false }
        return keywords.contains(prim)
    }

    internal static func isStatementCommand(_ token: String) -> Bool {
        guard let prim = LogoPrimitive.from(token) else { return false }
        return statementCommands.contains(prim)
    }

    internal static func isVariadicPrimitive(_ prim: LogoPrimitive) -> Bool {
        return variadicPrimitives.contains(prim)
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
        guard self.delegate != nil else { return }
        while index < tokens.count && frameReturn == nil && lastError == "[]" {
            let token = tokens[index]

            if token == "]" {
                return
            }

            if let proc = customProcedures[token.uppercased()] {
                let ret = invokeProcedure(proc, tokens: tokens, index: &index)
                if let r = ret, !r.isEmpty {
                    lastResult = r
                }
                index += 1
                continue
            }

            guard let prim = LogoPrimitive.from(token) else {
                let exprResult = evaluateExpression(tokens, index: &index)
                if !exprResult.isEmpty {
                    lastResult = exprResult
                }
                index += 1
                continue
            }

            if executeStatementCommand(prim, tokens: tokens, index: &index, frameReturn: &frameReturn) {
                index += 1
                continue
            }

            let exprResult = evaluateExpression(tokens, index: &index)
            if !exprResult.isEmpty {
                lastResult = exprResult
            }
            index += 1
        }
    }

    internal func executeStatementCommand(
        _ prim: LogoPrimitive,
        tokens: [String],
        index: inout Int,
        frameReturn: inout String?
    ) -> Bool {
        executeVariableCommand(prim, tokens: tokens, index: &index)
            || executeControlCommand(prim, tokens: tokens, index: &index, frameReturn: &frameReturn)
            || executeEditingCommand(prim, tokens: tokens, index: &index)
            || executeDrawingCommand(prim, tokens: tokens, index: &index)
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
