import Foundation

public struct DiagramMenuCommand: Command {
    public let id: CommandID = .diagramMenu
    public let name = "Diagram Snippets Menu"
    public let description = "Open diagram snippet menu"
    public let commandBarAliases = ["diagram", "diagrams", "snippet", "snippets"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.menuBar.updateCategories(for: editor)
        if let idx = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.diagrams" }) {
            editor.menuBar.categoryIndex = idx
            editor.menuBar.itemIndex = 0
        }
        editor.isMenuBarActive = true
        return .succeeded
    }
}
