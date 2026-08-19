import Foundation

/// Defines formatting modes for LOGO date/time operations.
public enum LogoDateTimeMode: Sendable, Equatable {
    case date
    case time
    case dateTime

    public init?(raw: String) {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        switch stripped {
        case "date": self = .date
        case "time": self = .time
        case "datetime", "date_time", "dateTime": self = .dateTime
        default: return nil
        }
    }
}
