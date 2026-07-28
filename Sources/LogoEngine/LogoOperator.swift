import Foundation

/// Strongly-typed enum representing infix arithmetic and comparison operators in LOGO expressions.
public enum LogoOperator: String, CaseIterable, Equatable, Sendable {
    // Arithmetic Operators
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"
    case power = "^"

    // Comparison Operators
    case equal = "=="
    case aliasEqual = "="
    case notEqual = "!="
    case aliasNotEqual = "<>"
    case lessThan = "<"
    case lessOrEqual = "<="
    case greaterThan = ">"
    case greaterOrEqual = ">="

    /// Resolves an operator string to a strongly-typed LogoOperator enum.
    public static func from(_ token: String) -> LogoOperator? {
        LogoOperator(rawValue: token)
    }

    /// Whether this operator is an arithmetic operator (+, -, *, /, %, ^).
    public var isArithmetic: Bool {
        switch self {
        case .add, .subtract, .multiply, .divide, .modulo, .power:
            return true
        default:
            return false
        }
    }

    /// Whether this operator is a comparison operator (==, =, !=, <>, <, <=, >, >=).
    public var isComparison: Bool {
        switch self {
        case .equal, .aliasEqual, .notEqual, .aliasNotEqual, .lessThan, .lessOrEqual, .greaterThan, .greaterOrEqual:
            return true
        default:
            return false
        }
    }
}
