import Editor
import Foundation

/// Primary cross-platform system clipboard implementation for zago.
public final class SystemClipboardStrategy: EditorClipboardStrategy, @unchecked Sendable {
    private let backend: any EditorClipboardStrategy

    public init() {
        #if canImport(AppKit)
            self.backend = MacClipboardBackend()
        #elseif os(Windows)
            self.backend = WindowsClipboardBackend()
        #elseif os(Linux) || os(Android)
            self.backend = LinuxClipboardBackend()
        #else
            self.backend = FallbackClipboardBackend()
        #endif
    }

    public func copyText(_ text: String) {
        backend.copyText(text)
    }

    public func copyBlock(_ block: CanvasBlockClipboard) {
        backend.copyBlock(block)
    }

    public func getText() -> String? {
        backend.getText()
    }

    public func getBlock() -> CanvasBlockClipboard? {
        backend.getBlock()
    }

    public func clear() {
        backend.clear()
    }
}
