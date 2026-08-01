import Foundation

/// Represents a user-defined LOGO procedure defined via `TO procName :param1 ... body ... END`.
/// Procedures can act as Statement Commands (non-returning) or Reporters/Operations (returning a value via `OUTPUT`).
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

internal enum LogoRuntimeValue: Equatable {
    case string(String)
    case dateTime(String)

    var description: String {
        switch self {
        case .string(let value), .dateTime(let value):
            return value
        }
    }

    var isNumeric: Bool {
        switch self {
        case .string(let value):
            return Double(value) != nil
        case .dateTime:
            return false
        }
    }
}

/// LOGO-style Macro Language Engine for text editors.
///
/// ### Core Concepts & Execution Architecture:
///
/// 1. **Custom Procedure**:
///    - Subprograms defined via `TO procName :arg1 ... END`, stored in ``customProcedures``.
///    - Can execute as standalone commands, or return value strings via the `OUTPUT` primitive.
///
/// 2. **Statement Command (`executeStatementCommand`)**:
///    - Built-in non-returning action commands (e.g. `MAKE`, `PRINT`, `SHOW`, `FORWARD`, `IF`, `REPEAT`, `BOX`).
///    - Focuses on performing side-effects, dispatched by `LogoEngine+StatementCommands.swift` to domain modules:
///      - `executeVariableCommand` (Variable and data structure mutations)
///      - `executeControlCommand` (Control flow and loops)
///      - `executeEditingCommand` (Text editing and buffer actions)
///      - `executeDrawingCommand` (Turtle graphics and table drawing)
///
/// 3. **Expression Primitive (`evaluateExpressionPrimitive`)**:
///    - Built-in value-returning operation primitives and reporters (e.g. `SUM`, `FIRST`, `BUFFERS`, `DATE`, `WORD?`).
///    - Focuses on value computation and evaluation, dispatched by `LogoEngine+ExpressionPrimitives.swift` via nil-coalescing chain:
///      - `evaluateDataStructurePrimitives` (Data structures and selectors)
///      - `evaluateMathPrimitives` (Arithmetic and logical operations)
///      - `evaluateBufferPrimitives` (Buffer state queries)
///      - `evaluateTemplatePrimitives` (Higher-order functional templates and iterators: `MAP`, `FILTER`, `REDUCE`, `APPLY`)
///      - `evaluateSystemPrimitives` (System state, environment queries, and date/time: `DATE`, `TIME`, `ASCII`, `CHAR`, `COUNT`)
public final class LogoEngine {
    public var customProcedures: [String: LogoProcedure] = [:]
    public var variables: [String: String] = [:]
    internal var variableValues: [String: LogoRuntimeValue] = [:]
    internal var lastExpressionValue: LogoRuntimeValue? = nil
    public var hasSetStatusMessage: Bool = false
    internal var gensymCounter: Int = 0

    // Turtle graphics state
    public var isPenDown: Bool = true
    public var heading: Int = 90 // 0 = UP, 90 = RIGHT, 180 = DOWN, 270 = LEFT

    /// Set of built-in statement commands that perform side-effects and do not return values to callers.
    internal static let statementCommands: Set<LogoPrimitive> = [
        .make, .name, .type, .show, .delete, .backspace, .deleteLine,
        .top, .bottom, .lineStart, .lineEnd, .appendText, .prependText, .changeText,
        .joinLine, .splitLine, .indentLines, .outdentLines,
        .move, .mark, .cut, .uncut, .justify, .goto, .box, .drawBox, .line, .hr, .vline, .vhr, .table, .diagram,
        .newline, .penDown, .penUp, .forward, .back, .turnRight, .turnLeft,
        .setline, .gotoline, .gotocol, .clearBuffer, .ifCondition, .ifElseCondition, .output, .run,
        .repeatLoop, .foreverLoop, .forLoop, .dotimesLoop, .whileLoop,
        .doWhileLoop, .untilLoop, .doUntilLoop, .caseSwitch, .condSwitch,
        .testCondition, .ifTrue, .ifFalse, .stop, .catchTag, .throwTag, .wait,
        .bye, .ignore, .foreach, .to, .exec, .search, .sort, .fill, .end, .mdsetItem, .setFirst, .setBFL
    ]

    /// Set of built-in expression primitives (reporters/operations) that evaluate to value strings.
    internal static let expressionPrimitives: Set<LogoPrimitive> = [
        .apply, .invoke, .map, .mapSe, .filter, .reduce, .crossmap, .runResult,
        .date, .time, .thing, .word, .list, .sentence, .fput, .lput, .array, .mdarray,
        .listToArray, .arrayToList, .combine, .reverse, .gensym, .first,
        .last, .firsts, .butFirst, .butLast, .butFirsts, .item, .mditem,
        .pick, .remove, .remdup, .quoted, .split, .setItem,
        .push, .pop, .dequeue, .isWord, .isList, .isArray,
        .isNumber, .isEmpty, .isEqual, .isNotEqual, .isIdentityEqual, .isBefore,
        .isMember, .isSubstring, .isProcedure, .isPrimitive, .isDefined, .isName,
        .count, .ascii, .char, .member, .uppercase, .lowercase,
        .standout, .translit,
        .transformToHans, .transformToHant, .transformToLatin,
        .transformToHiragana, .transformToKatakana, .transformToRomaji,
        .parse, .runparse, .less, .greater, .lessOrEqual, .greaterOrEqual,
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

    /// Step-by-step 3-stage statement execution loop for tokenized scripts.
    internal func executeTokens(_ tokens: [String], index: inout Int, frameReturn: inout String?) {
        guard self.delegate != nil else { return }
        while index < tokens.count && frameReturn == nil && !byeFlag && lastError == "[]" {
            let token = tokens[index]

            if token == "]" {
                return
            }

            // Step 1: Built-in Statement Command
            if let prim = LogoPrimitive.from(token),
               executeStatementCommand(prim, tokens: tokens, index: &index, frameReturn: &frameReturn) {
                index += 1
                continue
            }

            // Step 2: User-defined Procedure Command
            if let proc = customProcedures[token.uppercased()] {
                let ret = invokeProcedure(proc, tokens: tokens, index: &index)
                if let r = ret, !r.isEmpty {
                    lastResult = r
                }
                index += 1
                continue
            }

            // Step 3: Standalone Expression Evaluation
            let exprResult = evaluateExpression(tokens, index: &index)
            if !exprResult.isEmpty {
                lastResult = exprResult
            }
            index += 1
        }
    }
}
