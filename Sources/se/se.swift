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

    func run() throws {
        let editor = Editor(filePath: file, wrapColumn: wrap)
        editor.run()
    }
}
