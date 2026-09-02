import Foundation

extension EditorSettingKey {
    func makeUpdate(value rawValue: String) -> EditorSettingUpdate? {
        let trimmedRaw = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = trimmedRaw.lowercased()
        switch self {
        case .wrap:
            let column =
                (value == "off" || value == "false" || value == "none") ? nil : Int(value).flatMap { $0 > 0 ? $0 : nil }
            return .wrap(column: column)
        case .ruler: return .ruler(SettingBoolean.parse(value))
        case .lineNumbers: return .lineNumbers(SettingBoolean.parse(value))
        case .subLineNumbers: return .subLineNumbers(SettingBoolean.parse(value))
        case .canvasMode: return .canvasMode(SettingBoolean.parse(value))
        case .syntax: return .syntaxHighlighting(SettingBoolean.parse(value))
        case .smartTab: return .smartTab(SettingBoolean.parse(value))
        case .listWrapIndent: return .listWrapIndent(SettingBoolean.parse(value))
        case .gitDiff: return .gitDiff(SettingBoolean.parse(value))
        case .autoReload: return .autoReload(SettingBoolean.parse(value))
        case .ipc: return .ipc(SettingBoolean.parse(value))
        case .regex: return .regex(SettingBoolean.parse(value))
        case .debug: return .debug(SettingBoolean.parse(value))
        case .trimTrailingWhitespace: return .trimTrailingWhitespace(SettingBoolean.parse(value))
        case .tab:
            guard let size = Int(value), size > 0 else { return nil }
            return .tabSize(size)
        case .listIndentSize:
            guard let size = Int(value), size > 0 else { return nil }
            return .listIndentSize(size)
        case .language:
            return Language(settingValue: rawValue).map(EditorSettingUpdate.language)
        case .spellLanguage:
            return rawValue.isEmpty ? nil : .spellLanguage(rawValue)
        case .border: return .border(BorderStyle(value), rawValue: value)
        case .arrow: return .arrow(ArrowStyle(value))
        case .keymap:
            if ["classic", "nano", "default"].contains(value) {
                return .keymap(.classic)
            } else if ["modern", "vscode", "cua"].contains(value) {
                return .keymap(.modern)
            }
            return nil
        case .modernbindings:
            return .modernbindings(SettingBoolean.parse(value))
        case .noNewlines:
            return .noNewlines(SettingBoolean.parse(value))
        case .fill:
            guard let width = Int(value), width > 0 else { return nil }
            return .fill(width)
        case .maxFileSize:
            guard let bytes = ConfigLoader.parseByteSize(value), bytes >= 0 else { return nil }
            return .maxFileSize(bytes)
        case .largeFileThreshold:
            guard let bytes = ConfigLoader.parseByteSize(value), bytes >= 0 else { return nil }
            return .largeFileThreshold(bytes)
        case .maxLineHighlightLength:
            guard let len = Int(value), len > 0 else { return nil }
            return .maxLineHighlightLength(len)
        case .backup:
            return .backup(SettingBoolean.parse(value))
        case .backupDir:
            let clean = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty || clean.lowercased() == "off" || clean.lowercased() == "none" {
                return .backupDir(nil)
            }
            return .backupDir(clean)
        case .launchToJournal:
            return .launchToJournal(SettingBoolean.parse(value))
        case .journalFolder:
            let clean = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty || clean.lowercased() == "off" || clean.lowercased() == "none" {
                return .journalFolder(nil)
            }
            return .journalFolder(clean)
        case .mouse:
            return .mouse(SettingBoolean.parse(value))
        case .zero:
            return .zero(SettingBoolean.parse(value))
        case .indicator:
            return .indicator(SettingBoolean.parse(value))
        }
    }
}

public enum EditorSettingUpdate {
    case wrap(column: Int?)
    case fill(Int)
    case ruler(Bool?)
    case lineNumbers(Bool?)
    case subLineNumbers(Bool?)
    case indicator(Bool?)
    case canvasMode(Bool?)
    case syntaxHighlighting(Bool?)
    case autoReload(Bool?)
    case trimTrailingWhitespace(Bool?)
    case noNewlines(Bool?)
    case regex(Bool?)
    case debug(Bool?)
    case smartTab(Bool?)
    case listIndentSize(Int)
    case listWrapIndent(Bool?)
    case gitDiff(Bool?)
    case spellLanguage(String)
    case tabSize(Int)
    case language(Language)
    case border(BorderStyle?, rawValue: String)
    case arrow(ArrowStyle?)
    case ipc(Bool?)
    case keymap(KeymapPreset)
    case modernbindings(Bool?)
    case maxFileSize(Int64)
    case largeFileThreshold(Int64)
    case maxLineHighlightLength(Int)
    case backup(Bool?)
    case backupDir(String?)
    case launchToJournal(Bool?)
    case journalFolder(String?)
    case mouse(Bool?)
    case zero(Bool?)
}

public enum EditorEffect: Equatable {
    case ipcEnabled(Bool)
}

public protocol EditorEffectDelegate: AnyObject {
    func editor(_ editor: Editor, didEmit effect: EditorEffect)
}

public enum EditorSettingUpdateParser {
    public static let settingNames = EditorSettingKey.allCases.map(\.rawValue)

    public static func parse(setting: String, value: String) -> EditorSettingUpdate? {
        EditorSettingKey(rawValue: setting.lowercased())?.makeUpdate(value: value)
    }

    public static func valueSuggestions(for setting: String) -> [String] {
        EditorSettingKey(rawValue: setting.lowercased())?.suggestedValues ?? []
    }
}
