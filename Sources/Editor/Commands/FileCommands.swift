import Foundation

public struct SaveFileCommand: Command {
    public let id: CommandID = .fileSave
    public let name = "Save File"
    public let description = "Save current file"
    public let keys: [Key] = [.ctrl("S"), .ctrl("s")]
    public let commandBarAliases = ["save"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveBuffer(path: nil)
    }
}

public struct WriteOutCommand: Command {
    public let id: CommandID = .fileWriteOut
    public let name = "WriteOut"
    public let description = "Save file to a chosen path"
    public let keys: [Key] = [.ctrl("O"), .ctrl("o"), .f3]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptWriteFilePath()
    }
}

public struct WriteCommand: Command {
    public let id: CommandID = .fileWriteOut
    public let name = "Write File"
    public let description = "Save file to path or current file"
    public let commandBarAliases: [String] = ["write", "w", ":w"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveBuffer(path: nil)
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        if input.rest.isEmpty {
            editor.saveBuffer(path: nil)
        } else {
            editor.writeBuffer(path: input.rest)
        }
        return .handled
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

public struct OpenCommand: Command {
    public let id: CommandID = .fileInsert
    public let name = "Open File"
    public let description = "Open file in a new buffer"
    public let commandBarAliases: [String] = ["open", "edit", "e", ":e"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptInsertFilePath()
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        guard !input.rest.isEmpty else {
            editor.setStatusMessage(editor.l10n["status.path_required"])
            return .handled
        }

        editor.openBuffer(path: input.rest)
        return .handled
    }
}

public struct DirectoryBufferCommand: Command {
    public let id: CommandID = .fileDirectory
    public let name = "Directory Buffer"
    public let description = "Open directory buffer"
    public let keys: [Key] = []

    public init() {}

    public func execute(on editor: Editor) {
        editor.openDirectoryBuffer(path: nil)
    }
}

public struct DirCommand: Command {
    public let id: CommandID = .fileDirectory
    public let name = "Directory"
    public let description = "Open directory browser buffer"
    public let commandBarAliases: [String] = ["dir", "ls"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.openDirectoryBuffer(path: nil)
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        editor.openDirectoryBuffer(path: input.rest.isEmpty ? nil : input.rest)
        return .handled
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

public struct SaveExitCommand: Command {
    public let id: CommandID = .fileSaveExit
    public let name = "Save & Exit"
    public let description = "Save current file and close buffer"
    public let commandBarAliases: [String] = [
        "file", "save-exit", "saveexit", "wq", ":wq", "wq!", ":wq!", "x", ":x",
    ]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveAndCloseBuffer(path: nil)
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        guard let first = input.lowerFirstToken else { return .noMatch }
        let targetPath = input.rest.isEmpty ? nil : input.rest

        if first == "x" || first == ":x" {
            if editor.buffer.isModified {
                editor.saveAndCloseBuffer(path: targetPath)
            } else {
                editor.closeCurrentBuffer()
            }
        } else {
            editor.saveAndCloseBuffer(path: targetPath)
        }
        return .handled
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

public struct QuitCommand: Command {
    public let id: CommandID = .fileExit
    public let name = "Quit"
    public let description = "Close buffer or exit editor"
    public let commandBarAliases: [String] = ["close", "exit", "quit", "q", ":q", "q!", ":q!"]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.buffer.isModified {
            editor.promptExitSaveConfirm()
        } else {
            editor.closeCurrentBuffer()
        }
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        guard let first = input.lowerFirstToken else { return .noMatch }
        if first == "q!" || first == ":q!" {
            editor.closeCurrentBuffer()
        } else {
            execute(on: editor)
        }
        return .handled
    }
}

public struct EditConfigCommand: Command {
    public let id: CommandID = .fileEditConfig
    public let name = "Edit Config"
    public let description = "Edit ~/.zagorc configuration file"
    public let keys: [Key] = []
    public let commandBarAliases = ["edit-config"]

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
    public let commandBarAliases = ["reload-config"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.reloadConfig()
    }
}
