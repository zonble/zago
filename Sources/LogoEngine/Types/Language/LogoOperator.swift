import Foundation

/// Strongly-typed enum representing infix arithmetic and comparison operators in LOGO expressions.
enum LogoOperator: String, CaseIterable, Equatable, Sendable {
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
    init?(token: String) {
        self.init(rawValue: token)
    }

    /// Resolves an operator string to a strongly-typed LogoOperator enum.
    static func parse(_ token: String) -> LogoOperator? {
        LogoOperator(token: token)
    }

    /// Resolves an operator string to a strongly-typed LogoOperator enum.
    static func from(_ token: String) -> LogoOperator? {
        LogoOperator(token: token)
    }

    static let tokens = Set(allCases.map(\.rawValue))

    /// Whether this operator is an arithmetic operator (+, -, *, /, %, ^).
    var isArithmetic: Bool {
        switch self {
        case .add, .subtract, .multiply, .divide, .modulo, .power:
            return true
        default:
            return false
        }
    }

    /// Whether this operator is a comparison operator (==, =, !=, <>, <, <=, >, >=).
    var isComparison: Bool {
        switch self {
        case .equal, .aliasEqual, .notEqual, .aliasNotEqual, .lessThan, .lessOrEqual, .greaterThan, .greaterOrEqual:
            return true
        default:
            return false
        }
    }

    var isSingleCharacter: Bool { rawValue.count == 1 }
}
