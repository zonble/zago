import Config
import Foundation

public struct EditorOptions {
    public var filePaths: [String]
    public var wrapColumn: Int?
    public var showRuler: Bool?
    public var showLineNumbers: Bool?
    public var showSubLineNumbers: Bool?
    public var enableSyntax: Bool?
    public var autoReload: Bool?
    public var language: Language?
    public var spellLanguage: String?
    public var initialLine: Int?
    public var initialColumn: Int?
    public var readOnly: Bool?
    public var pipedInput: String?

    public init(
        filePaths: [String] = [],
        wrapColumn: Int? = nil,
        showRuler: Bool? = nil,
        showLineNumbers: Bool? = nil,
        showSubLineNumbers: Bool? = nil,
        enableSyntax: Bool? = nil,
        autoReload: Bool? = nil,
        language: Language? = nil,
        spellLanguage: String? = nil,
        initialLine: Int? = nil,
        initialColumn: Int? = nil,
        readOnly: Bool? = nil,
        pipedInput: String? = nil
    ) {
        self.filePaths = filePaths
        self.wrapColumn = wrapColumn
        self.showRuler = showRuler
        self.showLineNumbers = showLineNumbers
        self.showSubLineNumbers = showSubLineNumbers
        self.enableSyntax = enableSyntax
        self.autoReload = autoReload
        self.language = language
        self.spellLanguage = spellLanguage
        self.initialLine = initialLine
        self.initialColumn = initialColumn
        self.readOnly = readOnly
        self.pipedInput = pipedInput
    }
}
