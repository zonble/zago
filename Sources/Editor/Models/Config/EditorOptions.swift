import Config
import Foundation

public struct EditorOptions {
    public var filePaths: [String]
    public var wrapColumn: Int?
    public var fillColumn: Int?
    public var showRuler: Bool?
    public var showLineNumbers: Bool?
    public var showSubLineNumbers: Bool?
    public var enableSyntax: Bool?
    public var autoReload: Bool?
    public var ipcEnabled: Bool?
    public var language: Language?
    public var spellLanguage: String?
    public var initialLine: Int?
    public var initialColumn: Int?
    public var readOnly: Bool?
    public var pipedInput: String?
    public var keymapPreset: KeymapPreset?
    public var defaultLineEnding: LineEnding?
    public var backup: Bool?
    public var backupDir: String?
    public var launchToJournal: Bool?
    public var journalFolder: String?
    public var enableMouse: Bool?

    public init(
        filePaths: [String] = [],
        wrapColumn: Int? = nil,
        fillColumn: Int? = nil,
        showRuler: Bool? = nil,
        showLineNumbers: Bool? = nil,
        showSubLineNumbers: Bool? = nil,
        enableSyntax: Bool? = nil,
        autoReload: Bool? = nil,
        ipcEnabled: Bool? = nil,
        language: Language? = nil,
        spellLanguage: String? = nil,
        initialLine: Int? = nil,
        initialColumn: Int? = nil,
        readOnly: Bool? = nil,
        pipedInput: String? = nil,
        keymapPreset: KeymapPreset? = nil,
        defaultLineEnding: LineEnding? = nil,
        backup: Bool? = nil,
        backupDir: String? = nil,
        launchToJournal: Bool? = nil,
        journalFolder: String? = nil,
        enableMouse: Bool? = nil
    ) {
        self.filePaths = filePaths
        self.wrapColumn = wrapColumn
        self.fillColumn = fillColumn
        self.showRuler = showRuler
        self.showLineNumbers = showLineNumbers
        self.showSubLineNumbers = showSubLineNumbers
        self.enableSyntax = enableSyntax
        self.autoReload = autoReload
        self.ipcEnabled = ipcEnabled
        self.language = language
        self.spellLanguage = spellLanguage
        self.initialLine = initialLine
        self.initialColumn = initialColumn
        self.readOnly = readOnly
        self.pipedInput = pipedInput
        self.keymapPreset = keymapPreset
        self.defaultLineEnding = defaultLineEnding
        self.backup = backup
        self.backupDir = backupDir
        self.launchToJournal = launchToJournal
        self.journalFolder = journalFolder
        self.enableMouse = enableMouse
    }
}
