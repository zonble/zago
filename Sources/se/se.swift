import ArgumentParser
import Editor
import Foundation

@main
struct SE: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "se",
        abstract: "A Swift TUI Text Editor with Nano keybindings and softwrap support."
    )

    @Argument(help: "The file to edit.")
    var file: String?

    @Option(name: [.customShort("w"), .long], help: "Specify softwrap column width (e.g. 80). If omitted, softwrap adapts to terminal width.")
    var wrap: Int?

    @Flag(name: [.customShort("r"), .long], help: "Display a classic WordStar-style ruler bar (----!----1----!----2) above the text viewport.")
    var ruler: Bool = false

    @Option(name: [.customLong("syntax")], help: "Enable or disable syntax highlighting (true/false).")
    var syntax: String?

    func run() throws {
        let enableSyntax: Bool?
        if let s = syntax?.lowercased() {
            enableSyntax = (s == "true" || s == "1" || s == "on" || s == "yes")
        } else {
            enableSyntax = nil
        }
        let editor = Editor(filePath: file, wrapColumn: wrap, showRuler: ruler, enableSyntax: enableSyntax)
        editor.run()
    }
}
