import Foundation
import Drawing

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
    case setBorderStyle(String)
    case setArrowStyle(String)
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
    case fillTableCell(String)

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
    case defaultArrowStyle
    case hasCanvasBlockMark
    case canvasBlockFrame
    case hasTableCell

    // Buffer Queries
    case bufferList
    case currentBufferIndex
    case bufferText
    case selectionText
    case isModified
    case fileName
}

/// Typed values returned by editor state queries from a LOGO program.
public enum LogoEditorQueryResult {
    case integer(Int)
    case string(String)
    case bool(Bool)
    case strings([String])
    case borderStyle(BorderStyle)
    case arrowStyle(ArrowStyle)
    case canvasBlockFrame(LogoCanvasBlockFrame)

    var integerValue: Int? {
        guard case .integer(let value) = self else { return nil }
        return value
    }

    var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    var boolValue: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }

    var stringsValue: [String]? {
        guard case .strings(let value) = self else { return nil }
        return value
    }

    var borderStyleValue: BorderStyle? {
        guard case .borderStyle(let value) = self else { return nil }
        return value
    }

    var arrowStyleValue: ArrowStyle? {
        guard case .arrowStyle(let value) = self else { return nil }
        return value
    }

    var canvasBlockFrameValue: LogoCanvasBlockFrame? {
        guard case .canvasBlockFrame(let value) = self else { return nil }
        return value
    }
}
