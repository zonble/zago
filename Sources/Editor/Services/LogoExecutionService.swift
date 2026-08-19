import Diagram
import Drawing
import Foundation
import LogoEngine

/// Application service for executing LOGO scripts either in headless mode or within a buffer context.
public final class LogoExecutionService: @unchecked Sendable {
    public init() {}

    /// Renders a LOGO script directly to lines in a clean, standalone buffer with no Editor or UI overhead.
    public static func render(
        script: String,
        initialVariables: [String: String] = [:],
        tabSize: Int = 4,
        borderStyle: BorderStyle = .single,
        arrowStyle: ArrowStyle = .solid
    ) -> [String] {
        let buffer = TextBuffer()
        let delegate = TextBufferLogoDelegate(
            buffer: buffer,
            defaultBorderStyle: borderStyle,
            defaultArrowStyle: arrowStyle,
            tabSize: tabSize
        )
        let engine = LogoEngine(delegate: delegate, initialVariables: initialVariables)
        engine.execute(script)
        let lines = buffer.lines
        guard lines.count > 1 || lines.first?.isEmpty == false else {
            return [""]
        }
        return lines
    }

    /// Executes a LOGO script on a target buffer with customizable hooks and initial variables.
    func execute(
        script: String,
        in buffer: TextBuffer,
        initialVariables: [String: String] = [:],
        defaultBorderStyle: BorderStyle = .single,
        defaultArrowStyle: ArrowStyle = .solid,
        tabSize: Int = 4,
        hooks: LogoUIHooks = .empty
    ) -> (lastResult: String?, output: [String]) {
        final class OutputCollector: @unchecked Sendable {
            var lines: [String] = []
        }
        let collector = OutputCollector()
        var combinedHooks = hooks
        let originalAppend = hooks.onAppendOutput
        combinedHooks.onAppendOutput = { text in
            collector.lines.append(text)
            originalAppend?(text)
        }

        let delegate = TextBufferLogoDelegate(
            buffer: buffer,
            defaultBorderStyle: defaultBorderStyle,
            defaultArrowStyle: defaultArrowStyle,
            tabSize: tabSize,
            hooks: combinedHooks
        )
        let engine = LogoEngine(delegate: delegate, initialVariables: initialVariables)
        engine.execute(script)
        return (engine.lastResult, collector.lines)
    }
}
