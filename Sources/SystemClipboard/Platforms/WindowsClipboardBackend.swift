import Editor
import Foundation

#if os(Windows)
    import WinSDK

    internal final class WindowsClipboardBackend: EditorClipboardStrategy, @unchecked Sendable {
        private let customFormat: UINT
        private let lock = NSLock()

        init() {
            let formatName: [WCHAR] = Array("ZagoCanvasBlock".utf16) + [0]
            self.customFormat = RegisterClipboardFormatW(formatName)
        }

        func copyText(_ text: String) {
            lock.lock()
            defer { lock.unlock() }

            guard OpenClipboard(nil) else { return }
            defer { CloseClipboard() }
            EmptyClipboard()

            setUnicodeText(text)
        }

        func copyBlock(_ block: CanvasBlockClipboard) {
            lock.lock()
            defer { lock.unlock() }

            guard OpenClipboard(nil) else { return }
            defer { CloseClipboard() }
            EmptyClipboard()

            // 1. Write plain text for external applications
            let plainText = block.rows.joined(separator: "\r\n")
            setUnicodeText(plainText)

            // 2. Write custom JSON data for zago Canvas Block
            if customFormat != 0, let data = try? JSONEncoder().encode(block) {
                setCustomData(format: customFormat, data: data)
            }
        }

        func getText() -> String? {
            lock.lock()
            defer { lock.unlock() }

            guard OpenClipboard(nil) else { return nil }
            defer { CloseClipboard() }

            guard let handle = GetClipboardData(UINT(CF_UNICODETEXT)) else { return nil }
            guard let ptr = GlobalLock(handle) else { return nil }
            defer { GlobalUnlock(handle) }

            let wideChars = ptr.assumingMemoryBound(to: WCHAR.self)
            return String(decodingCString: wideChars, as: UTF16.self)
        }

        func getBlock() -> CanvasBlockClipboard? {
            lock.lock()
            defer { lock.unlock() }

            guard customFormat != 0, OpenClipboard(nil) else { return nil }
            defer { CloseClipboard() }

            guard let handle = GetClipboardData(customFormat) else { return nil }
            let size = GlobalSize(handle)
            guard size > 0, let ptr = GlobalLock(handle) else { return nil }
            defer { GlobalUnlock(handle) }

            let data = Data(bytes: ptr, count: Int(size))
            return try? JSONDecoder().decode(CanvasBlockClipboard.self, from: data)
        }

        func clear() {
            lock.lock()
            defer { lock.unlock() }

            guard OpenClipboard(nil) else { return }
            defer { CloseClipboard() }
            EmptyClipboard()
        }

        private func setUnicodeText(_ text: String) {
            let utf16 = Array(text.utf16) + [0]
            let byteCount = utf16.count * MemoryLayout<WCHAR>.size

            guard let hGlobal = GlobalAlloc(UINT(GMEM_MOVEABLE), SIZE_T(byteCount)) else { return }
            guard let ptr = GlobalLock(hGlobal) else {
                GlobalFree(hGlobal)
                return
            }

            ptr.copyMemory(from: utf16, byteCount: byteCount)
            GlobalUnlock(hGlobal)

            if SetClipboardData(UINT(CF_UNICODETEXT), hGlobal) == nil {
                GlobalFree(hGlobal)
            }
        }

        private func setCustomData(format: UINT, data: Data) {
            let byteCount = data.count
            guard byteCount > 0, let hGlobal = GlobalAlloc(UINT(GMEM_MOVEABLE), SIZE_T(byteCount)) else { return }
            guard let ptr = GlobalLock(hGlobal) else {
                GlobalFree(hGlobal)
                return
            }

            data.withUnsafeBytes { rawBuffer in
                if let baseAddress = rawBuffer.baseAddress {
                    ptr.copyMemory(from: baseAddress, byteCount: byteCount)
                }
            }
            GlobalUnlock(hGlobal)

            if SetClipboardData(format, hGlobal) == nil {
                GlobalFree(hGlobal)
            }
        }
    }
#endif
