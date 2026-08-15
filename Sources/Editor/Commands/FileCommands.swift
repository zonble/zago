import Foundation

struct SaveFileCommand: Command {
    let id: CommandID = .fileSave
    let name = "Save File"
    let description = "Save current file"
    let commandBarAliases = ["save"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveBuffer(path: nil)
    }
}

struct WriteOutCommand: Command {
    let id: CommandID = .fileWriteOut
    let name = "WriteOut"
    let description = "Save file to a chosen path"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptWriteFilePath()
        return .prompting
    }
}

struct WriteCommand: Command {
    let id: CommandID = .fileWriteOut
    let name = "Write File"
    let description = "Save file to path or current file"
    let commandBarAliases: [String] = ["write", "w", ":w"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveBuffer(path: nil)
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        if input.rest.isEmpty {
            return editor.saveBuffer(path: nil)
        } else {
            return editor.writeBuffer(path: input.rest)
        }
    }
}

struct ReadFileCommand: Command {
    let id: CommandID = .fileInsert
    let name = "Read File"
    let description = "Insert external file"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptInsertFilePath()
        return .prompting
    }
}

struct OpenCommand: Command {
    let id: CommandID = .fileInsert
    let name = "Open File"
    let description = "Open file in a new buffer"
    let commandBarAliases: [String] = ["open", "edit", "e", ":e"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptInsertFilePath()
        return .prompting
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard !input.rest.isEmpty else {
            let message = editor.l10n["status.path_required"]
            return .failed(message, message: message)
        }

        return editor.openBuffer(path: input.rest)
    }
}

struct DirectoryBufferCommand: Command {
    let id: CommandID = .fileDirectory
    let name = "Directory Buffer"
    let description = "Open directory buffer"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.openDirectoryBuffer(path: nil)
        return .succeeded
    }
}

struct DirCommand: Command {
    let id: CommandID = .fileDirectory
    let name = "Directory"
    let description = "Open directory browser buffer"
    let commandBarAliases: [String] = ["dir", "ls"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.openDirectoryBuffer(path: nil)
        return .succeeded
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        editor.openDirectoryBuffer(path: input.rest.isEmpty ? nil : input.rest)
        return .succeeded
    }
}

struct SaveAndExitCommand: Command {
    let id: CommandID = .fileSaveExit
    let name = "Save & Exit"
    let description = "Save file and exit buffer"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptSaveAndExit()
        return .prompting
    }
}

struct SaveExitCommand: Command {
    let id: CommandID = .fileSaveExit
    let name = "Save & Exit"
    let description = "Save current file and close buffer"
    let commandBarAliases: [String] = [
        "file", "save-exit", "saveexit", "wq", ":wq", "wq!", ":wq!", "x", ":x",
    ]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveAndCloseBuffer(path: nil)
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
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

struct ExitEditorCommand: Command {
    let id: CommandID = .fileExit
    let name = "Exit"
    let description = "Exit editor or close current buffer"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct QuitCommand: Command {
    let id: CommandID = .fileExit
    let name = "Quit"
    let description = "Close buffer or exit editor"
    let commandBarAliases: [String] = ["close", "exit", "quit", "q", ":q", "q!", ":q!"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.buffer.isModified {
            editor.promptExitSaveConfirm()
            return .prompting
        } else {
            editor.closeCurrentBuffer()
            return .succeeded
        }
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        guard let first = input.lowerFirstToken else { return .noOp }
        if first == "q!" || first == ":q!" {
            editor.closeCurrentBuffer()
            return .succeeded
        } else {
            return execute(on: editor)
        }
    }
}

struct EditConfigCommand: Command {
    let id: CommandID = .fileEditConfig
    let name = "Edit Config"
    let description = "Edit ~/.zagorc configuration file"
    let commandBarAliases = ["edit-config"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.editConfig()
        return .succeeded
    }
}

struct ReloadConfigCommand: Command {
    let id: CommandID = .fileReloadConfig
    let name = "Reload Config"
    let description = "Reload ~/.zagorc configuration file"
    let commandBarAliases = ["reload-config"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.reloadConfig()
        return .succeeded
    }
}
