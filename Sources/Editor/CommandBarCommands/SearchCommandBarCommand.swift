import Foundation

public struct SearchCommandBarCommand: CommandBarCommand {
    public let name = "/"
    public let help = "/<keyword>"
    public let completionNames = ["/"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        return input.text.hasPrefix("/")
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        let query = String(input.text.dropFirst())
        if !query.isEmpty {
            editor.lastSearchQuery = query
        }
        let targetQuery = !query.isEmpty ? query : editor.lastSearchQuery
        if targetQuery.isEmpty {
            editor.setStatusMessage(L10n["status.cancelled_search"])
            return .handled
        }

        editor.performSearch(query: targetQuery, useRegex: editor.isRegexSearchEnabled)
        return .handled
    }
}
