import Foundation
import LogoEngine

struct LogoMacroCommand: Command {
    let id: CommandID = .macroLogo
    let name = "Command"
    let description = "Run an editor command"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptLogoMacro()
        return .prompting
    }
}

struct LogoReferenceCommand: Command {
    let id: CommandID = .logoReference
    let name = "Editor LOGO Reference"
    let description = "Show Editor LOGO command reference"
    let commandBarAliases = ["help-logo"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        TextDocumentView(
            terminal: editor.terminal,
            title: editor.l10n["logoview.reference_title"],
            lines: LogoReferenceContent.lines(language: editor.language),
            footer: editor.l10n["textview.footer"]
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
        return .succeeded
    }
}

struct LogoWorkspaceCommand: Command {
    let id: CommandID = .logoWorkspace
    let name = "Editor LOGO Workspace"
    let description = "Show Editor LOGO user procedures and variables"
    let commandBarAliases = ["logo-workspace"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        TextDocumentView(
            terminal: editor.terminal,
            title: editor.l10n["logoview.workspace_title"],
            lines: LogoWorkspaceContent.lines(engine: editor.logoEngine, language: editor.language),
            footer: editor.l10n["textview.footer"]
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
        return .succeeded
    }
}

struct ToggleMenuBarCommand: Command {
    let id: CommandID = .menuShow
    let name = "Menu Bar"
    let description = "Show top menu bar"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.menuBarController.toggle()
        return .succeeded
    }
}

struct ShowHelpCommand: Command {
    let id: CommandID = .helpShow
    let name = "Get Help"
    let description = "Show full-screen help"
    let commandBarAliases = ["help-keys"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        TextDocumentView(
            terminal: editor.terminal,
            title: editor.l10n["helpview.title"],
            lines: HelpContent.lines(editor: editor),
            footer: editor.l10n["textview.footer"]
        ).show()
        editor.renderer.invalidateScreenCache()
        editor.refreshScreen()
        return .succeeded
    }
}

struct SymbolPickerCommand: Command {
    let id: CommandID = .symbolPicker
    let name = "Insert Symbol"
    let description = "Show modern Markdown symbol picker dialog window"
    let commandBarAliases = ["symbol", "symbols", "insert-symbol"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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
        return .succeeded
    }
}
