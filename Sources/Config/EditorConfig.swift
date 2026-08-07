import Drawing
import Foundation

/// Parsed configuration settings loaded from ~/.zagorc or ./.zagorc files.
public struct EditorConfig {
    public var wrapColumn: Int? = nil
    public var showRuler: Bool = false
    public var showLineNumbers: Bool = true
    public var showSubLineNumbers: Bool = false
    public var startInCanvasMode: Bool = false
    public var tabSize: Int = 4
    public var enableSyntaxHighlight: Bool = true
    public var autoReload: Bool = true
    public var trimTrailingWhitespaceOnSave: Bool = false
    public var showGitDiff: Bool = true
    public var language: Language? = nil
    public var spellLanguage: String = "en_US"
    public var defaultBorderStyle: BorderStyle = .single
    public var defaultArrowStyle: ArrowStyle = .solid
    public var customKeyBinds: [Key: String] = [:]
    public var unbindKeys: Set<Key> = []
    public var logoPrelude: String = ""
    public var logoScripts: [String: String] = [:]
    public var syntaxErrorCount: Int = 0
    public var loadedFilePath: String? = nil

    public init() {}

    public static func normalizedWrapColumn(_ column: Int?) -> Int? {
        guard let column else { return nil }
        return max(10, column)
    }
}
