import Foundation

public struct LogoOutputCommand: Command {
    public let id: CommandID = .logoOutput
    public let name = "LOGO Output Buffer"
    public let description = "Toggle viewing the *LOGO Output* buffer"
    public let keys: [Key] = [.alt("L"), .alt("l")]
    public let commandBarAliases: [String] = ["output", "logooutput", "log", "messages"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    public func execute(on editor: Editor) {
        editor.toggleLogoOutputBuffer()
    }
}

public struct ClearLogoOutputCommand: Command {
    public let id: CommandID = .logoClearOutput
    public let name = "Clear LOGO Output Buffer"
    public let description = "Clear all contents in the *LOGO Output* buffer"
    public let keys: [Key] = []
    public let commandBarAliases: [String] = ["clearoutput", "clog", "clear-output"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    public func execute(on editor: Editor) {
        editor.clearLogoOutputBuffer()
    }
}
