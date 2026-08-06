import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

private final class CoverageDelegate: LogoEngineDelegate, @unchecked Sendable {
    var statusMessages: [String] = []
    var refreshCount = 0

    func logoEngine(_ engine: LogoEngine, performAction action: LogoEditorAction) {
        switch action {
        case .setStatusMessage(let message):
            statusMessages.append(message)
        case .refreshScreen:
            refreshCount += 1
        default:
            break
        }
    }

    func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> Any? { nil }
}

@Suite(.serialized)
struct LogoCoverageTests {
    private func evaluate(_ script: String, engine: LogoEngine = LogoEngine()) -> String {
        let tokens = engine.tokenize(script)
        var index = 0
        return engine.evaluateExpression(tokens, index: &index)
    }

    @Test func testDataConstructorsAndVariadicEvaluationBranches() {
        let engine = LogoEngine()

        #expect(evaluate("(WORD \"a \"b \"c)", engine: engine) == "abc")
        #expect(evaluate("(LIST 1 2 3)", engine: engine) == "[1 2 3]")
        #expect(evaluate("(SENTENCE [1 2] {3 4} \"5)", engine: engine) == "[1 2 3 4 5]")
        #expect(evaluate("(PRODUCT 2 3 4)", engine: engine) == "24")
        #expect(evaluate("(MIN [3 1] 4 9)", engine: engine) == "1")
        #expect(evaluate("(MAX [3 1] 4 9)", engine: engine) == "9")
        #expect(evaluate("(AND TRUE 1 \"hello)", engine: engine) == "1")
        #expect(evaluate("(OR 0 FALSE \"hello)", engine: engine) == "1")

        #expect(evaluate("SENTENCE {1 2} \"tail", engine: engine) == "[1 2 tail]")
        #expect(evaluate("FPUT \"a {b c}", engine: engine) == "{a b c}")
        #expect(evaluate("LPUT \"z \"xy", engine: engine) == "xyz")
        #expect(evaluate("MDARRAY [2 0]", engine: engine) == "{{} {}}")
        #expect(evaluate("LISTTOARRAY \"x", engine: engine) == "{x}")
        #expect(evaluate("ARRAYTOLIST \"x", engine: engine) == "[x]")
        #expect(evaluate("COMBINE \"a {b c}", engine: engine) == "")
        #expect(evaluate("\"left + \"right", engine: engine) == "leftright")
        #expect(evaluate("\"left - 1", engine: engine) == "left")
    }

    @Test func testDataSelectorsQueriesAndEdgeCases() {
        let engine = LogoEngine()
        engine.variables["quoted"] = "\"already"

        #expect(evaluate("FIRSTS \"ab", engine: engine) == "[a b]")
        #expect(evaluate("BUTFIRSTS [[a b] {x y} \"cd]", engine: engine) == "[[b] {y} d]")
        #expect(evaluate("ITEM 9 [1 2]", engine: engine) == "")
        #expect(evaluate("REMOVE \"na \"banana", engine: engine) == "ba")
        #expect(evaluate("REMOVE 2 {1 2 3 2}", engine: engine) == "{1 3}")
        #expect(evaluate("SPLIT 2 [1 2 3 2 4]", engine: engine) == "[[1] [3] [4]]")
        #expect(evaluate("SPLIT \",\" \"a,,b,c", engine: engine) == "[a b c]")
        #expect(evaluate("QUOTED :quoted", engine: engine) == "\"already")
        #expect(evaluate("MDITEM [2 2] {{a b} {c d}}", engine: engine) == "d")
        #expect(evaluate("MDITEM [2 3] {{a b} {c d}}", engine: engine) == "")
        #expect(evaluate("MEMBER 2 {1 2 3}", engine: engine) == "{2 3}")
        #expect(evaluate("FIRST []", engine: engine) == "")
        #expect(evaluate("LAST \"", engine: engine) == "")
    }

    @Test func testVariableCommandsMutateListsArraysAndStrings() {
        let editor = Editor()
        let engine = LogoEngine(delegate: editor)

        engine.execute("NAME \"bar \"target")
        #expect(engine.variables["target"] == "bar")

        engine.execute("MAKE \"letters \"abc SETITEM 2 \"letters \"Z")
        #expect(engine.variables["letters"] == "aZc")

        engine.execute("SETITEM 99 \"letters \"Q")
        #expect(engine.variables["letters"] == "aZc")

        engine.execute("MAKE \"items [old tail] SETFIRST \"items \"new")
        #expect(engine.variables["items"] == "[new tail]")

        engine.execute("MAKE \"emptyList [] SETFIRST \"emptyList \"seed")
        #expect(engine.variables["emptylist"] == "[seed]")

        engine.variables["emptyword"] = ""
        engine.execute("SETFIRST \"emptyWord \"seed")
        #expect(engine.variables["emptyword"] == "seed")

        engine.execute("MAKE \"listTail [head old] SETBF \"listTail [x y]")
        #expect(engine.variables["listtail"] == "[head x y]")

        engine.execute("MAKE \"arrayTail {head old} SETBF \"arrayTail {x y}")
        #expect(engine.variables["arraytail"] == "{head x y}")

        engine.execute("MAKE \"wordTail \"abc SETBF \"wordTail \"YZ")
        #expect(engine.variables["wordtail"] == "aYZ")
    }

    @Test func testVariableCommandsHandleNestedMutationAndQueueAliases() {
        let editor = Editor()
        let engine = LogoEngine(delegate: editor)

        engine.execute("MAKE \"grid {{a b} {c d}} MDSETITEM [2 1] \"grid \"z")
        #expect(engine.variables["grid"] == "{{a b} {z d}}")

        engine.execute("MAKE \"text \"abcd MDSETITEM [3] \"text \"Z")
        #expect(engine.variables["text"] == "abZd")

        engine.execute("MAKE \"stack {b c} PUSH \"stack \"a")
        #expect(engine.variables["stack"] == "{a b c}")

        engine.execute("MAKE \"queue {a b} QUEUE \"queue \"c")
        #expect(engine.variables["queue"] == "{a b c}")

        engine.execute("MAKE \"word \"bc PUSH \"word \"a")
        #expect(engine.variables["word"] == "abc")

        engine.execute("MAKE \"tailWord \"ab DEQUEUE \"tailWord \"c")
        #expect(engine.variables["tailword"] == "abc")
    }

    @Test func testControlCommandsHandleRunRunresultStopByeAndWait() {
        let delegate = CoverageDelegate()
        let engine = LogoEngine(delegate: delegate)
        var frameReturn: String?

        var runBlockIndex = 0
        #expect(engine.executeControlCommand(.run, tokens: ["RUN", "[", "MAKE", "\"x", "5", "]"], index: &runBlockIndex, frameReturn: &frameReturn))
        #expect(engine.variables["x"] == "5")

        frameReturn = nil
        var runStringIndex = 0
        #expect(engine.executeControlCommand(.run, tokens: ["RUN", "OUTPUT 7"], index: &runStringIndex, frameReturn: &frameReturn))
        #expect(frameReturn == "7")

        frameReturn = nil
        var runResultIndex = 0
        #expect(engine.executeControlCommand(.runResult, tokens: ["RUNRESULT", "[", "OUTPUT", "42", "]"], index: &runResultIndex, frameReturn: &frameReturn))
        #expect(engine.lastResult == "[42]")

        frameReturn = nil
        var emptyRunResultIndex = 0
        #expect(engine.executeControlCommand(.runResult, tokens: ["RUNRESULT", "[", "MAKE", "\"z", "1", "]"], index: &emptyRunResultIndex, frameReturn: &frameReturn))
        #expect(engine.lastResult == "[]")

        frameReturn = nil
        var stopIndex = 0
        #expect(engine.executeControlCommand(.stop, tokens: ["STOP"], index: &stopIndex, frameReturn: &frameReturn))
        #expect(frameReturn == "")

        frameReturn = nil
        var waitIndex = 0
        #expect(engine.executeControlCommand(.wait, tokens: ["WAIT", "60"], index: &waitIndex, frameReturn: &frameReturn))
        #expect(delegate.refreshCount == 1)

        engine.byeFlag = false
        engine.execute("BYE MAKE \"after 1")
        #expect(engine.byeFlag)
        #expect(engine.variables["after"] == nil)
    }

    @Test func testControlLoopAndConditionVariants() {
        let delegate = CoverageDelegate()
        let engine = LogoEngine(delegate: delegate)

        engine.execute("TEST 1 = 2 IFTRUE [ MAKE \"flag \"bad ] IFFALSE [ MAKE \"flag \"ok ]")
        #expect(engine.variables["flag"] == "ok")

        engine.variables["trail"] = ""
        engine.execute("FOR [i 3 1 -1] [ MAKE \"trail WORD :trail :i ]")
        #expect(engine.variables["trail"] == "321")

        engine.variables["dots"] = ""
        engine.execute("DOTIMES [i 3] [ MAKE \"dots WORD :dots :i ]")
        #expect(engine.variables["dots"] == "012")

        engine.variables["untilval"] = "0"
        engine.execute("UNTIL [:untilVal >= 2] [ MAKE \"untilVal :untilVal + 1 ]")
        #expect(engine.variables["untilval"] == "2")

        var frameReturn: String?
        engine.variables["dw"] = "0"
        var doWhileIndex = 0
        #expect(
            engine.executeControlCommand(
                .doWhileLoop,
                tokens: ["DO.WHILE", "[", "MAKE", "\"dw", ":dw", "+", "1", "]", ":dw", "<", "2", "]"],
                index: &doWhileIndex,
                frameReturn: &frameReturn
            )
        )
        #expect(engine.variables["dw"] == "2")

        frameReturn = nil
        engine.variables["du"] = "0"
        var doUntilIndex = 0
        #expect(
            engine.executeControlCommand(
                .doUntilLoop,
                tokens: ["DO.UNTIL", "[", "MAKE", "\"du", ":du", "+", "1", "]", ":du", ">=", "2", "]"],
                index: &doUntilIndex,
                frameReturn: &frameReturn
            )
        )
        #expect(engine.variables["du"] == "2")
    }

    @Test func testControlDispatchHelpersTemplatesAndProcedureEdges() {
        let delegate = CoverageDelegate()
        let engine = LogoEngine(delegate: delegate)

        let caseClauses = ["[", "[", "a", "]", "\"first", "]", "[", "[", "b", "c", "]", "\"second", "]", "[", "ELSE", "\"fallback", "]"]
        #expect(engine.evaluateCaseClauses(targetVal: "c", clausesBlock: caseClauses) == "second")
        #expect(engine.evaluateCaseClauses(targetVal: "z", clausesBlock: caseClauses) == "fallback")

        let condClauses = ["[", "[", "1", ">", "2", "]", "\"bad", "]", "[", "[", "2", ">", "1", "]", "\"good", "]", "[", "ELSE", "\"fallback", "]"]
        #expect(engine.evaluateCondClauses(clausesBlock: condClauses) == "good")

        engine.execute("CATCH \"error [ THROW \"custom \"boom ]")
        #expect(engine.lastResult == "boom")
        #expect(engine.currentThrowTag == nil)
        #expect(engine.currentThrowValue == nil)

        var frameReturn: String?
        var throwIndex = 0
        #expect(engine.executeControlCommand(.throwTag, tokens: ["THROW", "\"justTag"], index: &throwIndex, frameReturn: &frameReturn))
        #expect(engine.currentThrowTag == "justtag")
        #expect(engine.currentThrowValue == "")

        engine.execute("TO ADDONE :x OUTPUT :x + 1 END EXEC ADDONE 4")
        #expect(engine.lastResult == "5")

        engine.execute("TO HALT MAKE \"stopTest 1 STOP MAKE \"stopTest 2 END HALT")
        #expect(engine.variables["stoptest"] == "1")

        #expect(engine.applyTemplate(templateStr: "[[x y] [OUTPUT WORD :x :y]]", args: ["A", "B"]) == "AB")
        #expect(engine.applyTemplate(templateStr: "[OUTPUT WORD ?1 ?1]", args: ["Z"]) == "ZZ")
        #expect(engine.applyTemplate(templateStr: "[?1 < ?2]", args: ["1", "2"]) == "1")
        #expect(engine.applyTemplate(templateStr: "ADDONE", args: ["9"]) == "10")
    }

    @Test func testEvaluationHelpersRestoreStateAndReportRecursionErrors() {
        let delegate = CoverageDelegate()
        let engine = LogoEngine(delegate: delegate)

        #expect(engine.evaluateCondition([]) == false)
        #expect(engine.evaluateCondition(["0"]) == false)
        #expect(engine.evaluateCondition(["apple", "<", "banana"]) == true)
        #expect(engine.evaluateCondition(["hello", "world"]) == true)

        engine.variables["x"] = "outer"
        let proc = LogoProcedure(name: "JOIN", parameters: ["x", "y"], bodyTokens: ["OUTPUT", "WORD", ":x", ":y"])
        var invokeIndex = 0
        #expect(engine.invokeProcedure(proc, tokens: ["JOIN", "\"left", "\"right"], index: &invokeIndex) == "leftright")
        #expect(engine.variables["x"] == "outer")

        engine.procedureCallDepth = engine.maxProcedureCallDepth
        var recursionIndex = 0
        #expect(engine.invokeProcedure(proc, tokens: ["JOIN", "\"a", "\"b"], index: &recursionIndex) == nil)
        #expect(engine.lastError.contains("recursion limit exceeded"))
        #expect(delegate.statusMessages.last == engine.lastError)
    }
}
