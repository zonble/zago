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

        // Editing Commands
        commandRegistry.register(DeleteLineCommand())
        commandRegistry.register(DeleteCharCommand())
        commandRegistry.register(ToggleMarkCommand())
        commandRegistry.register(CutTextCommand())
        commandRegistry.register(UncutTextCommand())
        commandRegistry.register(InsertTabCommand())
        commandRegistry.register(UndoCommand())
        commandRegistry.register(JustifyParagraphCommand())
        commandRegistry.register(SpellCheckCommand())
        commandRegistry.register(EvalLogoCommand())

        // Search & Cursor Commands
        commandRegistry.register(WhereIsCommand())
        commandRegistry.register(GotoLineCommand())
        commandRegistry.register(RefreshScreenCommand())
        commandRegistry.register(ShowCursorPosCommand())

        // Buffer Commands
        commandRegistry.register(PrevBufferCommand())
        commandRegistry.register(NextBufferCommand())
        commandRegistry.register(NewBufferCommand())

        // File Commands
        commandRegistry.register(WriteOutCommand())
        commandRegistry.register(ReadFileCommand())
        commandRegistry.register(SaveAndExitCommand())
        commandRegistry.register(ExitEditorCommand())
        commandRegistry.register(EditConfigCommand())
        commandRegistry.register(ReloadConfigCommand())

        // UI & Macro Commands
        commandRegistry.register(LogoMacroCommand())
        commandRegistry.register(ToggleMenuBarCommand())
        commandRegistry.register(ShowHelpCommand())
        commandRegistry.register(ToggleTableModeCommand())
        commandRegistry.register(CycleTableStyleCommand())
    }
}
