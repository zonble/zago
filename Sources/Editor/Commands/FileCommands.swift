import Foundation

public struct SaveFileCommand: Command {
    public let id: CommandID = .fileSave
    public let name = "Save File"
    public let description = "Save current file"
    public let keys: [Key] = [.ctrl("S")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveBuffer(path: nil)
    }
}

public struct WriteOutCommand: Command {
    public let id: CommandID = .fileWriteOut
    public let name = "WriteOut"
    public let description = "Save file to a chosen path"
    public let keys: [Key] = [.ctrl("O"), .f3]

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
    public let description = "Edit ~/.zagorc configuration file"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        editor.editConfig()
    }
}

public struct ReloadConfigCommand: Command {
    public let id: CommandID = .fileReloadConfig
    public let name = "Reload Config"
    public let description = "Reload ~/.zagorc configuration file"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        editor.reloadConfig()
    }
}
