# Editor LOGO Error Handling & `ASSERT` Specification

This document defines the architecture, classification, presentation rules, precise position tracking, call stack reporting, and assertion mechanisms for error handling in `zago`'s Editor LOGO engine.

---

## 🎯 Design Philosophy

Editor LOGO combines classic LOGO's human-friendly error messages (Seymour Papert's "Debugging as Learning" philosophy) with the safety and debugging requirements of an interactive terminal text editor.

In `zago`:
1. **Dual-Tier Error Reporting**:
   - **Status Bar**: Displays a clean, concise status message (e.g. `[LOGO Error: I don't know how to MAAK]`).
   - **`*LOGO Output*` Console / Log**: Appends a comprehensive log entry with line and column numbers, procedure context, and multi-frame call stack backtraces (e.g. `[LOGO Error at line 3, col 5 in procedure 'MAAK': ...]`).
2. **Precise Source Position Tracking (`line`, `col`)**:
   - Every `LogoToken` preserves its exact `sourceRange` in the input script.
   - When evaluating linear text selections, Markdown ` ```logo ` code fences, or multi-line procedures, line and column numbers are accurately calculated relative to the host document's coordinate system (`debugStartLine`).
3. **Structured Procedure Call Stack Traces**:
   - Deep nested procedure calls maintain execution frames (`LogoExecutionFrame`).
   - Uncaught runtime errors format a visual caller chain (e.g. `in INNER (line 2) <- OUTER (line 5) <- top-level (line 7)`).
4. **Atomic Undo Protection**:
   - When an uncaught error occurs during macro execution, buffer mutations are automatically rolled back via `saveUndoSnapshot`, preventing corrupted intermediate editor state.
5. **Exception Trapping (`CATCH` / `THROW`)**:
   - Runtime errors can be trapped using `CATCH "ERROR [ ... ]` for graceful fallback and error recovery.

---

## 📚 The 6 Core Error Categories

Editor LOGO categorizes runtime failures into 6 distinct categories:

| Category | Trigger Condition | Status Bar Message | Output Console Message (with Line & Column) |
| :--- | :--- | :--- | :--- |
| **1. Unknown Command** | Unknown procedure / statement keyword typo | `[LOGO Error: I don't know how to <cmd>]` | `[LOGO Error at line L, col C: I don't know how to <cmd>]` |
| **2. Missing Inputs** | Insufficient arguments passed to a primitive or procedure | `[LOGO Error: Not enough inputs to <prim>]` | `[LOGO Error at line L, col C: Not enough inputs to <prim>]` |
| **3. Type Mismatch** | Non-numeric or unexpected input type | `[LOGO Error: <prim> doesn't like <val> as input]` | `[LOGO Error at line L, col C: <prim> doesn't like '<val>' as input]` |
| **4. No Output** | Void procedure called as expression reporter | `[LOGO Error: <proc> didn't output to <caller>]` | `[LOGO Error at line L, col C: <proc> didn't output to <caller>]` |
| **5. Bracket Mismatch** | Unclosed bracket `[` or parenthesis `(` | `[LOGO Error: Unmatched brackets]` | `[LOGO Error at line L, col C: Unmatched bracket ']' or ')']` |
| **6. Assertion Failed** | `ASSERT` condition evaluated to `false` | `[LOGO Assertion Failed: <message>]` | `[LOGO Assertion Failed at line L, col C: <message>]` |

---

## 🧭 Enhanced Location & Procedure Call Stack Tracing

When errors occur within user-defined procedures or nested calls, the output console generates formatted error headers and call stack traces:

### 1. Procedure Context Header
If the error happened within a named procedure:
```text
[LOGO Error at line 2, col 3 in procedure 'INNER': I don't know how to UNKNOWN_COMMAND]
```

### 2. Multi-Frame Backtrace
If the error occurred across multiple nested procedure frames, a backtrace line is appended:
```text
  in INNER (line 2) <- OUTER (line 5) <- top-level (line 7)
```

### 3. Markdown Code Fence Context
When running `evalLogoCode` inside a Markdown ` ```logo ` block, line numbers automatically map to the line numbers of the enclosing Markdown file.

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
   - Execution continues silently to the next command without side effects.

2. **Condition is `false`**:
   - Triggers Category 6 error (`LogoError`).
   - Status Bar shows: `[LOGO Assertion Failed: <message>]`.
   - Output Console receives: `[LOGO Assertion Failed at line L, col C: <message>]`.
   - Halts execution and triggers atomic undo rollback (unless trapped inside `CATCH "ERROR`).

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

All runtime errors can be intercepted using LOGO's `CATCH` statement:

```logo
CATCH "ERROR [
  ASSERT :x > 100 "x is too small
]
IF HAS.ERROR? [
  TYPE "Handled error: "
  PRINT ERROR
]
```

When an error is trapped inside `CATCH "ERROR`:
- `HAS.ERROR?` returns `true`.
- `ERROR` reporter returns a structured LOGO list describing the error:
  ```logo
  [code "message" "procedureName"]
  ```

Example output of `:ERROR`:
```logo
[1 "x is too small" "MY_PROC"]
```

---

## 🏗️ Implementation Architecture

In the Swift source code:

1. **`LogoError` Struct** (`Sources/LogoEngine/Types/Core/LogoError.swift`):
   - Structured error containing:
     - `code: Int`
     - `message: String`
     - `procedureName: String?`
     - `token: LogoToken?` (with token text and `sourceRange`)
     - `callStack: [LogoExecutionFrame]`

2. **`LogoEngine.reportError(_ error: LogoError, token: String)`** (`Sources/LogoEngine/Core/LogoEngine.swift`):
   - Captures current execution frame, token position, procedure name, and call stack backtrace.
   - Sets `hasUncaughtError = true` and notifies delegates.

3. **`formatErrorForOutput`** (`Sources/Editor/Controllers/Editor/Editor+Logo.swift`):
   - Formats `(errorLine, callStackLine)` with precise `(line, col)` calculated against `debugStartLine` and the active buffer coordinate system.
   - Writes detailed diagnostic reports to `*LOGO Output*` console.
