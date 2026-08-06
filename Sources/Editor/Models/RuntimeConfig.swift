import Foundation

/// Value object storing runtime configuration settings and UI toggle options for the editor.
public struct RuntimeConfig: Sendable, Equatable {
    /// Whether the WordStar ruler bar is enabled.
    public var showRuler: Bool

    /// Whether line numbers gutter is enabled.
    public var showLineNumbers: Bool

    /// Whether sub-line wrapping numbers are enabled.
    public var showSubLineNumbers: Bool

    /// Whether ANSI syntax highlighting is enabled.
    public var enableSyntaxHighlight: Bool

    /// Whether automatic file reload on external modification is enabled.
    public var autoReload: Bool

    /// Number of spaces representing a Tab character.
    public var tabSize: Int

    /// Whether trailing whitespace is automatically trimmed on save.
    public var trimTrailingWhitespaceOnSave: Bool

    /// Whether Git diff indicators in gutter are enabled.
    public var showGitDiff: Bool

    public init(
        showRuler: Bool = false,
        showLineNumbers: Bool = true,
        showSubLineNumbers: Bool = false,
        enableSyntaxHighlight: Bool = true,
        autoReload: Bool = true,
        tabSize: Int = 4,
        trimTrailingWhitespaceOnSave: Bool = false,
        showGitDiff: Bool = true
    ) {
        self.showRuler = showRuler
        self.showLineNumbers = showLineNumbers
        self.showSubLineNumbers = showSubLineNumbers
        self.enableSyntaxHighlight = enableSyntaxHighlight
        self.autoReload = autoReload
        self.tabSize = tabSize
        self.trimTrailingWhitespaceOnSave = trimTrailingWhitespaceOnSave
        self.showGitDiff = showGitDiff
    }
}
