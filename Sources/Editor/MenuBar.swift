import Foundation

public struct MenuItem {
    public let titleKey: String
    public let hotkeyChar: Character
    public let commandId: CommandID?
    public let action: ((Editor) -> Void)?
    public let isChecked: ((Editor) -> Bool)?

    public init(
        titleKey: String,
        hotkeyChar: Character,
        commandId: CommandID? = nil,
        action: ((Editor) -> Void)? = nil,
        isChecked: ((Editor) -> Bool)? = nil
    )
    {
        self.titleKey = titleKey
        self.hotkeyChar = hotkeyChar
        self.commandId = commandId
        self.action = action
        self.isChecked = isChecked
    }
}

public struct MenuCategory {
    public let titleKey: String
    public let hotkeyChar: Character
    public let items: [MenuItem]

    public init(titleKey: String, hotkeyChar: Character, items: [MenuItem]) {
        self.titleKey = titleKey
        self.hotkeyChar = hotkeyChar
        self.items = items
    }
}

/// Menu Bar Data Engine handling menu categories, items, and keyboard navigation.
public final class MenuBar {
    public var categoryIndex: Int = 0
    public var itemIndex: Int = 0

    public var categories: [MenuCategory] = []

    public init() {
        setupCategories()
    }

    public func setupCategories() {
        updateCategories(for: nil)
    }

    public func updateCategories(for editor: Editor? = nil) {
        var baseCategories: [MenuCategory] = [
            MenuCategory(
                titleKey: "menu.file", hotkeyChar: "f",
                items: [
                    MenuItem(titleKey: "menu.file.new", hotkeyChar: "n", commandId: .bufferNew),
                    MenuItem(titleKey: "menu.file.open", hotkeyChar: "o", commandId: .fileInsert),
                    MenuItem(titleKey: "menu.file.save", hotkeyChar: "s", commandId: .fileSave),
                    MenuItem(titleKey: "menu.file.write_out", hotkeyChar: "w", commandId: .fileWriteOut),
                    MenuItem(titleKey: "menu.file.save_exit", hotkeyChar: "e", commandId: .fileSaveExit),
                    MenuItem(titleKey: "menu.file.exit", hotkeyChar: "x", commandId: .fileExit),
                    MenuItem(titleKey: "menu.file.edit_config", hotkeyChar: "c", commandId: .fileEditConfig),
                    MenuItem(titleKey: "menu.file.reload_config", hotkeyChar: "r", commandId: .fileReloadConfig),
                ]),
            MenuCategory(
                titleKey: "menu.edit", hotkeyChar: "e",
                items: [
                    MenuItem(titleKey: "menu.edit.undo", hotkeyChar: "u", commandId: .editUndo),
                    MenuItem(titleKey: "menu.edit.mark", hotkeyChar: "m", commandId: .editMark),
                    MenuItem(titleKey: "menu.edit.cut", hotkeyChar: "c", commandId: .editCut),
                    MenuItem(titleKey: "menu.edit.paste", hotkeyChar: "p", commandId: .editUncut),
                    MenuItem(titleKey: "menu.edit.delete_line", hotkeyChar: "d", commandId: .editDeleteLine),
                    MenuItem(titleKey: "menu.edit.search", hotkeyChar: "s", commandId: .searchWhereIs),
                    MenuItem(titleKey: "menu.edit.goto_line", hotkeyChar: "g", commandId: .cursorGotoLine),
                    MenuItem(titleKey: "menu.edit.spell", hotkeyChar: "t", commandId: .editSpell),
                    MenuItem(titleKey: "menu.edit.justify", hotkeyChar: "j", commandId: .editJustify),
                    MenuItem(titleKey: "menu.edit.text_editing_mode", hotkeyChar: "x", commandId: .textMode, isChecked: { $0.baseMode == .text }),
                    MenuItem(titleKey: "menu.edit.canvas_mode", hotkeyChar: "v", commandId: .canvasToggle, isChecked: { $0.baseMode == .canvas }),
                    MenuItem(titleKey: "menu.edit.table_editing_mode", hotkeyChar: "b", commandId: .tableToggle, isChecked: { $0.isTableModeActive }),
                ]),
            MenuCategory(
                titleKey: "menu.buffer", hotkeyChar: "b",
                items: [
                    MenuItem(titleKey: "menu.buffer.next", hotkeyChar: "n", commandId: .bufferNext),
                    MenuItem(titleKey: "menu.buffer.prev", hotkeyChar: "p", commandId: .bufferPrev),
                ]),
            MenuCategory(
                titleKey: "menu.shapes", hotkeyChar: "s",
                items: [
                    MenuItem(titleKey: "menu.shapes.box", hotkeyChar: "b", action: { $0.runLogoScript("BOX") }),
                    MenuItem(titleKey: "menu.shapes.draw_box", hotkeyChar: "d", action: { $0.runLogoScript("DRAWBOX") }),
                    MenuItem(titleKey: "menu.shapes.line", hotkeyChar: "l", action: { $0.runLogoScript("LINE") }),
                    MenuItem(titleKey: "menu.shapes.vline", hotkeyChar: "v", action: { $0.runLogoScript("VLINE") }),
                    MenuItem(titleKey: "menu.shapes.table", hotkeyChar: "t", action: { $0.promptTableDimensions() }),
                    MenuItem(titleKey: "menu.shapes.frame_mode", hotkeyChar: "r", commandId: .frameToggle, isChecked: { $0.isFrameModeActive }),
                    MenuItem(titleKey: "menu.shapes.fill", hotkeyChar: "f", action: { $0.promptFillText() }),
                ]),
            MenuCategory(
                titleKey: "menu.borders", hotkeyChar: "o",
                items: [
                    MenuItem(
                        titleKey: "menu.borders.single", hotkeyChar: "s",
                        action: { editor in
                            editor.defaultBorderStyle = .single
                            editor.setStatusMessage("[ Default Border: Single ]")
                        },
                        isChecked: { $0.defaultBorderStyle == .single }),
                    MenuItem(
                        titleKey: "menu.borders.double", hotkeyChar: "d",
                        action: { editor in
                            editor.defaultBorderStyle = .double
                            editor.setStatusMessage("[ Default Border: Double ]")
                        },
                        isChecked: { $0.defaultBorderStyle == .double }),
                    MenuItem(
                        titleKey: "menu.borders.round", hotkeyChar: "r",
                        action: { editor in
                            editor.defaultBorderStyle = .round
                            editor.setStatusMessage("[ Default Border: Round ]")
                        },
                        isChecked: { $0.defaultBorderStyle == .round }),
                    MenuItem(
                        titleKey: "menu.borders.double_round", hotkeyChar: "u",
                        action: { editor in
                            editor.defaultBorderStyle = .doubleRound
                            editor.setStatusMessage("[ Default Border: Double Round ]")
                        },
                        isChecked: { $0.defaultBorderStyle == .doubleRound }),
                    MenuItem(
                        titleKey: "menu.borders.ascii", hotkeyChar: "a",
                        action: { editor in
                            editor.defaultBorderStyle = .ascii
                            editor.setStatusMessage("[ Default Border: ASCII ]")
                        },
                        isChecked: { $0.defaultBorderStyle == .ascii }),
                    MenuItem(
                        titleKey: "menu.borders.markdown", hotkeyChar: "m",
                        action: { editor in
                            editor.defaultBorderStyle = .markdown
                            editor.setStatusMessage("[ Default Border: Markdown ]")
                        },
                        isChecked: { $0.defaultBorderStyle == .markdown }),
                    MenuItem(titleKey: "menu.borders.next_style", hotkeyChar: "n", commandId: .borderStyle),
                ]),
            MenuCategory(
                titleKey: "menu.tools", hotkeyChar: "t",
                items: [
                    MenuItem(titleKey: "menu.tools.logo", hotkeyChar: "l", commandId: .macroLogo),
                    MenuItem(titleKey: "menu.tools.eval_logo", hotkeyChar: "q", commandId: .editEvalLogo),
                    MenuItem(
                        titleKey: "menu.tools.line_numbers", hotkeyChar: "n",
                        action: { editor in
                            editor.displayConfig.showLineNumbers.toggle()
                            let state = editor.displayConfig.showLineNumbers ? "shown" : "hidden"
                            editor.setStatusMessage("[ Line Numbers \(state) ]")
                        }),
                    MenuItem(
                        titleKey: "menu.tools.ruler", hotkeyChar: "r",
                        action: { editor in
                            editor.displayConfig.showRuler.toggle()
                        }),
                    MenuItem(
                        titleKey: "menu.tools.wrap_80", hotkeyChar: "8",
                        action: { editor in
                            editor.layoutEngine.wrapColumn = 80
                            editor.setStatusMessage("[ Wrap Column set to 80 ]")
                        }),
                    MenuItem(
                        titleKey: "menu.tools.wrap_60", hotkeyChar: "6",
                        action: { editor in
                            editor.layoutEngine.wrapColumn = 60
                            editor.setStatusMessage("[ Wrap Column set to 60 ]")
                        }),
                    MenuItem(
                        titleKey: "menu.tools.wrap_40", hotkeyChar: "4",
                        action: { editor in
                            editor.layoutEngine.wrapColumn = 40
                            editor.setStatusMessage("[ Wrap Column set to 40 ]")
                        }),
                    MenuItem(
                        titleKey: "menu.tools.wrap_reset", hotkeyChar: "0",
                        action: { editor in
                            editor.layoutEngine.wrapColumn = nil
                            editor.setStatusMessage("[ Wrap Column reset to dynamic ]")
                        }),
                ]),
        ]

        if let ed = editor, DiagramSnippets.shouldShowDiagramMenu(for: ed) {
            baseCategories.append(DiagramSnippets.makeMenuCategory(for: ed))
        }

        baseCategories.append(
            MenuCategory(
                titleKey: "menu.help", hotkeyChar: "h",
                items: [
                    MenuItem(titleKey: "menu.help.show", hotkeyChar: "h", commandId: .helpShow),
                    MenuItem(titleKey: "menu.help.logo_reference", hotkeyChar: "l", commandId: .logoReference),
                    MenuItem(titleKey: "menu.help.logo_workspace", hotkeyChar: "w", commandId: .logoWorkspace),
                ])
        )

        self.categories = baseCategories
        if categoryIndex >= categories.count {
            categoryIndex = max(0, categories.count - 1)
        }
    }

    public var currentCategory: MenuCategory {
        categories[categoryIndex]
    }

    public var currentItem: MenuItem? {
        let items = currentCategory.items
        guard itemIndex >= 0 && itemIndex < items.count else { return nil }
        return items[itemIndex]
    }
}
