import Foundation

extension Editor {
    public static let logoDebuggerBufferTitle = "*LOGO Debugger*"

    func showLogoDebuggerBuffer() {
        let activeSource = debuggerController.activeSourceBufferID.flatMap { id in buffers.first { $0.id == id } }
        let source: TextBuffer
        if case .paused = logoEngine.executionState {
            source = activeSource ?? buffer
        } else if buffer.filePath == Self.logoDebuggerBufferTitle {
            source = activeSource ?? buffer
        } else {
            source = buffer
        }
        let lines = debuggerController.breakpoints(in: source)
        let debugBuffer: TextBuffer
        if let index = buffers.firstIndex(where: { $0.filePath == Self.logoDebuggerBufferTitle }) {
            debugBuffer = buffers[index]
            currentBufferIndex = index
        } else {
            debugBuffer = LogoOutputBuffer()
            debugBuffer.filePath = Self.logoDebuggerBufferTitle
            buffers.append(debugBuffer)
            currentBufferIndex = buffers.count - 1
        }
        let state: [String]
        if case .paused(let frame) = logoEngine.executionState {
            let relativeLine =
                frame.token.map { token in
                    debuggerController.activeScript.prefix(token.sourceRange.lowerBound).reduce(0) {
                        $1 == "\n" ? $0 + 1 : $0
                    }
                } ?? 0
            let callStack = logoEngine.executionFrames.reversed().map {
                "  \($0.procedureName ?? "<top level>")"
            }
            let locals = logoEngine.variables.keys.sorted().map {
                "  \($0) = \(logoEngine.variables[$0] ?? "")"
            }
            var pausedState = [
                String(format: l10n["debug.paused_at"], frame.procedureName ?? "<top level>"),
                String(
                    format: l10n["debug.source"], source.filePath ?? source.id,
                    debuggerController.activeSourceStartLine + relativeLine + 1),
                String(format: l10n["debug.token"], frame.token?.text ?? ""),
                l10n["debug.call_stack"],
            ]
            pausedState.append(contentsOf: callStack)
            pausedState.append(contentsOf: ["", l10n["debug.locals"]])
            pausedState.append(contentsOf: locals)
            if let evaluation = debuggerController.lastEvaluation {
                pausedState.append(contentsOf: ["", String(format: l10n["debug.evaluation"], evaluation)])
            }
            pausedState.append("")
            state = pausedState
        } else {
            state = [String(format: l10n["debug.state"], String(describing: logoEngine.executionState)), ""]
        }
        debugBuffer.lines =
            [l10n["debug.logo_title"], ""] + state
            + [String(format: l10n["debug.breakpoints"], source.filePath ?? source.id)]
            + (lines.isEmpty ? [l10n["debug.none"]] : lines.map { String(format: l10n["debug.line"], $0 + 1) })
            + ["", l10n["debug.commands"]]
        debugBuffer.lineIndex = 0
        debugBuffer.columnIndex = 0
    }

    func toggleLogoDebuggerBuffer() { showLogoDebuggerBuffer() }

    func resumeLogoDebugExecution(step: Bool) {
        if let id = debuggerController.executionTargetBufferID,
            let index = buffers.firstIndex(where: { $0.id == id })
        {
            switchToBuffer(index: index)
        }
        if step { logoEngine.stepExecution() } else { logoEngine.continueExecution() }
        if case .paused = logoEngine.executionState {
            showLogoDebuggerBuffer()
        } else {
            reportOperationResult(.succeeded(message: l10n["status.logo_debug_completed"]))
        }
    }

    func abortLogoDebugExecution() {
        logoEngine.abortExecution()
        reportOperationResult(.succeeded(message: l10n["status.logo_debug_aborted"]))
        showLogoDebuggerBuffer()
    }

    func evaluateLogoDebugExpression(_ expression: String) {
        guard !expression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let result = logoEngine.evaluatePausedExpression(expression) else {
            reportOperationResult(.noOp(message: l10n["status.logo_debug_not_paused"]))
            return
        }
        debuggerController.lastEvaluation = result
        showLogoDebuggerBuffer()
        reportOperationResult(.succeeded(message: String(format: l10n["status.logo_debug_result"], result)))
    }
}
