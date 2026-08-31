import Drawing
import Foundation

/// Parsed configuration settings loaded from ~/.zagorc or ./.zagorc files.
public struct EditorConfig {
    public var wrapColumn: Int? = nil
    public var fillColumn: Int = 72
    public var showRuler: Bool = false
    public var showLineNumbers: Bool = true
    public var showSubLineNumbers: Bool = false
    public var showIndicator: Bool = false
    public var isZeroMode: Bool = false
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

    /// Whether to automatically create a backup file (<filename>~) before saving existing files. Defaults to false.
    public var backup: Bool = false
    /// Custom directory path to store backup files. If nil, backups are created in the same directory as the original file.
    public var backupDir: String? = nil

    /// Whether to open today's daily journal when starting zago without explicit file arguments. Defaults to false.
    public var launchToJournal: Bool = false
    /// Destination directory path for storing daily journals. If nil, defaults to ~/Documents/zago_journal or ~/zago_journal.
    public var journalFolder: String? = nil

    /// Whether terminal mouse tracking (clicks, drags, scrolls) is enabled. Defaults to true.
    public var enableMouse: Bool = true

    public init() {}

    public static func normalizedWrapColumn(_ column: Int?) -> Int? {
        guard let column else { return nil }
        return max(10, column)
    }
}
