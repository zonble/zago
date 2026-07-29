import Foundation

extension LogoEngine {
    /// Statement Command Dispatcher (`executeStatementCommand`)
    ///
    /// ### Role & Architecture:
    /// - **Role**: Responsible for executing built-in LOGO **Statement Commands** (actions/statements).
    /// - **Behavior**: Statement commands perform side-effects (e.g. variable mutation `.make`, editor output `.type`/`.show`, turtle movement `.forward`, box rendering `.box`, and control flow `.if`/`.repeat`). They do **NOT** return value strings to callers.
    /// - **Return Type**: `Bool` (`true` indicates the command was handled, `false` indicates it is not a statement command).
    ///
    /// ### Sub-module Hierarchy:
    /// 1. `executeVariableCommand` (Variable and data structure mutations: `.make`, `.name`, `.setItem`, `.setFirst`, `.setBFL`, `.push`, `.pop`)
    /// 2. `executeControlCommand` (Control flow and procedure definitions: `.ifCondition`, `.ifElseCondition`, `.repeatLoop`, `.forLoop`, `.whileLoop`, `.catchTag`, `.to`, `.exec`)
    /// 3. `executeEditingCommand` (Text editing and buffer operations: `.type`, `.show`, `.delete`, `.move`, `.cut`, buffer actions)
    /// 4. `executeDrawingCommand` (Turtle graphics, lines, boxes, and tables: `.penDown`, `.forward`, `.goto`, `.box`, `.line`, `.table`)
    ///
    /// - Parameters:
    ///   - prim: The LOGO primitive to execute.
    ///   - tokens: Script token sequence.
    ///   - index: Current token index pointer (inout).
    ///   - frameReturn: Procedure return value container (inout).
    /// - Returns: `true` if handled as a statement command, `false` otherwise.
    internal func executeStatementCommand(
        _ prim: LogoPrimitive,
        tokens: [String],
        index: inout Int,
        frameReturn: inout String?
    ) -> Bool {
        executeVariableCommand(prim, tokens: tokens, index: &index)
            || executeControlCommand(prim, tokens: tokens, index: &index, frameReturn: &frameReturn)
            || executeEditingCommand(prim, tokens: tokens, index: &index)
            || executeDrawingCommand(prim, tokens: tokens, index: &index)
    }
}
