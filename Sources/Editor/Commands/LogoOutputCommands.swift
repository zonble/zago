import Foundation

struct LogoOutputCommand: Command {
    let id: CommandID = .logoOutput
    let name = "LOGO Output Buffer"
    let description = "Toggle viewing the *LOGO Output* buffer"
    let commandBarAliases: [String] = ["output", "logooutput", "log", "messages"]

    init() {}

    func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleLogoOutputBuffer()
        return .succeeded
    }
}

struct ClearLogoOutputCommand: Command {
    let id: CommandID = .logoClearOutput
    let name = "Clear LOGO Output Buffer"
    let description = "Clear all contents in the *LOGO Output* buffer"
    let commandBarAliases: [String] = ["clearoutput", "clog", "clear-output"]

    init() {}

    func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearLogoOutputBuffer()
        return .succeeded
    }
}

struct RunLogoScriptCommand: Command {
    let id: CommandID = .fileRunLogo
    let name = "Run LOGO Script"
    let description = "Run full LOGO script in active buffer"
    let commandBarAliases: [String] = ["run", "runscript", "runlogo"]

    init() {}

    func isAvailable(in editor: Editor) -> Bool {
        editor.buffer.filePath?.lowercased().hasSuffix(".logo") == true
    }

    func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard isAvailable(in: editor) else { return .noOp }
        let code = editor.buffer.lines.joined(separator: "\n")
        editor.runLogoScript(code)
        return .succeeded
    }
}

struct LogoCanvasCommand: Command {
    let id: CommandID = .logoCanvas
    let name = "LOGO Canvas Buffer"
    let description = "Toggle viewing the *LOGO Canvas* buffer"
    let commandBarAliases: [String] = ["canvas-buffer", "logocanvas", "canvas"]

    init() {}

    func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleLogoCanvasBuffer()
        return .succeeded
    }
}

struct LogoDebugCommand: Command {
    let id: CommandID = .logoDebug
    let name = "LOGO Debugger"
    let description = "Manage LOGO breakpoints"
    let commandBarAliases = ["logo"]
    init() {}
    func isAvailable(in editor: Editor) -> Bool { editor.isLogoUIEnabled }

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleLogoDebuggerBuffer()
        return .succeeded
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        let subcmd = input.tokens.dropFirst().first?.lowercased()
        #if os(WASI)
            if subcmd == "break" || subcmd == "continue" || subcmd == "step" || subcmd == "abort" {
                return .noOp(message: editor.l10n["status.logo_debug_unsupported_wasi"])
            }
        #endif

        switch subcmd {
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

struct ClearLogoOutputAndCanvasCommand: Command {
    let id: CommandID = .logoClearOutput
    let name = "Clear Canvas & Output"
    let description = "Clear all contents in *LOGO Canvas* and *LOGO Output* buffers"
    let commandBarAliases: [String] = ["clear", "clearall", "clear-canvas"]

    init() {}

    func match(_ input: CommandBarInput) -> Bool {
        guard let token = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(token)
    }

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.clearLogoOutputAndCanvasBuffers()
        return .succeeded
    }
}
