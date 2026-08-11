extension Editor {
    public var currentPromptMode: PromptMode {
        get { promptController.mode }
        set { promptController.mode = newValue }
    }

    public var promptInputText: String {
        get { promptController.inputText }
        set { promptController.inputText = newValue }
    }

    public var promptCursorIndex: Int {
        get { promptController.cursorIndex }
        set { promptController.cursorIndex = newValue }
    }

    public var promptCompletionText: String? {
        get { promptController.completionText }
        set { promptController.completionText = newValue }
    }

    public var logoPromptHistory: [String] {
        get { promptController.logoHistory }
        set { promptController.logoHistory = newValue }
    }

    public var logoHistoryIndex: Int {
        get { promptController.logoHistoryIndex }
        set { promptController.logoHistoryIndex = newValue }
    }

    public var lastSearchQuery: String {
        get { searchController.lastSearchQuery }
        set { searchController.lastSearchQuery = newValue }
    }

    public var isMenuBarActive: Bool {
        get { menuBarController.isActive }
        set { menuBarController.isActive = newValue }
    }

    public var menuBar: MenuBar {
        menuBarController.menuBar
    }

    public var baseMode: EditorBaseMode {
        get { buffer.baseMode }
        set { buffer.baseMode = newValue }
    }

    public var overlayMode: EditorOverlayMode {
        get { buffer.overlayMode }
        set { buffer.overlayMode = newValue }
    }

    public var canvasVisualColumn: Int {
        get { buffer.canvasVisualColumn }
        set { buffer.canvasVisualColumn = newValue }
    }

    public var canvasHorizontalOffset: Int {
        get { buffer.canvasHorizontalOffset }
        set { buffer.canvasHorizontalOffset = newValue }
    }

    public var isTableModeActive: Bool {
        get { buffer.isTableModeActive }
        set { buffer.isTableModeActive = newValue }
    }

    public var currentTableCell: TableCell? {
        get { buffer.currentTableCell }
        set { buffer.currentTableCell = newValue }
    }

    public var defaultBorderStyle: BorderStyle {
        get { buffer.borderStyle }
        set { buffer.borderStyle = newValue }
    }

    public var defaultArrowStyle: ArrowStyle {
        get { buffer.arrowStyle }
        set { buffer.arrowStyle = newValue }
    }
}
