import Foundation

public struct SettingCommand: Command {
    public let id: CommandID = .fileEditConfig
    public let name = "Setting"
    public let description = "Set editor settings (e.g. set wrap 80)"
    public let commandBarAliases: [String] = ["set", "unset"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.editConfig()
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
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

    public static let settingNames = [
        "wrap", "ruler", "linenumbers", "sublinenumbers", "syntax", "autoreload", "regex", "tab", "lang", "border",
    ]

    public static func valueSuggestions(for setting: String) -> [String] {
        switch setting.lowercased() {
        case "wrap", "wrapcolumn":
            return ["80", "off"]
        case "ruler", "rulerbar", "showruler",
            "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers", "line_number",
            "sublinenumbers", "sublinenumber", "subline-numbers", "subline-number", "subline_numbers",
            "subline_number", "sublines",
            "syntax", "enablesyntax", "syntaxhighlight", "syntaxhighlighting",
            "autoreload", "auto-reload", "auto_reload",
            "regex", "regexp", "enableregex":
            return ["on", "off"]
        case "tab", "tabsize":
            return ["2", "4", "8"]
        case "lang", "language":
            return ["en", "zh_TW"]
        case "border", "borderstyle", "border-style", "border_style", "defaultborder", "defaultborderstyle",
            "default-border-style", "default_border_style":
            return ["single", "double", "round", "double-round", "ascii", "ascii-round"]
        default:
            return []
        }
    }
}
