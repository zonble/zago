import Foundation

public struct NumericGotoCommandBarCommand: CommandBarCommand {
    public let name = "goto"
    public let help = "line or line:column"

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        input.text.range(of: #"^-?\d+([:,]-?\d+)?$"#, options: .regularExpression) != nil
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        let parts = input.text.split(whereSeparator: { $0 == ":" || $0 == "," }).map(String.init)
        guard let first = parts.first, let line = Int(first), line > 0 else {
            editor.setStatusMessage(L10n["status.invalid_line"])
            return .handled
        }

        if parts.count == 2 {
            guard let col = Int(parts[1]), col > 0 else {
                editor.setStatusMessage(L10n["status.invalid_column"])
                return .handled
            }
            editor.goToLocation(line: line, column: col)
        } else {
            editor.goToLocation(line: line)
        }

        return .handled
    }
}
