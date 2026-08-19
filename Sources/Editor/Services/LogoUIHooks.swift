import Drawing
import Foundation
import LogoEngine

/// Closures for intercepting UI-specific LOGO actions and queries when running inside an interactive Editor.
public struct LogoUIHooks: @unchecked Sendable {
    public var onSaveUndoSnapshot: (@Sendable () -> Void)?
    public var onSetStatusMessage: (@Sendable (String) -> Void)?
    public var onRefreshScreen: (@Sendable () -> Void)?
    public var onDispatchCommand: (@Sendable (LogoEditorAction) -> Void)?
    public var onReadWord: (@Sendable (String) -> String?)?
    public var onReadChar: (@Sendable (String) -> String?)?
    public var onAppendOutput: (@Sendable (String) -> Void)?
    public var onFillCanvasBlock: (@Sendable (String) -> Bool)?
    public var onQueryExtra: (@Sendable (LogoEditorQuery) -> LogoEditorQueryResult?)?

    public init(
        onSaveUndoSnapshot: (@Sendable () -> Void)? = nil,
        onSetStatusMessage: (@Sendable (String) -> Void)? = nil,
        onRefreshScreen: (@Sendable () -> Void)? = nil,
        onDispatchCommand: (@Sendable (LogoEditorAction) -> Void)? = nil,
        onReadWord: (@Sendable (String) -> String?)? = nil,
        onReadChar: (@Sendable (String) -> String?)? = nil,
        onAppendOutput: (@Sendable (String) -> Void)? = nil,
        onFillCanvasBlock: (@Sendable (String) -> Bool)? = nil,
        onQueryExtra: (@Sendable (LogoEditorQuery) -> LogoEditorQueryResult?)? = nil
    ) {
        self.onSaveUndoSnapshot = onSaveUndoSnapshot
        self.onSetStatusMessage = onSetStatusMessage
        self.onRefreshScreen = onRefreshScreen
        self.onDispatchCommand = onDispatchCommand
        self.onReadWord = onReadWord
        self.onReadChar = onReadChar
        self.onAppendOutput = onAppendOutput
        self.onFillCanvasBlock = onFillCanvasBlock
        self.onQueryExtra = onQueryExtra
    }

    public static let empty = LogoUIHooks()
}
