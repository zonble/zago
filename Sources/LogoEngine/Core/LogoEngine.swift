@_exported import Drawing
import Foundation

/// LOGO-style Macro Language Engine for text editors.
///
/// ### Core Concepts & Execution Architecture:
///
/// 1. **Custom Procedure**:
///    - Subprograms defined via `TO procName :arg1 ... END`, stored in
///      ``customProcedures``.
///    - Can execute as standalone commands, or return value strings via the
///      `OUTPUT` primitive.
///
/// 2. **Statement Command (`executeStatementCommand`)**:
///    - Built-in non-returning action commands (e.g. `MAKE`, `PRINT`, `SHOW`,
///      `FORWARD`, `IF`, `REPEAT`, `BOX`).
///    - Focuses on performing side-effects, dispatched by
///      `LogoEngine+StatementCommands.swift` to domain modules:
///      - `executeVariableCommand` (Variable and data structure mutations)
///      - `executeControlCommand` (Control flow and loops)
///      - `executeEditingCommand` (Text editing and buffer actions)
///      - `executeDrawingCommand` (Turtle graphics and table drawing)
///
/// 3. **Expression Primitive (`evaluateExpressionPrimitive`)**:
///    - Built-in value-returning operation primitives and reporters (e.g.
///      `SUM`, `FIRST`, `BUFFERS`, `DATE`, `WORD?`).
///    - Focuses on value computation and evaluation, dispatched by
///      `LogoEngine+ExpressionPrimitives.swift` via nil-coalescing chain:
///      - `evaluateDataStructurePrimitives` (Data structures and selectors)
///      - `evaluateMathPrimitives` (Arithmetic and logical operations)
///      - `evaluateBufferPrimitives` (Buffer state queries)
///      - `evaluateTemplatePrimitives` (Higher-order functional templates and
///        iterators: `MAP`, `FILTER`, `REDUCE`, `APPLY`)
///      - `evaluateSystemPrimitives` (System state, environment queries, and
///        date/time: `DATE`, `TIME`, `ASCII`, `CHAR`, `COUNT`)
public final class LogoEngine: @unchecked Sendable {
    public internal(set) var customProcedures: [String: LogoProcedure] = [:]
    public internal(set) var variables: LogoEnvironment
    internal var propertyLists: [String: [String: LogoValue]] = [:]
    public internal(set) var executionFrames: [LogoExecutionFrame] = []
    public internal(set) var executionState: LogoExecutionState = .idle
    public var shouldPauseBeforeToken: ((LogoToken) -> Bool)?
    private let debuggerCondition = NSCondition()
    private var pauseOnNextToken = false
    private var abortRequested = false
    private var debuggerEvaluationRequest: String?
    private var debuggerEvaluationResult: String?
    internal var rootSourceTokens: [LogoToken] = []
    internal var lastExpressionValue: LogoValue? = nil
    public var hasSetStatusMessage: Bool = false
    internal var gensymCounter: Int = 0

    // Turtle graphics state
    internal var isPenDown: Bool = true
    internal var heading: LogoHeading = .right

    public let pluginRegistry: LogoPluginRegistry

    /// Set of built-in statement commands that perform side-effects and do not return values to callers.
    internal static let statementCommands = LogoPrimitive.statementCommands

    /// Set of built-in expression primitives (reporters/operations) that evaluate to value strings.
    internal static let expressionPrimitives = LogoPrimitive.expressionPrimitives

    internal static let keywords: Set<LogoPrimitive> = statementCommands.union(expressionPrimitives)

    internal static let variadicPrimitives = LogoPrimitive.variadicPrimitives

    public func register(plugin: any LogoParserPlugin) {
        pluginRegistry.register(plugin)
    }

    public func unregister(pluginId: String) {
        pluginRegistry.unregister(id: pluginId)
    }

    public func parsePrimitive(_ token: String) -> LogoPrimitive? {
        LogoPrimitive.from(token, registry: pluginRegistry)
    }

    public func parseOperator(_ token: String) -> LogoOperator? {
        LogoOperator.from(token, registry: pluginRegistry)
    }

    public func parseHeading(_ token: String) -> LogoHeading? {
        pluginRegistry.parseHeading(token) ?? LogoHeading(token)
    }

    public func parseBoolean(_ token: String) -> Bool? {
        let clean = token.lowercased()
        if clean == "true" || clean == "1" || clean == "round" || clean == "rounded" { return true }
        if clean == "false" || clean == "0" { return false }
        return pluginRegistry.parseBoolean(token)
    }

    public func parseBorderStyle(_ token: String) -> BorderStyle? {
        pluginRegistry.parseBorderStyle(token) ?? BorderStyle(token)
    }

    public func parseCalendarIdentifier(_ token: String) -> Calendar.Identifier? {
        pluginRegistry.parseCalendarIdentifier(token) ?? Calendar.Identifier(logoCalendarName: token)
    }

    public func parseDateTimeStylePreset(_ token: String, mode: LogoDateTimeMode = .dateTime) -> LogoDateTimeStylePreset? {
        pluginRegistry.parseDateTimeStylePreset(token) ?? (LogoDateTimeStylePreset.isPresetName(token) ? LogoDateTimeStylePreset(raw: token, mode: mode) : nil)
    }

    public func isFillerToken(_ token: String) -> Bool {
        pluginRegistry.isFillerToken(token)
    }

    public func isKeyword(_ token: String) -> Bool {
        guard let prim = parsePrimitive(token) else { return false }
        return Self.keywords.contains(prim)
    }

    public func isStatementCommand(_ token: String) -> Bool {
        guard let prim = parsePrimitive(token) else { return false }
        return Self.statementCommands.contains(prim)
    }

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
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard
            let value = reader.nextOptionalExpression(isBoundary: { [weak self] token in
                (self?.isStatementCommand(token) ?? LogoEngine.isStatementCommand(token)) || token == "]" || token == ")"
            })
        else { return nil }
        reader.commit(to: &index)
        return unquote(value)
    }

    public var lastResult: String? = nil
    internal var repCount: Int = 0
    internal var testResult: Bool? = nil
    public var lastError: LogoError? = nil
    public var hasUncaughtError: Bool = false
    internal var byeFlag: Bool = false
    internal var currentThrowTag: String? = nil
    internal var currentThrowValue: String? = nil
    internal var procedureCallDepth: Int = 0
    internal let maxProcedureCallDepth: Int = 64
    internal var expressionCallDepth: Int = 0
    internal let maxExpressionCallDepth: Int = 128
    internal static let defaultMaxLoopIterations: Int = 10_000
    internal var maxLoopIterations: Int = LogoEngine.defaultMaxLoopIterations

    public weak var delegate: LogoEngineDelegate?

    public init(
        delegate: LogoEngineDelegate? = nil,
        initialVariables: [String: String] = [:],
        pluginRegistry: LogoPluginRegistry = LogoPluginRegistry()
    ) {
        self.delegate = delegate
        self.variables = LogoEnvironment(initialValues: initialVariables)
        self.pluginRegistry = pluginRegistry
    }

    public func abortExecution() {
        debuggerCondition.lock()
        guard case .paused = executionState else {
            debuggerCondition.unlock()
            return
        }
        abortRequested = true
        byeFlag = true
        executionState = .running
        debuggerCondition.broadcast()
        while executionState == .running {
            debuggerCondition.wait()
        }
        debuggerCondition.unlock()
    }

    public func continueExecution() {
        resumeExecution(step: false)
    }

    public func stepExecution() {
        resumeExecution(step: true)
    }

    public func evaluatePausedExpression(_ expression: String) -> String? {
        debuggerCondition.lock()
        guard case .paused = executionState else {
            debuggerCondition.unlock()
            return nil
        }
        debuggerEvaluationResult = nil
        debuggerEvaluationRequest = expression
        debuggerCondition.broadcast()
        while debuggerEvaluationRequest != nil {
            debuggerCondition.wait()
        }
        let result = debuggerEvaluationResult
        debuggerCondition.unlock()
        return result
    }

    private func resumeExecution(step: Bool) {
        debuggerCondition.lock()
        guard case .paused = executionState else {
            debuggerCondition.unlock()
            return
        }
        pauseOnNextToken = step
        executionState = .running
        debuggerCondition.broadcast()
        while executionState == .running {
            debuggerCondition.wait()
        }
        debuggerCondition.unlock()
    }

    /// Executes LOGO macro script on the delegate context, creating a single atomic Undo snapshot.
    public func execute(_ script: String) {
        debuggerCondition.lock()
        abortRequested = false
        byeFlag = false
        executionState = .running
        let thread = Thread { [weak self] in
            self?.executeScript(script)
        }
        thread.stackSize = 8 * 1024 * 1024
        thread.start()
        while executionState == .running {
            debuggerCondition.wait()
        }
        debuggerCondition.unlock()
    }

    private func executeScript(_ script: String) {
        lastResult = nil
        lastError = nil
        hasUncaughtError = false
        hasSetStatusMessage = false
        procedureCallDepth = 0
        expressionCallDepth = 0

        let sourceTokens = LogoTokenizer.tokenizeTokens(script)
        let tokens = sourceTokens.map(\.text)
        guard !tokens.isEmpty else {
            finishExecution()
            return
        }

        // Save a single atomic Undo snapshot for the entire macro execution
        delegate?.logoEngine(self, performAction: .saveUndoSnapshot)

        rootSourceTokens = sourceTokens
        executionFrames = [LogoExecutionFrame(procedureName: nil, token: nil, scopeDepth: variables.scopeDepth)]
        defer {
            rootSourceTokens = []
            executionFrames = []
            finishExecution()
        }
        var index = 0
        var frameReturn: String? = nil
        executeTokens(tokens, sourceTokens: sourceTokens, index: &index, frameReturn: &frameReturn)
        if let ret = frameReturn, !ret.isEmpty {
            lastResult = ret
        }
        delegate?.logoEngine(self, performAction: .clampCursor)
    }

    /// Step-by-step 3-stage statement execution loop for tokenized scripts.
    internal func executeTokens(
        _ tokens: [String],
        sourceTokens: [LogoToken]? = nil,
        index: inout Int,
        frameReturn: inout String?
    ) {
        while index < tokens.count && frameReturn == nil && !byeFlag && !hasUncaughtError && currentThrowTag == nil {
            if let sourceTokens, index < sourceTokens.count {
                if !executionFrames.isEmpty {
                    executionFrames[executionFrames.count - 1] = LogoExecutionFrame(
                        procedureName: executionFrames.last?.procedureName,
                        token: sourceTokens[index],
                        scopeDepth: variables.scopeDepth
                    )
                }
                if let token = executionFrames.last?.token,
                    pauseOnNextToken || shouldPauseBeforeToken?(token) == true
                {
                    if !executionFrames.isEmpty && !pauseExecution(at: executionFrames[executionFrames.count - 1]) {
                        return
                    }
                }
            }
            let token = tokens[index]

            if token == "]" {
                return
            }

            if isFillerToken(token) && !token.hasPrefix("\"") && !token.hasPrefix(":") && !token.hasPrefix("[") && !token.hasPrefix("(") {
                index += 1
                continue
            }

            // Step 1: Built-in Statement Command
            if let prim = parsePrimitive(token),
                executeStatementCommand(prim, tokens: tokens, index: &index, frameReturn: &frameReturn)
            {
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

            // Step 3: Unknown Identifier Check -> "I don't know how to <token>"
            if isUnknownIdentifierToken(token) {
                let unquoted = unquote(token)
                let errorMessage = "[LOGO Error: I don't know how to \(unquoted)]"
                reportError(LogoError(code: 1, message: errorMessage), token: token)
                return
            }

            // Step 4: Standalone Expression Evaluation (primitives, numbers, variables, strings)
            let exprResult = evaluateExpression(tokens, index: &index)
            if !exprResult.isEmpty {
                lastResult = exprResult
            }
            index += 1
        }
    }

    private func pauseExecution(at frame: LogoExecutionFrame) -> Bool {
        debuggerCondition.lock()
        pauseOnNextToken = false
        executionState = .paused(frame)
        debuggerCondition.broadcast()
        while case .paused = executionState {
            if let expression = debuggerEvaluationRequest {
                let tokens = LogoTokenizer.tokenize(expression)
                var index = 0
                debuggerEvaluationResult = tokens.isEmpty ? "" : evaluateExpression(tokens, index: &index)
                debuggerEvaluationRequest = nil
                debuggerCondition.broadcast()
                continue
            }
            debuggerCondition.wait()
        }
        let shouldContinue = !abortRequested
        debuggerCondition.unlock()
        return shouldContinue
    }

    private func finishExecution() {
        debuggerCondition.lock()
        executionState = .completed
        debuggerCondition.broadcast()
        debuggerCondition.unlock()
    }

    internal func isUnknownIdentifierToken(_ token: String) -> Bool {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "()[]"))
        if clean.isEmpty || clean.hasPrefix(";") || clean.hasPrefix("//") || clean.hasPrefix("#") {
            return false
        }
        if isQuotedWordToken(clean) || clean.hasPrefix(":") || clean.hasPrefix("?") {
            return false
        }
        if Double(clean) != nil {
            return false
        }
        let upper = clean.uppercased()
        if customProcedures[upper] != nil || parsePrimitive(clean) != nil || LogoPrimitive.from(upper) != nil {
            return false
        }
        if parseOperator(clean) != nil {
            return false
        }
        if isFillerToken(clean) {
            return false
        }
        return true
    }

    internal func reportError(_ error: LogoError, token: String = "") {
        lastError = error
        hasUncaughtError = true
        delegate?.logoEngine(self, performAction: .setStatusMessage(error.message))
        hasSetStatusMessage = true
    }

    internal func guardLoopIteration(_ loopName: String, iteration: Int) -> Bool {
        let limit = max(1, maxLoopIterations)
        guard iteration <= limit else {
            let message = "[LOGO loop iteration limit exceeded: \(loopName) (\(limit) iterations)]"
            lastError = LogoError(code: 1, message: message)
            hasUncaughtError = true
            delegate?.logoEngine(self, performAction: .setStatusMessage(message))
            hasSetStatusMessage = true
            return false
        }
        return true
    }
}
