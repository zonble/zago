import Foundation

private func mathOptionalArgumentBoundary(_ token: String) -> Bool {
    LogoEngine.isKeyword(token) || token == "]" || token == ")"
}

extension LogoEngine {
    /// Evaluates Numeric, Math, Bitwise, Logical, and Formatting Primitives.
    internal func evaluateMathPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = parsePrimitive(tokens[index]) else { return nil }

        switch prim {
        case .sum:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let first = reader.nextExpression()
            let parsedFirst = LogoValue.parse(first)
            if case .list = parsedFirst {
                reader.commit(to: &index)
                return formatNum(numericSum(of: parsedFirst))
            }
            if case .array = parsedFirst {
                reader.commit(to: &index)
                return formatNum(numericSum(of: parsedFirst))
            }
            let a = Double(first) ?? 0
            let b = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(a + b)

        case .min:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let first = reader.nextExpression()
            let parsedFirst = LogoValue.parse(first)
            if case .list = parsedFirst {
                reader.commit(to: &index)
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: false) ?? 0)
            }
            if case .array = parsedFirst {
                reader.commit(to: &index)
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: false) ?? 0)
            }
            let a = Double(first) ?? 0
            let b = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(Swift.min(a, b))

        case .max:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let first = reader.nextExpression()
            let parsedFirst = LogoValue.parse(first)
            if case .list = parsedFirst {
                reader.commit(to: &index)
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: true) ?? 0)
            }
            if case .array = parsedFirst {
                reader.commit(to: &index)
                return formatNum(numericExtremum(of: parsedFirst, preferMaximum: true) ?? 0)
            }
            let a = Double(first) ?? 0
            let b = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(Swift.max(a, b))

        case .difference:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            let b = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(a - b)

        case .product:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            let b = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(a * b)

        case .quotient:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            if let rawB = reader.nextOptionalExpression(isBoundary: mathOptionalArgumentBoundary) {
                let b = Double(rawB) ?? 1
                reader.commit(to: &index)
                return formatNum(b != 0 ? a / b : 0)
            }
            reader.commit(to: &index)
            return formatNum(a != 0 ? 1.0 / a : 0)

        case .power:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            let b = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(pow(a, b))

        case .remainder:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            let b = reader.nextInteger(default: 1)
            reader.commit(to: &index)
            return "\(b != 0 ? a % b : 0)"

        case .modulo:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            let b = reader.nextInteger(default: 1)
            reader.commit(to: &index)
            if b == 0 { return "0" }
            let r = a % b
            return "\(r >= 0 ? r : r + abs(b))"

        case .minus:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            if let rawB = reader.nextOptionalExpression() {
                let b = Double(rawB) ?? 0
                reader.commit(to: &index)
                return formatNum(a - b)
            }
            reader.commit(to: &index)
            return formatNum(-a)

        case .abs:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(abs(a))

        case .int:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return "\(Int(a))"

        case .round:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return "\(Int(round(a)))"

        case .sqrt:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(sqrt(max(0, a)))

        case .exp:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(exp(a))

        case .log10:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble(default: 1)
            reader.commit(to: &index)
            return formatNum(log10(max(0.00001, a)))

        case .ln:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble(default: 1)
            reader.commit(to: &index)
            return formatNum(log(max(0.00001, a)))

        case .arctan:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            if let rawB = reader.nextOptionalExpression() {
                let b = Double(rawB) ?? 0
                reader.commit(to: &index)
                return formatNum(atan2(b, a) * 180.0 / .pi)
            }
            reader.commit(to: &index)
            return formatNum(atan(a) * 180.0 / .pi)

        case .sin:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(sin(a * .pi / 180.0))

        case .cos:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(cos(a * .pi / 180.0))

        case .tan:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(tan(a * .pi / 180.0))

        case .radArctan:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            if let rawB = reader.nextOptionalExpression() {
                let b = Double(rawB) ?? 0
                reader.commit(to: &index)
                return formatNum(atan2(b, a))
            }
            reader.commit(to: &index)
            return formatNum(atan(a))

        case .radSin:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(sin(a))

        case .radCos:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(cos(a))

        case .radTan:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextDouble()
            reader.commit(to: &index)
            return formatNum(tan(a))

        case .iseq:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let start = reader.nextInteger(default: 1)
            let end = reader.nextInteger(default: start)
            var step = start <= end ? 1 : -1
            if let rawStep = reader.nextOptionalExpression(isBoundary: mathOptionalArgumentBoundary) {
                let parsedStep = Int(rawStep) ?? step
                if parsedStep != 0 {
                    step = parsedStep
                }
            }
            reader.commit(to: &index)
            let seq = Array(stride(from: start, through: end, by: step))
            return LogoValue.list(seq.map { LogoValue.string("\($0)") }).description

        case .rseq:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let start = reader.nextDouble()
            let end = reader.nextDouble(default: start)
            let count = max(1, reader.nextInteger(default: 1))
            reader.commit(to: &index)
            if count == 1 { return LogoValue.list([LogoValue.string(formatNum(start))]).description }
            let step = (end - start) / Double(count - 1)
            var res: [LogoValue] = []
            for i in 0..<count {
                res.append(LogoValue.string(formatNum(start + Double(i) * step)))
            }
            return LogoValue.list(res).description

        case .random:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let firstVal = reader.nextInteger(default: 10)
            if let rawSecond = reader.nextOptionalExpression(isBoundary: mathOptionalArgumentBoundary) {
                let secondVal = Int(rawSecond) ?? firstVal
                let low = min(firstVal, secondVal)
                let high = max(firstVal, secondVal)
                reader.commit(to: &index)
                return "\(Int.random(in: low...high))"
            }
            reader.commit(to: &index)
            let upperLimit = max(1, firstVal)
            return "\(Int.random(in: 0..<upperLimit))"

        case .rerandom:
            return "1"

        case .form:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let val = reader.nextDouble()
            let width = reader.nextInteger()
            let prec = reader.nextInteger()
            reader.commit(to: &index)
            return String(format: "%*.*f", width, prec, val)

        case .bitAnd:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            let b = reader.nextInteger()
            reader.commit(to: &index)
            return "\(a & b)"

        case .bitOr:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            let b = reader.nextInteger()
            reader.commit(to: &index)
            return "\(a | b)"

        case .bitXor:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            let b = reader.nextInteger()
            reader.commit(to: &index)
            return "\(a ^ b)"

        case .bitNot:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            reader.commit(to: &index)
            return "\( ~a )"

        case .ashift, .lshift:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            let shift = reader.nextInteger()
            reader.commit(to: &index)
            if shift >= 0 {
                return "\(a << shift)"
            } else {
                return "\(a >> (-shift))"
            }

        case .rshift:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let a = reader.nextInteger()
            let shift = reader.nextInteger()
            reader.commit(to: &index)
            if shift >= 0 {
                return "\(a >> shift)"
            } else {
                return "\(a << (-shift))"
            }

        case .trueVal:
            return "true"

        case .falseVal:
            return "false"

        case .andLogic:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            return (logoIsTrue(v1) && logoIsTrue(v2)).logoString

        case .orLogic:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            return (logoIsTrue(v1) || logoIsTrue(v2)).logoString

        case .xorLogic:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v1 = reader.nextExpression()
            let v2 = reader.nextExpression()
            reader.commit(to: &index)
            return (logoIsTrue(v1) != logoIsTrue(v2)).logoString

        case .notLogic:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let v = reader.nextExpression()
            reader.commit(to: &index)
            return (!logoIsTrue(v)).logoString

        default:
            return nil
        }
    }

}
