import ArgumentParser
import Config
import Editor
import Foundation

@main
struct Zago: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "zago",
        abstract: "zago - zonble's nano + LOGO: A lightweight terminal text editor with powerful plain-text diagramming."
    )

    @Argument(help: "The file(s) to edit.")
    var files: [String] = []

    @Option(
        name: [.customShort("w"), .long],
        help: "Specify softwrap column width (e.g. 80). If omitted, softwrap adapts to terminal width.")
    var wrap: Int?

    @Flag(
        name: [.customShort("r"), .long],
        help:
            "Display a classic WordStar-style ruler bar (----!----1----!----2) above the text viewport.")
    var ruler: Bool = false

    @Option(
        name: [.customLong("syntax")], help: "Enable or disable syntax highlighting (true/false).")
    var syntax: String?

    @Option(
        name: [.customLong("lang"), .customLong("language")], help: "Set interface language (en/zh_TW)."
    )
    var lang: String?

    @Flag(
        name: [.customLong("init"), .customLong("init-config"), .customLong("generate-config")],
        help: "Generate a default ~/.zagorc configuration file.")
    var initConfig: Bool = false

    @Option(
        name: [.customShort("e"), .customLong("eval")],
        help: "Execute inline LOGO code string in headless mode and print output to stdout.")
    var eval: String?

    @Option(
        name: [.customShort("s"), .customLong("run"), .customLong("script")],
        help: "Execute a LOGO script file in headless mode and print output to stdout.")
    var script: String?

    func run() throws {
        if initConfig {
            let targetPath = files.first
            let generatedPath = try ConfigLoader.generateDefaultConfigFile(targetPath: targetPath)
            print("Successfully generated default configuration file at: \(generatedPath)")
            return
        }
        let enableSyntax: Bool?
        if let s = syntax?.lowercased() {
            enableSyntax = (s == "true" || s == "1" || s == "on" || s == "yes")
        } else {
            enableSyntax = nil
        }

        let selectedLang: Language?
        if let l = lang?.lowercased() {
            if l == "zh_tw" || l == "zh-hant" || l == "zh" || l == "tw" {
                selectedLang = .zh_TW
            } else if l == "en" || l == "english" {
                selectedLang = .en
            } else {
                selectedLang = nil
            }
        } else {
            selectedLang = nil
        }

        if let code = eval {
            let editor = Editor(
                wrapColumn: wrap, showRuler: false, enableSyntax: false, language: selectedLang)
            editor.runLogoScript(code)
            let output = editor.buffer.lines.joined(separator: "\n")
            print(output)
            return
        }

        if let scriptPath = script {
            let fileURL = URL(fileURLWithPath: scriptPath)
            do {
                let code = try String(contentsOf: fileURL, encoding: .utf8)
                let editor = Editor(
                    wrapColumn: wrap, showRuler: false, enableSyntax: false, language: selectedLang)
                editor.runLogoScript(code)
                let output = editor.buffer.lines.joined(separator: "\n")
                print(output)
                return
            } catch {
                if let data = "Error reading script file '\(scriptPath)': \(error.localizedDescription)\n".data(using: .utf8) {
                    FileHandle.standardError.write(data)
                }
                throw ExitCode.failure
            }
        }

        let editor = Editor(
            filePaths: files, wrapColumn: wrap, showRuler: ruler, enableSyntax: enableSyntax,
            language: selectedLang)
        editor.run()
    }
}
