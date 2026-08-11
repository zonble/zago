import Foundation

extension Editor {
    public static let logoDebuggerBufferTitle = "*LOGO Debugger*"

    public func showLogoDebuggerBuffer() {
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
            let relativeLine = frame.token.map { token in
                debuggerController.activeScript.prefix(token.sourceRange.lowerBound).reduce(0) { $1 == "\n" ? $0 + 1 : $0 }
            } ?? 0
            let callStack = logoEngine.executionFrames.reversed().map {
                "  \($0.procedureName ?? "<top level>")"
            }
            let locals = logoEngine.variables.keys.sorted().map {
                "  \($0) = \(logoEngine.variables[$0] ?? "")"
            }
            var pausedState = [
                "Paused at \(frame.procedureName ?? "<top level>")",
                "Source: \(source.filePath ?? source.id):\(debuggerController.activeSourceStartLine + relativeLine + 1)",
                "Token: \(frame.token?.text ?? "")",
                "Call stack:",
            ]
            pausedState.append(contentsOf: callStack)
            pausedState.append(contentsOf: ["", "Locals:"])
            pausedState.append(contentsOf: locals)
            if let evaluation = debuggerController.lastEvaluation {
                pausedState.append(contentsOf: ["", "Evaluation: \(evaluation)"])
            }
            pausedState.append("")
            state = pausedState
        } else {
            state = ["State: \(String(describing: logoEngine.executionState))", ""]
        }
        debugBuffer.lines = ["LOGO Debugger", ""] + state + ["Breakpoints — \(source.filePath ?? source.id)"]
            + (lines.isEmpty ? ["  (none)"] : lines.map { "  ● line \($0 + 1)" })
            + ["", "Commands: :logo continue | :logo step | :logo abort | :logo eval"]
        debugBuffer.lineIndex = 0
        debugBuffer.columnIndex = 0
    }

    public func toggleLogoDebuggerBuffer() { showLogoDebuggerBuffer() }

    public func resumeLogoDebugExecution(step: Bool) {
        if let id = debuggerController.executionTargetBufferID,
            let index = buffers.firstIndex(where: { $0.id == id })
        {
            switchToBuffer(index: index)
        }
        if step { logoEngine.stepExecution() } else { logoEngine.continueExecution() }
        if case .paused = logoEngine.executionState {
            showLogoDebuggerBuffer()
        } else {
            setStatusMessage("[LOGO Debug] Execution completed")
        }
    }

    public func abortLogoDebugExecution() {
        logoEngine.abortExecution()
        setStatusMessage("[LOGO Debug] Execution aborted")
        showLogoDebuggerBuffer()
    }

    public func evaluateLogoDebugExpression(_ expression: String) {
        guard !expression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let result = logoEngine.evaluatePausedExpression(expression) else {
            setStatusMessage("[LOGO Debug] Execution is not paused")
            return
        }
        debuggerController.lastEvaluation = result
        showLogoDebuggerBuffer()
        setStatusMessage("[LOGO Debug] \(result)")
    }
}
