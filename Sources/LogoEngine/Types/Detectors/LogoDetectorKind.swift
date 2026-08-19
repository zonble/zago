import Foundation

/// Defines data detector detection categories in LogoEngine.
public enum LogoDetectorKind: Sendable, Equatable {
    case url
    case email
    case phone
    case date
    case address

    public init?(_ primitive: LogoPrimitive) {
        switch primitive {
        case .detectURL: self = .url
        case .detectEmail: self = .email
        case .detectPhone: self = .phone
        case .detectDate: self = .date
        case .detectAddress: self = .address
        default: return nil
        }
    }

    public init?(raw: String) {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        switch stripped {
        case "url", "link": self = .url
        case "email", "mail": self = .email
        case "phone", "tel": self = .phone
        case "date", "time": self = .date
        case "address", "addr": self = .address
        default: return nil
        }
    }

    public static func parse(_ raw: String) -> LogoDetectorKind? {
        LogoDetectorKind(raw: raw)
    }
}
