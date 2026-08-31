import Foundation

/// Controller handling Menu Bar UI activation, keyboard navigation, and menu item execution.
final class MenuBarController: KeyInputHandler {
    weak var editor: Editor?

    /// Whether the menu bar mode is currently active.
    var isActive: Bool = false

    /// Underlying MenuBar model storing category and item state.
    let menuBar = MenuBar()

    init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// Toggles Menu Bar mode on ESC key in normal edit mode.
    func toggle() {
        guard let editor else { return }
        isActive.toggle()
        if isActive {
            menuBar.updateCategories(for: editor)
            menuBar.categoryIndex = 0
            menuBar.itemIndex = menuBar.firstSelectableItemIndex(in: menuBar.currentCategory.items)
        }
    }

    /// KeyInputHandler protocol implementation.
    func handleKey(_ key: Key) -> Bool {
        guard isActive else { return false }
        processKey(key)
        return true
    }

    /// Handles key input navigation when Menu Bar is active.
    func processKey(_ key: Key) {
        switch key {
        case .esc, .ctrl("C"), .ctrl("G"):
            isActive = false

        case .arrowLeft:
            menuBar.categoryIndex = (menuBar.categoryIndex - 1 + menuBar.categories.count) % menuBar.categories.count
            menuBar.itemIndex = menuBar.firstSelectableItemIndex(in: menuBar.currentCategory.items)

        case .arrowRight:
            menuBar.categoryIndex = (menuBar.categoryIndex + 1) % menuBar.categories.count
            menuBar.itemIndex = menuBar.firstSelectableItemIndex(in: menuBar.currentCategory.items)

        case .arrowUp:
            let items = menuBar.currentCategory.items
            let count = items.count
            if count > 0 {
                var nextIdx = menuBar.itemIndex
                for _ in 0..<count {
                    nextIdx = (nextIdx - 1 + count) % count
                    if !items[nextIdx].isDivider {
                        menuBar.itemIndex = nextIdx
                        break
                    }
                }
            }

        case .arrowDown:
            let items = menuBar.currentCategory.items
            let count = items.count
            if count > 0 {
                var nextIdx = menuBar.itemIndex
                for _ in 0..<count {
                    nextIdx = (nextIdx + 1) % count
                    if !items[nextIdx].isDivider {
                        menuBar.itemIndex = nextIdx
                        break
                    }
                }
            }

        case .home:
            menuBar.categoryIndex = 0
            menuBar.itemIndex = menuBar.firstSelectableItemIndex(in: menuBar.currentCategory.items)

        case .end:
            menuBar.categoryIndex = max(0, menuBar.categories.count - 1)
            menuBar.itemIndex = menuBar.firstSelectableItemIndex(in: menuBar.currentCategory.items)

        case .pageUp:
            let items = menuBar.currentCategory.items
            if let firstIdx = items.firstIndex(where: { !$0.isDivider }) {
                menuBar.itemIndex = firstIdx
            }

        case .pageDown:
            let items = menuBar.currentCategory.items
            if let lastIdx = items.lastIndex(where: { !$0.isDivider }) {
                menuBar.itemIndex = lastIdx
            }

        case .enter:
            executeCurrentMenuItem()

        case .char(let ch):
            let lowerCh = Character(String(ch).lowercased())
            // Check if letter matches any category hotkey (f, e, s, b, t, h)
            if let catIdx = menuBar.categories.firstIndex(where: { $0.hotkeyChar == lowerCh }) {
                menuBar.categoryIndex = catIdx
                menuBar.itemIndex = menuBar.firstSelectableItemIndex(in: menuBar.currentCategory.items)
            } else {
                // Check if letter matches any item hotkey within active category (skipping dividers)
                let items = menuBar.currentCategory.items
                if let itemIdx = items.firstIndex(where: { !$0.isDivider && $0.hotkeyChar == lowerCh }) {
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
        guard let editor, let item = menuBar.currentItem, !item.isDivider else { return }
        isActive = false

        if let cmdId = item.commandId {
            _ = editor.commandRegistry.dispatch(id: cmdId, editor: editor)
        } else if let action = item.action {
            action(editor)
        }
    }
}
