import Foundation

/// Pure value operations shared by LOGO expression and template evaluation.
internal func formatNum(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0,
        value >= Double(Int.min), value <= Double(Int.max)
    {
        return "\(Int(value))"
    }
    return "\(value)"
}

internal func numericSum(of value: LogoValue) -> Double {
    switch value {
    case .string(let string):
        return Double(string) ?? 0
    case .measurement(let val, _, _):
        return val
    case .list(let items), .array(let items):
        return items.reduce(0) { $0 + numericSum(of: $1) }
    }
}

internal func numericValues(in value: LogoValue) -> [Double] {
    switch value {
    case .string(let string):
        return Double(string).map { [$0] } ?? []
    case .measurement(let val, _, _):
        return [val]
    case .list(let items), .array(let items):
        return items.flatMap { numericValues(in: $0) }
    }
}

internal func numericExtremum(of value: LogoValue, preferMaximum: Bool) -> Double? {
    let values = numericValues(in: value)
    guard var result = values.first else { return nil }
    for value in values.dropFirst() {
        result = preferMaximum ? Swift.max(result, value) : Swift.min(result, value)
    }
    return result
}

internal func logoIsTrue(_ value: String) -> Bool {
    let clean = value.lowercased().trimmingCharacters(in: .whitespaces)
    if clean == "1" || clean == "true" { return true }
    if clean == "0" || clean == "false" || clean.isEmpty { return false }
    if let number = Double(clean) { return number != 0 }
    return true
}
