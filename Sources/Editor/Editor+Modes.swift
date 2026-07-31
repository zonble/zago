import Foundation

public enum EditorBaseMode: String, Sendable, Equatable {
    case text
    case canvas
}

public enum EditorOverlayMode: String, Sendable, Equatable {
    case none
    case table
    case frame
}

extension Editor {
    public var isCanvasModeActive: Bool {
        baseMode == .canvas
    }

    public var isFrameModeActive: Bool {
        overlayMode == .frame
    }

    public func switchToTextMode() {
        if baseMode == .canvas {
            syncCanvasCursorToBuffer()
        }
        clearActiveMark()
        baseMode = .text
        if overlayMode == .frame {
            overlayMode = .none
        }
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

    public func toggleFrameMode() {
        if overlayMode == .frame {
            clearActiveMark()
            overlayMode = .none
            setStatusMessage("[ Frame Mode Exited ]")
            return
        }

        if isTableModeActive {
            setStatusMessage("[ Frame Mode disabled in Table Mode ]")
            return
        }

        let wasCanvasMode = baseMode == .canvas
        clearActiveMark()
        baseMode = .canvas
        if !wasCanvasMode {
            syncCanvasCursorFromBuffer()
        }
        overlayMode = .frame
        setStatusMessage("[ FRAME MODE ]")
    }

    func modeIndicatorText() -> String {
        var labels: [String] = []
        if baseMode == .canvas {
            labels.append("CANVAS")
        }
        if isTableModeActive {
            labels.append("TABLE")
        } else if overlayMode == .frame {
            labels.append("FRAME")
        }
        return labels.joined(separator: " | ")
    }
}
