import Foundation

/// Unified interface for mode and controller key event handling.
public protocol KeyInputHandler: AnyObject {
    /// Attempts to handle the input key for this mode or controller.
    /// - Parameters:
    ///   - key: The key input event.
    ///   - editor: The main editor instance providing environment and state access.
    /// - Returns: `true` if the key was consumed by this handler, `false` to let the key pass through to the next handler.
    func handleKey(_ key: Key, editor: Editor) -> Bool
}
