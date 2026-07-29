import Foundation

extension LogoEngine {
    /// Expression Primitive Evaluator (`evaluateExpressionPrimitive`)
    ///
    /// ### Role & Architecture:
    /// - **Role**: Responsible for calculating and evaluating built-in LOGO **Expression Primitives / Reporters**.
    /// - **Behavior**: These primitives are operators and reporters (e.g. `SUM`, `FIRST`, `BUFFERS`, `DATE`, `WORD?`). They always compute and return a value string to the expression evaluator.
    /// - **Return Type**: `String?` (returns evaluated value string if handled, or `nil` to fall back to variables/literals).
    ///
    /// ### Sub-module Hierarchy (Nil-Coalescing Dispatch Chain):
    /// 1. `evaluateDataStructurePrimitives` (Data structures and selectors: `WORD`, `LIST`, `FIRST`, `LAST`, `ITEM`, `REMOVE`, `WORD?`, `EMPTY?`)
    /// 2. `evaluateMathPrimitives` (Arithmetic, trigonometry, bitwise, and logical operations: `SUM`, `DIFFERENCE`, `PRODUCT`, `QUOTIENT`, `SQRT`, `SIN`, `AND`, `NOT`)
    /// 3. `evaluateBufferPrimitives` (Buffer state queries: `BUFFERS`, `BUFFER`, `GETLINE`, `ROW`, `COL`, `ISMODIFIED`)
    /// 4. `evaluateTemplatePrimitives` (Higher-order functional templates and iterators: `APPLY`, `MAP`, `FILTER`, `REDUCE`, `SORT`)
    /// 5. `evaluateSystemPrimitives` (System state, environment queries, and date/time: `DATE`, `TIME`, `ASCII`, `CHAR`, `STANDOUT`, `COUNT`)
    ///
    /// - Parameters:
    ///   - tokens: Script token sequence.
    ///   - index: Current token index pointer (inout).
    /// - Returns: Evaluated string result if handled, `nil` otherwise.
    internal func evaluateExpressionPrimitive(_ tokens: [String], index: inout Int) -> String? {
        evaluateDataStructurePrimitives(tokens, index: &index)
            ?? evaluateMathPrimitives(tokens, index: &index)
            ?? evaluateBufferPrimitives(tokens, index: &index)
            ?? evaluateTemplatePrimitives(tokens, index: &index)
            ?? evaluateSystemPrimitives(tokens, index: &index)
    }
}
