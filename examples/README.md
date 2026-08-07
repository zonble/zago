# zago Editor LOGO Examples & LeetCode Samples

This directory contains standalone **Editor LOGO (.logo)** scripts showcasing the expressive power of `zago`'s built-in LOGO engine, ranging from esoteric language interpreters (Brainfuck) to classic algorithm solutions (LeetCode, Caesar Cipher, Bitwise Algorithms).

---

## 📁 Included Examples

| File | Category | Description | Key LOGO Features Demonstrated |
| :--- | :--- | :--- | :--- |
| [`brainfuck.logo`](file:///Users/zonble/Work/zago/examples/brainfuck.logo) | Interpreter | Full **Brainfuck (BF)** interpreter running inside `zago` LOGO | `ARRAY`, `WHILE` loops, `CHAR`, `ORD`, `SETITEM` |
| [`fizzbuzz.logo`](file:///Users/zonble/Work/zago/examples/fizzbuzz.logo) | Classic Algo | Classic **FizzBuzz** (1 to N) implementation | `WHILE` loop, `%` modulo, `FORMAT` |
| [`caesar_cipher.logo`](file:///Users/zonble/Work/zago/examples/caesar_cipher.logo) | Cryptography | **Caesar Cipher** encryption/decryption | `ORD`, `CHAR`, modulo arithmetic, `WORD` |
| [`leetcode_001_two_sum.logo`](file:///Users/zonble/Work/zago/examples/leetcode_001_two_sum.logo) | LeetCode #1 | Two Sum problem | Nested `WHILE` loops, `ITEM`, `LIST` construction |
| [`leetcode_020_valid_parentheses.logo`](file:///Users/zonble/Work/zago/examples/leetcode_020_valid_parentheses.logo) | LeetCode #20 | Valid Parentheses string matching using a stack | `FPUT`, `FIRST`, `BUTFIRST` (List-as-Stack) |
| [`leetcode_053_max_subarray.logo`](file:///Users/zonble/Work/zago/examples/leetcode_053_max_subarray.logo) | LeetCode #53 | Maximum Subarray (Kadane's Algorithm) | `FOREACH` higher-order iterator, `MAX` math |
| [`leetcode_070_climbing_stairs.logo`](file:///Users/zonble/Work/zago/examples/leetcode_070_climbing_stairs.logo) | LeetCode #70 | Climbing Stairs (Dynamic Programming / Fibonacci) | `WHILE` loop, DP state variables |
| [`leetcode_125_valid_palindrome.logo`](file:///Users/zonble/Work/zago/examples/leetcode_125_valid_palindrome.logo) | LeetCode #125 | Valid Palindrome string cleaner | `LOWERCASE`, `REGEX_REPLACE`, `REVERSE` |
| [`leetcode_136_single_number.logo`](file:///Users/zonble/Work/zago/examples/leetcode_136_single_number.logo) | LeetCode #136 | Single Number problem using Bitwise XOR | `BIT.XOR`, `FOREACH` |
| [`leetcode_191_number_of_1_bits.logo`](file:///Users/zonble/Work/zago/examples/leetcode_191_number_of_1_bits.logo) | LeetCode #191 | Number of 1 Bits (Hamming Weight) | `BIT.AND`, `BIT.SHR`, `WHILE` loop |
| [`leetcode_217_contains_duplicate.logo`](file:///Users/zonble/Work/zago/examples/leetcode_217_contains_duplicate.logo) | LeetCode #217 | Contains Duplicate array check | `COUNT`, `REMDUP` list deduplication |
| [`leetcode_231_power_of_two.logo`](file:///Users/zonble/Work/zago/examples/leetcode_231_power_of_two.logo) | LeetCode #231 | Power of Two check using Bitwise AND trick | `BIT.AND`, bitwise arithmetic |

---

## 🚀 How to Run Examples

### Method A: Headless Pipeline Execution (CLI)
You can run any `.logo` script directly from your terminal using `zago -e`:

```bash
# Run Single Number (LeetCode #136)
zago -e "$(cat examples/leetcode_136_single_number.logo)"

# Run Hamming Weight (LeetCode #191)
zago -e "$(cat examples/leetcode_191_number_of_1_bits.logo)"

# Run Power of Two (LeetCode #231)
zago -e "$(cat examples/leetcode_231_power_of_two.logo)"
```

---

### Method B: Interactive Editor Execution (TUI)
1. Open `zago`.
2. Press **`Esc`** to open the bottom LOGO command prompt.
3. Type:
   ```logo
   LOAD "examples/leetcode_136_single_number.logo
   ```
4. Output will render directly inside your buffer!
