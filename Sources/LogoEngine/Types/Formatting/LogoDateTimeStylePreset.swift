import Foundation

/// Supported style presets and custom pattern specifications for date/time formatting.
public enum LogoDateTimeStylePreset: Sendable, Equatable {
    public static let allowedPresetNames: [String] = ["short", "medium", "long", "full", "iso8601"]

    case short
    case medium
    case long
    case full
    case iso8601
    case custom(String)

    public init(raw: String, mode: LogoDateTimeMode) {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
        switch clean {
        case "short": self = .short
        case "medium", "med": self = .medium
        case "long": self = .long
        case "full": self = .full
        case "iso8601", "iso": self = .iso8601
        default:
            if clean.isEmpty {
                switch mode {
                case .date: self = .custom("yyyy-MM-dd")
                case .time: self = .custom("HH:mm:ss")
                case .dateTime: self = .custom("yyyy-MM-dd HH:mm:ss")
                }
            } else {
                self = .custom(raw)
            }
        }
    }

    public static func parse(_ raw: String, mode: LogoDateTimeMode) -> LogoDateTimeStylePreset {
        LogoDateTimeStylePreset(raw: raw, mode: mode)
    }

    public static func isPresetName(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        switch stripped {
        case "short", "medium", "med", "long", "full", "iso8601", "iso":
            return true
        default:
            return false
        }
    }

    public var dateStyle: DateFormatter.Style? {
        switch self {
        case .short: return .short
        case .medium: return .medium
        case .long: return .long
        case .full: return .full
        default: return nil
        }
    }
}
