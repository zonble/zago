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
        #expect(output.contains("indices:_[1 2]"))
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
    }

    @Test func testLeetCode053MaxSubarrayExample() throws {
        let output = try executeScriptFile("leetcode_053_max_subarray.logo")
        #expect(output.contains("===_LeetCode_053:_Maximum_Subarray_(Kadane's_Algorithm)_==="))
        #expect(output.contains("max_sum:_6"))
    }

    @Test func testLeetCode058LengthOfLastWordExample() throws {
        let output = try executeScriptFile("leetcode_058_length_of_last_word.logo")
        #expect(output.contains("===_LeetCode_058:_Length_of_Last_Word_==="))
        #expect(output.contains("length:_5"))
    }

    @Test func testLeetCode070ClimbingStairsExample() throws {
        let output = try executeScriptFile("leetcode_070_climbing_stairs.logo")
        #expect(output.contains("===_LeetCode_070:_Climbing_Stairs_==="))
        #expect(output.contains("n:_5_ways:_8"))
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
    }

    @Test func testLeetCode217ContainsDuplicateExample() throws {
        let output = try executeScriptFile("leetcode_217_contains_duplicate.logo")
        #expect(output.contains("===_LeetCode_217:_Contains_Duplicate_==="))
        #expect(output.contains("duplicate:_true"))
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

    @Test func testFunctionalDemoExample() throws {
        let output = try executeScriptFile("functional_demo.logo")
        #expect(output.contains("===_Functional_Programming_Demo_==="))
        #expect(output.contains("squares:__[1 4 9 16 25]"))
        #expect(output.contains("evens:____[2 4]"))
        #expect(output.contains("sum:______15"))
        #expect(output.contains("map_se:___[1 10 2 20 3 30]"))
    }

    @Test func testControlFlowDemoExample() throws {
        let output = try executeScriptFile("control_flow_demo.logo")
        #expect(output.contains("===_Control_Flow_&_Exception_Demo_==="))
        #expect(output.contains("score:_95_level:_A"))
        #expect(output.contains("score:_82_level:_B"))
        #expect(output.contains("score:_58_level:_F"))
        #expect(output.contains("temperature:_32_state:_Liquid"))
        #expect(output.contains("TEST_passed"))
        #expect(output.contains("found_'cherry'_at_index:_3"))
        #expect(output.contains("dotimes_counter:_0_1_2_"))
    }

    @Test func testAsciiDrawingDemoExample() throws {
        let output = try executeScriptFile("ascii_drawing_demo.logo")
        #expect(output.contains("===_ASCII_Drawing_&_Diagram_Demo_==="))
        #expect(output.contains("API_Gateway"))
        #expect(output.contains("Database_Node"))
    }

    @Test func testCJKTextDemoExample() throws {
        let output = try executeScriptFile("cjk_text_demo.logo")
        #expect(output.contains("===_CJK_Text_Transformation_Demo_==="))
        #expect(output.contains("hans:_高阶语言与函数式编程"))
        #expect(output.contains("back:_高階語言與函數式編程"))
        #expect(output.contains("spaced:_zago 編輯器 LOGO 語言"))
        #expect(output.contains("kata:_トウキョウ"))
        #expect(output.contains("emojis:_2"))
    }

    @Test func testTurtleDemoExample() throws {
        let output = try executeScriptFile("turtle_demo.logo")
        #expect(output.contains("===_Turtle_Graphics_Demo_==="))
    }

    @Test func testMatrixDemoExample() throws {
        let output = try executeScriptFile("matrix_demo.logo")
        #expect(output.contains("===_Multidimensional_Arrays_&_Reflection_Demo_==="))
        #expect(output.contains("matrix_elem_[2,1]:_Z"))
        #expect(output.contains("stack_after_push:_[30 10 20]"))
        #expect(output.contains("popped_val:_30_stack_remaining:_[10 20]"))
        #expect(output.contains("is_print_primitive:_true"))
        #expect(output.contains("is_addone_procedure:_false"))
    }

    @Test func testBufferEditorDemoExample() throws {
        let output = try executeScriptFile("buffer_editor_demo.logo")
        #expect(output.contains("===_Editor_Buffer_Automation_Demo_==="))
        #expect(output.contains("line_1_after_setline:_Updated_Header_Line"))
    }

    @Test func testLeetCode054SpiralMatrixExample() throws {
        let output = try executeScriptFile("leetcode_054_spiral_matrix.logo")
        #expect(output.contains("===_LeetCode_#054_/_#059:_Spiral_Matrix_==="))
        #expect(output.contains("spiral_matrix:_{{1 6 9} {2 7 8} {3 4 5}}"))
    }

    @Test func testLeetCode062UniquePathsExample() throws {
        let output = try executeScriptFile("leetcode_062_unique_paths.logo")
        #expect(output.contains("===_LeetCode_#062:_Unique_Paths_(2D_DP)_==="))
        #expect(output.contains("grid:_3x7_unique_paths:_28"))
    }

    @Test func testLeetCode200NumberOfIslandsExample() throws {
        let output = try executeScriptFile("leetcode_200_number_of_islands.logo")
        #expect(output.contains("===_LeetCode_#200:_Number_of_Islands_(2D_BFS)_==="))
        #expect(output.contains("grid:_3x3_islands_count:_2"))
    }

    @Test func testSystemTimeDemoExample() throws {
        let output = try executeScriptFile("system_time_demo.logo")
        #expect(output.contains("===_System_Date,_Time_&_Numeric_Sequences_Demo_==="))
        #expect(output.contains("date:_"))
        #expect(output.contains("time:_"))
        #expect(output.contains("rseq_0_to_10_count_5:_[0 2.5 5 7.5 10]"))
    }

    @Test func testLogoInLogoInterpreterExample() throws {
        let output = try executeScriptFile("logo_in_logo_interpreter.logo")
        #expect(output.contains("===_Meta-Logo:_A_Self-Hosting_LOGO_Interpreter_in_LOGO_==="))
        #expect(output.contains("META_LOGO_OUT:_===_Hello_From_Meta-Logo_Interpreter!_==="))
        #expect(output.contains("META_LOGO_OUT:_30"))
        #expect(output.contains("META_LOGO_OUT:_200"))
        #expect(output.contains("META_LOGO_OUT:_3"))
    }

    @Test func testAdvancedUtilsDemoExample() throws {
        let output = try executeScriptFile("advanced_utils_demo.logo")
        #expect(output.contains("===_Advanced_Utilities_&_Linguistics_Demo_==="))
        #expect(output.contains("sorted_list:_[10 20 30 40 50]"))
        #expect(output.contains("formatted_pi:_    3.1416"))
        #expect(output.contains("indexes_of_a_in_banana:_[2 4 6]"))
        #expect(output.contains("to_hiragana(katakana):_かたかな"))
    }
}






