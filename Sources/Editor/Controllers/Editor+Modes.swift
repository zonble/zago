import Foundation

public enum EditorBaseMode: String, Sendable, Equatable {
    case text
    case canvas
}

public enum EditorOverlayMode: String, Sendable, Equatable {
    case none
    case table
}

extension Editor {
    var isCanvasModeActive: Bool {
        baseMode == .canvas
    }

    func switchToTextMode() {
        if baseMode == .canvas {
            syncCanvasCursorToBuffer()
        }
        clearActiveMark()
        baseMode = .text
        clearModeStatusMessage()
        renderer.invalidateScreenCache()
    }

    func switchToCanvasMode() {
        guard !buffer.isReadOnly else {
            reportOperationResult(.noOp(message: l10n["status.buffer_readonly_bracketed"]))
            return
        }
        let wasCanvasMode = baseMode == .canvas
        clearActiveMark()
        baseMode = .canvas
        if !wasCanvasMode {
            syncCanvasCursorFromBuffer()
        }
        clearModeStatusMessage()
        renderer.invalidateScreenCache()
    }

    private func clearModeStatusMessage() {
        switch statusMessage {
        case "[ Text Editing Mode ]", "[ Canvas Mode ]":
            reportOperationResult(.succeeded(message: ""))
        default:
            break
        }
    }

    func toggleCanvasMode() {
        if baseMode == .canvas {
            switchToTextMode()
        } else {
            switchToCanvasMode()
        }
    }

    func modeIndicatorText() -> String {
        var labels: [String] = []
        if baseMode == .canvas {
            labels.append(l10n["mode.canvas"])
        }
        if isTableModeActive {
            labels.append(l10n["mode.table"])
        }
        return labels.joined(separator: " | ")
    }
}
