import Foundation

/// Centralized UI chrome and layout dimension metrics for calculating editor viewports.
public struct UILayoutMetrics {
    /// Number of terminal rows reserved for top Title Bar (or Menu Bar).
    public static let titleBarHeight = 1

    /// Number of terminal rows reserved for optional WordStar Ruler Bar.
    public static let rulerBarHeight = 1

    /// Number of terminal rows reserved for Status/Prompt Line.
    public static let statusLineHeight = 1

    /// Number of terminal rows reserved for dynamic Contextual Help Bar (2 lines).
    public static let helpBarHeight = 2

    /// Character width reserved for line numbers gutter (e.g. " 123 ").
    public static let defaultGutterWidth = 5

    /// Minimum allowable text display width.
    public static let minimumTextWidth = 10

    /// Calculates total UI chrome height (Title + Status + Help + optional Ruler).
    public static func chromeHeight(showRuler: Bool) -> Int {
        let base = titleBarHeight + statusLineHeight + helpBarHeight
        return showRuler ? (base + rulerBarHeight) : base
    }

    /// Calculates main text area height for given terminal rows and ruler visibility.
    public static func mainAreaHeight(rows: Int, showRuler: Bool) -> Int {
        max(1, rows - chromeHeight(showRuler: showRuler))
    }

    /// Calculates effective line numbers gutter width.
    public static func effectiveGutterWidth(showGutter: Bool) -> Int {
        showGutter ? defaultGutterWidth : 0
    }

    /// Calculates effective text display width given terminal columns and gutter visibility.
    public static func textWidth(cols: Int, showGutter: Bool) -> Int {
        max(minimumTextWidth, cols - effectiveGutterWidth(showGutter: showGutter))
    }
}
