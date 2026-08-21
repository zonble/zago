import Drawing
import Foundation

/// Parsed configuration settings loaded from ~/.zagorc or ./.zagorc files.
public struct EditorConfig {
    public var wrapColumn: Int? = nil
    public var fillColumn: Int = 72
    public var showRuler: Bool = false
    public var showLineNumbers: Bool = true
    public var showSubLineNumbers: Bool = false
    public var startInCanvasMode: Bool = false
    public var tabSize: Int = 4
    public var smartTab: Bool = true
    public var listIndentSize: Int = 2
    public var listWrapIndent: Bool = true
    public var enableSyntaxHighlight: Bool = true
    public var autoReload: Bool = true
    public var trimTrailingWhitespaceOnSave: Bool = false
    public var noNewlines: Bool = false
    public var showGitDiff: Bool = true
    public var language: Language? = nil
    public var spellLanguage: String = "en_US"
    public var defaultBorderStyle: BorderStyle = .single
    public var defaultArrowStyle: ArrowStyle = .solid
    public var keymapPreset: String = "classic"
    public var customKeyBinds: [Key: String] = [:]
    public var customModeKeyBinds: [String: [Key: String]] = [:]
    public var unbindKeys: Set<Key> = []
    public var logoPrelude: String = ""
    public var logoScripts: [String: String] = [:]
    public var ipcEnabled: Bool = false
    public var debugMode: Bool = false
    public var loadedDialects: [String] = []
    /// Inline and included GNU Nano syntax definitions from .zagorc.
    public var nanoRCContent: String = ""
    public var syntaxErrorCount: Int = 0
    public var loadedFilePath: String? = nil

    /// Maximum file size in bytes allowed to open (0 means no limit). Defaults to 50 MB.
    public var maxFileSizeBytes: Int64 = 50 * 1024 * 1024
    /// File size threshold in bytes above which large file degradation mode is active. Defaults to 5 MB.
    public var largeFileThresholdBytes: Int64 = 5 * 1024 * 1024
    /// Maximum line character length allowed for regex syntax highlighting. Defaults to 10,000 characters.
    public var maxLineHighlightLength: Int = 10000

    public init() {}

    public static func normalizedWrapColumn(_ column: Int?) -> Int? {
        guard let column else { return nil }
        return max(10, column)
    }
}
