import Foundation

extension Editor {
    /// Toggles Menu Bar mode on ESC key in normal edit mode.
    func toggleMenuBar() {
        menuBarController.toggle(editor: self)
    }

    /// Handles key input navigation when Menu Bar is active.
    func processMenuBarKey(_ key: Key) {
        menuBarController.processKey(key, editor: self)
    }

    /// Executes current selected menu item action.
    func executeCurrentMenuItem() {
        menuBarController.executeCurrentMenuItem(editor: self)
    }
}
