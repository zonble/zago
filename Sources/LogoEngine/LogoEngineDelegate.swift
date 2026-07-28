import Foundation

/// Action mutations dispatched from LOGO scripts to the host text editor.
public enum LogoEditorAction {
    case saveUndoSnapshot
    case clampCursor
    case insertText(String)
    case insertNewline
    case setStatusMessage(String)
    case deleteChar
    case backspaceChar
    case deleteLine
    case moveCursorVirtual(Int)
    case search(String)
    case markModified
    case applySetting(setting: String, arg: String)
    case updateLineIndex(Int)
    case updateColumnIndex(Int)
    case setLine(index: Int, text: String)
    case ensureLineExists(index: Int)

    // Navigation & Editing Actions
    case moveLeft
    case moveRight
    case moveHome
    case moveEnd
    case editMark
    case editCut
    case editUncut
    case editJustify

    // Multi-Buffer & Buffer Mutation Actions
    case gotoLine(Int)
    case gotoCol(Int)
    case clearBuffer
    case switchBuffer(index: Int)
    case openBuffer(path: String)
    case closeBuffer
    case nextBuffer
    case prevBuffer
}

/// State queries requested from LOGO scripts to the host text editor.
public enum LogoEditorQuery {
    case currentLineIndex
    case currentColumnIndex
    case lineCount
    case lineAt(Int)

    // Buffer Queries
    case bufferList
    case currentBufferIndex
    case bufferText
    case selectionText
    case isModified
    case fileName
}

/// Clean abstract delegate protocol for host editor interaction.
public protocol LogoEngineDelegate: AnyObject {
    /// Perform an action or mutation on the host editor.
    func logoEngine(_ engine: LogoEngine, performAction action: LogoEditorAction)

    /// Query state or data from the host editor.
    func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> Any?
}
