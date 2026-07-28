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

/// Abstract interface for host editor interaction, completely decoupling LogoEngine from concrete Editor implementations.
public protocol LogoEditorContext: AnyObject {
    func saveUndoSnapshot()
    func clampCursor()
    func insertString(_ text: String)
    func insertNewline()
    func setStatusMessage(_ message: String)
    func delete()
    func backspace()
    func moveCursorVirtual(deltaRow: Int)
    func dispatchCommand(_ command: LogoEditorCommand)
    func performSearch(query: String)

    var lineIndex: Int { get set }
    var columnIndex: Int { get set }
    var lineCount: Int { get }

    func getLine(at index: Int) -> String
    func setLine(at index: Int, text: String)
    func ensureLineExists(at index: Int)
    func markBufferModified()
    func applySetting(_ setting: String, arg: String)
}
