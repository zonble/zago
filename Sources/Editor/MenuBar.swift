import Foundation

public struct MenuItem {
    public let titleKey: String
    public let hotkeyChar: Character
    public let commandId: String?
    public let action: ((Editor) -> Void)?

    public init(titleKey: String, hotkeyChar: Character, commandId: String? = nil, action: ((Editor) -> Void)? = nil) {
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
            MenuCategory(titleKey: "menu.file", hotkeyChar: "f", items: [
                MenuItem(titleKey: "menu.file.new", hotkeyChar: "n", commandId: "buffer.new"),
                MenuItem(titleKey: "menu.file.open", hotkeyChar: "o", commandId: "file.insert"),
                MenuItem(titleKey: "menu.file.save", hotkeyChar: "s", commandId: "file.save"),
                MenuItem(titleKey: "menu.file.save_exit", hotkeyChar: "e", commandId: "file.save_exit"),
                MenuItem(titleKey: "menu.file.exit", hotkeyChar: "x", commandId: "file.exit")
            ]),
            MenuCategory(titleKey: "menu.edit", hotkeyChar: "e", items: [
                MenuItem(titleKey: "menu.edit.undo", hotkeyChar: "u", commandId: "edit.undo"),
                MenuItem(titleKey: "menu.edit.mark", hotkeyChar: "m", commandId: "edit.mark"),
                MenuItem(titleKey: "menu.edit.cut", hotkeyChar: "c", commandId: "edit.cut"),
                MenuItem(titleKey: "menu.edit.paste", hotkeyChar: "p", commandId: "edit.uncut"),
                MenuItem(titleKey: "menu.edit.delete_line", hotkeyChar: "d", commandId: "edit.delete_line"),
                MenuItem(titleKey: "menu.edit.justify", hotkeyChar: "j", commandId: "edit.justify")
            ]),
            MenuCategory(titleKey: "menu.search", hotkeyChar: "s", items: [
                MenuItem(titleKey: "menu.search.whereis", hotkeyChar: "w", commandId: "search.whereis"),
                MenuItem(titleKey: "menu.search.spell", hotkeyChar: "t", commandId: "edit.spell"),
                MenuItem(titleKey: "menu.search.goto_line", hotkeyChar: "g", commandId: "cursor.goto_line")
            ]),
            MenuCategory(titleKey: "menu.buffer", hotkeyChar: "b", items: [
                MenuItem(titleKey: "menu.buffer.next", hotkeyChar: "n", commandId: "buffer.next"),
                MenuItem(titleKey: "menu.buffer.prev", hotkeyChar: "p", commandId: "buffer.prev")
            ]),
            MenuCategory(titleKey: "menu.tools", hotkeyChar: "t", items: [
                MenuItem(titleKey: "menu.tools.logo", hotkeyChar: "l", commandId: "macro.logo"),
                MenuItem(titleKey: "menu.tools.ruler", hotkeyChar: "r", action: { editor in
                    editor.displayConfig.showRuler.toggle()
                })
            ]),
            MenuCategory(titleKey: "menu.help", hotkeyChar: "h", items: [
                MenuItem(titleKey: "menu.help.show", hotkeyChar: "h", commandId: "help.show")
            ])
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
