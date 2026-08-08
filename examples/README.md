# zago Editor LOGO Examples & LeetCode Samples

This directory contains standalone **Editor LOGO (.logo)** scripts showcasing the expressive power of `zago`'s built-in LOGO engine, ranging from esoteric language interpreters (Brainfuck, Self-Hosting LOGO Interpreter) to classic algorithm solutions (LeetCode, Caesar Cipher, Bitwise Algorithms, Regular Expressions, Mathematics, ASCII Canvas, CJK Linguistics, Turtle Graphics, Multidimensional Matrices, Buffer Automation, 2D Grid Algorithms, System Date/Time & Advanced Utilities).

---

## 📁 Included Examples

| File | Category | Description | Key LOGO Features Demonstrated |
| :--- | :--- | :--- | :--- |
| [`advanced_utils_demo.logo`](advanced_utils_demo.logo) | Utilities & Linguistics | **Sorting, Radians Trig & Hiragana Transliteration** | `SORT`, `FORM`, `INDEXESOF`, `RADSIN`, `RADCOS`, `TOHIRAGANA` |
| [`error_handling_demo.logo`](error_handling_demo.logo) | Exceptions & Output | **Error Handling & Log Output** | `CATCH "ERROR`, `THROW "ERROR`, `ERROR` |
| [`property_list_demo.logo`](property_list_demo.logo) | Dictionary & Key-Value | **Property Lists / Key-Value Objects** | `PPROP`, `GPROP`, `REMPROP`, `PLIST`, `PLISTS` |
| [`reflection_demo.logo`](reflection_demo.logo) | Workspace & Reflection | **Reflection & Dynamic Metaprogramming** | `NAMES`, `PROCEDURES`, `CONTENTS`, `TEXT`, `DEFINE`, `ARITY`, `ERASE`, `ERALL` |
| [`logo_in_logo_interpreter.logo`](logo_in_logo_interpreter.logo) | Self-Hosting Metaprogramming | **Self-Hosting LOGO Interpreter in LOGO** | AST Walker, Env symbol tables, `DEF` / `CALL` procs |
| [`brainfuck.logo`](brainfuck.logo) | Interpreter | Full **Brainfuck (BF)** interpreter running inside `zago` LOGO | `ARRAY`, `WHILE` loops, `CHAR`, `ORD`, `SETITEM` |
| [`fizzbuzz.logo`](fizzbuzz.logo) | Classic Algo | Classic **FizzBuzz** (1 to N) implementation | `WHILE` loop, `%` modulo, `FORMAT` |
| [`leap_year.logo`](leap_year.logo) | Classic Algo | **Leap Year Checker** | Modulo `%` logic, `IF`, `FORMAT` |
| [`system_time_demo.logo`](system_time_demo.logo) | System & Sequences | **System Date, Time, Sequences & Seed** | `DATE`, `TIME`, `RSEQ`, `RERANDOM`, `RANDOM`, `IGNORE` |
| [`regex_demo.logo`](regex_demo.logo) | Regex & String | **Regex & Text Search** (Pattern matching, masking, padding) | `REGEX_MATCH?`, `REGEX_REPLACE`, `PADLEFT`, `PADRIGHT` |
| [`math_demo.logo`](math_demo.logo) | Math & Sequences | **Math & Trigonometry** (Euclidean distance, log, power, series) | `SQRT`, `POWER`, `LOG10`, `LN`, `ABS`, `ISEQ`, `RANDOM` |
| [`functional_demo.logo`](functional_demo.logo) | Functional Programming | **Higher-Order Functions** (Map, Filter, Reduce, Crossmap) | `MAP`, `MAP.SE`, `FILTER`, `REDUCE`, `CROSSMAP`, `RUNRESULT` |
| [`control_flow_demo.logo`](control_flow_demo.logo) | Control Flow & Exceptions | **Control Flow & Non-local Exit** (Case, Cond, Test, Catch/Throw) | `CASE`, `COND`, `TEST`, `IFTRUE`, `CATCH`, `THROW`, `DOTIMES` |
| [`ascii_drawing_demo.logo`](ascii_drawing_demo.logo) | ASCII Canvas & Diagrams | **ASCII Canvas Drawing** (Boxes, lines, border & arrow styles) | `SETBORDERSTYLE`, `SETARROWSTYLE`, `BOX`, `LINE`, `VLINE` |
| [`cjk_text_demo.logo`](cjk_text_demo.logo) | CJK Linguistics | **CJK Text Transformation & Transliteration** (Simplified/Traditional, Kana, Emoji) | `TOHANS`, `TOHANT`, `SPACING.CJK`, `TOKATAKANA`, `CHARCOUNT.EMOJI` |
| [`turtle_demo.logo`](turtle_demo.logo) | Turtle Graphics | **Classic LOGO Turtle Graphics** (Heading, pen up/down, move) | `PENDOWN`, `PENUP`, `FORWARD`, `BACK`, `TURNRIGHT`, `SETHEADING` |
| [`matrix_demo.logo`](matrix_demo.logo) | Multidimensional & Reflection | **Multidimensional Arrays, Stacks & Reflection** | `MDARRAY`, `MDITEM`, `MDSETITEM`, `PUSH`, `POP`, `GENSYM`, `DEFINED?` |
| [`buffer_editor_demo.logo`](buffer_editor_demo.logo) | Buffer Automation | **Editor Buffer Control** (Line append, read/write, counts) | `APPEND`, `PREPEND`, `SETLINE`, `GETLINE`, `LINECOUNT`, `ROW`, `COL` |
| [`caesar_cipher.logo`](caesar_cipher.logo) | Cryptography | **Caesar Cipher** encryption/decryption | `ORD`, `CHAR`, modulo arithmetic, `WORD` |
| [`leetcode_001_two_sum.logo`](leetcode_001_two_sum.logo) | LeetCode #1 | Two Sum problem | Nested `WHILE` loops, `ITEM`, `LIST` construction |
| [`leetcode_014_longest_common_prefix.logo`](leetcode_014_longest_common_prefix.logo) | LeetCode #14 | Longest Common Prefix | `STARTSWITH?`, `SUBSTRING`, `COUNT`, `WHILE` |
| [`leetcode_020_valid_parentheses.logo`](leetcode_020_valid_parentheses.logo) | LeetCode #20 | Valid Parentheses string matching using a stack | `FPUT`, `FIRST`, `BUTFIRST` (List-as-Stack) |
| [`leetcode_053_max_subarray.logo`](leetcode_053_max_subarray.logo) | LeetCode #53 | Maximum Subarray (Kadane's Algorithm) | `FOREACH` higher-order iterator, `MAX` math |
| [`leetcode_054_spiral_matrix.logo`](leetcode_054_spiral_matrix.logo) | LeetCode #54 / #59 | **Spiral Matrix II** (2D Grid traversal) | `MDARRAY`, `MDSETITEM`, `MDITEM`, `WHILE` |
| [`leetcode_058_length_of_last_word.logo`](leetcode_058_length_of_last_word.logo) | LeetCode #58 | Length of Last Word | `TRIM`, `SPLIT`, `LAST`, `COUNT` |
| [`leetcode_062_unique_paths.logo`](leetcode_062_unique_paths.logo) | LeetCode #62 | **Unique Paths** (2D Dynamic Programming) | `MDARRAY`, `MDSETITEM`, `MDITEM`, `IFELSE` |
| [`leetcode_070_climbing_stairs.logo`](leetcode_070_climbing_stairs.logo) | LeetCode #70 | Climbing Stairs (Dynamic Programming / Fibonacci) | `WHILE` loop, DP state variables |
| [`leetcode_125_valid_palindrome.logo`](leetcode_125_valid_palindrome.logo) | LeetCode #125 | Valid Palindrome string cleaner | `LOWERCASE`, `REGEX_REPLACE`, `REVERSE` |
| [`leetcode_136_single_number.logo`](leetcode_136_single_number.logo) | LeetCode #136 | Single Number problem using Bitwise XOR | `BIT.XOR`, `FOREACH` |
| [`leetcode_151_reverse_words.logo`](leetcode_151_reverse_words.logo) | LeetCode #151 | Reverse Words in a String | `TRIM`, `SPLIT`, `FILTER`, `REVERSE`, `JOIN` |
| [`leetcode_191_number_of_1_bits.logo`](leetcode_191_number_of_1_bits.logo) | LeetCode #191 | Number of 1 Bits (Hamming Weight) | `BIT.AND`, `BIT.SHR`, `WHILE` loop |
| [`leetcode_200_number_of_islands.logo`](leetcode_200_number_of_islands.logo) | LeetCode #200 | **Number of Islands** (2D Grid BFS / Flood Fill) | `MDARRAY`, `MDSETITEM`, `MDITEM`, `FPUT`, `BUTFIRST` |
| [`leetcode_217_contains_duplicate.logo`](leetcode_217_contains_duplicate.logo) | LeetCode #217 | Contains Duplicate array check | `COUNT`, `REMDUP` list deduplication |
| [`leetcode_231_power_of_two.logo`](leetcode_231_power_of_two.logo) | LeetCode #231 | Power of Two check using Bitwise AND trick | `BIT.AND`, bitwise arithmetic |

---

## 🚀 How to Run Examples

### Method A: Headless Pipeline Execution (CLI)
You can run any `.logo` script directly from your terminal using `zago -e`:

```bash
# Run Advanced Utilities & Linguistics Demo
zago -e "$(cat examples/advanced_utils_demo.logo)"

# Run Self-Hosting LOGO Interpreter in LOGO Demo
zago -e "$(cat examples/logo_in_logo_interpreter.logo)"

# Run System Date, Time & Sequences Demo
zago -e "$(cat examples/system_time_demo.logo)"

# Run Spiral Matrix (LeetCode #54 / #59)
zago -e "$(cat examples/leetcode_054_spiral_matrix.logo)"

# Run Unique Paths 2D DP (LeetCode #62)
zago -e "$(cat examples/leetcode_062_unique_paths.logo)"

# Run Number of Islands 2D BFS (LeetCode #200)
zago -e "$(cat examples/leetcode_200_number_of_islands.logo)"

# Run Matrix & Reflection Demo
zago -e "$(cat examples/matrix_demo.logo)"

# Run Buffer Automation Demo
zago -e "$(cat examples/buffer_editor_demo.logo)"

# Run ASCII Drawing & Diagram Demo
zago -e "$(cat examples/ascii_drawing_demo.logo)"

# Run CJK Text Transformation Demo
zago -e "$(cat examples/cjk_text_demo.logo)"

# Run Turtle Graphics Demo
zago -e "$(cat examples/turtle_demo.logo)"
```

---

### Method B: Interactive Editor Execution (TUI)
1. Open `zago`.
2. Press **`Esc`** to open the bottom LOGO command prompt.
3. Type:
   ```logo
   LOAD "examples/advanced_utils_demo.logo
   ```
4. Output will render directly inside your buffer!
