import Foundation

public struct LogoMacroCommand: Command {
    public let id: CommandID = .macroLogo
    public let name = "LOGO Macro"
    public let description = "Execute LOGO macro script"
    public let keys: [Key] = [.alt("l"), .alt("L"), .alt(":"), .char("¬"), .char("Ò"), .char("…"), .f8]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptLogoMacro()
    }
}

public struct ToggleMenuBarCommand: Command {
    public let id: CommandID = .menuShow
    public let name = "Menu Bar"
    public let description = "Show top menu bar"
    public let keys: [Key] = [.f1, .ctrl("M"), .alt("m"), .alt("M")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.toggleMenuBar()
    }
}

public struct ShowHelpCommand: Command {
    public let id: CommandID = .helpShow
    public let name = "Get Help"
    public let description = "Show full-screen help"
    public let keys: [Key] = [.ctrl("G")]

    public init() {}

    public func execute(on editor: Editor) {
        let helpView = HelpView(terminal: editor.terminal)
        helpView.show()
    }
}
