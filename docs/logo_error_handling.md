# Editor LOGO Error Handling & `ASSERT` Specification

This document defines the architecture, classification, presentation rules, and assertion mechanisms for error handling in `zago`'s Editor LOGO engine.

---

## 🎯 Design Philosophy

Editor LOGO combines classic LOGO's human-friendly error messages (Seymour Papert's "Debugging as Learning" philosophy) with the safety requirements of an interactive terminal text editor.

In `zago`:
1. **Dual-Tier Error Reporting**:
   - **Status Bar**: Displays a clean, non-judgmental, classic LOGO short message (e.g. `[LOGO Error: I don't know how to MAAK]`).
   - **LOGO Output Console / Log**: Appends a detailed log entry with line numbers and context (e.g. `[LOGO Error at line 3: I don't know how to MAAK]`).
2. **Atomic Undo Protection**:
   - When an uncaught error occurs during macro execution, the buffer state change is automatically rolled back via `saveUndoSnapshot` so invalid macro execution never leaves corrupt buffer state behind.
3. **Exception Trapping (`CATCH` / `THROW`)**:
   - All errors can be trapped by `CATCH "ERROR [ ... ]` for custom error recovery.

---

## 📚 The 6 Core Error Categories

Editor LOGO categorizes all runtime failures into 6 distinct categories:

| Category | Trigger Condition | Status Bar Message | Output Console Message |
| :--- | :--- | :--- | :--- |
| **1. Unknown Command** | Unknown procedure / statement keyword typo | `[LOGO Error: I don't know how to <cmd>]` | `[LOGO Error at line L: I don't know how to <cmd>]` |
| **2. Missing Inputs** | Insufficient arguments passed to a primitive | `[LOGO Error: Not enough inputs to <prim>]` | `[LOGO Error at line L: Not enough inputs to <prim> (expects N)]` |
| **3. Type Mismatch** | Non-numeric input passed to math primitive | `[LOGO Error: <prim> doesn't like <val> as input]` | `[LOGO Error at line L: <prim> doesn't like '<val>' as numeric input]` |
| **4. No Output** | Void procedure called as expression reporter | `[LOGO Error: <proc> didn't output to <caller>]` | `[LOGO Error at line L: <proc> didn't output value to <caller>]` |
| **5. Bracket Mismatch** | Unclosed bracket `[` or parenthesis `(` | `[LOGO Error: Unmatched brackets]` | `[LOGO Error at line L: Unmatched bracket ']' or ')']` |
| **6. Assertion Failed** | `ASSERT` condition evaluated to `false` | `[LOGO Assertion Failed: <message>]` | `[LOGO Assertion Failed at line L: <message>]` |

---

## 🧪 The `ASSERT` Primitive Specification

### Syntax

```logo
ASSERT condition [message]
```

- **`condition`**: Any LOGO expression or boolean reporter (e.g. `:x > 0`, `EQUAL? :a :b`, `IS.NUMBER? :val`).
- **`message`** *(optional)*: Custom failure message string. If omitted, defaults to `"Assertion failed"`.

### Behavior

1. **Condition is `true`**:
   - Execution continues silently to the next command without side-effects.

2. **Condition is `false`**:
   - Triggers Category 6 error (`LogoError.assertionFailed(message)`).
   - Status Bar shows: `[LOGO Assertion Failed: <message>]`.
   - Output Console receives: `[LOGO Assertion Failed at line L: <message>]`.
   - Sets `hasUncaughtError = true` and halts execution (unless trapped inside `CATCH "ERROR`).

### Usage Examples

#### 1. Precondition Guard in Macro Scripts
```logo
MAKE "lines LINES
ASSERT :lines > 0 "Buffer must not be empty

MAKE "w 20
ASSERT :w >= 3 "Box width must be at least 3
```

#### 2. Guard inside Custom Procedures
```logo
TO DRAW_HEADER :title
  ASSERT :title <> "" "Header title cannot be empty"
  BOX :title CENTER ROUND
END
```

#### 3. Macro Unit Testing
```logo
MAKE "price "15"
MAKE "padded PADLEFT :price 5 "0"
ASSERT :padded = "00015" "PADLEFT output mismatch"
```

---

## 🛡️ Exception Trapping with `CATCH` and `THROW`

All 6 error categories can be intercepted using LOGO's `CATCH` statement:

```logo
CATCH "ERROR [
  ASSERT :x > 100 "x is too small
]
IF HAS.ERROR? [
  TYPE "Handled_error:_
  TYPE ERROR
]
```

When an error is trapped inside `CATCH "ERROR`:
- `HAS.ERROR?` returns `true`.
- `ERROR` reporter returns a LOGO list describing the error: `[code message line]`.

---

## 🏗️ Implementation Architecture

In Swift source code:

1. **`LogoError` Struct**:
   - Represents structured errors with code, short message (for status bar), and detailed message (for log/console).
2. **`LogoEngine.reportError(_ error: LogoError, token: String)`**:
   - Handles dual output: sends short message to `delegate.setStatusMessage` and appends full detailed message to `appendLogoOutput`.
3. **`executeAssertCommand` in `LogoEngine+ControlCommands.swift`**:
   - Parses condition expression and optional message.
   - Evaluates boolean truthiness via `isTrueCondition`.
