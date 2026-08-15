import Foundation

/// Strongly-typed 4-directional heading for the LOGO turtle in the character grid.
enum LogoHeading: String, Sendable, CaseIterable, Equatable {
    case up = "UP"
    case right = "RIGHT"
    case down = "DOWN"
    case left = "LEFT"

    var turnedRight: LogoHeading {
        switch self {
        case .up: .right
        case .right: .down
        case .down: .left
        case .left: .up
        }
    }

    var turnedLeft: LogoHeading {
        switch self {
        case .up: .left
        case .left: .down
        case .down: .right
        case .right: .up
        }
    }

    var opposite: LogoHeading {
        switch self {
        case .up: .down
        case .right: .left
        case .down: .up
        case .left: .right
        }
    }

    static func parse(_ raw: String) -> LogoHeading? {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let unquoted = clean.hasPrefix("\"") ? String(clean.dropFirst()) : (clean.hasPrefix(":") ? String(clean.dropFirst()) : clean)
        let stripped = unquoted.trimmingCharacters(in: CharacterSet(charactersIn: "\"|")).uppercased()
        return switch stripped {
        case "UP", "TOP":
            .up
        case "RIGHT":
            .right
        case "DOWN", "BOTTOM":
            .down
        case "LEFT":
            .left
        default:
            nil
        }
    }
}
