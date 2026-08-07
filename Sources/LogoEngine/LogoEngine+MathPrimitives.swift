import Foundation

extension LogoEngine {
    private func hasNextMathArgument(_ tokens: [String], after index: Int) -> Bool {
        guard index + 1 < tokens.count else { return false }
        let nextToken = tokens[index + 1]
        return !LogoEngine.isStatementCommand(nextToken) && nextToken != "]" && nextToken != ")"
    }

    /// Evaluates Numeric, Math, Bitwise, Logical, and Formatting Primitives.
    internal func evaluateMathPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = LogoPrimitive.from(tokens[index]) else { return nil }

        switch prim {
        case .sum:
            index += 1
            let first = evaluateExpression(tokens, index: &index)
            let parsedFirst = LogoValue.parse(first)
            if case .list = parsedFirst {
                return formatNum(numericSum(of: parsedFirst))
            }
            if case .array = parsedFirst {
                return formatNum(numericSum(of: parsedFirst))
            }
            let a = Double(first) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a + b)

        case .min:
            index += 1
            let first = evaluateExpression(tokens, index: &index)
            let parsedFirst = LogoValue.parse(first)
            if case .list = parsedFirst {
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: false) ?? 0)
            }
            if case .array = parsedFirst {
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: false) ?? 0)
            }
            let a = Double(first) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(Swift.min(a, b))

        case .max:
            index += 1
            let first = evaluateExpression(tokens, index: &index)
            let parsedFirst = LogoValue.parse(first)
            if case .list = parsedFirst {
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: true) ?? 0)
            }
            if case .array = parsedFirst {
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: true) ?? 0)
            }
            let a = Double(first) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(Swift.max(a, b))

        case .difference:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a - b)

        case .product:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(a * b)

        case .quotient:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let b = Double(evaluateExpression(tokens, index: &index)) ?? 1
                return formatNum(b != 0 ? a / b : 0)
            }
            return formatNum(a != 0 ? 1.0 / a : 0)

        case .power:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(pow(a, b))

        case .remainder:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 1
            return "\(b != 0 ? a % b : 0)"

        case .modulo:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 1
            if b == 0 { return "0" }
            let r = a % b
            return "\(r >= 0 ? r : r + abs(b))"

        case .minus:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            if index + 1 < tokens.count && !LogoEngine.isStatementCommand(tokens[index + 1]) && tokens[index + 1] != "]"
            {
                index += 1
                let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
                return formatNum(a - b)
            }
            return formatNum(-a)

        case .abs:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(abs(a))

        case .int:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(Int(a))"

        case .round:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(Int(round(a)))"

        case .sqrt:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sqrt(max(0, a)))

        case .exp:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(exp(a))

        case .log10:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 1
            return formatNum(log10(max(0.00001, a)))

        case .ln:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 1
            return formatNum(log(max(0.00001, a)))

        case .arctan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            if hasNextMathArgument(tokens, after: index) {
                index += 1
                let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
                return formatNum(atan2(b, a) * 180.0 / .pi)
            }
            return formatNum(atan(a) * 180.0 / .pi)

        case .sin:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sin(a * .pi / 180.0))

        case .cos:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(cos(a * .pi / 180.0))

        case .tan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(tan(a * .pi / 180.0))

        case .radArctan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            if hasNextMathArgument(tokens, after: index) {
                index += 1
                let b = Double(evaluateExpression(tokens, index: &index)) ?? 0
                return formatNum(atan2(b, a))
            }
            return formatNum(atan(a))

        case .radSin:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(sin(a))

        case .radCos:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(cos(a))

        case .radTan:
            index += 1
            let a = Double(evaluateExpression(tokens, index: &index)) ?? 0
            return formatNum(tan(a))

        case .iseq:
            index += 1
            let start = Int(evaluateExpression(tokens, index: &index)) ?? 1
            index += 1
            let end = Int(evaluateExpression(tokens, index: &index)) ?? start
            var step = start <= end ? 1 : -1
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let parsedStep = Int(evaluateExpression(tokens, index: &index)) ?? step
                if parsedStep != 0 {
                    step = parsedStep
                }
            }
            let seq = Array(stride(from: start, through: end, by: step))
            return LogoValue.list(seq.map { LogoValue.string("\($0)") }).description

        case .rseq:
            index += 1
            let start = Double(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let end = Double(evaluateExpression(tokens, index: &index)) ?? start
            index += 1
            let count = max(1, Int(evaluateExpression(tokens, index: &index)) ?? 1)
            if count == 1 { return LogoValue.list([LogoValue.string(formatNum(start))]).description }
            let step = (end - start) / Double(count - 1)
            var res: [LogoValue] = []
            for i in 0..<count {
                res.append(LogoValue.string(formatNum(start + Double(i) * step)))
            }
            return LogoValue.list(res).description

        case .random:
            index += 1
            let firstVal = Int(evaluateExpression(tokens, index: &index)) ?? 10
            if index + 1 < tokens.count && !LogoEngine.isKeyword(tokens[index + 1]) && tokens[index + 1] != "]" {
                index += 1
                let secondVal = Int(evaluateExpression(tokens, index: &index)) ?? firstVal
                let low = min(firstVal, secondVal)
                let high = max(firstVal, secondVal)
                return "\(Int.random(in: low...high))"
            }
            let upperLimit = max(1, firstVal)
            return "\(Int.random(in: 0..<upperLimit))"

        case .rerandom:
            return "1"

        case .form:
            index += 1
            let val = Double(evaluateExpression(tokens, index: &index)) ?? 0.0
            index += 1
            let width = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let prec = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return String(format: "%*.*f", width, prec, val)

        case .bitAnd:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a & b)"

        case .bitOr:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a | b)"

        case .bitXor:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let b = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\(a ^ b)"

        case .bitNot:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            return "\( ~a )"

        case .ashift, .lshift:
            index += 1
            let a = Int(evaluateExpression(tokens, index: &index)) ?? 0
            index += 1
            let shift = Int(evaluateExpression(tokens, index: &index)) ?? 0
            if shift >= 0 {
                return "\(a << shift)"
            } else {
                return "\(a >> (-shift))"
            }

        case .trueVal:
            return "true"

        case .falseVal:
            return "false"

        case .andLogic:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) && logoIsTrue(v2)) ? "true" : "false"

        case .orLogic:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) || logoIsTrue(v2)) ? "true" : "false"

        case .xorLogic:
            index += 1
            let v1 = evaluateExpression(tokens, index: &index)
            index += 1
            let v2 = evaluateExpression(tokens, index: &index)
            return (logoIsTrue(v1) != logoIsTrue(v2)) ? "true" : "false"

        case .notLogic:
            index += 1
            let v = evaluateExpression(tokens, index: &index)
            return logoIsTrue(v) ? "false" : "true"

        default:
            return nil
        }
    }
}
