import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

@Suite struct LogoDateTimeTests {
    @Test func testBasicDateDefault() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["DATE"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(!res.isEmpty)
        let parts = res.split(separator: "-")
        #expect(parts.count == 3)
    }

    @Test func testBasicTimeDefault() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["TIME"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(!res.isEmpty)
        let parts = res.split(separator: ":")
        #expect(parts.count == 3)
    }

    @Test func testBasicDateTimeDefault() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["DATETIME"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(!res.isEmpty)
        #expect(res.contains("-"))
        #expect(res.contains(":"))
    }

    @Test func testSmartPolymorphicROCArguments() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["DATE", "\"zh_TW", "\"roc"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("民國") || res.contains("115"))
    }

    @Test func testSmartPolymorphicSingleROCArgument() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["DATE", "\"roc"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("民國") || res.contains("115"))
    }

    @Test func testSmartPolymorphicJapaneseArgument() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["DATE", "\"japanese"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("令和") || res.contains("8年"))
    }

    @Test func testCustomPatternFormatting() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)  // 2023-11-14 22:13:20 UTC
        let formatted = LogoDateTimeFormatter.format(
            date: fixedDate,
            mode: .date,
            formatSpec: "yyyy/MM/dd",
            localeSpec: "en_US",
            timeZoneSpec: "UTC",
            calendarSpec: "gregorian"
        )
        #expect(formatted == "2023/11/14")
    }

    @Test func testISO8601Formatting() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let formatted = LogoDateTimeFormatter.format(
            date: fixedDate,
            mode: .dateTime,
            formatSpec: "iso8601",
            localeSpec: "en_US",
            timeZoneSpec: "UTC"
        )
        #expect(formatted == "2023-11-14T22:13:20Z")
    }

    @Test func testMinguoROCCalendar() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)  // 2023-11-14 (民國112年)
        let formatted = LogoDateTimeFormatter.format(
            date: fixedDate,
            mode: .date,
            formatSpec: "GGGy年M月d日",
            localeSpec: "zh_TW",
            timeZoneSpec: "UTC",
            calendarSpec: "roc"
        )
        #expect(formatted.contains("112") || formatted.contains("民國"))
    }

    @Test func testTimeZonesAndOffsets() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)  // 22:13:20 UTC -> 07:13:20 (+09:00 next day)
        let formattedTokyo = LogoDateTimeFormatter.format(
            date: fixedDate,
            mode: .time,
            formatSpec: "HH:mm:ss",
            timeZoneSpec: "Asia/Tokyo"
        )
        #expect(formattedTokyo == "07:13:20")

        let formattedOffset = LogoDateTimeFormatter.format(
            date: fixedDate,
            mode: .time,
            formatSpec: "HH:mm:ss",
            timeZoneSpec: "+0900"
        )
        #expect(formattedOffset == "07:13:20")
    }

    @Test func testEvaluatorPropertyList() {
        let engine = LogoEngine()
        var index = 0
        let tokens = [
            "DATE",
            "[", "format", "\"yyyy-MM-dd", "tz", "\"UTC", "calendar", "\"gregorian", "]",
        ]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(!res.isEmpty)
        #expect(res.split(separator: "-").count == 3)
    }

    @Test func testEvaluatorVariadicParentheses() {
        let engine = LogoEngine()
        var index = 0
        let tokens = [
            "(", "DATE", "\"iso8601", "\"en_US", "\"UTC", ")",
        ]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(!res.isEmpty)
        #expect(res.hasSuffix("Z"))
    }

    @Test func testDateFormatPrimitiveWithList() {
        let engine = LogoEngine()
        var index = 0
        let tokens = [
            "FORMAT.DATE", "[", "2026", "12", "25", "]", "\"japanese",
        ]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("令和8年") || res.contains("12月25日"))
    }

    @Test func testDateFormatPrimitiveWithISOString() {
        let engine = LogoEngine()
        var index = 0
        let tokens = [
            "FORMAT.DATE", "\"2026-08-31T15:00:00Z", "\"yyyy/MM/dd", "\"UTC",
        ]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "2026/08/31")
    }

    @Test func testDateAddPrimitive() {
        let engine = LogoEngine()
        var index = 0
        let tokens = [
            "DATE.ADD", "\"2026-08-15", "7", "\"days",
        ]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "2026-08-22")
    }

    @Test func testDateDiffPrimitive() {
        let engine = LogoEngine()
        var index = 0
        let tokens = [
            "DATE.DIFF", "\"2026-12-31", "\"2026-08-15", "\"days",
        ]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "138")
    }

    @Test func testCustomCommandProcedureActsAsStatementBoundary() {
        let script = """
        to li :x type word "- " :x end
        make "today [2026 8 18]
        li FORMAT.DATE :today "full "en_US
        li FORMAT.DATE :today "roc
        li FORMAT.DATE (DATE.ADD :today 2 days) "roc
        """
        final class BufferDelegate: LogoEngineDelegate, @unchecked Sendable {
            var lines: [String] = []
            func logoEngine(_ engine: LogoEngine, performAction action: LogoEditorAction) {
                if case .insertText(let text) = action {
                    lines.append(text)
                }
            }
            func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> LogoEditorQueryResult? { nil }
        }
        let delegate = BufferDelegate()
        let engine = LogoEngine(delegate: delegate)
        engine.execute(script)
        #expect(delegate.lines.count == 3)
        #expect(delegate.lines[0] == "- Tuesday, August 18, 2026")
        #expect(delegate.lines[1] == "- 民國 115年8月18日")
        #expect(delegate.lines[2] == "- 民國 2026年8月20日")
    }

    @Test func testCustomReporterProcedureEvaluatesAsArgument() {
        let script = """
        to mydate output [2026 8 18] end
        to myfmt output "roc end
        make "result FORMAT.DATE mydate myfmt
        """
        let engine = LogoEngine()
        engine.execute(script)
        #expect(engine.variables["result"] == "民國 115年8月18日")
    }
}
