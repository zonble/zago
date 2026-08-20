import Foundation

/// Manages clipboard content for text lines and canvas block regions by delegating to a strategy.
public final class ClipboardCoordinator: @unchecked Sendable {
    public let strategy: any EditorClipboardStrategy
    public var lastMutationTime: Date? = nil
    public var lastIsPaste: Bool = false

    public var clipboardText: String? {
        get { strategy.getText() }
        set {
            if let newValue {
                strategy.copyText(newValue)
            } else {
                strategy.clear()
            }
        }
    }

    public var canvasBlockClipboard: CanvasBlockClipboard? {
        get { strategy.getBlock() }
        set {
            if let newValue {
                strategy.copyBlock(newValue)
            } else {
                strategy.clear()
            }
        }
    }

    public init(strategy: any EditorClipboardStrategy = InMemoryClipboardStrategy()) {
        self.strategy = strategy
    }

    /// Clears both text and canvas block clipboards.
    public func clear() {
        strategy.clear()
        lastMutationTime = nil
        lastIsPaste = false
    }
}
