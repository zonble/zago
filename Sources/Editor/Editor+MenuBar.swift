import Foundation

extension Editor {
    /// Toggles Menu Bar mode on ESC key in normal edit mode.
    func toggleMenuBar() {
        isMenuBarActive.toggle()
        if isMenuBarActive {
            menuBar.updateCategories(for: self)
            menuBar.categoryIndex = 0
            menuBar.itemIndex = 0
        }
    }

    /// Handles key input navigation when Menu Bar is active.
    func processMenuBarKey(_ key: Key) {
        switch key {
        case .esc, .ctrl("C"), .ctrl("G"):
            isMenuBarActive = false

        case .arrowLeft:
            menuBar.categoryIndex = (menuBar.categoryIndex - 1 + menuBar.categories.count) % menuBar.categories.count
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .arrowRight:
            menuBar.categoryIndex = (menuBar.categoryIndex + 1) % menuBar.categories.count
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .arrowUp:
            let count = menuBar.currentCategory.items.count
            if count > 0 {
                menuBar.itemIndex = (menuBar.itemIndex - 1 + count) % count
            }

        case .arrowDown:
            let count = menuBar.currentCategory.items.count
            if count > 0 {
                menuBar.itemIndex = (menuBar.itemIndex + 1) % count
            }

        case .home:
            menuBar.itemIndex = 0

        case .end:
            menuBar.itemIndex = max(0, menuBar.currentCategory.items.count - 1)

        case .pageUp:
            menuBar.categoryIndex = 0
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .pageDown:
            menuBar.categoryIndex = max(0, menuBar.categories.count - 1)
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .enter:
            executeCurrentMenuItem()

        case .char(let ch):
            let lowerCh = Character(String(ch).lowercased())
            // Check if letter matches any category hotkey (f, e, s, b, t, h)
            if let catIdx = menuBar.categories.firstIndex(where: { $0.hotkeyChar == lowerCh }) {
                menuBar.categoryIndex = catIdx
                menuBar.itemIndex = 0
            } else {
                // Check if letter matches any item hotkey within active category
                let items = menuBar.currentCategory.items
                if let itemIdx = items.firstIndex(where: { $0.hotkeyChar == lowerCh }) {
                    menuBar.itemIndex = itemIdx
                    executeCurrentMenuItem()
                }
            }

        default:
            break
        }
    }

    /// Executes current selected menu item action.
    func executeCurrentMenuItem() {
        guard let item = menuBar.currentItem else { return }
        isMenuBarActive = false

        if let cmdId = item.commandId {
            _ = commandRegistry.dispatch(id: cmdId, editor: self)
        } else if let action = item.action {
            action(self)
        }
    }
}
