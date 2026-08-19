import Foundation

/// Defines formatting styles for numbers in LogoEngine.
public enum LogoNumberStyle: String, CaseIterable, Sendable, Equatable {
    case decimal = "decimal"
    case currency = "currency"
    case percent = "percent"
    case roman = "roman"
    case financial = "financial"
    case ordinal = "ordinal"
    case spellout = "spellout"

    public init?(keyword raw: String) {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
        switch clean {
        case "spellout", "words", "word", "text", "chinese", "cjk", "spoken":
            self = .spellout
        case "financial", "capital", "caps", "cap", "upper", "check", "cheque", "bank", "invoice", "traditional", "daxie":
            self = .financial
        case "currency", "money", "curr", "cash":
            self = .currency
        case "percent", "percentage", "pct":
            self = .percent
        case "roman", "romannumeral":
            self = .roman
        case "ordinal", "ord":
            self = .ordinal
        case "decimal", "number", "num", "grouping":
            self = .decimal
        default:
            return nil
        }
    }

    public var numberFormatterStyle: NumberFormatter.Style? {
        switch self {
        case .ordinal: return .ordinal
        case .spellout: return .spellOut
        case .currency: return .currency
        case .percent: return .percent
        case .decimal: return .decimal
        case .roman, .financial: return nil
        }
    }

    public static func parse(_ raw: String) -> LogoNumberStyle {
        LogoNumberStyle(keyword: raw) ?? .decimal
    }

    public static func isStyleKeyword(_ raw: String) -> Bool {
        LogoNumberStyle(keyword: raw) != nil
    }
}
