import Foundation

public struct WriteOutCommand: Command {
    public let id: CommandID = .fileSave
    public let name = "WriteOut"
    public let description = "Save file"
    public let keys: [Key] = [.ctrl("O"), .ctrl("S"), .f3]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptWriteFilePath()
    }
}

public struct ReadFileCommand: Command {
    public let id: CommandID = .fileInsert
    public let name = "Read File"
    public let description = "Insert external file"
    public let keys: [Key] = [.ctrl("R"), .f5]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptInsertFilePath()
    }
}

public struct SaveAndExitCommand: Command {
    public let id: CommandID = .fileSaveExit
    public let name = "Save & Exit"
    public let description = "Save file and exit buffer"
    public let keys: [Key] = [.f4]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptSaveAndExit()
    }
}

public struct ExitEditorCommand: Command {
    public let id: CommandID = .fileExit
    public let name = "Exit"
    public let description = "Exit editor or close current buffer"
    public let keys: [Key] = [.ctrl("X"), .f2]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.buffer.isModified {
            editor.promptExitSaveConfirm()
        } else {
            editor.closeCurrentBuffer()
        }
    }
}

public struct EditConfigCommand: Command {
    public let id: CommandID = .fileEditConfig
    public let name = "Edit Config"
    public let description = "Edit ~/.serc configuration file"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        editor.editConfig()
    }
}

public struct ReloadConfigCommand: Command {
    public let id: CommandID = .fileReloadConfig
    public let name = "Reload Config"
    public let description = "Reload ~/.serc configuration file"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        editor.reloadConfig()
    }
}
