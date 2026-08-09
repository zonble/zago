import Foundation

public struct DiagramMenuCommand: Command {
    public let id: CommandID = .diagramMenu
    public let name = "Diagram Snippets Menu"
    public let description = "Open diagram snippet menu"
    public let keys: [Key] = []
    public let commandBarAliases = ["diagram", "diagrams", "snippet", "snippets"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.menuBar.updateCategories(for: editor)
        if let idx = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.diagrams" }) {
            editor.menuBar.categoryIndex = idx
            editor.menuBar.itemIndex = 0
        }
        editor.isMenuBarActive = true
    }
}
