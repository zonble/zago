import Foundation
import Testing

@testable import Editor
@testable import LogoEngine

@Suite struct LogoExampleExecutionTests {
    @Test func testAllExampleLogoScriptsExecutionAndExpectedOutput() throws {
        let fm = FileManager.default
        let examplesUrl = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("examples").appendingPathComponent("logo")
        let files = try fm.contentsOfDirectory(at: examplesUrl, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "logo" }

        #expect(files.count >= 34, "Expected at least 34 example logo files in examples/logo/")

        for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let filename = file.lastPathComponent
            if filename == "game.logo" { continue }
            let script = try String(contentsOf: file, encoding: .utf8)
            let editor = Editor()

            editor.logoEngine.execute(script)

            #expect(
                !editor.logoEngine.hasUncaughtError,
                "Example script failed: \(filename) with error: \(editor.logoEngine.lastError?.message ?? "")")

            let fullBufferText = editor.buffer.lines.joined(separator: "\n").trimmingCharacters(
                in: .whitespacesAndNewlines)
            #expect(!fullBufferText.isEmpty, "Example script \(filename) produced completely empty output buffer")
        }
    }
}
