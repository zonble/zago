import Foundation

public struct EditorExternalBufferInfo: Sendable {
    public let bufferId: String
    public let filePath: String?
    public let fileName: String
    public let isModified: Bool
    public let isFocused: Bool

    public init(
        bufferId: String,
        filePath: String?,
        fileName: String,
        isModified: Bool,
        isFocused: Bool
    ) {
        self.bufferId = bufferId
        self.filePath = filePath
        self.fileName = fileName
        self.isModified = isModified
        self.isFocused = isFocused
    }
}

public struct EditorExternalTextResult: Sendable {
    public let lines: [String]
    public let totalLines: Int

    public init(lines: [String], totalLines: Int) {
        self.lines = lines
        self.totalLines = totalLines
    }
}

public struct EditorExternalSelectionResult: Sendable {
    public let hasSelection: Bool
    public let text: String
    public let lines: [String]
    public let startLine: Int?
    public let startColumn: Int?
    public let endLine: Int?
    public let endColumn: Int?

    public init(
        hasSelection: Bool,
        text: String,
        lines: [String],
        startLine: Int?,
        startColumn: Int?,
        endLine: Int?,
        endColumn: Int?
    ) {
        self.hasSelection = hasSelection
        self.text = text
        self.lines = lines
        self.startLine = startLine
        self.startColumn = startColumn
        self.endLine = endLine
        self.endColumn = endColumn
    }
}

public struct EditorExternalCursorInfo: Sendable {
    public let line: Int
    public let column: Int
    public let visualCol: Int
    public let mode: String

    public init(
        line: Int,
        column: Int,
        visualCol: Int,
        mode: String
    ) {
        self.line = line
        self.column = column
        self.visualCol = visualCol
        self.mode = mode
    }
}

public struct EditorExternalLogoResult: Sendable {
    public let success: Bool
    public let result: String
    public let error: String?

    public init(
        success: Bool,
        result: String,
        error: String?
    ) {
        self.success = success
        self.result = result
        self.error = error
    }
}
