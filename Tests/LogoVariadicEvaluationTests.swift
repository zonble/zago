import Foundation
import Testing

@testable import LogoEngine

@Suite(.serialized)
struct LogoVariadicEvaluationTests {
    private func evaluate(_ script: String, engine: LogoEngine = LogoEngine()) -> String {
        let tokens = LogoTokenizer.tokenize(script)
        var index = 0
        return engine.evaluateExpression(tokens, index: &index)
    }

    @Test func testParenthesizedIfElse() {
        let engine = LogoEngine()
        #expect(evaluate("(IFELSE TRUE [\"yes] [\"no])", engine: engine) == "yes")
        #expect(evaluate("(IFELSE FALSE [\"yes] [\"no])", engine: engine) == "no")
        #expect(evaluate("(IFELSE TRUE [] [\"no])", engine: engine) == "")
        #expect(evaluate("(IFELSE 1 > 0 [\"bigger] [\"smaller])", engine: engine) == "bigger")
    }

    @Test func testParenthesizedDateTimePrimitives() {
        let engine = LogoEngine()
        #expect(!evaluate("(DATE \"yyyy)", engine: engine).isEmpty)
        #expect(!evaluate("(TIME \"HH:mm)", engine: engine).isEmpty)
        #expect(!evaluate("(DATETIME \"yyyy-MM-dd HH:mm)", engine: engine).isEmpty)

        // FORMAT.DATE
        #expect(!evaluate("(FORMAT.DATE \"2026-09-03 \"yyyy)", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.DATE \"2026-09-03T14:30:00 \"yyyy-MM-dd)", engine: engine).isEmpty)
        #expect(evaluate("(FORMAT.DATE)", engine: engine) == "")

        // DATE.ADD
        #expect(!evaluate("(DATE.ADD \"2026-09-03 5 \"days)", engine: engine).isEmpty)
        #expect(!evaluate("(DATE.ADD \"2026-09-03T10:00:00 2 \"hours)", engine: engine).isEmpty)
        #expect(evaluate("(DATE.ADD)", engine: engine) == "")

        // DATE.DIFF
        #expect(evaluate(#"(DATE.DIFF "2026-09-01 "2026-09-06 "days)"#, engine: engine) == "-5")
        #expect(evaluate("(DATE.DIFF \"2026-09-01)", engine: engine) == "0")

        // CONVERT.CALENDAR
        #expect(!evaluate("(CONVERT.CALENDAR \"2026-09-03 \"roc)", engine: engine).isEmpty)
        #expect(!evaluate("(CONVERT.CALENDAR \"2026-09-03 \"roc \"gregorian \"yyyy/MM/dd)", engine: engine).isEmpty)
        #expect(evaluate("(CONVERT.CALENDAR)", engine: engine) == "")
    }

    @Test func testParenthesizedFormatPrimitives() {
        let engine = LogoEngine()
        // FORMAT.NUMBER
        #expect(!evaluate("(FORMAT.NUMBER 12345.67 \"currency \"en_US)", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.NUMBER 0.25 \"percent)", engine: engine).isEmpty)
        #expect(evaluate("(FORMAT.NUMBER)", engine: engine) == "")

        // FORMAT.BYTES
        #expect(!evaluate("(FORMAT.BYTES 1048576)", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.BYTES 1048576 \"count)", engine: engine).isEmpty)
        #expect(evaluate("(FORMAT.BYTES)", engine: engine) == "")

        #if canImport(Darwin)
        // FORMAT.LIST
        #expect(!evaluate("(FORMAT.LIST [apple banana orange])", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.LIST [apple banana orange] \"or)", engine: engine).isEmpty)
        #expect(evaluate("(FORMAT.LIST)", engine: engine) == "")

        // FORMAT.RELATIVETIME
        #expect(!evaluate("(FORMAT.RELATIVETIME 3 \"days)", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.RELATIVETIME \"2026-09-01)", engine: engine).isEmpty)
        #expect(evaluate("(FORMAT.RELATIVETIME)", engine: engine) == "")

        // FORMAT.NAME
        #expect(!evaluate("(FORMAT.NAME \"John \"Smith)", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.NAME \"John \"Michael \"Smith)", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.NAME [given John family Smith])", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.NAME [John])", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.NAME [John Michael Smith])", engine: engine).isEmpty)
        #expect(evaluate("(FORMAT.NAME)", engine: engine) == "")
        #endif
    }

    @Test func testParenthesizedMeasurePrimitives() {
        let engine = LogoEngine()
        // MEASURE.SCALE
        #expect(evaluate("(MEASURE.SCALE 10 \"cm 2.5)", engine: engine) == "[25 cm]")
        #expect(evaluate("(MEASURE.SCALE [10 cm] 3)", engine: engine) == "[30 cm]")
        #expect(evaluate("(MEASURE.SCALE)", engine: engine) == "")

        // MEASURE.ADD / SUB / EQUAL? / LESS? / GREATER? / MIN / MAX
        #expect(evaluate("(MEASURE.ADD 10 \"cm 5 \"cm)", engine: engine) == "[15 cm]")
        #expect(evaluate("(MEASURE.ADD [10 cm] [5 cm])", engine: engine) == "[15 cm]")
        #expect(evaluate("(MEASURE.SUB 10 \"cm 4 \"cm)", engine: engine) == "[6 cm]")
        #expect(evaluate("(MEASURE.SUB [10 cm] [4 cm])", engine: engine) == "[6 cm]")
        #expect(evaluate("(MEASURE.EQUAL? 10 \"cm 10 \"cm)", engine: engine) == "true")
        #expect(evaluate("(MEASURE.EQUAL? [10 cm] [10 cm])", engine: engine) == "true")
        #expect(evaluate("(MEASURE.LESS? 5 \"cm 10 \"cm)", engine: engine) == "true")
        #expect(evaluate("(MEASURE.LESS? [5 cm] [10 cm])", engine: engine) == "true")
        #expect(evaluate("(MEASURE.GREATER? 10 \"cm 5 \"cm)", engine: engine) == "true")
        #expect(evaluate("(MEASURE.GREATER? [10 cm] [5 cm])", engine: engine) == "true")
        #expect(evaluate("(MEASURE.MIN 10 \"cm 5 \"cm)", engine: engine) == "[5 cm]")
        #expect(evaluate("(MEASURE.MIN [10 cm] [5 cm])", engine: engine) == "[5 cm]")
        #expect(evaluate("(MEASURE.MAX 10 \"cm 5 \"cm)", engine: engine) == "[10 cm]")
        #expect(evaluate("(MEASURE.MAX [10 cm] [5 cm])", engine: engine) == "[10 cm]")

        // CONVERT.MEASURE
        #expect(evaluate("(CONVERT.MEASURE 1 \"m \"cm)", engine: engine) == "100")
        #expect(evaluate("(CONVERT.MEASURE [1 m] \"cm)", engine: engine) == "100")
        #expect(evaluate("(CONVERT.MEASURE)", engine: engine) == "")

        #if canImport(Darwin)
        // FORMAT.MEASURE
        #expect(!evaluate("(FORMAT.MEASURE 100 \"cm)", engine: engine).isEmpty)
        #expect(!evaluate("(FORMAT.MEASURE [100 cm])", engine: engine).isEmpty)
        #expect(evaluate("(FORMAT.MEASURE)", engine: engine) == "")
        #endif
    }

    @Test func testParenthesizedDetectPrimitives() {
        let engine = LogoEngine()
        #if os(Linux) || os(Windows)
        for name in ["DETECT.URL", "DETECT.EMAIL", "DETECT.PHONE", "DETECT.DATE", "DETECT.ADDRESS"] {
            let engine = LogoEngine()
            #expect(evaluate("(\(name) \"Visit https://apple.com today)", engine: engine) == "")
            #expect(engine.lastError?.message == "[LOGO Error: \(name) is not supported on this platform]")
        }
        #else
        #expect(!evaluate("(DETECT.URL \"Visit https://apple.com today)", engine: engine).isEmpty)
        #expect(!evaluate("(DETECT.EMAIL \"Contact me at test@example.com)", engine: engine).isEmpty)
        #expect(!evaluate("(DETECT.PHONE \"Call 123-456-7890 now)", engine: engine).isEmpty)
        #expect(!evaluate("(DETECT.DATE \"Meet on 2026-09-03 please)", engine: engine).isEmpty)
        #expect(!evaluate("(DETECT.ADDRESS \"1 Infinite Loop Cupertino CA)", engine: engine).isEmpty)
        #endif
    }
}
