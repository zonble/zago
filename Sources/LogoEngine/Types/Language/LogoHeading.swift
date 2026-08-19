import Foundation

/// Strongly-typed 4-directional heading for the LOGO turtle in the character grid.
public enum LogoHeading: String, Sendable, CaseIterable, Equatable {
    case up = "UP"
    case right = "RIGHT"
    case down = "DOWN"
    case left = "LEFT"

    public var turnedRight: LogoHeading {
        switch self {
        case .up: .right
        case .right: .down
        case .down: .left
        case .left: .up
        }
    }

    public var turnedLeft: LogoHeading {
        switch self {
        case .up: .left
        case .left: .down
        case .down: .right
        case .right: .up
        }
    }

    public var opposite: LogoHeading {
        switch self {
        case .up: .down
        case .right: .left
        case .down: .up
        case .left: .right
        }
    }

    public init?(raw: String) {
        self.init(raw)
    }

    public init?(_ raw: String) {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let unquoted =
            clean.hasPrefix("\"")
            ? String(clean.dropFirst()) : (clean.hasPrefix(":") ? String(clean.dropFirst()) : clean)
        let stripped = unquoted.trimmingCharacters(in: CharacterSet(charactersIn: "\"|")).uppercased()
        switch stripped {
        case "UP", "TOP": self = .up
        case "RIGHT": self = .right
        case "DOWN", "BOTTOM": self = .down
        case "LEFT": self = .left
        default: return nil
        }
    }

    public static func parse(_ raw: String, registry: LogoPluginRegistry? = nil) -> LogoHeading? {
        if let registry, let heading = registry.parseHeading(raw) {
            return heading
        }
        return LogoHeading(raw)
    }
}
