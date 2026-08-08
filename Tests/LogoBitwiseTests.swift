import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

@Suite struct LogoBitwiseTests {
    private func eval(_ expression: String, engine: LogoEngine) -> String {
        let tokens = engine.tokenize(expression)
        var index = 0
        return engine.evaluateExpression(tokens, index: &index)
    }

    private func getExamplePath(filename: String) -> String {
        let repoRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = repoRoot.appendingPathComponent("examples").appendingPathComponent(filename)
        var path = fileURL.path
        #if os(Windows)
        if path.hasPrefix("/") && path.contains(":") {
            path.removeFirst()
        }
        return path.replacingOccurrences(of: "/", with: "\\")
        #else
        return path
        #endif
    }

    private func executeScriptFile(_ filename: String) throws -> String {
        let path = getExamplePath(filename: filename)
        let script = try String(contentsOfFile: path, encoding: .utf8)

        let editor = Editor()
        editor.runLogoScript(script)
        return editor.buffer.lines.joined(separator: "\n")
    }

    @Test func testBitwiseAndOrXorNot() throws {
        let engine = LogoEngine()

        // BIT.AND (6 & 3 = 2)
        #expect(eval("BIT.AND 6 3", engine: engine) == "2")

        // BIT.OR (6 | 3 = 7)
        #expect(eval("BIT.OR 6 3", engine: engine) == "7")

        // BIT.XOR (6 ^ 3 = 5)
        #expect(eval("BIT.XOR 6 3", engine: engine) == "5")

        // BIT.NOT (~0 = -1)
        #expect(eval("BIT.NOT 0", engine: engine) == "-1")
    }

    @Test func testBitwiseShift() throws {
        let engine = LogoEngine()

        // BIT.SHL (1 << 4 = 16)
        #expect(eval("BIT.SHL 1 4", engine: engine) == "16")

        // BIT.SHR (16 >> 2 = 4)
        #expect(eval("BIT.SHR 16 2", engine: engine) == "4")
    }

    @Test func testLeetCode136SingleNumberExample() throws {
        let output = try executeScriptFile("leetcode_136_single_number.logo")
        #expect(output.contains("===_LeetCode_136:_Single_Number_==="))
        #expect(output.contains("single:_4"))
        #expect(output.contains("single:_1"))
    }

    @Test func testLeetCode191NumberOf1BitsExample() throws {
        let output = try executeScriptFile("leetcode_191_number_of_1_bits.logo")
        #expect(output.contains("===_LeetCode_191:_Number_of_1_Bits_==="))
        #expect(output.contains("1_bits:_3"))
        #expect(output.contains("1_bits:_1"))
    }

    @Test func testLeetCode231PowerOfTwoExample() throws {
        let output = try executeScriptFile("leetcode_231_power_of_two.logo")
        #expect(output.contains("===_LeetCode_231:_Power_of_Two_==="))
        #expect(output.contains("power_of_two:_true"))
        #expect(output.contains("power_of_two:_false"))
    }
}
