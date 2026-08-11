import Foundation

extension Editor {
    public static let logoDebuggerBufferTitle = "*LOGO Debugger*"

    public func showLogoDebuggerBuffer() {
        let source = buffer
        let lines = debuggerController.breakpoints(in: source)
        let debugBuffer: TextBuffer
        if let index = buffers.firstIndex(where: { $0.filePath == Self.logoDebuggerBufferTitle }) {
            debugBuffer = buffers[index]
            currentBufferIndex = index
        } else {
            debugBuffer = LogoOutputBuffer()
            debugBuffer.filePath = Self.logoDebuggerBufferTitle
            buffers.append(debugBuffer)
            currentBufferIndex = buffers.count - 1
        }
        debugBuffer.lines = ["LOGO Debugger", "", "Breakpoints — \(source.filePath ?? source.id)"]
            + (lines.isEmpty ? ["  (none)"] : lines.map { "  ● line \($0 + 1)" })
            + ["", "Commands: :logo break | :logo breaks | :logo eval"]
        debugBuffer.lineIndex = 0
        debugBuffer.columnIndex = 0
    }

    public func toggleLogoDebuggerBuffer() { showLogoDebuggerBuffer() }
}
