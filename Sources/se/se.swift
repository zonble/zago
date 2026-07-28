import ArgumentParser
import Editor
import Foundation

@main
struct SE: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "se",
        abstract: "A Swift TUI Text Editor with Nano keybindings and softwrap support."
    )

    @Argument(help: "The file(s) to edit.")
    var files: [String] = []

    @Option(name: [.customShort("w"), .long], help: "Specify softwrap column width (e.g. 80). If omitted, softwrap adapts to terminal width.")
    var wrap: Int?

    @Flag(name: [.customShort("r"), .long], help: "Display a classic WordStar-style ruler bar (----!----1----!----2) above the text viewport.")
    var ruler: Bool = false

    @Option(name: [.customLong("syntax")], help: "Enable or disable syntax highlighting (true/false).")
    var syntax: String?

    @Option(name: [.customLong("lang"), .customLong("language")], help: "Set interface language (en/zh_TW).")
    var lang: String?

    @Flag(name: [.customLong("init"), .customLong("init-config"), .customLong("generate-config")], help: "Generate a default ~/.serc configuration file.")
    var initConfig: Bool = false

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

        let editor = Editor(filePaths: files, wrapColumn: wrap, showRuler: ruler, enableSyntax: enableSyntax, language: selectedLang)
        editor.run()
    }
}
