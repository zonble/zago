extension Editor {
    var currentPromptMode: PromptMode {
        get { promptController.mode }
        set { promptController.mode = newValue }
    }

    var promptInputText: String {
        get { promptController.inputText }
        set { promptController.inputText = newValue }
    }

    var promptCursorIndex: Int {
        get { promptController.cursorIndex }
        set { promptController.cursorIndex = newValue }
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

    var defaultArrowStyle: ArrowStyle {
        get { buffer.arrowStyle }
        set { buffer.arrowStyle = newValue }
    }
}
