import Foundation

public struct LogoCanvasBlockFrame: Sendable, Equatable {
    public let lineIndex: Int
    public let visualColumn: Int
    public let width: Int
    public let height: Int

    public init(lineIndex: Int, visualColumn: Int, width: Int, height: Int) {
        self.lineIndex = lineIndex
        self.visualColumn = visualColumn
        self.width = width
        self.height = height
    }
}

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
    case joinLine(separator: String)
    case replaceText(old: String, new: String)
    case indentLines(levels: Int)
    case outdentLines(levels: Int)
    case createTable(rows: Int, cols: Int, cellWidth: Int?)
    case insertDiagramSnippet(type: String?)
    case setBorderStyle(String)
    case nextBorderStyle
    case moveCursorVirtual(Int)
    case search(String)
    case markModified
    case updateLineIndex(Int)
    case updateColumnIndex(Int)
    case setLine(index: Int, text: String)
    case ensureLineExists(index: Int)
    case refreshScreen
    case fillCanvasBlock(String)

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
}

/// State queries requested from LOGO scripts to the host text editor.
public enum LogoEditorQuery {
    case currentLineIndex
    case currentColumnIndex
    case lineCount
    case lineAt(Int)
    case defaultBorderStyle
    case hasCanvasBlockMark
    case canvasBlockFrame

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
