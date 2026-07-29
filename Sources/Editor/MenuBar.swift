import Foundation

public struct MenuItem {
    public let titleKey: String
    public let hotkeyChar: Character
    public let commandId: CommandID?
    public let action: ((Editor) -> Void)?

    public init(titleKey: String, hotkeyChar: Character, commandId: CommandID? = nil, action: ((Editor) -> Void)? = nil)
    {
        self.titleKey = titleKey
        self.hotkeyChar = hotkeyChar
        self.commandId = commandId
        self.action = action
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
        categories = [
            MenuCategory(
                titleKey: "menu.file", hotkeyChar: "f",
                items: [
                    MenuItem(titleKey: "menu.file.new", hotkeyChar: "n", commandId: .bufferNew),
                    MenuItem(titleKey: "menu.file.open", hotkeyChar: "o", commandId: .fileInsert),
                    MenuItem(titleKey: "menu.file.save", hotkeyChar: "s", commandId: .fileSave),
                    MenuItem(titleKey: "menu.file.save_exit", hotkeyChar: "e", commandId: .fileSaveExit),
                    MenuItem(titleKey: "menu.file.exit", hotkeyChar: "x", commandId: .fileExit),
                ]),
            MenuCategory(
                titleKey: "menu.edit", hotkeyChar: "e",
                items: [
                    MenuItem(titleKey: "menu.edit.undo", hotkeyChar: "u", commandId: .editUndo),
                    MenuItem(titleKey: "menu.edit.mark", hotkeyChar: "m", commandId: .editMark),
                    MenuItem(titleKey: "menu.edit.cut", hotkeyChar: "c", commandId: .editCut),
                    MenuItem(titleKey: "menu.edit.paste", hotkeyChar: "p", commandId: .editUncut),
                    MenuItem(titleKey: "menu.edit.delete_line", hotkeyChar: "d", commandId: .editDeleteLine),
                    MenuItem(titleKey: "menu.edit.justify", hotkeyChar: "j", commandId: .editJustify),
                ]),
            MenuCategory(
                titleKey: "menu.search", hotkeyChar: "s",
                items: [
                    MenuItem(titleKey: "menu.search.whereis", hotkeyChar: "w", commandId: .searchWhereIs),
                    MenuItem(titleKey: "menu.search.spell", hotkeyChar: "t", commandId: .editSpell),
                    MenuItem(titleKey: "menu.search.goto_line", hotkeyChar: "g", commandId: .cursorGotoLine),
                ]),
            MenuCategory(
                titleKey: "menu.buffer", hotkeyChar: "b",
                items: [
                    MenuItem(titleKey: "menu.buffer.next", hotkeyChar: "n", commandId: .bufferNext),
                    MenuItem(titleKey: "menu.buffer.prev", hotkeyChar: "p", commandId: .bufferPrev),
                ]),
            MenuCategory(
                titleKey: "menu.tools", hotkeyChar: "t",
                items: [
                    MenuItem(titleKey: "menu.tools.logo", hotkeyChar: "l", commandId: .macroLogo),
                    MenuItem(titleKey: "menu.tools.eval_logo", hotkeyChar: "q", commandId: .editEvalLogo),
                    MenuItem(titleKey: "menu.tools.table_mode", hotkeyChar: "t", commandId: .tableToggle),
                    MenuItem(
                        titleKey: "menu.tools.line_numbers", hotkeyChar: "n",
                        action: { editor in
                            editor.displayConfig.showLineNumbers.toggle()
                            let state = editor.displayConfig.showLineNumbers ? "shown" : "hidden"
                            editor.setStatusMessage("[ Line Numbers \(state) ]")
                        }),
                    MenuItem(titleKey: "menu.tools.table_style", hotkeyChar: "s", commandId: .tableStyle),
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
            MenuCategory(
                titleKey: "menu.help", hotkeyChar: "h",
                items: [
                    MenuItem(titleKey: "menu.help.show", hotkeyChar: "h", commandId: .helpShow)
                ]),
        ]
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
