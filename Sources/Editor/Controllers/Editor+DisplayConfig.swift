import Foundation

extension Editor {
    public struct DisplayConfig: Sendable, Equatable {
        public var showRuler: Bool
        public var showLineNumbers: Bool
        public var showSubLineNumbers: Bool
        public var enableSyntaxHighlight: Bool
        public var autoReload: Bool
        public var tabSize: Int
        public var trimTrailingWhitespaceOnSave: Bool
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
}
