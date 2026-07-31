import Foundation

public struct SettingCommandBarCommand: CommandBarCommand {
    public let name = "set"
    public let help = "set <option> [value]"
    public static let settingNames = ["wrap", "ruler", "linenumbers", "syntax", "autoreload", "tab", "lang"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return first == "set" || first == "unset"
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        guard let first = input.lowerFirstToken else { return .handled }

        let parts = input.rest.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let setting = parts.first, !setting.isEmpty else {
            editor.setStatusMessage(L10n["status.path_required"])
            return .handled
        }

        let rawArg = parts.count > 1 ? parts[1].lowercased() : ""
        let arg = first == "unset" ? "off" : rawArg
        editor.applyEditorSetting(setting: setting.lowercased(), arg: arg)
        return .handled
    }

    public static func valueSuggestions(for setting: String) -> [String] {
        switch setting.lowercased() {
        case "wrap", "wrapcolumn":
            return ["80", "off"]
        case "ruler", "rulerbar", "showruler",
             "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers", "line_number",
             "syntax", "enablesyntax", "syntaxhighlight", "syntaxhighlighting",
             "autoreload", "auto-reload", "auto_reload":
            return ["on", "off"]
        case "tab", "tabsize":
            return ["2", "4", "8"]
        case "lang", "language":
            return ["en", "zh_TW"]
        default:
            return []
        }
    }
}
