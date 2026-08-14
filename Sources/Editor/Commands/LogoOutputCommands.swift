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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleLogoOutputBuffer()
        return .succeeded
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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearLogoOutputBuffer()
        return .succeeded
    }
}

public struct RunLogoScriptCommand: Command {
    public let id: CommandID = .fileRunLogo
    public let name = "Run LOGO Script"
    public let description = "Run full LOGO script in active buffer"
    public let keys: [Key] = [.f5]
    public let commandBarAliases: [String] = ["run", "runscript", "runlogo"]

    public init() {}

    public func isAvailable(in editor: Editor) -> Bool {
        editor.buffer.filePath?.lowercased().hasSuffix(".logo") == true
    }

    public func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard isAvailable(in: editor) else { return .noOp }
        let code = editor.buffer.lines.joined(separator: "\n")
        editor.runLogoScript(code)
        return .succeeded
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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleLogoCanvasBuffer()
        return .succeeded
    }
}

public struct LogoDebugCommand: Command {
    public let id: CommandID = .logoDebug
    public let name = "LOGO Debugger"
    public let description = "Manage LOGO breakpoints"
    public let commandBarAliases = ["logo"]
    public init() {}
    public func isAvailable(in editor: Editor) -> Bool { editor.isLogoUIEnabled }
    

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleLogoDebuggerBuffer()
        return .succeeded
    }
    

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        switch input.tokens.dropFirst().first?.lowercased() {
        case "break":
            let enabled = editor.debuggerController.toggleBreakpoint(in: editor.buffer)
            let key = enabled ? "status.logo_debug_breakpoint_set" : "status.logo_debug_breakpoint_cleared"
            return .succeeded(message: String(format: editor.l10n[key], editor.buffer.lineIndex + 1))
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
        default: return .succeeded(message: editor.l10n["status.logo_debug_usage"])
        }
        return .succeeded
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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearLogoOutputAndCanvasBuffers()
        return .succeeded
    }
}
