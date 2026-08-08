import Foundation

extension Editor {
    public static let logoOutputBufferTitle = "*LOGO Output*"

    public func findLogoOutputBufferIndex() -> Int? {
        buffers.firstIndex { $0.filePath == Self.logoOutputBufferTitle }
    }

    @discardableResult
    public func ensureLogoOutputBuffer() -> TextBuffer {
        if let idx = findLogoOutputBufferIndex() {
            return buffers[idx]
        }
        let buf = TextBuffer()
        buf.filePath = Self.logoOutputBufferTitle
        buf.baseMode = .text
        buf.viewShowRuler = false
        buf.viewShowLineNumbers = true
        buf.isReadOnly = true
        buf.lines = [
            "================================================================================",
            " zago LOGO Output History Log",
            "================================================================================",
            ""
        ]
        buffers.append(buf)
        return buf
    }

    public func appendLogoOutputHeader(_ scriptName: String) {
        let buf = ensureLogoOutputBuffer()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let header = "--- [\(timestamp)] Run: \(scriptName) ---"
        buf.lines.append(header)
    }

    public func appendLogoOutput(_ text: String, scriptName: String? = nil) {
        guard !text.isEmpty else { return }
        let buf = ensureLogoOutputBuffer()
        if let scriptName {
            appendLogoOutputHeader(scriptName)
        }
        let split = text.components(separatedBy: "\n")
        buf.lines.append(contentsOf: split)
    }

    public func toggleLogoOutputBuffer() {
        if let idx = findLogoOutputBufferIndex() {
            if currentBufferIndex == idx {
                let prevIdx = (idx - 1 + buffers.count) % buffers.count
                switchToBuffer(index: prevIdx)
            } else {
                switchToBuffer(index: idx)
            }
        } else {
            ensureLogoOutputBuffer()
            if let idx = findLogoOutputBufferIndex() {
                switchToBuffer(index: idx)
            }
        }
    }

    public func clearLogoOutputBuffer() {
        let buf = ensureLogoOutputBuffer()
        buf.lines = [
            "================================================================================",
            " zago LOGO Output History Log",
            "================================================================================",
            ""
        ]
        setStatusMessage("Cleared *LOGO Output* buffer.")
    }

    public static let logoCanvasBufferTitle = "*LOGO Canvas*"

    public func findLogoCanvasBufferIndex() -> Int? {
        buffers.firstIndex { $0.filePath == Self.logoCanvasBufferTitle }
    }

    @discardableResult
    public func ensureLogoCanvasBuffer() -> TextBuffer {
        if let idx = findLogoCanvasBufferIndex() {
            return buffers[idx]
        }
        let buf = TextBuffer()
        buf.filePath = Self.logoCanvasBufferTitle
        buf.baseMode = .canvas
        buf.viewShowRuler = false
        buf.viewShowLineNumbers = true
        buf.lines = Array(repeating: String(repeating: " ", count: 80), count: 24)
        buffers.append(buf)
        return buf
    }

    public func toggleLogoCanvasBuffer() {
        if let idx = findLogoCanvasBufferIndex() {
            if currentBufferIndex == idx {
                let prevIdx = (idx - 1 + buffers.count) % buffers.count
                switchToBuffer(index: prevIdx)
            } else {
                switchToBuffer(index: idx)
            }
        } else {
            ensureLogoCanvasBuffer()
            if let idx = findLogoCanvasBufferIndex() {
                switchToBuffer(index: idx)
            }
        }
    }

    public func clearLogoCanvasBuffer() {
        let buf = ensureLogoCanvasBuffer()
        buf.lines = Array(repeating: String(repeating: " ", count: 80), count: 24)
        setStatusMessage("Cleared *LOGO Canvas* buffer.")
    }

    public func clearLogoOutputAndCanvasBuffers() {
        clearLogoOutputBuffer()
        clearLogoCanvasBuffer()
        setStatusMessage("Cleared LOGO Output & Canvas buffers.")
    }
}
