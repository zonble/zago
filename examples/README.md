# zago Editor LOGO Examples & LeetCode Samples

This directory contains standalone **Editor LOGO (.logo)** scripts showcasing the expressive power of `zago`'s built-in LOGO engine, ranging from esoteric language interpreters (Brainfuck) to classic algorithm solutions (LeetCode).

---

## 📁 Included Examples

| File | Category | Description | Key LOGO Features Demonstrated |
| :--- | :--- | :--- | :--- |
| [`brainfuck.logo`](file:///Users/zonble/Work/zago/examples/brainfuck.logo) | Interpreter | Full **Brainfuck (BF)** interpreter running inside `zago` LOGO | `ARRAY`, `WHILE` loops, `CHAR`, `ASCII`, `SETITEM` |
| [`fizzbuzz.logo`](file:///Users/zonble/Work/zago/examples/fizzbuzz.logo) | Classic Algo | Classic **FizzBuzz** (1 to N) implementation | `WHILE` loop, `%` modulo, `FORMAT` |
| [`leetcode_001_two_sum.logo`](file:///Users/zonble/Work/zago/examples/leetcode_001_two_sum.logo) | LeetCode #1 | Two Sum problem | Nested `WHILE` loops, `ITEM`, `LIST` construction |
| [`leetcode_020_valid_parentheses.logo`](file:///Users/zonble/Work/zago/examples/leetcode_020_valid_parentheses.logo) | LeetCode #20 | Valid Parentheses string matching using a stack | `FPUT`, `FIRST`, `BUTFIRST` (List-as-Stack) |
| [`leetcode_125_valid_palindrome.logo`](file:///Users/zonble/Work/zago/examples/leetcode_125_valid_palindrome.logo) | LeetCode #125 | Valid Palindrome string cleaner | `LOWERCASE`, `REGEX_REPLACE`, `REVERSE` |
| [`leetcode_053_max_subarray.logo`](file:///Users/zonble/Work/zago/examples/leetcode_053_max_subarray.logo) | LeetCode #53 | Maximum Subarray (Kadane's Algorithm) | `FOREACH` higher-order iterator, `MAX` math |

---

## 🚀 How to Run Examples

### Method A: Headless Pipeline Execution (CLI)
You can run any `.logo` script directly from your terminal using `zago -e`:

```bash
# Run Brainfuck Interpreter
zago -e "$(cat examples/brainfuck.logo)"

# Run Two Sum LeetCode solution
zago -e "$(cat examples/leetcode_001_two_sum.logo)"

# Run Valid Palindrome solution
zago -e "$(cat examples/leetcode_125_valid_palindrome.logo)"
```

---

### Method B: Interactive Editor Execution (TUI)
1. Open `zago`.
2. Press **`Esc`** to open the bottom LOGO command prompt.
3. Type:
   ```logo
   LOAD "examples/brainfuck.logo
   ```
4. Output will render directly inside your buffer!
