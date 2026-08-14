import Foundation

public struct SettingCommand: Command {
    public let id: CommandID = .fileEditConfig
    public let name = "Setting"
    public let description = "Set editor settings (e.g. set wrap 80)"
    public let commandBarAliases: [String] = ["set", "unset"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.editConfig()
        return .succeeded
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard let first = input.lowerFirstToken else { return .succeeded }

        let parts = input.rest.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let setting = parts.first, !setting.isEmpty else {
            return .succeeded(message: editor.l10n["status.path_required"])
        }

        let rawValue = parts.count > 1 ? parts[1] : ""
        let value = first == "unset" ? "off" : rawValue
        guard let editorSetting = EditorSettingUpdateParser.parse(setting: setting, value: value) else {
            return .succeeded(message: editor.l10n["status.path_required"])
        }
        editor.apply(editorSetting)
        return .succeeded
    }

    public static let settingNames = EditorSettingUpdateParser.settingNames

    public static func valueSuggestions(for setting: String) -> [String] {
        EditorSettingUpdateParser.valueSuggestions(for: setting)
    }
}
