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
        commandRegistry.register(MoveWordForwardCommand())
        commandRegistry.register(MoveWordBackwardCommand())

        // Selection Commands
        commandRegistry.register(SelectAllCommand())
        commandRegistry.register(SelectLeftCommand())
        commandRegistry.register(SelectRightCommand())
        commandRegistry.register(SelectUpCommand())
        commandRegistry.register(SelectDownCommand())
        commandRegistry.register(SelectHomeCommand())
        commandRegistry.register(SelectEndCommand())
        commandRegistry.register(SelectPgupCommand())
        commandRegistry.register(SelectPgdnCommand())

        // Editing Commands
        commandRegistry.register(DeleteLineCommand())
        commandRegistry.register(DeleteCharCommand())
        commandRegistry.register(ToggleMarkCommand())
        commandRegistry.register(CopyTextCommand())
        commandRegistry.register(CutTextCommand())
        commandRegistry.register(UncutTextCommand())
        commandRegistry.register(CancelSelectionCommand())
        commandRegistry.register(InsertTabCommand())
        commandRegistry.register(InsertBacktabCommand())
        commandRegistry.register(UndoCommand())
        commandRegistry.register(RedoCommand())
        commandRegistry.register(JustifyCommand())
        commandRegistry.register(SpellCheckCommand())
        commandRegistry.register(EvalLogoCommand())
        commandRegistry.register(ToggleCommentCommand())
        commandRegistry.register(JoinLineCommand())
        commandRegistry.register(SplitLineCommand())

        // Search & Cursor Commands
        commandRegistry.register(SearchCommand())
        commandRegistry.register(SearchReplaceCommand())
        commandRegistry.register(SearchNextCommand())
        commandRegistry.register(SearchPreviousCommand())
        commandRegistry.register(OpenDocumentLinkCommand())
        commandRegistry.register(NextHeadingCommand())
        commandRegistry.register(PreviousHeadingCommand())
        commandRegistry.register(DocumentOutlineCommand())
        commandRegistry.register(GotoLineCommand())
        commandRegistry.register(GoToEndOfFileCommand())
        commandRegistry.register(RefreshScreenCommand())
        commandRegistry.register(ShowCursorPosCommand())

        // Buffer Commands
        commandRegistry.register(PrevBufferCommand())
        commandRegistry.register(NextBufferCommand())
        commandRegistry.register(NewBufferCommand())

        // File Commands
        commandRegistry.register(OpenCommand())
        commandRegistry.register(SaveFileCommand())
        commandRegistry.register(WriteOutCommand())
        commandRegistry.register(ReadFileCommand())
        commandRegistry.register(DirectoryBufferCommand())
        commandRegistry.register(SaveAndExitCommand())
        commandRegistry.register(ExitEditorCommand())
        commandRegistry.register(EditConfigCommand())
        commandRegistry.register(ReloadConfigCommand())
        commandRegistry.register(OpenJournalCommand())
        commandRegistry.register(OpenJournalDirectoryCommand())
        commandRegistry.register(SortDirCommand())

        // Table Mode Commands
        commandRegistry.register(TableNextCellCommand())
        commandRegistry.register(TablePrevCellCommand())
        commandRegistry.register(TableAdjustWidthIncCommand())
        commandRegistry.register(TableAdjustWidthDecCommand())
        commandRegistry.register(TableAdjustHeightIncCommand())
        commandRegistry.register(TableAdjustHeightDecCommand())
        commandRegistry.register(TableCenterTextCommand())
        commandRegistry.register(TableCellStartCommand())
        commandRegistry.register(TableCellEndCommand())
        commandRegistry.register(TableClearCellCommand())

        // CommandBar Specialized Commands
        commandRegistry.register(QuitCommand())
        commandRegistry.register(SaveExitCommand())
        commandRegistry.register(DirCommand())
        commandRegistry.register(WriteCommand())
        commandRegistry.register(SettingCommand())
        commandRegistry.register(BufferCommand())
        commandRegistry.register(NumericGotoCommand())
        commandRegistry.register(SlashSearchCommand())
        commandRegistry.register(SubstituteCommand())

        // UI & Macro Commands
        commandRegistry.register(LogoMacroCommand())
        commandRegistry.register(LogoReferenceCommand())
        commandRegistry.register(StyleDSLReferenceCommand())
        commandRegistry.register(LogoWorkspaceCommand())
        commandRegistry.register(LogoOutputCommand())
        commandRegistry.register(ClearLogoOutputCommand())
        commandRegistry.register(RunLogoScriptCommand())
        commandRegistry.register(LogoCanvasCommand())
        commandRegistry.register(LogoDebugCommand())
        commandRegistry.register(ClearLogoOutputAndCanvasCommand())
        commandRegistry.register(ToggleMenuBarCommand())
        commandRegistry.register(ShowHelpCommand())
        commandRegistry.register(DescribeKeyCommand())
        commandRegistry.register(DescribeCommandCommand())
        commandRegistry.register(SymbolPickerCommand())
        commandRegistry.register(SwitchTextModeCommand())
        commandRegistry.register(ToggleCanvasModeCommand())
        commandRegistry.register(ToggleTableModeCommand())
        commandRegistry.register(ToggleZeroModeCommand())
        commandRegistry.register(ToggleIndicatorCommand())
        commandRegistry.register(CycleBorderStyleCommand())
        commandRegistry.register(DiagramMenuCommand())
        commandRegistry.register(ToggleCommentCommand())

        // TMD Commands
        commandRegistry.register(TMDExportMIDICommand())
        commandRegistry.register(TMDExportMusicXMLCommand())
        commandRegistry.register(TMDExportLilyPondCommand())
        commandRegistry.register(TMDExportABCCommand())
        commandRegistry.register(TMDExportWAVCommand())
        commandRegistry.register(TMDReferenceCommand())

        // AI Proposal Commands
        commandRegistry.register(AcceptProposalCommand())
        commandRegistry.register(RejectProposalCommand())
        commandRegistry.register(NextProposalCommand())
        commandRegistry.register(PreviousProposalCommand())
        commandRegistry.register(MockAISuggestionCommand())
    }
}
