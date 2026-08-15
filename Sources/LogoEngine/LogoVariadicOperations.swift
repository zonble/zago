import Foundation

/// Pure implementations for variadic primitives that only transform values.
internal func evaluateVariadicValuePrimitive(_ primitive: LogoPrimitive, arguments: [String]) -> String? {
    switch primitive {
    case .word:
        return arguments.joined()

    case .list:
        return "[" + arguments.joined(separator: " ") + "]"

    case .sentence:
        var items: [LogoValue] = []
        for argument in arguments {
            switch LogoValue.parse(argument) {
            case .list(let values), .array(let values):
                items.append(contentsOf: values)
            case .string(let value):
                items.append(.string(value))
            }
        }
        return LogoValue.list(items).description

    case .sum, .product, .min, .max:
        let values = arguments.flatMap { numericValues(in: LogoValue.parse($0)) }
        switch primitive {
        case .sum: return formatNum(values.reduce(0, +))
        case .product: return formatNum(values.reduce(1, *))
        case .min: return formatNum(values.min() ?? 0)
        case .max: return formatNum(values.max() ?? 0)
        default: return nil
        }

    case .andLogic:
        return arguments.allSatisfy(logoIsTrue) ? "1" : "0"

    case .orLogic:
        return arguments.contains(where: logoIsTrue) ? "1" : "0"

    default:
        return nil
    }
}
