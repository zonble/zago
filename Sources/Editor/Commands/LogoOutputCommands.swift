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

public struct LogoDebugCommand: Command {
    public let id: CommandID = .logoDebug
    public let name = "LOGO Debugger"
    public let description = "Manage LOGO breakpoints"
    public let commandBarAliases = ["logo"]
    public init() {}
    public func execute(on editor: Editor) { editor.toggleLogoDebuggerBuffer() }
    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        switch input.tokens.dropFirst().first?.lowercased() {
        case "break":
            let enabled = editor.debuggerController.toggleBreakpoint(in: editor.buffer)
            editor.setStatusMessage("[LOGO Debug] Breakpoint \(enabled ? "set" : "cleared") at line \(editor.buffer.lineIndex + 1)")
        case "breaks": editor.showLogoDebuggerBuffer()
        case "eval":
            let parts = input.rest.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            if parts.count > 1 {
                editor.evaluateLogoDebugExpression(String(parts[1]))
            } else {
                editor.evalLogoCode()
            }
        case "continue": editor.resumeLogoDebugExecution(step: false)
        case "step": editor.resumeLogoDebugExecution(step: true)
        case "abort": editor.abortLogoDebugExecution()
        case "debug", nil: editor.toggleLogoDebuggerBuffer()
        default: editor.setStatusMessage("[LOGO Debug] Usage: :logo break | breaks | eval [expression] | debug | continue | step | abort")
        }
        return .handled
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
