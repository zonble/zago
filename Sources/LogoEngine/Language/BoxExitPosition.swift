import Foundation

/// Defines the cursor exit position after drawing a box in LogoEngine.
public enum BoxExitPosition: String, Sendable, CaseIterable {
    case ne
    case se
    case nw
    case sw
    case down

    public init?(_ raw: String) {
        let clean = raw.lowercased().filter { $0.isLetter || $0.isNumber }
        switch clean {
        case "ne", "atne", "topright": self = .ne
        case "se", "atse", "bottomright": self = .se
        case "nw", "atnw", "topleft": self = .nw
        case "sw", "atsw", "bottomleft": self = .sw
        case "down", "atdown", "bottom", "s", "south": self = .down
        default: return nil
        }
    }

    public static func parse(_ raw: String) -> BoxExitPosition? {
        BoxExitPosition(raw)
    }
}
