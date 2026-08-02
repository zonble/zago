import Foundation

extension Editor {
    /// Registers default editor commands and keybindings using concrete command structs.
    func setupDefaultCommands() {
        // Navigation Commands
        commandRegistry.register(MoveRightCommand())
        commandRegistry.register(MoveLeftCommand())
        commandRegistry.register(MoveUpCommand())
        commandRegistry.register(MoveDownCommand())
        commandRegistry.register(MoveHomeCommand())
        commandRegistry.register(MoveEndCommand())
        commandRegistry.register(MovePgdnCommand())
        commandRegistry.register(MovePgupCommand())

        // Selection Commands
        commandRegistry.register(SelectLeftCommand())
        commandRegistry.register(SelectRightCommand())
        commandRegistry.register(SelectUpCommand())
        commandRegistry.register(SelectDownCommand())
        commandRegistry.register(SelectHomeCommand())
        commandRegistry.register(SelectEndCommand())

        // Editing Commands
        commandRegistry.register(DeleteLineCommand())
        commandRegistry.register(DeleteCharCommand())
        commandRegistry.register(ToggleMarkCommand())
        commandRegistry.register(CopyTextCommand())
        commandRegistry.register(CutTextCommand())
        commandRegistry.register(UncutTextCommand())
        commandRegistry.register(CancelSelectionCommand())
        commandRegistry.register(InsertTabCommand())
        commandRegistry.register(UndoCommand())
        commandRegistry.register(JustifyCommand())
        commandRegistry.register(SpellCheckCommand())
        commandRegistry.register(EvalLogoCommand())

        // Search & Cursor Commands
        commandRegistry.register(WhereIsCommand())
        commandRegistry.register(SearchNextCommand())
        commandRegistry.register(SearchPreviousCommand())
        commandRegistry.register(OpenDocumentLinkCommand())
        commandRegistry.register(GotoLineCommand())
        commandRegistry.register(RefreshScreenCommand())
        commandRegistry.register(ShowCursorPosCommand())

        // Buffer Commands
        commandRegistry.register(PrevBufferCommand())
        commandRegistry.register(NextBufferCommand())
        commandRegistry.register(NewBufferCommand())

        // File Commands
        commandRegistry.register(SaveFileCommand())
        commandRegistry.register(WriteOutCommand())
        commandRegistry.register(ReadFileCommand())
        commandRegistry.register(DirectoryBufferCommand())
        commandRegistry.register(SaveAndExitCommand())
        commandRegistry.register(ExitEditorCommand())
        commandRegistry.register(EditConfigCommand())
        commandRegistry.register(ReloadConfigCommand())

        // CommandBar Specialized Commands
        commandRegistry.register(QuitCommand())
        commandRegistry.register(SaveExitCommand())
        commandRegistry.register(OpenCommand())
        commandRegistry.register(DirCommand())
        commandRegistry.register(WriteCommand())
        commandRegistry.register(SettingCommand())
        commandRegistry.register(BufferCommand())
        commandRegistry.register(NumericGotoCommand())
        commandRegistry.register(SearchCommand())
        commandRegistry.register(SubstituteCommand())

        // UI & Macro Commands
        commandRegistry.register(LogoMacroCommand())
        commandRegistry.register(LogoReferenceCommand())
        commandRegistry.register(LogoWorkspaceCommand())
        commandRegistry.register(ToggleMenuBarCommand())
        commandRegistry.register(ShowHelpCommand())
        commandRegistry.register(SwitchTextModeCommand())
        commandRegistry.register(ToggleCanvasModeCommand())
        commandRegistry.register(ToggleTableModeCommand())
        commandRegistry.register(CycleBorderStyleCommand())
        commandRegistry.register(
            BlockCommand(
                id: .diagramMenu,
                name: "diagram.menu",
                description: "Open diagram snippet menu",
                keys: []
            ) { editor in
                editor.menuBar.updateCategories(for: editor)
                if let idx = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.diagrams" }) {
                    editor.menuBar.categoryIndex = idx
                    editor.menuBar.itemIndex = 0
                }
                editor.isMenuBarActive = true
            }
        )
    }
}
