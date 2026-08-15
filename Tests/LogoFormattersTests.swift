import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

@Suite struct LogoFormattersTests {

    // MARK: - FORMAT.NUMBER Tests

    @Test func testFormatNumberSpellOutChinese() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.NUMBER", "12345", "\"spellout", "\"zh_TW"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("一萬") || res.contains("萬") || res.contains("千"))
    }

    @Test func testFormatNumberSpellOutEnglish() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.NUMBER", "42", "\"spellout", "\"en_US"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.lowercased() == "forty-two")

        index = 0
        let tokensWords = ["FORMAT.NUMBER", "42", "\"words", "\"en_US"]
        let resWords = engine.evaluateExpression(tokensWords, index: &index)
        #expect(resWords.lowercased() == "forty-two")
    }

    @Test func testFormatNumberFinancialChineseDigits() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.NUMBER", "12345", "\"financial", "\"zh_TW"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "壹萬貳仟參佰肆拾伍")

        index = 0
        let tokensCaps = ["FORMAT.NUMBER", "12345", "\"caps", "\"zh_TW"]
        let resCaps = engine.evaluateExpression(tokensCaps, index: &index)
        #expect(resCaps == "壹萬貳仟參佰肆拾伍")

        index = 0
        let tokensCheck = ["FORMAT.NUMBER", "12345", "\"check"]
        let resCheck = engine.evaluateExpression(tokensCheck, index: &index)
        #expect(resCheck == "壹萬貳仟參佰肆拾伍")
    }

    @Test func testFormatNumberFinancialChineseLarge() {
        let res = LogoFormatters.formatFinancialChinese(10050208)
        #expect(res.contains("壹仟") && res.contains("萬") && res.contains("零"))
    }

    @Test func testFormatNumberFinancialZeroAndNegative() {
        #expect(LogoFormatters.formatFinancialChinese(0) == "零")
        #expect(LogoFormatters.formatFinancialChinese(-100) == "負壹佰")
    }

    @Test func testFormatNumberRomanNumerals() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.NUMBER", "2026", "\"roman"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "MMXXVI")

        #expect(LogoFormatters.formatRoman(4) == "IV")
        #expect(LogoFormatters.formatRoman(9) == "IX")
        #expect(LogoFormatters.formatRoman(40) == "XL")
        #expect(LogoFormatters.formatRoman(90) == "XC")
        #expect(LogoFormatters.formatRoman(400) == "CD")
        #expect(LogoFormatters.formatRoman(900) == "CM")
    }

    @Test func testFormatNumberCurrency() {
        let resUSD = LogoFormatters.formatNumber(1234.5, style: .currency, locale: "en_US", currencyCode: "USD", precision: 2)
        #expect(resUSD.contains("1,234.50") || resUSD.contains("$"))

        let resJPY = LogoFormatters.formatNumber(1234, style: .currency, locale: "ja_JP", currencyCode: "JPY", precision: 0)
        #expect(resJPY.contains("1,234") || resJPY.contains("¥"))
    }

    @Test func testFormatNumberPercent() {
        let res = LogoFormatters.formatNumber(0.75, style: .percent, locale: "en_US", precision: 0)
        #expect(res.contains("75") && res.contains("%"))
    }

    @Test func testFormatNumberDecimalGrouping() {
        let res = LogoFormatters.formatNumber(1234567.89, style: .decimal, locale: "en_US", precision: 2)
        #expect(res.contains("1,234,567.89"))
    }

    @Test func testFormatNumberOrdinal() {
        let res1 = LogoFormatters.formatNumber(1, style: .ordinal, locale: "en_US")
        #expect(res1.contains("1st") || res1.contains("1"))

        let res2 = LogoFormatters.formatNumber(2, style: .ordinal, locale: "en_US")
        #expect(res2.contains("2nd") || res2.contains("2"))
    }

    @Test func testFormatNumberPropertyList() {
        let engine = LogoEngine()
        var index = 0
        let tokens = [
            "FORMAT.NUMBER", "1234.5",
            "[", "style", "\"currency", "curr", "\"USD", "locale", "\"en_US", "]"
        ]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("1,234.50") || res.contains("$"))
    }

    // MARK: - FORMAT.LIST Tests

#if !os(Linux) && !os(Windows)
    @Test func testFormatListAndTraditionalChinese() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.LIST", "[", "蘋果", "香蕉", "芭樂", "]", "\"and", "\"zh_TW"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("蘋果") && res.contains("香蕉") && res.contains("芭樂"))
    }

    @Test func testFormatListAndEnglish() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.LIST", "[", "Alice", "Bob", "Charlie", "]", "\"and", "\"en_US"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("Alice") && res.contains("Bob") && res.contains("Charlie"))
        #expect(res.contains("and"))
    }

    @Test func testFormatListOrTraditionalChinese() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.LIST", "[", "蘋果", "香蕉", "芭樂", "]", "\"or", "\"zh_TW"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("或"))
    }

    @Test func testFormatListOrEnglish() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.LIST", "[", "Alice", "Bob", "Charlie", "]", "\"or", "\"en_US"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res.contains("or"))
    }

    @Test func testFormatListUnitNarrow() {
        let res = LogoFormatters.formatList(["A", "B", "C"], type: .unit, locale: "zh_TW")
        #expect(res == "A、B、C")

        let resEn = LogoFormatters.formatList(["A", "B", "C"], type: .unit, locale: "en_US")
        #expect(resEn == "A, B, C")
    }

    @Test func testFormatListEdgeCases() {
        #expect(LogoFormatters.formatList([], type: .and) == "")
        #expect(LogoFormatters.formatList(["Solo"], type: .and) == "Solo")
        #expect(LogoFormatters.formatList(["A", "B"], type: .or, locale: "zh_TW") == "A或B")
        #expect(LogoFormatters.formatList(["A", "B"], type: .or, locale: "en_US") == "A or B")
    }

    #endif

    // MARK: - FORMAT.RELATIVETIME Tests

#if !os(Linux) && !os(Windows)
    @Test func testFormatRelativeTimeYesterdayChinese() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.RELATIVETIME", "-1", "\"day", "\"zh_TW"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "昨天" || res.contains("天前") || res.contains("1天前"))
    }

    @Test func testFormatRelativeTimeDaysAgoEnglish() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.RELATIVETIME", "-3", "\"days", "\"en_US"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "3 days ago")
    }

    @Test func testFormatRelativeTimeFutureHoursEnglish() {
        let engine = LogoEngine()
        var index = 0
        let tokens = ["FORMAT.RELATIVETIME", "2", "\"hours", "\"en_US"]
        let res = engine.evaluateExpression(tokens, index: &index)
        #expect(res == "in 2 hours")
    }

    @Test func testFormatRelativeTimeTargetDate() {
        let target = Date().addingTimeInterval(-86400 * 2) // 2 days ago
        let res = LogoFormatters.formatRelativeDate(target: target, locale: "en_US")
        #expect(res.contains("2 days ago") || res.contains("days ago"))
    }

    #endif

    // MARK: - FORMAT.BYTES Tests

    @Test func testFormatBytesSizes() {
        let engine = LogoEngine()
        var index = 0
        let tokens1MB = ["FORMAT.BYTES", "1048576"]
        let res1MB = engine.evaluateExpression(tokens1MB, index: &index)
        #expect(res1MB.contains("1 MB") || res1MB.contains("MB"))

        index = 0
        let tokens1GB = ["FORMAT.BYTES", "1073741824"]
        let res1GB = engine.evaluateExpression(tokens1GB, index: &index)
        #expect(res1GB.contains("GB"))
    }

    @Test func testFormatBytesExact() {
        let res = LogoFormatters.formatBytes(1048576, style: .bytes, locale: "en_US")
        #expect(res.contains("1,048,576 bytes"))
    }

    @Test func testFormatBytesMemory() {
        let res = LogoFormatters.formatBytes(1048576, style: .memory)
        #expect(res.contains("MB") || res.contains("1 MB"))
    }

    // MARK: - Variadic Call Tests

    @Test func testVariadicParenthesesFormatters() {
        let engine = LogoEngine()
        var index = 0
        let tokensNum = ["(", "FORMAT.NUMBER", "2026", "\"roman", ")"]
        let resNum = engine.evaluateExpression(tokensNum, index: &index)
        #expect(resNum == "MMXXVI")

#if !os(Linux) && !os(Windows)
        index = 0
        let tokensList = ["(", "FORMAT.LIST", "[", "One", "Two", "]", "\"or", "\"en_US", ")"]
        let resList = engine.evaluateExpression(tokensList, index: &index)
        #expect(resList == "One or Two")
#endif

        index = 0
        let tokensBytes = ["(", "FORMAT.BYTES", "1048576", "\"bytes", "\"en_US", ")"]
        let resBytes = engine.evaluateExpression(tokensBytes, index: &index)
        #expect(resBytes.contains("1,048,576 bytes"))
    }

    // MARK: - Implicit Return Tests

    @Test func testSingleExpressionProcedureImplicitReturn() {
        let engine = LogoEngine()
        engine.execute("TO 大寫 :x FORMAT.NUMBER :x \"bank \"zh-TW END")

        var index = 0
        let callTokens = ["大寫", "2324234232"]
        let res = engine.evaluateExpression(callTokens, index: &index)
        #expect(res == "貳拾參億貳仟肆佰貳拾參萬肆仟貳佰參拾貳")

        engine.execute("TO 雙倍 :n :n * 2 END")

        index = 0
        let callDouble = ["雙倍", "21"]
        let resDouble = engine.evaluateExpression(callDouble, index: &index)
        #expect(resDouble == "42")
    }

    // MARK: - Procedure Docstring & Help Tests

    @Test func testProcedureDocstringsAndDoc() {
        let engine = LogoEngine()
        engine.execute("TO 大寫 :x \"將阿拉伯數字轉為繁體中文公文大寫\" FORMAT.NUMBER :x \"bank \"zh-TW END")

        #expect(engine.customProcedures["大寫"]?.docstring == "將阿拉伯數字轉為繁體中文公文大寫")

        var index = 0
        let docTokens = ["DOC", "\"大寫"]
        let docRes = engine.evaluateExpression(docTokens, index: &index)
        #expect(docRes == "將阿拉伯數字轉為繁體中文公文大寫")

        // Multi-line body docstring
        engine.execute("""
        TO 雙倍 :n
          "計算數值的雙倍乘積"
          :n * 2
        END
        """)

        #expect(engine.customProcedures["雙倍"]?.docstring == "計算數值的雙倍乘積")

        // Unquoted procedure symbol directly
        index = 0
        let unquotedDocTokens = ["DOC", "大寫"]
        let unquotedDocRes = engine.evaluateExpression(unquotedDocTokens, index: &index)
        #expect(unquotedDocRes == "將阿拉伯數字轉為繁體中文公文大寫")

        index = 0
        let unquotedDocDoubleTokens = ["DOC", "雙倍"]
        let unquotedDocDoubleRes = engine.evaluateExpression(unquotedDocDoubleTokens, index: &index)
        #expect(unquotedDocDoubleRes == "計算數值的雙倍乘積")
    }
}
