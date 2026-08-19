import Foundation

/// Manages clipboard content for text lines and canvas block regions.
public final class ClipboardCoordinator: @unchecked Sendable {
    public var clipboardText: String? = nil
    public var canvasBlockClipboard: CanvasBlockClipboard? = nil
    public var lastMutationTime: Date? = nil
    public var lastIsPaste: Bool = false

    public init() {}

    /// Clears both text and canvas block clipboards.
    public func clear() {
        clipboardText = nil
        canvasBlockClipboard = nil
        lastMutationTime = nil
        lastIsPaste = false
    }
}
