import Foundation

/// Available full keymap presets for the editor.
public enum KeymapPreset: String, CaseIterable, Sendable, Hashable {
    /// Classic GNU Nano style keybindings (^O WriteOut, ^W WhereIs, ^K Cut, ^U Uncut, M-U Undo).
    case classic

    /// Modern VS Code / CUA style keybindings (^S Save, ^F Find, ^H Replace, ^Z Undo, ^Y Redo, ^A Select All, ^Q Exit).
    case modern
}
