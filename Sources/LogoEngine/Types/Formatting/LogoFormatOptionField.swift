import Foundation

/// Common key fields supported in formatting options dictionaries.
public enum LogoFormatOptionField: String, CaseIterable, Sendable, Equatable {
    case style
    case format
    case locale
    case language
    case currency
    case precision
    case unit
    case calendar
    case date
    case time

    public static func parse(_ raw: String) -> LogoFormatOptionField? {
        let clean = raw.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\"' ")).trimmingCharacters(in: .whitespacesAndNewlines)
        switch clean {
        case "style": return .style
        case "fmt", "format": return .format
        case "locale", "loc": return .locale
        case "lang", "language": return .language
        case "currency", "curr": return .currency
        case "precision", "prec", "digits": return .precision
        case "unit": return .unit
        case "calendar", "cal": return .calendar
        case "date": return .date
        case "time": return .time
        default: return nil
        }
    }
}
