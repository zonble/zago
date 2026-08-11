# Editor LOGO Debugger

The Editor LOGO debugger treats LOGO as zago's extension language, in the same role that Emacs Lisp has in Emacs. It is available from every editable buffer, not only `.logo` files.

## Executable Units

`LOGO eval` resolves, in order, the active selection, the Markdown `logo` fenced block containing the cursor, the current LOGO procedure or balanced block, and finally the current line. Markdown snippets are therefore first-class executable units.

## Breakpoints

Breakpoints belong to the editor, not `LogoEngine`. They are transient session state keyed by `TextBuffer.id` and a zero-based buffer line. They never modify source text or get saved into files.

```text
:logo break     Toggle a breakpoint at the current line.
:logo breaks    Show breakpoints for the current buffer.
:logo eval      Evaluate the current executable LOGO unit.
:logo debug     Open the *LOGO Debugger* buffer.
:logo continue  Resume until the next breakpoint.
:logo step      Execute one token, then pause again.
:logo abort     Stop the paused execution.
:logo eval EXPR Evaluate a reporter expression in the paused scope.
```

Markers are renderer overlays adjacent to line numbers; zago does not depend on mouse gutters.

## Debugger Buffer

`*LOGO Debugger*` is a read-only, session-only special buffer analogous to `*LOGO Output*`. It lists buffer breakpoints before execution, then shows paused source, call stack, locals, and available commands.

## Paused Execution

`LogoExecutionFrame` contains a procedure name, current `LogoToken`, and scope depth. Procedure bodies retain source tokens, so frames identify source inside procedures and at top level.

Breakpoint suspension keeps the interpreter worker suspended in place, preserving nested blocks, procedure scopes, and the complete LOGO call stack. Interactive controls are continue, step into, backtrace, locals, evaluation, and abort.

## Inline Evaluation

Use `:logo eval SUM :size 2` while paused. It runs in the current frame environment and displays the result in `*LOGO Debugger*`; it does not modify the source buffer.
