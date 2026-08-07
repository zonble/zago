import Foundation

/// Unified source-of-truth for arrow head visual styles (Unicode-only customization).
public enum ArrowStyle: String, CaseIterable, Sendable {
    case solid = "solid"       // ▲ ▼ ◀ ▶ (Default Unicode filled triangles)
    case stemmed = "stemmed"   // ↑ ↓ ← → (Legacy stemmed line arrows)
    case hollow = "hollow"     // △ ▽ ◁ ▷ (Outline triangle arrows)
    case small = "small"       // ▴ ▾ ◂ ▸ (Small triangle pointers)

    public init?(_ token: String) {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "solid", "fill", "filled", "black", "triangle":
            self = .solid
        case "stemmed", "stem", "line", "thin", "classic":
            self = .stemmed
        case "hollow", "outline", "white":
            self = .hollow
        case "small", "mini", "pointer":
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
