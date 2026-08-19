import Testing
@testable import Editor
import LogoEngine

@Suite struct LogoExecutionServiceTests {
    @Test func testHeadlessRenderReturnsLines() {
        let lines = LogoExecutionService.render(script: "BOX 10 3")
        #expect(lines.count == 3)
        #expect(lines.first?.contains("┌") == true || lines.first?.contains("+") == true || lines.first?.contains("┌") == true)
    }

    @Test func testHeadlessRenderWithCommands() {
        let lines = LogoExecutionService.render(script: "TYPE \"Hello NL TYPE \"World")
        #expect(lines == ["Hello", "World"])
    }

    @Test func testTextBufferLogoDelegateBufferMutations() {
        let buffer = TextBuffer()
        let delegate = TextBufferLogoDelegate(buffer: buffer)
        let engine = LogoEngine(delegate: delegate)

        engine.execute("TYPE \"Line1 NL TYPE \"Line2")
        #expect(buffer.lines == ["Line1", "Line2"])

        engine.execute("CHANGE \"Line \"Item")
        #expect(buffer.lines == ["Line1", "Item2"])
    }

    @Test func testLogoUIHooksInvocation() {
        final class HookState: @unchecked Sendable {
            var snapshotSaved = false
            var statusMsg = ""
        }
        let state = HookState()
        let buffer = TextBuffer()
        let hooks = LogoUIHooks(
            onSaveUndoSnapshot: { state.snapshotSaved = true },
            onSetStatusMessage: { msg in state.statusMsg = msg }
        )
        let delegate = TextBufferLogoDelegate(buffer: buffer, hooks: hooks)
        let engine = LogoEngine(delegate: delegate)

        engine.execute("SHOW \"Ready")
        #expect(state.snapshotSaved == true)
        #expect(state.statusMsg == "Ready")
    }
}
