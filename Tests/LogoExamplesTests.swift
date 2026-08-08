import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

@Suite struct LogoExamplesTests {
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

    @Test func testBrainfuckExample() throws {
        let output = try executeScriptFile("brainfuck.logo")
        #expect(output.contains("===_Brainfuck_Interpreter_Demo_==="))
        #expect(output.contains("Code:_+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++._Output:_"))
    }

    @Test func testFizzBuzzExample() throws {
        let output = try executeScriptFile("fizzbuzz.logo")
        #expect(output.contains("===_FizzBuzz_Demo_(1_to_15)_==="))
        #expect(output.contains(" 3:_Fizz"))
        #expect(output.contains(" 5:_Buzz"))
        #expect(output.contains("15:_FizzBuzz"))
    }

    @Test func testCaesarCipherExample() throws {
        let output = try executeScriptFile("caesar_cipher.logo")
        #expect(output.contains("===_Caesar_Cipher_Demo_==="))
        #expect(output.contains("original:_Hello_World"))
        #expect(output.contains("cipher:_KhoorbZruog"))
    }

    @Test func testLeetCode001TwoSumExample() throws {
        let output = try executeScriptFile("leetcode_001_two_sum.logo")
        #expect(output.contains("===_LeetCode_001:_Two_Sum_==="))
        #expect(output.contains("[1 2]"))
        #expect(output.contains("[2 3]"))
    }

    @Test func testLeetCode020ValidParenthesesExample() throws {
        let output = try executeScriptFile("leetcode_020_valid_parentheses.logo")
        #expect(output.contains("===_LeetCode_020:_Valid_Parentheses_==="))
        #expect(output.contains("valid:_true"))
        #expect(output.contains("valid:_false"))
    }

    @Test func testLeetCode053MaxSubarrayExample() throws {
        let output = try executeScriptFile("leetcode_053_max_subarray.logo")
        #expect(output.contains("===_LeetCode_053:_Maximum_Subarray_(Kadane's_Algorithm)_==="))
        #expect(output.contains("max_sum:_6"))
        #expect(output.contains("max_sum:_23"))
    }

    @Test func testLeetCode070ClimbingStairsExample() throws {
        let output = try executeScriptFile("leetcode_070_climbing_stairs.logo")
        #expect(output.contains("===_LeetCode_070:_Climbing_Stairs_==="))
        #expect(output.contains("n:_5_ways:_8"))
        #expect(output.contains("n:_8_ways:_34"))
    }

    @Test func testLeetCode125ValidPalindromeExample() throws {
        let output = try executeScriptFile("leetcode_125_valid_palindrome.logo")
        #expect(output.contains("===_LeetCode_125:_Valid_Palindrome_==="))
        #expect(output.contains("palindrome:_true"))
    }

    @Test func testLeetCode217ContainsDuplicateExample() throws {
        let output = try executeScriptFile("leetcode_217_contains_duplicate.logo")
        #expect(output.contains("===_LeetCode_217:_Contains_Duplicate_==="))
        #expect(output.contains("duplicate:_true"))
        #expect(output.contains("duplicate:_false"))
    }
}
