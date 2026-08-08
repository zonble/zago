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
}
