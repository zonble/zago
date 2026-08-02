import Foundation
import LogoEngine

public struct LogoMacroCommand: Command {
    public let id: CommandID = .macroLogo
    public let name = "Command"
    public let description = "Run an editor command"
    public let keys: [Key] = [.esc, .alt(":")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptLogoMacro()
    }
}

public struct LogoReferenceCommand: Command {
    public let id: CommandID = .logoReference
    public let name = "Editor LOGO Reference"
    public let description = "Show Editor LOGO command reference"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        TextDocumentView(
            terminal: editor.terminal,
            title: L10n["logoview.reference_title"],
            lines: LogoReferenceContent.lines(),
            footer: L10n["textview.footer"]
        ).show()
    }
}

public struct LogoWorkspaceCommand: Command {
    public let id: CommandID = .logoWorkspace
    public let name = "Editor LOGO Workspace"
    public let description = "Show Editor LOGO user procedures and variables"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        TextDocumentView(
            terminal: editor.terminal,
            title: L10n["logoview.workspace_title"],
            lines: LogoWorkspaceContent.lines(engine: editor.logoEngine),
            footer: L10n["textview.footer"]
        ).show()
    }
}

public struct ToggleMenuBarCommand: Command {
    public let id: CommandID = .menuShow
    public let name = "Menu Bar"
    public let description = "Show top menu bar"
    public let keys: [Key] = [.f1, .ctrl("M"), .alt("m"), .alt("M")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.toggleMenuBar()
    }
}

public struct ShowHelpCommand: Command {
    public let id: CommandID = .helpShow
    public let name = "Get Help"
    public let description = "Show full-screen help"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        TextDocumentView(
            terminal: editor.terminal,
            title: L10n["helpview.title"],
            lines: HelpContent.lines(),
            footer: L10n["textview.footer"]
        ).show()
    }
}
