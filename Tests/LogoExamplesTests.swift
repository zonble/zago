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
        #expect(output.contains("cipher:_Khoor_Zruog"))
    }

    @Test func testLeetCode001TwoSumExample() throws {
        let output = try executeScriptFile("leetcode_001_two_sum.logo")
        #expect(output.contains("===_LeetCode_001:_Two_Sum_==="))
        #expect(output.contains("[1 2]"))
        #expect(output.contains("[2 3]"))
    }

    @Test func testLeetCode014LongestCommonPrefixExample() throws {
        let output = try executeScriptFile("leetcode_014_longest_common_prefix.logo")
        #expect(output.contains("===_LeetCode_014:_Longest_Common_Prefix_==="))
        #expect(output.contains("prefix:_fl"))
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

    @Test func testLeetCode058LengthOfLastWordExample() throws {
        let output = try executeScriptFile("leetcode_058_length_of_last_word.logo")
        #expect(output.contains("===_LeetCode_058:_Length_of_Last_Word_==="))
        #expect(output.contains("length:_5"))
        #expect(output.contains("length:_4"))
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

    @Test func testLeetCode151ReverseWordsExample() throws {
        let output = try executeScriptFile("leetcode_151_reverse_words.logo")
        #expect(output.contains("===_LeetCode_151:_Reverse_Words_in_a_String_==="))
        #expect(output.contains("reversed:_blue_is_sky_the"))
        #expect(output.contains("reversed:_world_hello"))
    }

    @Test func testLeetCode217ContainsDuplicateExample() throws {
        let output = try executeScriptFile("leetcode_217_contains_duplicate.logo")
        #expect(output.contains("===_LeetCode_217:_Contains_Duplicate_==="))
        #expect(output.contains("duplicate:_true"))
        #expect(output.contains("duplicate:_false"))
    }

    @Test func testLeapYearExample() throws {
        let output = try executeScriptFile("leap_year.logo")
        #expect(output.contains("===_Leap_Year_Checker_==="))
        #expect(output.contains("year:_2000_leap:_true"))
        #expect(output.contains("year:_1900_leap:_false"))
        #expect(output.contains("year:_2024_leap:_true"))
        #expect(output.contains("year:_2023_leap:_false"))
    }

    @Test func testRegexDemoExample() throws {
        let output = try executeScriptFile("regex_demo.logo")
        #expect(output.contains("===_Regex_&_String_Search_Demo_==="))
        #expect(output.contains("email:_user@example.com_valid:_true"))
        #expect(output.contains("email:_invalid_email_valid:_false"))
        #expect(output.contains("masked:___Server_***.***.***.***_date_***-***-***"))
    }

    @Test func testMathDemoExample() throws {
        let output = try executeScriptFile("math_demo.logo")
        #expect(output.contains("===_Math_&_Trigonometry_Demo_==="))
        #expect(output.contains("distance_(0,0)_to_(3,4):_5.000000"))
        #expect(output.contains("sequence:_[1 2 3 4 5]_sum_of_squares:_55"))
        #expect(output.contains("log10(1000):_3.000000_ln(e):_1.000000"))
    }
}
