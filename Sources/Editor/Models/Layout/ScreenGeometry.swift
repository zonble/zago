import Foundation

/// Immutable value object representing calculated UI layout metrics and frame dimensions for a single render pass.
struct ScreenGeometry: Equatable {
    // MARK: - Layout Constants & Chrome Rules

    /// Number of terminal rows reserved for top Title Bar (or Menu Bar).
    static let titleBarHeight = 1

    /// Number of terminal rows reserved for optional WordStar Ruler Bar.
    static let rulerBarHeight = 1

    /// Number of terminal rows reserved for Status/Prompt Line.
    static let statusLineHeight = 1

    /// Number of terminal rows reserved for dynamic Contextual Help Bar (2 lines).
    static let helpBarHeight = 2

    /// Character width reserved for line numbers gutter (e.g. " 123 ").
    static let defaultGutterWidth = 5

    /// Minimum allowable text display width.
    static let minimumTextWidth = 10

    // MARK: - Frame Instance Metrics

    /// Terminal screen height in rows.
    let rows: Int

    /// Terminal screen width in columns.
    let cols: Int

    /// Whether the WordStar ruler bar is currently visible.
    let showRuler: Bool

    /// Whether the line numbers gutter is currently visible.
    let showGutter: Bool

    /// Whether the independent breakpoint marker gutter is visible.
    let showBreakpointGutter: Bool

    /// Calculated main text area height in rows.
    let mainAreaHeight: Int

    /// Calculated line numbers gutter width in character columns.
    let gutterWidth: Int

    /// Calculated effective text display area width in character columns.
    let textWidth: Int

    /// Initializes a ScreenGeometry by computing frame layout metrics for given terminal dimensions and display options.
    init(rows: Int, cols: Int, showRuler: Bool, showGutter: Bool, showBreakpointGutter: Bool = false) {
        self.rows = rows
        self.cols = cols
        self.showRuler = showRuler
        self.showGutter = showGutter
        self.showBreakpointGutter = showBreakpointGutter

        let chrome =
            showRuler
            ? (Self.titleBarHeight + Self.statusLineHeight + Self.helpBarHeight + Self.rulerBarHeight)
            : (Self.titleBarHeight + Self.statusLineHeight + Self.helpBarHeight)

        self.mainAreaHeight = max(1, rows - chrome)
        self.gutterWidth = (showGutter ? Self.defaultGutterWidth : 0) + (showBreakpointGutter ? 1 : 0)
        self.textWidth = max(Self.minimumTextWidth, cols - self.gutterWidth)
    }

    /// Convenience initializer deriving ruler and gutter visibility from an Editor instance.
    init(rows: Int, cols: Int, editor: Editor) {
        let showRuler = editor.displayConfig.showRuler && !editor.buffer.isDirectoryBuffer
        let showGutter = editor.displayConfig.showLineNumbers && !editor.buffer.isDirectoryBuffer
        let showBreakpointGutter = !editor.debuggerController.breakpoints(in: editor.buffer).isEmpty
        self.init(
            rows: rows,
            cols: cols,
            showRuler: showRuler,
            showGutter: showGutter,
            showBreakpointGutter: showBreakpointGutter
        )
    }
}
