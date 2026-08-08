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

public struct RunLogoScriptCommand: Command {
    public let id: CommandID = .fileRunLogo
    public let name = "Run LOGO Script"
    public let description = "Run full LOGO script in active buffer"
    public let keys: [Key] = [.f5]
    public let commandBarAliases: [String] = ["run", "runscript", "runlogo"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    public func execute(on editor: Editor) {
        let code = editor.buffer.lines.joined(separator: "\n")
        editor.runLogoScript(code)
    }
}

public struct LogoCanvasCommand: Command {
    public let id: CommandID = .logoCanvas
    public let name = "LOGO Canvas Buffer"
    public let description = "Toggle viewing the *LOGO Canvas* buffer"
    public let keys: [Key] = [.alt("C"), .alt("c")]
    public let commandBarAliases: [String] = ["canvas-buffer", "logocanvas", "canvas"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    public func execute(on editor: Editor) {
        editor.toggleLogoCanvasBuffer()
    }
}

public struct ClearLogoOutputAndCanvasCommand: Command {
    public let id: CommandID = .logoClearOutput
    public let name = "Clear Canvas & Output"
    public let description = "Clear all contents in *LOGO Canvas* and *LOGO Output* buffers"
    public let keys: [Key] = []
    public let commandBarAliases: [String] = ["clear", "clearall", "clear-canvas"]

    public init() {}

    public func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    public func execute(on editor: Editor) {
        editor.clearLogoOutputAndCanvasBuffers()
    }
}
