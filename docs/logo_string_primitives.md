# Specification Proposal: Editor LOGO String Primitives Expansion

## 1. Overview

To make `zago` an expressive text editor and Unix pipe filter, we propose extending the **Editor LOGO Engine** with a set of modern, Unicode-aware **String Primitives**, including full **Regex (Regular Expression) support**. 

This document summarizes `zago`'s **currently supported string primitives** alongside the **newly planned extensions**.

---

## 2. Comprehensive Primitive Comparison

### 2.1 Search, Indexing & Regex (搜尋、索引與正則表示式)

| Primitive | Status | Aliases | Arguments | Description | Example | Output |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `regex_match?` | 🆕 Planned | `regex_match`, `rematch?` | `pattern string` | Returns `true` if `string` matches regular expression `pattern`. | `regex_match? "^#+ " "# Title"` | `true` |
| `regex_replace` | 🆕 Planned | `rreplace`, `rsubstitute` | `pattern replacement string` | Replaces all matches of Regex `pattern` with `replacement` in `string`. | `regex_replace "\s+" " " "a   b"` | `"a b"` |
| `regex_find` | 🆕 Planned | `rfind`, `rfindall` | `pattern string` | Returns a **LOGO List** of all substrings matching Regex `pattern`. | `regex_find "\d+" "Item 42 and 100"` | `[42 100]` |
| `indexof` | 🆕 Planned | `index_of` | `needle haystack [startFrom]` | Returns 1-based index of **first** occurrence of `needle` in `haystack`. Returns `0` if not found. | `indexof "a" "banana"` | `2` |
| `lastindexof` | 🆕 Planned | `last_index_of` | `needle haystack` | Returns 1-based index of **last** occurrence of `needle` in `haystack`. Returns `0` if not found. | `lastindexof "a" "banana"` | `6` |
| `indexesof` | 🆕 Planned | `indicesof`, `all_indexes` | `needle haystack` | Returns a **LOGO List** containing **all 1-based match indices** of `needle` in `haystack`. Returns `[]` if not found. | `indexesof "a" "banana"` | `[2 4 6]` |
| `contains?` | 🆕 Planned | `containsp`, `includes?` | `needle haystack` | Returns `true` if `haystack` contains `needle`, else `false`. | `contains? "world" "hello world"` | `true` |
| `startswith?` | 🆕 Planned | `startsp`, `has_prefix?` | `prefix string` | Returns `true` if `string` starts with `prefix`, else `false`. | `startswith? "# " "# Title"` | `true` |
| `endswith?` | 🆕 Planned | `endsp`, `has_suffix?` | `suffix string` | Returns `true` if `string` ends with `suffix`, else `false`. | `endswith? ".md" "file.md"` | `true` |
| `member` | ✅ Existing | | `needle haystack` | Returns remainder of `haystack` starting from first match of `needle`. | `member "world" "hello world"` | `"world"` |
| `substring?` | ✅ Existing | `substringp` | `needle haystack` | Returns `true` if `haystack` contains `needle` (legacy boolean check). | `substring? "foo" "foo text"` | `true` |

---

### 2.2 Substring, Transformation & Casing (子字串與轉換)

| Primitive | Status | Aliases | Arguments | Description | Example | Output |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `substring` | 🆕 Planned | `substr`, `slice` | `string start [length]` | Extracts substring starting at 1-based `start` position for `length` characters. | `substring "Hello World" 1 5` | `"Hello"` |
| `replace` | 🆕 Planned | `substitute` | `old new string` | Replaces all occurrences of `old` substring with `new` in `string`. | `replace "foo" "bar" "foo text foo"` | `"bar text bar"` |
| `trim` | 🆕 Planned | `strip` | `string` | Removes leading and trailing whitespace from `string`. | `trim "  hello world  "` | `"hello world"` |
| `repeatstr` | 🆕 Planned | `str_repeat` | `count string` | Repeats `string` for `count` times. | `repeatstr 5 "="` | `"====="` |
| `uppercase` | ✅ Existing | `upcase` | `string` | Converts `string` to uppercase. | `uppercase "hello"` | `"HELLO"` |
| `lowercase` | ✅ Existing | `downcase` | `string` | Converts `string` to lowercase. | `lowercase "WORLD"` | `"world"` |
| `spacingCJK` | ✅ Existing | | `string` | Normalizes spacing between CJK characters and Latin/digits. | `spacingCJK "iOS開發"` | `"iOS 開發"` |
| `translit` | ✅ Existing | | `mode string` | Converts between script variants (Hans/Hant, Romaji, Hiragana, etc.). | `transformToHant "简体"` | `"繁體"` |

---

### 2.3 Split, Join, Lines & Formatting (分割、組合、行處理與格式化)

| Primitive | Status | Aliases | Arguments | Description | Example | Output |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `split` | 🆕 Planned | `tokenize_by` | `delimiter string` | Splits `string` by `delimiter` into a LOGO List of strings. | `split "," "apple,banana,orange"` | `[apple banana orange]` |
| `join` | 🆕 Planned | `implode` | `delimiter list` | Joins a LOGO List of values into a string separated by `delimiter`. | `join ", " [apple banana]` | `"apple, banana"` |
| `lines` | 🆕 Planned | `to_lines` | `string` | Splits multiline string into a LOGO List of individual lines. | `lines "A\nB"` | `[A B]` |
| `unlines` | 🆕 Planned | `from_lines` | `list` | Joins a LOGO List of lines into a multiline string with `\n`. | `unlines [A B]` | `"A\nB"` |
| `format` | 🆕 Planned | `sprintf` | `pattern list_of_args` | Formats a pattern string with placeholders (`%s`, `%d`, `%f`, `%x`/`%X`, `%0Nd`, `%-Ns`, `%1`, `%2`). | `format "| %-10s | %04d |" ["Apple" 42]` | `"\| Apple      \| 0042 \|"` |

---

### 2.4 Padding & Alignment (對齊與填補)

| Primitive | Status | Aliases | Arguments | Description | Example | Output |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `padleft` | 🆕 Planned | `rjust` | `width [padChar] string` | Left-pads `string` to specified display `width` with `padChar` (default space). | `padleft 5 "0" "42"` | `"00042"` |
| `padright` | 🆕 Planned | `ljust` | `width [padChar] string` | Right-pads `string` to specified display `width` with `padChar` (default space). | `padright 10 "." "item"` | `"item......"` |

---

### 2.5 Text Metrics & Buffer Access (現有文字測量與 Buffer 存取)

| Primitive | Status | Description |
| :--- | :--- | :--- |
| `getline [N]` | ✅ Existing | Gets line text at cursor or 1-based line $N$. |
| `row` / `col` | ✅ Existing | Gets current cursor 1-based line number and column number. |
| `linecount` | ✅ Existing | Gets total line count in current buffer. |
| `buffertext` | ✅ Existing | Gets entire text buffer content. |
| `selection` | ✅ Existing | Gets currently selected text snippet. |
| `charCount` / `charCountCJK` | ✅ Existing | Gets display character counts (CJK aware). |

---

## 3. Real-World Use Case Examples in `zago`

### Example A: Regex Log Filter & Formatting
```logo
; Extract all numbers from log line and format into Markdown table
make "line getline
make "nums regex_find "\d+" :line
print format "| Log Data | %s |" [join ", " :nums]
```

### Example B: Markdown Table Column Alignment
```logo
make "row split "," getline
make "col1 item 1 :row
make "col2 item 2 :row
print format "| %-15s | %10s |" [:col1 :col2]
```

### Example C: Finding All Pipe Column Boundaries in a Markdown Table
```logo
make "line "| Name | Age | City |"
make "cols indexesof "|" :line
print :cols
; Output: [1 8 14 21]
```

---

## 4. Implementation Roadmap

1. **Primitive Enum Additions**: Update `LogoPrimitive.swift` with new keywords and aliases.
2. **Evaluation Engine Extension**: Add handlers in `LogoEngine+DataPrimitives.swift`.
3. **TDD Unit Tests**: Create `Tests/LogoStringPrimitivesTests.swift` covering edge cases (Regex syntax errors, out of bounds, empty strings, CJK display widths, sprintf formatting).
4. **Documentation Update**: Update `docs/logo.md` and user manual.
