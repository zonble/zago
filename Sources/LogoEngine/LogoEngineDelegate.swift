import Foundation

/// Action commands dispatched to the host text editor from LOGO scripts.
public enum LogoEditorCommand {
    case moveLeft
    case moveRight
    case moveHome
    case moveEnd
    case editMark
    case editCut
    case editUncut
    case editJustify
}

/// Abstract delegate interface for host editor interaction using standard Swift delegate naming conventions.
public protocol LogoEngineDelegate: AnyObject {
    // Actions & Requests
    func logoEngineDidRequestSaveUndoSnapshot(_ engine: LogoEngine)
    func logoEngineDidRequestClampCursor(_ engine: LogoEngine)
    func logoEngine(_ engine: LogoEngine, didRequestInsertText text: String)
    func logoEngineDidRequestInsertNewline(_ engine: LogoEngine)
    func logoEngine(_ engine: LogoEngine, didRequestSetStatusMessage message: String)
    func logoEngineDidRequestDelete(_ engine: LogoEngine)
    func logoEngineDidRequestBackspace(_ engine: LogoEngine)
    func logoEngineDidRequestDeleteLine(_ engine: LogoEngine)
    func logoEngine(_ engine: LogoEngine, didRequestMoveCursorVirtual deltaRow: Int)
    func logoEngine(_ engine: LogoEngine, didRequestDispatchCommand command: LogoEditorCommand)
    func logoEngine(_ engine: LogoEngine, didRequestSearch query: String)
    func logoEngineDidMarkBufferModified(_ engine: LogoEngine)
    func logoEngine(_ engine: LogoEngine, didApplySetting setting: String, arg: String)

    // State & Data Source
    func logoEngineCurrentLineIndex(_ engine: LogoEngine) -> Int
    func logoEngine(_ engine: LogoEngine, didUpdateLineIndex lineIndex: Int)

    func logoEngineCurrentColumnIndex(_ engine: LogoEngine) -> Int
    func logoEngine(_ engine: LogoEngine, didUpdateColumnIndex columnIndex: Int)

    func logoEngineLineCount(_ engine: LogoEngine) -> Int

    func logoEngine(_ engine: LogoEngine, lineAt index: Int) -> String
    func logoEngine(_ engine: LogoEngine, setLineAt index: Int, text: String)
    func logoEngine(_ engine: LogoEngine, ensureLineExistsAt index: Int)
}
