import Foundation

/// Canonical editor setting names accepted at the command/config boundary.
public enum EditorSetting: String, CaseIterable {
    case wrap
    case ruler
    case lineNumbers = "linenumbers"
    case subLineNumbers = "sublinenumbers"
    case canvasMode = "canvas-mode"
    case syntax
    case autoReload = "autoreload"
    case ipc
    case regex
    case tab
    case language = "lang"
    case border
    case arrow
    case trimTrailingWhitespace = "trim-trailing-whitespace"

    public var suggestedValues: [String] {
        switch self {
        case .wrap: return ["80", "off"]
        case .ruler, .lineNumbers, .subLineNumbers, .canvasMode, .syntax, .autoReload, .ipc, .regex, .trimTrailingWhitespace:
            return ["on", "off"]
        case .tab: return ["2", "4", "8"]
        case .language: return ["en", "zh_TW"]
        case .border: return ["single", "double", "round", "double-round", "ascii", "ascii-round"]
        case .arrow: return ["solid", "stemmed", "hollow", "small"]
        }
    }

    func makeChange(value rawValue: String) -> EditorSettingChange? {
        let value = rawValue.lowercased()
        switch self {
        case .wrap:
            let column = (value == "off" || value == "false" || value == "none") ? nil : Int(value).flatMap { $0 > 0 ? $0 : nil }
            return .wrap(column: column)
        case .ruler: return .ruler(Self.parseBoolean(value))
        case .lineNumbers: return .lineNumbers(Self.parseBoolean(value))
        case .subLineNumbers: return .subLineNumbers(Self.parseBoolean(value))
        case .canvasMode: return .canvasMode(Self.parseBoolean(value))
        case .syntax: return .syntaxHighlighting(Self.parseBoolean(value))
        case .autoReload: return .autoReload(Self.parseBoolean(value))
        case .ipc: return .ipc(Self.parseBoolean(value))
        case .regex: return .regex(Self.parseBoolean(value))
        case .trimTrailingWhitespace: return .trimTrailingWhitespace(Self.parseBoolean(value))
        case .tab:
            guard let size = Int(value), size > 0 else { return nil }
            return .tabSize(size)
        case .language:
            if value == "en" { return .language(.en) }
            if value == "zh_tw" { return .language(.zh_TW) }
            return nil
        case .border: return .border(BorderStyle(value), rawValue: value)
        case .arrow: return .arrow(ArrowStyle(value))
        }
    }

    private static func parseBoolean(_ value: String) -> Bool? {
        if value == "on" || value == "true" { return true }
        if value == "off" || value == "false" { return false }
        return nil
    }
}

public enum EditorSettingChange {
    case wrap(column: Int?)
    case ruler(Bool?)
    case lineNumbers(Bool?)
    case subLineNumbers(Bool?)
    case canvasMode(Bool?)
    case syntaxHighlighting(Bool?)
    case autoReload(Bool?)
    case trimTrailingWhitespace(Bool?)
    case regex(Bool?)
    case tabSize(Int)
    case language(Language)
    case border(BorderStyle?, rawValue: String)
    case arrow(ArrowStyle?)
    case ipc(Bool?)
}

public enum EditorEffect: Equatable {
    case ipcEnabled(Bool)
}

public protocol EditorEffectDelegate: AnyObject {
    func editor(_ editor: Editor, didEmit effect: EditorEffect)
}

public enum EditorSettingParser {
    public static let settingNames = EditorSetting.allCases.map(\.rawValue)

    public static func parse(setting: String, value: String) -> EditorSettingChange? {
        EditorSetting(rawValue: setting.lowercased())?.makeChange(value: value)
    }

    public static func valueSuggestions(for setting: String) -> [String] {
        EditorSetting(rawValue: setting.lowercased())?.suggestedValues ?? []
    }
}
