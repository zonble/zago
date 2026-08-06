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
    public var isCanvasModeActive: Bool {
        baseMode == .canvas
    }

    public func switchToTextMode() {
        if baseMode == .canvas {
            syncCanvasCursorToBuffer()
        }
        clearActiveMark()
        baseMode = .text
        clearModeStatusMessage()
    }

    public func switchToCanvasMode() {
        let wasCanvasMode = baseMode == .canvas
        clearActiveMark()
        baseMode = .canvas
        if !wasCanvasMode {
            syncCanvasCursorFromBuffer()
        }
        clearModeStatusMessage()
    }

    private func clearModeStatusMessage() {
        switch statusMessage {
        case "[ Text Editing Mode ]", "[ Canvas Mode ]":
            setStatusMessage("")
        default:
            break
        }
    }

    public func toggleCanvasMode() {
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
