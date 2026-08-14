import Foundation

/// Represents the active high-level interaction mode in the Editor.
public enum EditorMode: String, CaseIterable, Sendable, Hashable {
    case text
    case canvas
    case table
    case prompt
    case menu
}
