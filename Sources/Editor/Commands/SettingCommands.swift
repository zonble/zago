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
            editor.setStatusMessage(editor.l10n["status.path_required"])
            return .handled
        }

        let rawValue = parts.count > 1 ? parts[1] : ""
        let value = first == "unset" ? "off" : rawValue
        guard let editorSetting = EditorSettingUpdateParser.parse(setting: setting, value: value) else {
            editor.setStatusMessage(editor.l10n["status.path_required"])
            return .handled
        }
        editor.apply(editorSetting)
        return .handled
    }

    public static let settingNames = EditorSettingUpdateParser.settingNames

    public static func valueSuggestions(for setting: String) -> [String] {
        EditorSettingUpdateParser.valueSuggestions(for: setting)
    }
}
