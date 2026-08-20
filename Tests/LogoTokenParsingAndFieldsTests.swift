import Drawing
import Foundation
@testable import LogoEngine
@testable import LogoLocalization
import Testing

struct LogoTokenParsingAndFieldsTests {
    private func makeEngine() -> LogoEngine {
        let engine = LogoEngine()
        engine.register(plugin: LogoTraditionalChinesePlugin())
        return engine
    }

    @Test
    func testLogoPersonNameFieldParsing() {
        #expect(LogoPersonNameField.parse("given") == .givenName)
        #expect(LogoPersonNameField.parse("first") == .givenName)
        #expect(LogoPersonNameField.parse("firstname") == .givenName)
        #expect(LogoPersonNameField.parse("givenname") == .givenName)

        #expect(LogoPersonNameField.parse("family") == .familyName)
        #expect(LogoPersonNameField.parse("last") == .familyName)
        #expect(LogoPersonNameField.parse("lastname") == .familyName)
        #expect(LogoPersonNameField.parse("familyname") == .familyName)
        #expect(LogoPersonNameField.parse("surname") == .familyName)

        #expect(LogoPersonNameField.parse("middle") == .middleName)
        #expect(LogoPersonNameField.parse("middlename") == .middleName)

        #expect(LogoPersonNameField.parse("prefix") == .prefix)
        #expect(LogoPersonNameField.parse("title") == .prefix)

        #expect(LogoPersonNameField.parse("suffix") == .suffix)
        #expect(LogoPersonNameField.parse("nickname") == .nickname)
        #expect(LogoPersonNameField.parse("nick") == .nickname)

        #expect(LogoPersonNameField.parse("name") == .fullName)
        #expect(LogoPersonNameField.parse("full") == .fullName)
        #expect(LogoPersonNameField.parse("fullname") == .fullName)

        #expect(LogoPersonNameField.parse("style") == .style)
        #expect(LogoPersonNameField.parse("locale") == .locale)
        #expect(LogoPersonNameField.parse("lang") == .locale)

        #expect(LogoPersonNameField.parse("unknown") == nil)
    }

    @Test
    func testLogoFormatOptionFieldParsing() {
        #expect(LogoFormatOptionField.parse("type") == .type)
        #expect(LogoFormatOptionField.parse("kind") == .type)
        #expect(LogoFormatOptionField.parse("style") == .style)
        #expect(LogoFormatOptionField.parse("fmt") == .format)
        #expect(LogoFormatOptionField.parse("format") == .format)
        #expect(LogoFormatOptionField.parse("locale") == .locale)
        #expect(LogoFormatOptionField.parse("loc") == .locale)
        #expect(LogoFormatOptionField.parse("lang") == .language)
        #expect(LogoFormatOptionField.parse("language") == .language)
        #expect(LogoFormatOptionField.parse("currency") == .currency)
        #expect(LogoFormatOptionField.parse("curr") == .currency)
        #expect(LogoFormatOptionField.parse("precision") == .precision)
        #expect(LogoFormatOptionField.parse("prec") == .precision)
        #expect(LogoFormatOptionField.parse("unit") == .unit)
        #expect(LogoFormatOptionField.parse("to") == .unit)
        #expect(LogoFormatOptionField.parse("natural") == .naturalScale)
        #expect(LogoFormatOptionField.parse("scale") == .naturalScale)
        #expect(LogoFormatOptionField.parse("calendar") == .calendar)
        #expect(LogoFormatOptionField.parse("date") == .date)
        #expect(LogoFormatOptionField.parse("time") == .time)

        #expect(LogoFormatOptionField.parse("unknown") == nil)
    }

    @Test
    func testTraditionalChinesePluginFieldParsing() {
        let plugin = LogoTraditionalChinesePlugin()

        #expect(plugin.parsePersonNameField("名") == .givenName)
        #expect(plugin.parsePersonNameField("名字") == .givenName)
        #expect(plugin.parsePersonNameField("姓") == .familyName)
        #expect(plugin.parsePersonNameField("姓氏") == .familyName)
        #expect(plugin.parsePersonNameField("字") == .middleName)
        #expect(plugin.parsePersonNameField("中間名") == .middleName)
        #expect(plugin.parsePersonNameField("稱謂") == .prefix)
        #expect(plugin.parsePersonNameField("頭銜") == .prefix)
        #expect(plugin.parsePersonNameField("後綴") == .suffix)
        #expect(plugin.parsePersonNameField("暱稱") == .nickname)
        #expect(plugin.parsePersonNameField("全名") == .fullName)
        #expect(plugin.parsePersonNameField("姓名") == .fullName)
        #expect(plugin.parsePersonNameField("風格") == .style)
        #expect(plugin.parsePersonNameField("語言") == .locale)

        #expect(plugin.parseFormatOptionField("類型") == .type)
        #expect(plugin.parseFormatOptionField("種類") == .type)
        #expect(plugin.parseFormatOptionField("風格") == .style)
        #expect(plugin.parseFormatOptionField("樣式") == .style)
        #expect(plugin.parseFormatOptionField("語言") == .locale)
        #expect(plugin.parseFormatOptionField("貨幣") == .currency)
        #expect(plugin.parseFormatOptionField("精度") == .precision)
        #expect(plugin.parseFormatOptionField("單位") == .unit)
        #expect(plugin.parseFormatOptionField("轉為") == .unit)
        #expect(plugin.parseFormatOptionField("自然換算") == .naturalScale)
        #expect(plugin.parseFormatOptionField("自動換算") == .naturalScale)
        #expect(plugin.parseFormatOptionField("曆法") == .calendar)
        #expect(plugin.parseFormatOptionField("日期") == .date)
        #expect(plugin.parseFormatOptionField("時間") == .time)
    }

    @Test
    func testLogoEngineTokenParsingHelpers() {
        let engine = makeEngine()

        // 1. Primitive and Operator
        #expect(engine.parsePrimitive("FORWARD") == .forward)
        #expect(engine.parsePrimitive("前進") == .forward)
        #expect(engine.parseOperator("+") == .add)

        // 2. Heading
        #expect(engine.parseHeading("left") == .left)
        #expect(engine.parseHeading("左") == .left)
        #expect(engine.parseHeading("上") == .up)
        #expect(engine.parseHeading("90") == nil)

        // 3. Boolean (strict, round rejected)
        #expect(engine.parseBoolean("true") == true)
        #expect(engine.parseBoolean("1") == true)
        #expect(engine.parseBoolean("false") == false)
        #expect(engine.parseBoolean("0") == false)
        #expect(engine.parseBoolean("round") == nil)
        #expect(engine.parseBoolean("rounded") == nil)
        #expect(engine.parseBoolean("真") == true)
        #expect(engine.parseBoolean("假") == false)

        // 4. BorderStyle and ExitPosition
        #expect(engine.parseBorderStyle("double") == .double)
        #expect(engine.parseBorderStyle("雙線") == .double)
        #expect(engine.parseExitPosition("nw") == .nw)
        #expect(engine.parseExitPosition("西北") == .nw)

        // 5. Calendar and DateTimeStyle
        #expect(engine.parseCalendarIdentifier("roc") == .republicOfChina)
        #expect(engine.parseCalendarIdentifier("民國曆") == .republicOfChina)
        #expect(engine.parseDateTimeStylePreset("short") == .short)
        #expect(engine.parseDateTimeStylePreset("簡短") == .short)

        // 6. NumberStyle, ListType, ByteCountStyle, PersonNameStyle
        #expect(engine.parseNumberStyle("financial") == .financial)
        #expect(engine.parseNumberStyle("金融") == .financial)
        #expect(engine.parseListType("and") == .and)
        #expect(engine.parseListType("以及") == .and)
        #expect(engine.parseByteCountStyle("memory") == .memory)
        #expect(engine.parseByteCountStyle("記憶體") == .memory)
        #expect(engine.parsePersonNameStyle("short") == .short)
        #expect(engine.parsePersonNameStyle("簡短") == .short)

        // 7. Fields
        #expect(engine.parsePersonNameField("first") == .givenName)
        #expect(engine.parsePersonNameField("名") == .givenName)
        #expect(engine.parseFormatOptionField("style") == .style)
        #expect(engine.parseFormatOptionField("風格") == .style)

        // 8. Filler, Keyword, Statement checks
        #expect(engine.isFillerToken("THEN") == true)
        #expect(engine.isFillerToken("則") == true)
        #expect(engine.isFillerToken("FORWARD") == false)

        #expect(engine.isKeyword("SHOW") == true)
        #expect(engine.isKeyword("顯示") == true)
        #expect(engine.isStatementCommand("SHOW") == true)
        #expect(engine.isStatementCommand("SUM") == false)
    }

    #if canImport(Darwin)
    @Test
    func testFormatNameAndBytesWithChinesePluginDictionary() {
        let engine = makeEngine()

        // 1. FORMAT.NAME with Chinese dictionary
        engine.execute("變數 \"name (姓名格式 [ \"姓 \"王 \"名 \"小明 \"稱謂 \"先生 \"風格 \"詳細 \"語言 \"zh-TW ])")
        #expect(engine.variables["name"]?.contains("王") == true)
        #expect(engine.variables["name"]?.contains("小明") == true)

        // 2. FORMAT.BYTES with Chinese dictionary
        engine.execute("變數 \"bytes (位元格式 1048576 [ \"風格 \"記憶體 \"語言 \"zh-TW ])")
        #expect(engine.variables["bytes"]?.contains("MB") == true || engine.variables["bytes"]?.contains("1") == true)

        // 3. FORMAT.NUMBER with Chinese dictionary
        engine.execute("變數 \"num (數字格式 1234.56 [ \"風格 \"貨幣 \"貨幣 \"USD \"語言 \"en-US ])")
        #expect(engine.variables["num"]?.contains("1,234.56") == true || engine.variables["num"]?.contains("$") == true)

        // 4. FORMAT.LIST with Chinese dictionary
        engine.execute("變數 \"list (清單格式 [ \"蘋果 \"香蕉 \"橘子 ] [ \"類型 \"以及 \"語言 \"zh-TW ])")
        #expect(engine.variables["list"]?.contains("蘋果") == true)
        #expect(engine.variables["list"]?.contains("香蕉") == true)

        // 5. FORMAT.MEASUREMENT with Chinese dictionary
        engine.execute("變數 \"m (度量格式 1500 \"m [ \"轉為 \"km \"自然換算 \"假 ])")
        #expect(engine.variables["m"]?.contains("1.5") == true || engine.variables["m"]?.contains("km") == true)
    }
    #endif
}
