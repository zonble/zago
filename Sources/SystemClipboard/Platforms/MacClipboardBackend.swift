import Editor
import Foundation

#if canImport(AppKit)
    import AppKit

    internal final class MacClipboardBackend: EditorClipboardStrategy, @unchecked Sendable {
        private static let blockType = NSPasteboard.PasteboardType("org.zago.canvas-block")
        private let lock = NSLock()

        init() {}

        func copyText(_ text: String) {
            lock.lock()
            defer { lock.unlock() }

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }

        func copyBlock(_ block: CanvasBlockClipboard) {
            lock.lock()
            defer { lock.unlock() }

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()

            // 1. Write plain text for external applications
            let plainText = block.rows.joined(separator: "\n")
            pasteboard.setString(plainText, forType: .string)

            // 2. Write custom JSON data for zago Canvas Block recognition
            if let blockData = try? JSONEncoder().encode(block) {
                pasteboard.setData(blockData, forType: Self.blockType)
            }
        }

        func getText() -> String? {
            lock.lock()
            defer { lock.unlock() }

            let pasteboard = NSPasteboard.general
            return pasteboard.string(forType: .string)
        }

        func getBlock() -> CanvasBlockClipboard? {
            lock.lock()
            defer { lock.unlock() }

            let pasteboard = NSPasteboard.general
            guard let data = pasteboard.data(forType: Self.blockType),
                let block = try? JSONDecoder().decode(CanvasBlockClipboard.self, from: data)
            else {
                return nil
            }
            return block
        }

        func clear() {
            lock.lock()
            defer { lock.unlock() }

            NSPasteboard.general.clearContents()
        }
    }
#endif
