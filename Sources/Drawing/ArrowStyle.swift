import Foundation

/// Unified source-of-truth for arrow head visual styles.
public enum ArrowStyle: String, CaseIterable, Sendable {
    case ascii = "ascii"  // ^ v < > (ASCII arrows)
    case solid = "solid"  // ▲ ▼ ◀ ▶ (Unicode filled triangles)
    case stemmed = "stemmed"  // ↑ ↓ ← → (Stemmed line arrows)
    case hollow = "hollow"  // △ ▽ ◁ ▷ (Outline triangle arrows)
    case small = "small"  // ▴ ▾ ◂ ▸ (Small triangle pointers)

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
