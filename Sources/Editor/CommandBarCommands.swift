import Foundation

public enum CommandBarDispatchResult: Sendable, Equatable {
    case handled
    case noMatch
}

public struct CommandBarInput: Sendable, Equatable {
    public let raw: String
    public let text: String
    public let tokens: [String]
    public let firstToken: String?
    public let rest: String

    public init(_ raw: String) {
        self.raw = raw
        self.text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tokens = text.split(whereSeparator: \.isWhitespace).map(String.init)
        let parts = text.split(maxSplits: 1, whereSeparator: \.isWhitespace)
        self.firstToken = parts.first.map(String.init)
        self.rest = parts.count > 1 ? String(parts[1]) : ""
    }

    public var lowerFirstToken: String? {
        firstToken?.lowercased()
    }

    public var firstTokenIsAllUppercaseWord: Bool {
        guard let firstToken else { return false }
        return firstToken != firstToken.lowercased() && firstToken == firstToken.uppercased()
    }
}

public protocol CommandBarCommand {
    var name: String { get }
    var help: String { get }

    func match(_ input: CommandBarInput) -> Bool
    func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult
}

public final class CommandBarRegistry {
    private var commands: [any CommandBarCommand] = []

    public init() {}

    public func register(_ command: any CommandBarCommand) {
        commands.append(command)
    }

    public func dispatch(_ rawInput: String, editor: Editor) -> CommandBarDispatchResult {
        let input = CommandBarInput(rawInput)
        guard !input.text.isEmpty else { return .handled }

        for command in commands where command.match(input) {
            return command.execute(input, editor: editor)
        }

        return .noMatch
    }

    public static func makeDefault() -> CommandBarRegistry {
        let registry = CommandBarRegistry()
        registry.register(CommandIDCommandBarCommand(names: ["save"], commandID: .fileSave))
        registry.register(CommandIDCommandBarCommand(names: ["new"], commandID: .bufferNew))
        registry.register(CommandIDCommandBarCommand(names: ["close"], commandID: .fileExit))
        registry.register(OpenCommandBarCommand())
        registry.register(WriteCommandBarCommand())
        registry.register(BufferCommandBarCommand())
        registry.register(NumericGotoCommandBarCommand())
        return registry
    }
}
