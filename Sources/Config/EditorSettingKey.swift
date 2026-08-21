import Foundation
import Drawing

/// Canonical setting keys shared by `.zagorc` and the editor command bar.
public enum EditorSettingKey: String, CaseIterable, Sendable {
    case wrap
    case ruler
    case lineNumbers = "linenumbers"
    case subLineNumbers = "sublinenumbers"
    case canvasMode = "canvas-mode"
    case syntax
    case smartTab = "smarttab"
    case listIndentSize = "list-indent-size"
    case listWrapIndent = "list-wrap-indent"
    case autoReload = "autoreload"
    case ipc
    case trimTrailingWhitespace = "trim-trailing-whitespace"
    case tab
    case language = "lang"
    case spellLanguage = "spell-language"
    case border
    case arrow
    case gitDiff = "git-diff"
    case debug
    case regex
    case keymap
    case modernbindings
    case noNewlines = "nonewlines"
    case fill
    case maxFileSize = "max-file-size"
    case largeFileThreshold = "large-file-threshold"
    case maxLineHighlightLength = "max-line-highlight-length"
    case backup
    case backupDir = "backupdir"

    public var suggestedValues: [String] {
        switch self {
        case .wrap: return ["80", "off"]
        case .fill: return ["72", "80"]
        case .ruler, .lineNumbers, .subLineNumbers, .canvasMode, .syntax, .smartTab, .listWrapIndent,
            .autoReload, .ipc, .regex, .debug, .gitDiff, .trimTrailingWhitespace, .noNewlines, .backup:
            return ["on", "off"]
        case .tab, .listIndentSize: return ["2", "4", "8"]
        case .language: return Language.allCases.map(\.rawValue)
        case .spellLanguage: return ["en_US", "zh_TW"]
        case .border: return BorderStyle.allCases.map(\.rawValue)
        case .arrow: return ArrowStyle.allCases.map(\.rawValue)
        case .keymap: return ["classic", "modern"]
        case .modernbindings: return ["on", "off"]
        case .maxFileSize: return ["50MB", "100MB", "off"]
        case .largeFileThreshold: return ["5MB", "10MB", "off"]
        case .maxLineHighlightLength: return ["10000", "5000"]
        case .backupDir: return ["~/.zago_backups"]
        }
    }

    var supportsConfigUnset: Bool {
        switch self {
        case .wrap, .ruler, .lineNumbers, .subLineNumbers, .canvasMode, .syntax, .smartTab,
            .listWrapIndent, .autoReload, .ipc, .trimTrailingWhitespace, .gitDiff, .debug, .modernbindings, .noNewlines, .backup:
            return true
        case .listIndentSize, .tab, .fill, .language, .spellLanguage, .border, .arrow, .regex, .keymap,
            .maxFileSize, .largeFileThreshold, .maxLineHighlightLength, .backupDir:
            return false
        }
    }
}

public enum SettingBoolean {
    public static func parse(_ rawValue: String, emptyValue: Bool? = nil) -> Bool? {
        switch rawValue.lowercased() {
        case "": return emptyValue
        case "true", "on", "1": return true
        case "false", "off", "0": return false
        default: return nil
        }
    }
}
