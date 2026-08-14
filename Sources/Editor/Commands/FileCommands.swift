import Foundation

public struct SaveFileCommand: Command {
    public let id: CommandID = .fileSave
    public let name = "Save File"
    public let description = "Save current file"
    public let keys: [Key] = [.ctrl("S"), .ctrl("s")]
    public let commandBarAliases = ["save"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveBuffer(path: nil)
    }
}

public struct WriteOutCommand: Command {
    public let id: CommandID = .fileWriteOut
    public let name = "WriteOut"
    public let description = "Save file to a chosen path"
    public let keys: [Key] = [.ctrl("O"), .ctrl("o"), .f3]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptWriteFilePath()
        return .prompting
    }
}

public struct WriteCommand: Command {
    public let id: CommandID = .fileWriteOut
    public let name = "Write File"
    public let description = "Save file to path or current file"
    public let commandBarAliases: [String] = ["write", "w", ":w"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveBuffer(path: nil)
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        if input.rest.isEmpty {
            return editor.saveBuffer(path: nil)
        } else {
            return editor.writeBuffer(path: input.rest)
        }
    }
}

public struct ReadFileCommand: Command {
    public let id: CommandID = .fileInsert
    public let name = "Read File"
    public let description = "Insert external file"
    public let keys: [Key] = [.ctrl("R"), .f5]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptInsertFilePath()
        return .prompting
    }
}

public struct OpenCommand: Command {
    public let id: CommandID = .fileInsert
    public let name = "Open File"
    public let description = "Open file in a new buffer"
    public let commandBarAliases: [String] = ["open", "edit", "e", ":e"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptInsertFilePath()
        return .prompting
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard !input.rest.isEmpty else {
            let message = editor.l10n["status.path_required"]
            return .failed(message, message: message)
        }

        return editor.openBuffer(path: input.rest)
    }
}

public struct DirectoryBufferCommand: Command {
    public let id: CommandID = .fileDirectory
    public let name = "Directory Buffer"
    public let description = "Open directory buffer"
    public let keys: [Key] = []

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.openDirectoryBuffer(path: nil)
        return .succeeded
    }
}

public struct DirCommand: Command {
    public let id: CommandID = .fileDirectory
    public let name = "Directory"
    public let description = "Open directory browser buffer"
    public let commandBarAliases: [String] = ["dir", "ls"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.openDirectoryBuffer(path: nil)
        return .succeeded
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        editor.openDirectoryBuffer(path: input.rest.isEmpty ? nil : input.rest)
        return .succeeded
    }
}

public struct SaveAndExitCommand: Command {
    public let id: CommandID = .fileSaveExit
    public let name = "Save & Exit"
    public let description = "Save file and exit buffer"
    public let keys: [Key] = [.f4]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptSaveAndExit()
        return .prompting
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

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveAndCloseBuffer(path: nil)
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard let first = input.lowerFirstToken else { return .noOp }
        let targetPath = input.rest.isEmpty ? nil : input.rest

        if first == "x" || first == ":x" {
            if editor.buffer.isModified {
                return editor.saveAndCloseBuffer(path: targetPath)
            } else {
                editor.closeCurrentBuffer()
                return .succeeded
            }
        } else {
            return editor.saveAndCloseBuffer(path: targetPath)
        }
    }
}

public struct ExitEditorCommand: Command {
    public let id: CommandID = .fileExit
    public let name = "Exit"
    public let description = "Exit editor or close current buffer"
    public let keys: [Key] = [.ctrl("X"), .ctrl("x"), .f2]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        if editor.buffer.isModified {
            editor.promptExitSaveConfirm()
            return .prompting
        } else {
            if editor.buffers.count <= 1 {
                editor.isRunning = false
            } else {
                editor.closeCurrentBuffer()
            }
            return .succeeded
        }
    }
}

public struct QuitCommand: Command {
    public let id: CommandID = .fileExit
    public let name = "Quit"
    public let description = "Close buffer or exit editor"
    public let commandBarAliases: [String] = ["close", "exit", "quit", "q", ":q", "q!", ":q!"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        if editor.buffer.isModified {
            editor.promptExitSaveConfirm()
            return .prompting
        } else {
            editor.closeCurrentBuffer()
            return .succeeded
        }
    }

    @discardableResult
    public func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard let first = input.lowerFirstToken else { return .noOp }
        if first == "q!" || first == ":q!" {
            editor.closeCurrentBuffer()
            return .succeeded
        } else {
            return execute(on: editor)
        }
    }
}

public struct EditConfigCommand: Command {
    public let id: CommandID = .fileEditConfig
    public let name = "Edit Config"
    public let description = "Edit ~/.zagorc configuration file"
    public let keys: [Key] = []
    public let commandBarAliases = ["edit-config"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.editConfig()
        return .succeeded
    }
}

public struct ReloadConfigCommand: Command {
    public let id: CommandID = .fileReloadConfig
    public let name = "Reload Config"
    public let description = "Reload ~/.zagorc configuration file"
    public let keys: [Key] = []
    public let commandBarAliases = ["reload-config"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.reloadConfig()
        return .succeeded
    }
}
