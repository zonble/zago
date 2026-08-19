import Foundation

/// Defines formatting styles for numbers in LogoEngine.
public enum LogoNumberStyle: Sendable, Equatable {
    case decimal
    case percent
    case currency
    case spellout
    case financial
    case roman
    case ordinal

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

    public static func parse(_ raw: String) -> LogoNumberStyle {
        LogoNumberStyle(keyword: raw) ?? .decimal
    }

    public static func isStyleKeyword(_ raw: String) -> Bool {
        LogoNumberStyle(keyword: raw) != nil
    }
}
