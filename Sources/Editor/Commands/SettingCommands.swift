import Foundation

struct SettingCommand: Command {
    let id: CommandID = .fileEditConfig
    let name = "Setting"
    let description = "Set editor settings (e.g. set wrap 80)"
    let commandBarAliases: [String] = ["set", "unset"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.editConfig()
        return .succeeded
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard let first = input.lowerFirstToken else { return .succeeded }

        let parts = input.rest.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let setting = parts.first, !setting.isEmpty else {
            return .succeeded(message: editor.l10n["status.path_required"])
        }

        let rawValue = parts.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let value = first == "unset" ? "off" : rawValue
        guard let editorSetting = EditorSettingUpdateParser.parse(setting: setting, value: value) else {
            return .succeeded(message: editor.l10n["status.path_required"])
        }
        editor.apply(editorSetting)
        return .succeeded
    }

    static let settingNames = EditorSettingUpdateParser.settingNames

    static func valueSuggestions(for setting: String) -> [String] {
        EditorSettingUpdateParser.valueSuggestions(for: setting)
    }
}
