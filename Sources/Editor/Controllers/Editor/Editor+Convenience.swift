extension Editor {
    var currentPromptMode: PromptMode {
        get { promptController.mode }
        set { promptController.mode = newValue }
    }

    var promptInputText: String {
        get { promptController.inputText }
        set {
            promptController.inputText = newValue
            promptController.cursorIndex = min(promptController.cursorIndex, newValue.count)
            promptController.selectionAnchorIndex = nil
        }
    }

    var promptCursorIndex: Int {
        get { promptController.cursorIndex }
        set {
            promptController.cursorIndex = max(0, min(newValue, promptController.inputText.count))
            promptController.selectionAnchorIndex = nil
        }
    }

    var promptCompletionText: String? {
        get { promptController.completionText }
        set { promptController.completionText = newValue }
    }

    var logoPromptHistory: [String] {
        get { promptController.logoHistory }
        set { promptController.logoHistory = newValue }
    }

    var logoHistoryIndex: Int {
        get { promptController.logoHistoryIndex }
        set { promptController.logoHistoryIndex = newValue }
    }

    var lastSearchQuery: String {
        get { searchController.lastSearchQuery }
        set { searchController.lastSearchQuery = newValue }
    }

    var isMenuBarActive: Bool {
        get { menuBarController.isActive }
        set { menuBarController.isActive = newValue }
    }

    var menuBar: MenuBar {
        menuBarController.menuBar
    }

    var baseMode: EditorBaseMode {
        get { buffer.baseMode }
        set { buffer.baseMode = newValue }
    }

    var overlayMode: EditorOverlayMode {
        get { buffer.overlayMode }
        set { buffer.overlayMode = newValue }
    }

    var canvasVisualColumn: Int {
        get { buffer.canvasVisualColumn }
        set { buffer.canvasVisualColumn = newValue }
    }

    var canvasHorizontalOffset: Int {
        get { buffer.canvasHorizontalOffset }
        set { buffer.canvasHorizontalOffset = newValue }
    }

    var topVLineIndex: Int {
        get { buffer.topVLineIndex }
        set { buffer.topVLineIndex = newValue }
    }

    var isTableModeActive: Bool {
        get { buffer.isTableModeActive }
        set { buffer.isTableModeActive = newValue }
    }

    var currentTableCell: TableCell? {
        get { buffer.currentTableCell }
        set { buffer.currentTableCell = newValue }
    }

    var defaultBorderStyle: BorderStyle {
        get { buffer.borderStyle }
        set { buffer.borderStyle = newValue }
    }

    var isBorderRounded: Bool {
        get { buffer.isBorderRounded }
        set { buffer.isBorderRounded = newValue }
    }

    var defaultArrowStyle: ArrowStyle {
        get { buffer.arrowStyle }
        set { buffer.arrowStyle = newValue }
    }
}
