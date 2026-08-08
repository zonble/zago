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
        let idx = editor.findLogoOutputBufferIndex()
        #expect(idx != nil)

        let buf = editor.buffers[idx!]
        #expect(buf.filePath == "*LOGO Output*")
        #expect(buf.isReadOnly == true)
        #expect(buf.lines.contains { $0.contains("Line 1 Output") })

        editor.toggleLogoOutputBuffer()
        #expect(editor.currentBufferIndex == idx!)

        editor.tableModeController.toggleTableMode()
        #expect(editor.isTableModeActive == false)
        #expect(editor.statusMessage == "[ Buffer is read-only ]")

        editor.switchToCanvasMode()
        #expect(editor.isCanvasModeActive == false)
        #expect(editor.statusMessage == "[ Buffer is read-only ]")

        editor.toggleLogoOutputBuffer()
        #expect(editor.currentBufferIndex != idx!)

        editor.clearLogoOutputBuffer()
        #expect(!editor.buffers[idx!].lines.contains { $0.contains("Line 1 Output") })
    }

    @Test func testErrorHandlingDemoExampleScript() {
        let editor = Editor()
        let scriptPath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent("examples/error_handling_demo.logo")
        guard FileManager.default.fileExists(atPath: scriptPath) else { return }
        guard let content = try? String(contentsOfFile: scriptPath, encoding: .utf8) else { return }

        let ok = editor.runLogoScript(content)
        #expect(ok)

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

        editor.commandRegistry.dispatch(key: .alt("C"), editor: editor)
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

    @Test func testClearLogoOutputAndCanvasCommand() {
        let editor = Editor(filePath: "diagram.logo")
        editor.runLogoScript("BOX 4 4")
        editor.appendLogoOutput("Some output message")

        #expect(editor.findLogoCanvasBufferIndex() != nil)
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
}
