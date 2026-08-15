import Foundation

struct DiagramMenuCommand: Command {
    let id: CommandID = .diagramMenu
    let name = "Diagram Snippets Menu"
    let description = "Open diagram snippet menu"
    let commandBarAliases = ["diagram", "diagrams", "snippet", "snippets"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.menuBar.updateCategories(for: editor)
        if let idx = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.diagrams" }) {
            editor.menuBar.categoryIndex = idx
            editor.menuBar.itemIndex = 0
        }
        editor.isMenuBarActive = true
        return .succeeded
    }
}
