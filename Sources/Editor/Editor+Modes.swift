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
        baseMode = .text
        if overlayMode == .frame {
            overlayMode = .none
        }
        setStatusMessage("[ Text Editing Mode ]")
    }

    public func switchToCanvasMode() {
        baseMode = .canvas
        setStatusMessage("[ Canvas Mode ]")
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
            overlayMode = .none
            setStatusMessage("[ Frame Mode Exited ]")
            return
        }

        if isTableModeActive {
            setStatusMessage("[ Frame Mode disabled in Table Mode ]")
            return
        }

        baseMode = .canvas
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
