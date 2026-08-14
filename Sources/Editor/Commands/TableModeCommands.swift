import Foundation

public struct SwitchTextModeCommand: Command {
    public let id: CommandID = .textMode
    public let name = "Text Editing Mode"
    public let description = "Switch to Text Editing Mode"
    public let keys: [Key] = []
    public let commandBarAliases = ["text-mode"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.switchToTextMode()
        return .succeeded
    }
}

public struct ToggleCanvasModeCommand: Command {
    public let id: CommandID = .canvasToggle
    public let name = "Canvas Mode"
    public let description = "Toggle Canvas Mode"
    public let keys: [Key] = [.f8, .alt("v"), .alt("V")]
    public let commandBarAliases = ["canvas-mode"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleCanvasMode()
        return .succeeded
    }
}

public struct ToggleTableModeCommand: Command {
    public let id: CommandID = .tableToggle
    public let name = "Table Mode"
    public let description = "Toggle Table Mode for active cell"
    public let keys: [Key] = [.f7, .alt("t"), .alt("T")]
    public let commandBarAliases = ["table-mode"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.toggleTableMode()
        return .succeeded
    }
}

public struct CycleBorderStyleCommand: Command {
    public let id: CommandID = .borderStyle
    public let name = "Cycle Border Style"
    public let description =
        "Switch default border style (Single -> Heavy -> Double -> Round -> Double Round -> ASCII)"
    public let keys: [Key] = [.alt("s"), .alt("S")]
    public let commandBarAliases = ["border", "border-style"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        let message: String
        switch editor.defaultBorderStyle {
        case .single:
            editor.defaultBorderStyle = .heavy
            message = editor.l10n.defaultBorder("Heavy Unicode (┏━┃)")
        case .heavy:
            editor.defaultBorderStyle = .double
            message = editor.l10n.defaultBorder("Double Unicode (╔═║)")
        case .double:
            editor.defaultBorderStyle = .round
            message = editor.l10n.defaultBorder("Round Unicode (╭─│)")
        case .round:
            editor.defaultBorderStyle = .doubleRound
            message = editor.l10n.defaultBorder("Double Round Unicode (╭═║)")
        case .doubleRound:
            editor.defaultBorderStyle = .ascii
            message = editor.l10n.defaultBorder("ASCII (+-|)")
        case .ascii:
            editor.defaultBorderStyle = .asciiRound
            message = editor.l10n.defaultBorder("ASCII Rounded (/-\\|)")
        case .asciiRound:
            editor.defaultBorderStyle = .single
            message = editor.l10n.defaultBorder("Single Unicode (┌─│)")
        }
        return .succeeded(message: message)
    }
}

public struct TableNextCellCommand: Command {
    public let id: CommandID = .tableNextCell
    public let name = "Next Table Cell"
    public let description = "Move to next table cell"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearActiveMark()
        editor.tableModeController.navigateNextTableCell()
        return .succeeded
    }
}

public struct TablePrevCellCommand: Command {
    public let id: CommandID = .tablePrevCell
    public let name = "Previous Table Cell"
    public let description = "Move to previous table cell"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearActiveMark()
        editor.tableModeController.navigatePrevTableCell()
        return .succeeded
    }
}

public struct TableAdjustWidthIncCommand: Command {
    public let id: CommandID = .tableAdjustWidthInc
    public let name = "Increase Table Cell Width"
    public let description = "Increase current table column width"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellWidth(delta: 1)
        return .succeeded
    }
}

public struct TableAdjustWidthDecCommand: Command {
    public let id: CommandID = .tableAdjustWidthDec
    public let name = "Decrease Table Cell Width"
    public let description = "Decrease current table column width"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellWidth(delta: -1)
        return .succeeded
    }
}

public struct TableAdjustHeightIncCommand: Command {
    public let id: CommandID = .tableAdjustHeightInc
    public let name = "Increase Table Cell Height"
    public let description = "Increase current table row height"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellHeight(delta: 1)
        return .succeeded
    }
}

public struct TableAdjustHeightDecCommand: Command {
    public let id: CommandID = .tableAdjustHeightDec
    public let name = "Decrease Table Cell Height"
    public let description = "Decrease current table row height"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellHeight(delta: -1)
        return .succeeded
    }
}

public struct TableCenterTextCommand: Command {
    public let id: CommandID = .tableCenterText
    public let name = "Center Table Cell Text"
    public let description = "Center text in current table cell"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.centerCellText()
        return .succeeded
    }
}

public struct TableCellStartCommand: Command {
    public let id: CommandID = .tableCellStart
    public let name = "Beginning of Table Cell"
    public let description = "Move cursor to beginning of table cell"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard let cell = editor.currentTableCell else { return .noOp }
        editor.clearActiveMark()
        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (leftBorder, _) = TableModeController.findCellHorizontalBorders(
            in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        editor.buffer.columnIndex = leftBorder + 1
        editor.tableModeController.clampTableModeCursor()
        return .succeeded
    }
}

public struct TableCellEndCommand: Command {
    public let id: CommandID = .tableCellEnd
    public let name = "End of Table Cell"
    public let description = "Move cursor to end of table cell"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard let cell = editor.currentTableCell else { return .noOp }
        editor.clearActiveMark()
        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
            in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        editor.buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
        editor.tableModeController.clampTableModeCursor()
        return .succeeded
    }
}

public struct TableClearCellCommand: Command {
    public let id: CommandID = .tableClearCell
    public let name = "Clear Table Cell"
    public let description = "Clear text inside current table cell"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard let cell = editor.currentTableCell else { return .noOp }
        editor.tableModeController.cutTableCellText(cell: cell)
        return .succeeded
    }
}
