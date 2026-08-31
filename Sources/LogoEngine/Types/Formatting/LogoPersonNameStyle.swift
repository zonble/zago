import Foundation

/// Supported styles for person name formatting in LogoEngine.
public enum LogoPersonNameStyle: Sendable, Equatable {
    public static let allowedStyleNames: [String] = ["medium", "short", "long", "abbreviated"]

    case `default`
    case short
    case medium
    case long
    case abbreviated

    public init?(keyword raw: String) {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let clean = lower.hasPrefix(":") ? String(lower.dropFirst()) : lower
        switch clean {
        case "short", "nickname", "given":
            self = .short
        case "long", "full", "formal":
            self = .long
        case "abbreviated", "abbr", "initials", "initial":
            self = .abbreviated
        case "medium", "default", "standard":
            self = .medium
        default:
            return nil
        }
    }

    #if canImport(Darwin)
        public var formatterStyle: PersonNameComponentsFormatter.Style {
            switch self {
            case .default, .medium: return .medium
            case .short: return .short
            case .long: return .long
            case .abbreviated: return .abbreviated
            }
        }
    #endif

    public static func parse(_ raw: String) -> LogoPersonNameStyle {
        LogoPersonNameStyle(keyword: raw) ?? .medium
    }

    public static func isStyleKeyword(_ raw: String) -> Bool {
        LogoPersonNameStyle(keyword: raw) != nil
    }
}
