import Foundation

/// Unified source-of-truth for arrow head visual styles.
public enum ArrowStyle: String, CaseIterable, Sendable {
    case ascii = "ascii"  // ^ v < > (ASCII arrows)
    case solid = "solid"  // ▲ ▼ ◀ ▶ (Unicode filled triangles)
    case stemmed = "stemmed"  // ↑ ↓ ← → (Stemmed line arrows)
    case hollow = "hollow"  // △ ▽ ◁ ▷ (Outline triangle arrows)
    case small = "small"  // ▴ ▾ ◂ ▸ (Small triangle pointers)
    case double = "double"  // ⇑ ⇓ ⇐ ⇒ (Double line arrows)
    case heavy = "heavy"  // ⬆ ⬇ ⬅ ⮕ (Heavy line arrows)
    case diamond = "diamond"  // ◇ ◇ ◇ ◇ (Hollow diamond / UML aggregation)
    case solidDiamond = "solid-diamond"  // ◆ ◆ ◆ ◆ (Solid diamond / UML composition)
    case circle = "circle"  // ● ● ● ● (Solid circle / State start)
    case openCircle = "open-circle"  // ○ ○ ○ ○ (Open circle / State end / interface)
    case cross = "cross"  // ✕ ✕ ✕ ✕ (Cross / Inactive / Cancel)
    case crow = "crow"  // ⤘ ⤛ ⤙ ⤚ (Crow's foot / ERD many)
    case harpoon = "harpoon"  // ↿ ⇂ ↼ ⇀ (Harpoon half-arrows)

    public init?(_ token: String) {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "ascii":
            self = .ascii
        case "solid":
            self = .solid
        case "stemmed":
            self = .stemmed
        case "hollow":
            self = .hollow
        case "small":
            self = .small
        case "double":
            self = .double
        case "heavy":
            self = .heavy
        case "diamond", "hollow-diamond":
            self = .diamond
        case "solid-diamond", "soliddiamond", "black-diamond":
            self = .solidDiamond
        case "circle", "dot", "bullet", "solid-circle":
            self = .circle
        case "open-circle", "opencircle", "hollow-circle":
            self = .openCircle
        case "cross", "x":
            self = .cross
        case "crow", "crowsfoot", "crows-foot":
            self = .crow
        case "harpoon":
            self = .harpoon
        default:
            return nil
        }
    }

    public static func from(_ token: String) -> ArrowStyle {
        ArrowStyle(token) ?? .solid
    }

    public static func isStyleToken(_ token: String) -> Bool {
        ArrowStyle(token) != nil
    }
}
