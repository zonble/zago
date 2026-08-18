import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

@Suite struct LogoErrorAndOutputTests {
    @Test func testLogoErrorStructAndListFormat() {
        let err = LogoError(code: 1, message: "Division by zero", procedureName: "SAFE_DIV")
        #expect(err.code == 1)
        #expect(err.message == "Division by zero")
        #expect(err.procedureName == "SAFE_DIV")
        #expect(err.toLogoListString == "[1 \"Division by zero\" \"SAFE_DIV\"]")
    }

    @Test func testCatchAndThrowErrorPrimitives() {
        let editor = Editor()
        let script = """
            TO TEST_DIV :a :b
                CATCH "ERROR [
                    IF :b = 0 [ THROW "ERROR "ZeroError ]
                    OUTPUT :a / :b
                ]
                OUTPUT ERROR
            END
            """
        editor.runLogoScript(script)
        #expect(editor.logoEngine.customProcedures["TEST_DIV"] != nil)

        editor.runLogoScript("OUTPUT TEST_DIV 10 2")
        #expect(editor.logoEngine.lastResult == "5")

        editor.runLogoScript("OUTPUT TEST_DIV 10 0")
        #expect(editor.logoEngine.lastResult?.contains("ZeroError") == true)
    }

    @Test func testLogoOutputBufferManagementAndCommands() {
        let editor = Editor()
        #expect(editor.findLogoOutputBufferIndex() == nil)

        editor.appendLogoOutput("Line 1 Output", scriptName: "test.logo")
        #expect(editor.findLogoOutputBufferIndex() == nil)

        let buf = editor.ensureLogoOutputBuffer()
        let idx = editor.findLogoOutputBufferIndex()
        #expect(idx != nil)
        #expect(buf.filePath == "*LOGO Output*")
        #expect(buf is LogoOutputBuffer)
        #expect(buf.isReadOnly == true)
        #expect(buf.allowsLogoExecution == false)
        #expect(buf.lines.contains { $0.contains("Line 1 Output") })

        editor.toggleLogoOutputBuffer()
        #expect(editor.currentBufferIndex == idx!)

        editor.tableModeController.toggleTableMode()
        #expect(editor.isTableModeActive == false)
        #expect(editor.statusMessage == editor.l10n["status.buffer_readonly_bracketed"])

        editor.switchToCanvasMode()
        #expect(editor.isCanvasModeActive == false)
        #expect(editor.statusMessage == editor.l10n["status.buffer_readonly_bracketed"])

        editor.toggleLogoOutputBuffer()
        #expect(editor.findLogoOutputBufferIndex() == nil)

        editor.clearLogoOutputBuffer()
        #expect(!editor.logoOutputHistory.contains { $0.contains("Line 1 Output") })
    }

    @Test func testLogoOutputBufferBlocksLogoExecutionLikeDirectoryBuffer() {
        let editor = Editor(filePath: "document.md")
        editor.toggleLogoOutputBuffer()
        #expect(editor.buffer is LogoOutputBuffer)

        let initialLines = editor.buffer.lines
        let ok = editor.runLogoScript("BOX 4 4")

        #expect(ok == false)
        #expect(editor.buffer.lines == initialLines)
        #expect(editor.statusMessage == editor.l10n["status.directory_buffer_readonly"])
    }

    @Test func testEvaluatingPlainTextReportsErrorWithoutTakingOverDocument() {
        let editor = Editor(filePath: "document.md")
        editor.buffer.lines = ["operation without taking over the document."]

        editor.evalLogoCode()

        #expect(editor.buffer.lines == ["operation without taking over the document."])
        #expect(editor.logoEngine.hasUncaughtError == false)
        #expect(editor.statusMessage == editor.l10n["status.logo_execution_error"])
    }

    @Test func testLogoOutputOnDemandLoggingAndAutoRemoval() {
        let editor = Editor(filePath: "document.md")
        #expect(editor.buffers.count == 1)
        #expect(editor.findLogoOutputBufferIndex() == nil)

        // Running LOGO commands logs output in background history without polluting buffers list
        editor.runLogoScript("PRINT \"Background Output Log\"")
        #expect(editor.buffers.count == 1)
        #expect(editor.findLogoOutputBufferIndex() == nil)
        #expect(editor.logoOutputHistory.contains { $0.contains("Background Output Log") })

        // Toggle ON (Alt+L): Dynamically creates *LOGO Output* buffer and switches to it
        editor.toggleLogoOutputBuffer()
        #expect(editor.buffers.count == 2)
        let outputIdx = editor.findLogoOutputBufferIndex()
        #expect(outputIdx != nil)
        #expect(editor.currentBufferIndex == outputIdx!)
        #expect(editor.buffer.lines.contains { $0.contains("Background Output Log") })

        // Toggle OFF (Alt+L): Switches back to document.md AND removes *LOGO Output* from buffers list
        editor.toggleLogoOutputBuffer()
        #expect(editor.buffers.count == 1)
        #expect(editor.findLogoOutputBufferIndex() == nil)
        #expect(editor.buffer.filePath == "document.md")
    }

    @Test func testErrorHandlingDemoExampleScript() {
        let editor = Editor()
        let scriptPath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(
            "examples/logo/error_handling_demo.logo")
        guard FileManager.default.fileExists(atPath: scriptPath) else { return }
        guard let content = try? String(contentsOfFile: scriptPath, encoding: .utf8) else { return }

        let ok = editor.runLogoScript(content)
        #expect(ok)

        editor.ensureLogoOutputBuffer()
        let outputIdx = editor.findLogoOutputBufferIndex()
        #expect(outputIdx != nil)
        let outputLines = editor.buffers[outputIdx!].lines
        #expect(outputLines.contains { $0.contains("5") })
        #expect(outputLines.contains { $0.contains("NaN") })
    }

    @Test func testLogoFileExecutionTargetsLogoCanvasBufferAndPreservesSourceCode() {
        let editor = Editor(filePath: "demo.logo")
        editor.buffer.lines = ["BOX 4 4"]

        let ok = editor.runLogoScript("BOX 4 4")
        #expect(ok)

        let sourceBuf = editor.buffers[0]
        #expect(sourceBuf.filePath == "demo.logo")
        #expect(sourceBuf.lines == ["BOX 4 4"])

        let canvasIdx = editor.findLogoCanvasBufferIndex()
        #expect(canvasIdx != nil)
        #expect(editor.currentBufferIndex == canvasIdx!)

        let canvasBuf = editor.buffers[canvasIdx!]
        #expect(canvasBuf.filePath == "*LOGO Canvas*")
        #expect(canvasBuf.lines.contains { $0.contains("┌") || $0.contains("┐") || $0.contains("─") })

        editor.toggleLogoCanvasBuffer()
        #expect(editor.currentBufferIndex == 0)
    }

    @Test func testNonLogoFileEvalExecutesInCurrentBuffer() {
        let editor = Editor(filePath: "document.md")
        editor.buffer.lines = ["BOX 4 4"]

        editor.evalLogoCode()

        #expect(editor.buffer.filePath == "document.md")
        #expect(editor.findLogoCanvasBufferIndex() == nil)
        #expect(editor.buffer.lines.contains { $0.contains("┌") || $0.contains("┐") || $0.contains("─") })
    }

    @Test func testMarkdownLogoBreakpointPausesStepsAndContinues() {
        let editor = Editor(filePath: "document.md")
        let source = editor.buffer
        source.lines = ["# Demo", "```logo", "MAKE \"x 1", "MAKE \"x 2", "```"]
        source.lineIndex = 2
        editor.debuggerController.toggleBreakpoint(in: source)

        editor.evalLogoCode()

        guard case .paused(let firstFrame) = editor.logoEngine.executionState else {
            Issue.record("Expected LOGO execution to pause")
            return
        }
        #expect(firstFrame.token?.text == "MAKE")
        #expect(editor.buffer.filePath == Editor.logoDebuggerBufferTitle)
        #expect(editor.logoEngine.variables["x"] == nil)

        editor.resumeLogoDebugExecution(step: true)
        guard case .paused(let secondFrame) = editor.logoEngine.executionState else {
            Issue.record("Expected stepped LOGO execution to pause")
            return
        }
        #expect(secondFrame.token?.text == "MAKE")
        #expect(editor.logoEngine.variables["x"] == "1")

        editor.resumeLogoDebugExecution(step: false)
        #expect(editor.logoEngine.executionState == .completed)
        #expect(editor.logoEngine.variables["x"] == "2")
        #expect(editor.buffer.id == source.id)
    }

    @Test func testRunMenuVisibilityOnLogoFilesOnly() {
        let mdEditor = Editor(filePath: "test.md")
        mdEditor.menuBar.updateCategories(for: mdEditor)
        #expect(!mdEditor.menuBar.categories.contains { $0.titleKey == "menu.run" })

        let logoEditor = Editor(filePath: "test.logo")
        logoEditor.menuBar.updateCategories(for: logoEditor)
        #expect(logoEditor.menuBar.categories.contains { $0.titleKey == "menu.run" })
    }

    @Test func testLogoCanvasCommandAndAltCSShortcut() {
        let editor = Editor(filePath: "test.logo")
        #expect(editor.findLogoCanvasBufferIndex() == nil)

        let handled = editor.commandRegistry.dispatch(key: .alt("C"), editor: editor)
        #expect(handled)

        let idx = editor.findLogoCanvasBufferIndex()
        #expect(idx != nil)
        #expect(editor.currentBufferIndex == idx!)

        let canvasBuf = editor.buffers[idx!]
        #expect(canvasBuf.baseMode == .canvas)

        #expect(editor.commandRegistry.dispatch(key: .alt("C"), editor: editor))
        #expect(editor.currentBufferIndex != idx!)
    }

    @Test func testRunLogoScriptCommandF5Shortcut() {
        let editor = Editor(filePath: "diagram.logo")
        editor.buffer.lines = ["BOX 4 4"]

        let handled = editor.commandRegistry.dispatch(key: .f5, editor: editor)
        #expect(handled)

        #expect(editor.buffers[0].lines == ["BOX 4 4"])
        let idx = editor.findLogoCanvasBufferIndex()
        #expect(idx != nil)
        #expect(editor.currentBufferIndex == idx!)
    }

    @Test func testRunLogoScriptCommandF5ShortcutOnlyRunsLogoFiles() {
        let editor = Editor(filePath: "document.md")
        editor.buffer.lines = ["BOX 4 4"]

        let handled = editor.commandRegistry.dispatch(key: .f5, editor: editor)
        #expect(handled)
        #expect(editor.findLogoCanvasBufferIndex() == nil)
        #expect(editor.logoOutputHistory.isEmpty)
    }

    @Test func testClearLogoOutputAndCanvasCommand() {
        let editor = Editor(filePath: "diagram.logo")
        editor.runLogoScript("BOX 4 4")
        editor.appendLogoOutput("Some output message")

        #expect(editor.findLogoCanvasBufferIndex() != nil)
        #expect(editor.findLogoOutputBufferIndex() == nil)

        editor.ensureLogoOutputBuffer()
        #expect(editor.findLogoOutputBufferIndex() != nil)

        editor.clearLogoOutputAndCanvasBuffers()

        let outputIdx = editor.findLogoOutputBufferIndex()!
        #expect(!editor.buffers[outputIdx].lines.contains { $0.contains("Some output message") })
    }

    @Test func testUnsavedBufferEvalInCurrentBuffer() {
        let editor = Editor()
        editor.buffer.lines = ["BOX 4 4"]

        editor.evalLogoCode()

        #expect(editor.findLogoCanvasBufferIndex() == nil)
        #expect(editor.buffer.lines.contains { $0.contains("┌") || $0.contains("┐") || $0.contains("─") })
    }

    @Test func testAssertPrimitiveSuccessAndFailure() {
        let editor = Editor()
        let logoEngine = LogoEngine(delegate: editor)

        // 1. ASSERT pass
        logoEngine.execute("MAKE \"x 10 ASSERT :x = 10 \"x must be 10")
        #expect(!logoEngine.hasUncaughtError)

        // 2. ASSERT failure with custom message
        let editor2 = Editor()
        let logoEngine2 = LogoEngine(delegate: editor2)
        logoEngine2.execute("MAKE \"x 5 ASSERT :x > 10 \"x is too small")
        #expect(logoEngine2.hasUncaughtError)
        #expect(logoEngine2.lastError?.message == "[LOGO Assertion Failed: x is too small]")

        // 3. ASSERT failure trapped inside CATCH "ERROR
        let editor3 = Editor()
        let logoEngine3 = LogoEngine(delegate: editor3)
        logoEngine3.execute(
            """
            CATCH "ERROR [
                ASSERT 1 = 2 "math is broken
            ]
            """)
        #expect(logoEngine3.lastError != nil)
    }

    @Test func testEvalLogoScopeBoundaries() {
        let editor = Editor()
        editor.buffer.lines = [
            "MAKE \"a 1",
            "```logo",
            "MAKE \"b 2",
            "MAKE \"c 3",
            "```",
            "MAKE \"d 4",
            "TO DOUBLE :x :x * 2 END",
            "MAKE \"e (DOUBLE 5)",
        ]

        // 1. Cursor on line 0 (ordinary single line) -> only line 0 is evaluated
        editor.buffer.lineIndex = 0
        editor.evalLogoCode()
        #expect(editor.logoEngine.variables["a"] == "1")
        #expect(editor.logoEngine.variables["b"] == nil)

        // 2. Cursor inside Markdown fence (line 2) -> lines 2 & 3 evaluated
        editor.buffer.lineIndex = 2
        editor.evalLogoCode()
        #expect(editor.logoEngine.variables["b"] == "2")
        #expect(editor.logoEngine.variables["c"] == "3")
        #expect(editor.logoEngine.variables["d"] == nil)

        // 3. Cursor on line right below Markdown fence (line 5) -> fence above evaluated
        editor.logoEngine.variables["b"] = nil
        editor.buffer.lineIndex = 5
        editor.evalLogoCode()
        #expect(editor.logoEngine.variables["b"] == "2")

        // 4. Cursor on line 6 -> defines DOUBLE procedure
        editor.buffer.lineIndex = 6
        editor.evalLogoCode()
        #expect(editor.logoEngine.customProcedures["DOUBLE"] != nil)

        // 5. Cursor on line 7 (after single-line TO ... END on line 6) -> only line 7 evaluated
        editor.buffer.lineIndex = 7
        editor.evalLogoCode()
        #expect(editor.logoEngine.variables["e"] == "10")
    }

    @Test func testEvalLogoDoesNotBleedAcrossSingleLineProcedures() {
        let editor = Editor()
        editor.buffer.lines = [
            "TO CDATE :x FORMAT.DATE :x \"full \"zh-TW END",
            "",
            "TO CNUM :x FORMAT.NUMBER :x \"words \"zh-TW END",
            "",
            "MAKE \"line5 5",
            "",
            "MAKE \"line7 7",
            "",
            "MAKE \"line9 9",
            "",
            "MAKE \"line11 11",
        ]

        // Ensure when cursor is on line 6 (MAKE "line7 7"),
        // ONLY line 6 is evaluated, and lines 0, 2, 4, 8, 10 are NOT evaluated!
        editor.buffer.lineIndex = 6
        editor.evalLogoCode()

        #expect(editor.logoEngine.variables["line7"] == "7")
        #expect(editor.logoEngine.variables["line5"] == nil)
        #expect(editor.logoEngine.variables["line9"] == nil)
        #expect(editor.logoEngine.variables["line11"] == nil)
        #expect(editor.logoEngine.customProcedures["CDATE"] == nil)
        #expect(editor.logoEngine.customProcedures["CNUM"] == nil)
    }
}
