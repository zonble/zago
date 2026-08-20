import Config
import Drawing
@testable import Editor
import Foundation
import LogoEngine
import LogoLocalization
import Testing

@Suite("LogoLocalizationTests")
struct LogoLocalizationTests {
    private func makeEngine() -> LogoEngine {
        let registry = LogoPluginRegistry(plugins: [LogoTraditionalChinesePlugin()])
        return LogoEngine(pluginRegistry: registry)
    }

    @Test
    func testTraditionalChineseDrawingAndTyping() {
        let lines = LogoExecutionService.render(
            script: """
            畫框 10 4
            前往 2 1
            打字 "你好
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        #expect(!lines.isEmpty)
        let joined = lines.joined(separator: "\n")
        #expect(joined.contains("┌"))
        #expect(joined.contains("你好"))
    }

    @Test
    func testTraditionalChineseRepeatLoop() {
        let lines = LogoExecutionService.render(
            script: """
            重複 3 [ 打字 "A ]
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        let joined = lines.joined(separator: "\n")
        #expect(joined.contains("AAA"))
    }

    @Test
    func testTraditionalChineseIfConditionAndOperators() {
        let engine = makeEngine()
        engine.execute("""
        如果 10 大於 5 [ 變數 "x "Pass ] [ 變數 "x "Fail ]
        """)
        #expect(engine.variables["x"] == "Pass")

        engine.execute("""
        如果 3 等於 3 [ 變數 "y "Equal ]
        """)
        #expect(engine.variables["y"] == "Equal")
    }

    @Test
    func testTraditionalChineseMathPrimitives() {
        let engine = makeEngine()
        engine.execute("""
        變數 "sumResult 總和 15 25
        變數 "diffResult 相差 50 20
        變數 "prodResult 相積 6 7
        """)
        #expect(engine.variables["sumresult"] == "40")
        #expect(engine.variables["diffresult"] == "30")
        #expect(engine.variables["prodResult".lowercased()] == "42")
    }

    @Test
    func testTraditionalChineseBoxStylesAndExitPositions() {
        let lines = LogoExecutionService.render(
            script: """
            畫框 "標題 20 雙線
            打字 "內容
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        let joined = lines.joined(separator: "\n")
        #expect(joined.contains("╔") || joined.contains("═"))
        #expect(joined.contains("標題"))
        #expect(joined.contains("內容"))

        let dashedLines = LogoExecutionService.render(
            script: """
            畫框 10 4 三段虛線
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        let dashedJoined = dashedLines.joined(separator: "\n")
        #expect(dashedJoined.contains("┄"))

        let doubleDashLines = LogoExecutionService.render(
            script: """
            畫框 10 4 二段虛線
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        let doubleDashJoined = doubleDashLines.joined(separator: "\n")
        #expect(doubleDashJoined.contains("╌"))
    }

    @Test
    func testInteractiveEditorExecutionWithChineseCommands() {
        let editor = Editor(language: .zh_TW)
        editor.runLogoScript("畫框 10 4")
        editor.runLogoScript("打字 \"你好")
        let text = editor.buffer.lines.joined(separator: "\n")
        #expect(text.contains("┌"))
        #expect(text.contains("你好"))
    }

    @Test
    func testCtrlQEvalLogoCodeWithChineseScript() {
        let editor = Editor(language: .zh_TW)
        editor.buffer.lines = ["畫框 12 4", "打字 \"世界"]
        editor.buffer.lineIndex = 0
        editor.evalLogoCode()
        let text = editor.buffer.lines.joined(separator: "\n")
        #expect(text.contains("┌"))
    }

    @Test
    func testZagorcLoadDialectDirective() {
        final class MemoryProvider: ConfigFileProvider, @unchecked Sendable {
            var files: [String: String] = [:]
            func fileExists(atPath path: String) -> Bool { files[path] != nil }
            func readString(atPath path: String) throws -> String {
                guard let content = files[path] else {
                    throw NSError(domain: "Test", code: 404)
                }
                return content
            }
            func writeString(_ content: String, toPath path: String) throws {
                files[path] = content
            }
            func homeDirectoryPath() -> String { "/home/user" }
            func currentDirectoryPath() -> String { "/workspace" }
            func resolvePath(_ path: String, relativeTo: String?) -> String { path }
        }

        let provider = MemoryProvider()
        provider.files["/home/user/.zagorc"] = """
        load dialect zh-TW
        set lang zh_TW
        """

        let loader = ConfigLoader(provider: provider)
        let config = loader.loadConfig()
        #expect(config.loadedDialects.contains("zh-TW"))
        #expect(config.syntaxErrorCount == 0)
    }

    @Test
    func testChineseTextTransformsAndDetectors() {
        let engine = makeEngine()
        engine.execute("""
        變數 "base64 Base64編碼 "hello
        變數 "urls 偵測網址 "https://example.com
        """)
        #expect(engine.variables["base64"] == "aGVsbG8=")
        #if canImport(Darwin)
            #expect(engine.variables["urls"] == "[https://example.com]")
        #else
            #expect(engine.variables["urls"] == "")
        #endif
    }

    @Test
    func testChineseHigherOrderAndDataStructures() {
        let engine = makeEngine()
        engine.execute("""
        變數 "nums [ 1 2 3 4 ]
        變數 "firstNum 第一個 :nums
        變數 "rest 除了第一個 :nums
        變數 "reversed 反轉 :nums
        變數 "isLst 列表? :nums
        """)
        #expect(engine.variables["firstnum"] == "1")
        #expect(engine.variables["rest"] == "[2 3 4]")
        #expect(engine.variables["reversed"] == "[4 3 2 1]")
        #expect(engine.variables["islst"] == "true")
    }

    @Test
    func testForeachWithChineseDrawingBlock() {
        let lines = LogoExecutionService.render(
            script: """
            遍歷 [ "roc" "japan" "thai" ] [ 畫框 ? ]
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        let joined = lines.joined(separator: "\n")
        #expect(joined.contains("roc"))
        #expect(joined.contains("japan"))
        #expect(joined.contains("thai"))
        #expect(joined.contains("┌"))
    }

    @Test
    func testCustomProcedureInChinese() {
        let engine = makeEngine()
        engine.execute("""
        定義 "問候 [ [ 名字 ] [
            輸出 接字 "你好， :名字
        ] ]
        變數 "msg 問候 "世界
        """)
        #expect(engine.variables["msg"] == "你好，世界")
    }

    @Test
    func testTraditionalChineseDateTimeAndCalendarKeywords() {
        let lines = LogoExecutionService.render(
            script: """
            換行 打字 轉簡體 現在時間 full "民國曆
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        #expect(!lines.isEmpty)
        let joined = lines.joined(separator: "\n")
        #expect(!joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test
    func testLogoParserPluginProtocolDefaultImplementations() {
        struct MinimalPlugin: LogoParserPlugin {
            let id = "minimal"
        }

        let plugin = MinimalPlugin()
        #expect(plugin.id == "minimal")
        #expect(plugin.displayName == "minimal")
        #expect(plugin.aliases.isEmpty)
        #expect(plugin.parsePrimitive("token") == nil)
        #expect(plugin.parseOperator("token") == nil)
        #expect(plugin.parseHeading("token") == nil)
        #expect(plugin.parseBoolean("token") == nil)
        #expect(plugin.parseExitPosition("token") == nil)
        #expect(plugin.parseBorderStyle("token") == nil)
        #expect(plugin.parseCalendarIdentifier("token") == nil)
        #expect(plugin.parseDateTimeStylePreset("token") == nil)
        #expect(plugin.parseNumberStyle("token") == nil)
        #expect(plugin.parseListType("token") == nil)
        #expect(plugin.parseByteCountStyle("token") == nil)
        #expect(plugin.parsePersonNameStyle("token") == nil)
        #expect(plugin.keywordAliases.isEmpty)
    }

    @Test
    func testTraditionalChinesePluginAllParserMethods() {
        let plugin = LogoTraditionalChinesePlugin()
        #expect(plugin.id == "zh-TW")
        #expect(plugin.displayName.contains("繁體中文"))
        #expect(plugin.aliases.contains("zh-Hant"))

        // 1. Primitive
        #expect(plugin.parsePrimitive("畫框") == .drawBox)
        #expect(plugin.parsePrimitive("打字") == .type)

        // 2. Operator
        #expect(plugin.parseOperator("大於") == .greaterThan)
        #expect(plugin.parseOperator("等於") == .equal)

        // 3. Heading
        #expect(plugin.parseHeading("北") == .up)
        #expect(plugin.parseHeading("東") == .right)

        // 4. Boolean
        #expect(plugin.parseBoolean("真") == true)
        #expect(plugin.parseBoolean("假") == false)

        // 5. ExitPosition
        #expect(plugin.parseExitPosition("東北") == .ne)
        #expect(plugin.parseExitPosition("西南") == .sw)

        // 6. BorderStyle
        #expect(plugin.parseBorderStyle("雙線") == .double)
        #expect(plugin.parseBorderStyle("三段虛線") == .tripleDash)

        // 7. CalendarIdentifier
        #expect(plugin.parseCalendarIdentifier("民國曆") == .republicOfChina)
        #expect(plugin.parseCalendarIdentifier("和曆") == .japanese)
        #expect(plugin.parseCalendarIdentifier("農曆") == .chinese)

        // 8. DateTimeStylePreset
        #expect(plugin.parseDateTimeStylePreset("完整") == .long)
        #expect(plugin.parseDateTimeStylePreset("簡短") == .short)

        // 9. NumberStyle
        #expect(plugin.parseNumberStyle("金融") == .financial)
        #expect(plugin.parseNumberStyle("中文數字") == .spellout)

        // 10. ListType
        #expect(plugin.parseListType("且") == .and)
        #expect(plugin.parseListType("或") == .or)

        // 11. ByteCountStyle
        #expect(plugin.parseByteCountStyle("檔案大小") == .file)
        #expect(plugin.parseByteCountStyle("記憶體") == .memory)

        // 12. PersonNameStyle
        #expect(plugin.parsePersonNameStyle("簡短") == .short)
        #expect(plugin.parsePersonNameStyle("詳細") == .long)

        // 13. KeywordAliases
        #expect(!plugin.keywordAliases.isEmpty)
        #expect(plugin.keywordAliases.contains("畫框"))
        #expect(plugin.keywordAliases.contains("民國曆"))
    }

    @Test
    func testPluginRegistryAndEngineComprehensiveDelegation() {
        let registry = LogoPluginRegistry()
        let plugin = LogoTraditionalChinesePlugin()
        registry.register(plugin)

        #expect(registry.contains(id: "zh-TW"))
        #expect(registry.contains(id: "zh-Hant"))
        #expect(!registry.contains(id: "fr"))

        #expect(registry.parsePrimitive("畫框") == .drawBox)
        #expect(registry.parseOperator("大於") == .greaterThan)
        #expect(registry.parseHeading("北") == .up)
        #expect(registry.parseBoolean("真") == true)
        #expect(registry.parseExitPosition("東北") == .ne)
        #expect(registry.parseBorderStyle("雙線") == .double)
        #expect(registry.parseCalendarIdentifier("民國曆") == .republicOfChina)
        #expect(registry.parseDateTimeStylePreset("完整") == .long)
        #expect(registry.parseNumberStyle("金融") == .financial)
        #expect(registry.parseListType("且") == .and)
        #expect(registry.parseByteCountStyle("檔案大小") == .file)
        #expect(registry.parsePersonNameStyle("簡短") == .short)
        #expect(!registry.allKeywordAliases.isEmpty)

        let engine = LogoEngine(pluginRegistry: registry)
        #expect(engine.parseHeading("北") == .up)
        #expect(engine.parseBoolean("真") == true)
        #expect(engine.parseBorderStyle("雙線") == .double)
        #expect(engine.parseCalendarIdentifier("民國曆") == .republicOfChina)
        #expect(engine.parseDateTimeStylePreset("完整") == .long)

        registry.unregister(id: "zh-TW")
        #expect(!registry.contains(id: "zh-TW"))
        #expect(registry.parsePrimitive("畫框") == nil)

        registry.register(plugin)
        #expect(registry.contains(id: "zh-TW"))
        registry.clear()
        #expect(registry.registeredPlugins.isEmpty)
    }

    @Test
    func testTraditionalChineseEndToEndExecutionForAllDomains() {
        let engine = makeEngine()

        // 1. Number Style formatting
        engine.execute("變數 \"numRes 數字格式 100 \"金融")
        #expect(engine.variables["numres"]?.contains("壹") == true || engine.variables["numres"]?.contains("佰") == true || engine.variables["numres"] == "100")

        // 2. List formatting
        engine.execute("變數 \"itemRes 列表格式 [ \"蘋果 \"香蕉 ] \"且")
        #expect(engine.variables["itemres"]?.contains("蘋果") == true)

        // 3. Byte Count formatting
        engine.execute("變數 \"byteRes 檔案大小格式 1048576 \"檔案大小")
        #expect(engine.variables["byteres"]?.contains("MB") == true || engine.variables["byteres"]?.contains("1") == true)

        // 4. Person name formatting
        #if canImport(Darwin)
        engine.execute("變數 \"nameRes 姓名格式 [ \"姓 \"王 \"名 \"小明 ] \"簡短")
        #expect(engine.variables["nameres"]?.contains("王") == true)
        #endif

        // 5. Calendar convert
        engine.execute("變數 \"calRes 轉換曆法 \"2026-08-19 \"民國曆")
        #expect(engine.variables["calres"]?.contains("民國") == true || engine.variables["calres"]?.contains("115") == true)
    }

    @Test
    func testTraditionalChineseFillerTokens() {
        let engine = makeEngine()

        // 1. 稱 1 為 "a (filler token "為")
        engine.execute("稱 1 為 \"a")
        #expect(engine.variables["a"] == "1")

        // 2. 稱 2 為 :b (filler token "為" with variable colon)
        engine.execute("稱 2 為 :b")
        #expect(engine.variables["b"] == "2")

        // 3. 重複 3 次 [ 打字 "A ] (filler token "次")
        let lines = LogoExecutionService.render(
            script: """
            重複 3 次 [ 打字 "A ]
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        let joined = lines.joined(separator: "\n")
        #expect(joined.contains("AAA"))

        // 4. 如果 10 大於 5 則 [ 變數 "flag "Pass ] (filler token "則")
        engine.execute("如果 10 大於 5 則 [ 變數 \"flag \"Pass ]")
        #expect(engine.variables["flag"] == "Pass")

        // 5. Quoted string literals matching filler tokens should NOT be skipped
        let renderFor = LogoExecutionService.render(
            script: """
            打字 "為
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        #expect(renderFor.joined(separator: "\n").contains("為"))

        // 6. Variable named "為" should work normally
        engine.execute("變數 \"為 999")
        #expect(engine.variables["為"] == "999")
        engine.execute("變數 \"c :為")
        #expect(engine.variables["c"] == "999")

        // 7. Plugin registry filler checks
        #expect(engine.isFillerToken("為"))
        #expect(engine.isFillerToken("成"))
        #expect(engine.isFillerToken("次"))
        #expect(engine.isFillerToken("到"))
        #expect(engine.isFillerToken("至"))
        #expect(engine.isFillerToken("則"))
        #expect(!engine.isFillerToken("畫框"))
    }

    @Test
    func testQuotedKeywordLiteralDoesNotResolveToPrimitiveOrOperator() {
        let lines = LogoExecutionService.render(
            script: """
            如果 (大於 3 2) [ 打字 "大於 ]
            """,
            plugins: [LogoTraditionalChinesePlugin()]
        )
        let joined = lines.joined(separator: "\n")
        #expect(joined.contains("大於"))
    }

    @Test
    func testPluginParsePrimitiveAndOperatorPrefixGuards() {
        let plugin = LogoTraditionalChinesePlugin()

        // Bare tokens
        #expect(plugin.parsePrimitive("畫框") == .drawBox)
        #expect(plugin.parsePrimitive("打字") == .type)
        #expect(plugin.parseOperator("大於") == .greaterThan)
        #expect(plugin.parseOperator("等於") == .equal)

        // Quoted words, single-quoted strings, and colon variable references must be nil
        #expect(plugin.parsePrimitive("\"畫框") == nil)
        #expect(plugin.parsePrimitive("\"畫框\"") == nil)
        #expect(plugin.parsePrimitive("'畫框'") == nil)
        #expect(plugin.parsePrimitive(":畫框") == nil)

        #expect(plugin.parseOperator("\"大於") == nil)
        #expect(plugin.parseOperator("\"大於\"") == nil)
        #expect(plugin.parseOperator("'大於'") == nil)
        #expect(plugin.parseOperator(":大於") == nil)
    }

    @Test
    func testUnifiedChineseIfAndIfElseDualBranchAndTernary() {
        let engine = makeEngine()

        // 1. Single-branch 如果
        engine.execute("變數 \"flag \"Init")
        engine.execute("如果 10 大於 5 [ 變數 \"flag \"Pass1 ]")
        #expect(engine.variables["flag"] == "Pass1")

        engine.execute("如果 2 大於 5 [ 變數 \"flag \"Failed ]")
        #expect(engine.variables["flag"] == "Pass1")

        // 2. Dual-branch 如果 (consecutive blocks)
        engine.execute("如果 10 大於 5 [ 變數 \"flag \"TrueBranch ] [ 變數 \"flag \"FalseBranch ]")
        #expect(engine.variables["flag"] == "TrueBranch")

        engine.execute("如果 2 大於 5 [ 變數 \"flag \"TrueBranch ] [ 變數 \"flag \"FalseBranch ]")
        #expect(engine.variables["flag"] == "FalseBranch")

        // 3. Dual-branch 如果 with filler tokens (則 / 否則 / 不然)
        engine.execute("如果 10 大於 5 則 [ 變數 \"flag \"TrueWithFiller ] 否則 [ 變數 \"flag \"FalseWithFiller ]")
        #expect(engine.variables["flag"] == "TrueWithFiller")

        engine.execute("如果 2 大於 5 則 [ 變數 \"flag \"TrueWithFiller ] 否則 [ 變數 \"flag \"FalseWithFiller ]")
        #expect(engine.variables["flag"] == "FalseWithFiller")

        engine.execute("如果 2 大於 5 則 [ 變數 \"flag \"TrueWithFiller ] 不然 [ 變數 \"flag \"FalseWithOtherwise ]")
        #expect(engine.variables["flag"] == "FalseWithOtherwise")

        // 4. Natural Chinese if synonyms (要是 / 假如 / 若是)
        engine.execute("要是 10 大於 5 [ 變數 \"flag \"IfSynonymTrue ] [ 變數 \"flag \"IfSynonymFalse ]")
        #expect(engine.variables["flag"] == "IfSynonymTrue")

        engine.execute("假如 2 大於 5 則 [ 變數 \"flag \"IfSynonymTrue ] 否則 [ 變數 \"flag \"IfSynonymFalse ]")
        #expect(engine.variables["flag"] == "IfSynonymFalse")

        // 5. Parenthesized ternary expression reporter
        engine.execute("變數 \"res1 (如果 10 大於 5 [ \"通過 ] [ \"不通過 ])")
        #expect(engine.variables["res1"] == "通過")

        engine.execute("變數 \"res2 (如果 2 大於 5 則 [ \"通過 ] 否則 [ \"不通過 ])")
        #expect(engine.variables["res2"] == "不通過")

        engine.execute("變數 \"res3 (要是 10 大於 5 [ \"通過 ] [ \"不通過 ])")
        #expect(engine.variables["res3"] == "通過")
    }
}
