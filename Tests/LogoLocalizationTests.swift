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
        #expect(engine.variables["urls"] == "[https://example.com]")
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
}
