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
    public let commandBarAliases = ["help-logo"]

    public init() {}

    public func execute(on editor: Editor) {
        TextDocumentView(
            terminal: editor.terminal,
            title: editor.l10n["logoview.reference_title"],
            lines: LogoReferenceContent.lines(language: editor.language),
            footer: editor.l10n["textview.footer"]
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
    }
}

public struct LogoWorkspaceCommand: Command {
    public let id: CommandID = .logoWorkspace
    public let name = "Editor LOGO Workspace"
    public let description = "Show Editor LOGO user procedures and variables"
    public let keys: [Key] = []
    public let commandBarAliases = ["logo-workspace"]

    public init() {}

    public func execute(on editor: Editor) {
        TextDocumentView(
            terminal: editor.terminal,
            title: editor.l10n["logoview.workspace_title"],
            lines: LogoWorkspaceContent.lines(engine: editor.logoEngine, language: editor.language),
            footer: editor.l10n["textview.footer"]
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
    }
}

public struct ToggleMenuBarCommand: Command {
    public let id: CommandID = .menuShow
    public let name = "Menu Bar"
    public let description = "Show top menu bar"
    public let keys: [Key] = [.f1, .ctrl("M"), .alt("m"), .alt("M")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.menuBarController.toggle()
    }
}

public struct ShowHelpCommand: Command {
    public let id: CommandID = .helpShow
    public let name = "Get Help"
    public let description = "Show full-screen help"
    public let keys: [Key] = []
    public let commandBarAliases = ["help-keys"]

    public init() {}

    public func execute(on editor: Editor) {
        TextDocumentView(
            terminal: editor.terminal,
            title: editor.l10n["helpview.title"],
            lines: HelpContent.lines(language: editor.language),
            footer: editor.l10n["textview.footer"]
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
    }
}

public struct SymbolPickerCommand: Command {
    public let id: CommandID = .symbolPicker
    public let name = "Insert Symbol"
    public let description = "Show modern Markdown symbol picker dialog window"
    public let keys: [Key] = []
    public let commandBarAliases = ["symbol", "symbols", "insert-symbol"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.menuBarController.isActive = false
        SymbolPickerView(
            terminal: editor.terminal,
            editor: editor,
            language: editor.language,
            onSelect: { chosenSymbol in
                editor.saveUndoSnapshot()
                if editor.isTableModeActive {
                    editor.tableModeController.pasteTableCellText(chosenSymbol)
                } else if editor.isCanvasModeActive {
                    editor.insertCanvasString(chosenSymbol)
                } else {
                    editor.buffer.insertString(chosenSymbol)
                }
            }
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
    }
}

