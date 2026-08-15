import Foundation

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

    public var suggestedValues: [String] {
        switch self {
        case .wrap: return ["80", "off"]
        case .fill: return ["72", "80"]
        case .ruler, .lineNumbers, .subLineNumbers, .canvasMode, .syntax, .smartTab, .listWrapIndent,
            .autoReload, .ipc, .regex, .debug, .gitDiff, .trimTrailingWhitespace, .noNewlines:
            return ["on", "off"]
        case .tab, .listIndentSize: return ["2", "4", "8"]
        case .language: return Language.allCases.map(\.rawValue)
        case .spellLanguage: return ["en_US", "zh_TW"]
        case .border: return ["single", "double", "round", "double-round", "ascii", "ascii-round"]
        case .arrow: return ["solid", "stemmed", "hollow", "small"]
        case .keymap: return ["classic", "modern"]
        case .modernbindings: return ["on", "off"]
        }
    }

    var supportsConfigUnset: Bool {
        switch self {
        case .wrap, .ruler, .lineNumbers, .subLineNumbers, .canvasMode, .syntax, .smartTab,
            .listWrapIndent, .autoReload, .ipc, .trimTrailingWhitespace, .gitDiff, .debug, .modernbindings, .noNewlines:
            return true
        case .listIndentSize, .tab, .fill, .language, .spellLanguage, .border, .arrow, .regex, .keymap:
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
