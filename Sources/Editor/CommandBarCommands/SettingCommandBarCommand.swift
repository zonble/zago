import Foundation

public struct SettingCommandBarCommand: CommandBarCommand {
    public let name = "set"
    public let help = "set <option> [value]"

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
}
