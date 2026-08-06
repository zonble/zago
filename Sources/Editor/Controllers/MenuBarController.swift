import Foundation

/// Controller handling Menu Bar UI activation, keyboard navigation, and menu item execution.
public final class MenuBarController: KeyInputHandler {
    /// Whether the menu bar mode is currently active.
    public var isActive: Bool = false

    /// Underlying MenuBar model storing category and item state.
    public let menuBar = MenuBar()

    public init() {}

    /// Toggles Menu Bar mode on ESC key in normal edit mode.
    public func toggle(editor: Editor) {
        isActive.toggle()
        if isActive {
            menuBar.updateCategories(for: editor)
            menuBar.categoryIndex = 0
            menuBar.itemIndex = 0
        }
    }

    /// KeyInputHandler protocol implementation.
    public func handleKey(_ key: Key, editor: Editor) -> Bool {
        guard isActive else { return false }
        processKey(key, editor: editor)
        return true
    }

    /// Handles key input navigation when Menu Bar is active.
    public func processKey(_ key: Key, editor: Editor) {
        switch key {
        case .esc, .ctrl("C"), .ctrl("G"):
            isActive = false

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
            executeCurrentMenuItem(editor: editor)

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
                    executeCurrentMenuItem(editor: editor)
                }
            }

        default:
            break
        }
    }

    /// Executes current selected menu item action.
    public func executeCurrentMenuItem(editor: Editor) {
        guard let item = menuBar.currentItem else { return }
        isActive = false

        if let cmdId = item.commandId {
            _ = editor.commandRegistry.dispatch(id: cmdId, editor: editor)
        } else if let action = item.action {
            action(editor)
        }
    }
}
