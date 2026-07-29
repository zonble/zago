import Foundation

extension LogoEngine {
    /// Evaluates built-in LOGO expression primitives by delegating to specialized domain handlers.
    internal func evaluateExpressionPrimitive(_ tokens: [String], index: inout Int) -> String? {
        evaluateDataStructurePrimitives(tokens, index: &index)
            ?? evaluateMathPrimitives(tokens, index: &index)
            ?? evaluateBufferPrimitives(tokens, index: &index)
            ?? evaluateControlPrimitives(tokens, index: &index)
    }
}
