import Foundation

struct SwitchTextModeCommand: Command {
    let id: CommandID = .textMode
    let name = "Text Editing Mode"
    let description = "Switch to Text Editing Mode"
    let commandBarAliases = ["text-mode"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.switchToTextMode()
        return .succeeded
    }
}

struct ToggleCanvasModeCommand: Command {
    let id: CommandID = .canvasToggle
    let name = "Canvas Mode"
    let description = "Toggle Canvas Mode"
    let commandBarAliases = ["canvas-mode"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleCanvasMode()
        return .succeeded
    }
}

struct ToggleTableModeCommand: Command {
    let id: CommandID = .tableToggle
    let name = "Table Mode"
    let description = "Toggle Table Mode for active cell"
    let commandBarAliases = ["table-mode"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.toggleTableMode()
        return .succeeded
    }
}

struct CycleBorderStyleCommand: Command {
    let id: CommandID = .borderStyle
    let name = "Cycle Border Style"
    let description =
        "Switch default border style (Single -> Heavy -> Double -> Round -> Double Round -> ASCII)"
    let commandBarAliases = ["border", "border-style"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct TableNextCellCommand: Command {
    let id: CommandID = .tableNextCell
    let name = "Next Table Cell"
    let description = "Move to next table cell"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearActiveMark()
        editor.tableModeController.navigateNextTableCell()
        return .succeeded
    }
}

struct TablePrevCellCommand: Command {
    let id: CommandID = .tablePrevCell
    let name = "Previous Table Cell"
    let description = "Move to previous table cell"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearActiveMark()
        editor.tableModeController.navigatePrevTableCell()
        return .succeeded
    }
}

struct TableAdjustWidthIncCommand: Command {
    let id: CommandID = .tableAdjustWidthInc
    let name = "Increase Table Cell Width"
    let description = "Increase current table column width"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellWidth(delta: 1)
        return .succeeded
    }
}

struct TableAdjustWidthDecCommand: Command {
    let id: CommandID = .tableAdjustWidthDec
    let name = "Decrease Table Cell Width"
    let description = "Decrease current table column width"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellWidth(delta: -1)
        return .succeeded
    }
}

struct TableAdjustHeightIncCommand: Command {
    let id: CommandID = .tableAdjustHeightInc
    let name = "Increase Table Cell Height"
    let description = "Increase current table row height"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellHeight(delta: 1)
        return .succeeded
    }
}

struct TableAdjustHeightDecCommand: Command {
    let id: CommandID = .tableAdjustHeightDec
    let name = "Decrease Table Cell Height"
    let description = "Decrease current table row height"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.resizeCurrentTableCellHeight(delta: -1)
        return .succeeded
    }
}

struct TableCenterTextCommand: Command {
    let id: CommandID = .tableCenterText
    let name = "Center Table Cell Text"
    let description = "Center text in current table cell"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.tableModeController.centerCellText()
        return .succeeded
    }
}

struct TableCellStartCommand: Command {
    let id: CommandID = .tableCellStart
    let name = "Beginning of Table Cell"
    let description = "Move cursor to beginning of table cell"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct TableCellEndCommand: Command {
    let id: CommandID = .tableCellEnd
    let name = "End of Table Cell"
    let description = "Move cursor to end of table cell"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct TableClearCellCommand: Command {
    let id: CommandID = .tableClearCell
    let name = "Clear Table Cell"
    let description = "Clear text inside current table cell"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard let cell = editor.currentTableCell else { return .noOp }
        editor.tableModeController.cutTableCellText(cell: cell)
        return .succeeded
    }
}
