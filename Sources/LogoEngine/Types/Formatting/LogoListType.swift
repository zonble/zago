import Foundation

/// Supported list join types for LogoEngine list formatting.
public enum LogoListType: Sendable, Equatable {
    case and
    case or
    case unit

    public init?(keyword raw: String) {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
        switch clean {
        case "or", "disjunction":
            self = .or
        case "unit", "narrow", "comma":
            self = .unit
        case "and", "standard", "conjunction":
            self = .and
        default:
            return nil
        }
    }

    public static func parse(_ raw: String) -> LogoListType {
        LogoListType(keyword: raw) ?? .and
    }

    public static func isTypeKeyword(_ raw: String) -> Bool {
        LogoListType(keyword: raw) != nil
    }
}
