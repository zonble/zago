import Testing
import Foundation
@testable import Config
@testable import Editor

@Suite struct KeymapSystemTests {

    @Test func testLayeredKeymapResolution() throws {
        let keymap = KeymapManager(preset: .classic)

        // In text mode, Tab is editTab
        #expect(keymap.resolve(key: .tab, in: .text) == .editTab)

        // In table mode, Tab is tableNextCell (overlay override)
        #expect(keymap.resolve(key: .tab, in: .table) == .tableNextCell)

        // In table mode, Shift+Tab is tablePrevCell
        #expect(keymap.resolve(key: .backtab, in: .table) == .tablePrevCell)

        // ArrowUp is moveUp in both text and table (fallback to base)
        #expect(keymap.resolve(key: .arrowUp, in: .text) == .moveUp)
        #expect(keymap.resolve(key: .arrowUp, in: .table) == .moveUp)
    }

    @Test func testClassicVsModernPresetResolution() throws {
        let keymap = KeymapManager(preset: .classic)

        // Classic: ^A is moveHome, ^W is searchWhereIs, ^O is fileWriteOut, ^X is fileExit, ^V is movePgdn, ^Y is movePgup
        #expect(keymap.resolve(key: .ctrl("a"), in: .text) == .moveHome)
        #expect(keymap.resolve(key: .ctrl("w"), in: .text) == .searchWhereIs)
        #expect(keymap.resolve(key: .ctrl("o"), in: .text) == .fileWriteOut)
        #expect(keymap.resolve(key: .ctrl("x"), in: .text) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("v"), in: .text) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("y"), in: .text) == .movePgup)
        #expect(keymap.resolve(key: .ctrl("v"), in: .canvas) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("y"), in: .canvas) == .movePgup)

        // Switch to Modern
        keymap.loadPreset(.modern)

        // Modern: ^A is selectAll, ^F is searchWhereIs, ^H is searchReplace, ^Q is fileExit, ^C is copy, ^X is cut, ^V is uncut
        #expect(keymap.resolve(key: .ctrl("a"), in: .text) == .selectAll)
        #expect(keymap.resolve(key: .ctrl("f"), in: .text) == .searchWhereIs)
        #expect(keymap.resolve(key: .ctrl("h"), in: .text) == .searchReplace)
        #expect(keymap.resolve(key: .ctrl("q"), in: .text) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("c"), in: .text) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("x"), in: .text) == .editCut)
        #expect(keymap.resolve(key: .ctrl("v"), in: .text) == .editUncut)
        #expect(keymap.resolve(key: .ctrl("c"), in: .canvas) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("x"), in: .canvas) == .editCut)
        #expect(keymap.resolve(key: .ctrl("v"), in: .canvas) == .editUncut)
    }

    @Test func testDynamicHelpBarReflection() throws {
        let editor = Editor(language: .en)
        let renderer = Renderer()

        // Default Classic Help Bar
        let classicHelp = renderer.renderHelpBar(cols: 80, promptMode: .none, editor: editor)
        #expect(classicHelp.contains("^O"))
        #expect(classicHelp.contains("^W"))
        #expect(classicHelp.contains("^X"))

        // Switch to Modern Preset via SettingUpdate
        editor.apply(.keymap(.modern))

        let modernHelp = renderer.renderHelpBar(cols: 100, promptMode: .none, editor: editor)
        #expect(modernHelp.contains("^S"))
        #expect(modernHelp.contains("^Q"))
        #expect(modernHelp.contains("^X"))
        #expect(modernHelp.contains("^C"))
        #expect(modernHelp.contains("^V"))
        #expect(modernHelp.contains("^F"))
        #expect(modernHelp.contains("^H"))
        #expect(modernHelp.contains("^A"))
        #expect(modernHelp.contains("PgUp"))
        #expect(modernHelp.contains("PgDn"))
    }

    @Test func testCustomBindingAndModeSpecificOverrides() throws {
        let keymap = KeymapManager(preset: .classic)

        // Custom global bind: map F4 to fileSave
        keymap.bind(key: .f4, commandID: .fileSave)
        #expect(keymap.resolve(key: .f4, in: .text) == .fileSave)
        #expect(keymap.resolve(key: .f4, in: .table) == .fileSave)

        // Mode-specific bind: map F4 to tableCenterText only in table mode
        keymap.bind(key: .f4, commandID: .tableCenterText, mode: .table)
        #expect(keymap.resolve(key: .f4, in: .text) == .fileSave)
        #expect(keymap.resolve(key: .f4, in: .table) == .tableCenterText)

        // Unbind in table mode restores base fallback
        keymap.unbind(key: .f4, mode: .table)
        #expect(keymap.resolve(key: .f4, in: .table) == .fileSave)
    }

    @Test func testConfigLoaderKeymapDirectives() throws {
        let configPath = "/home/user/.zagorc"
        let provider = InMemoryConfigFileProvider(
            homePath: "/home/user",
            currentPath: "/home/user",
            files: [
                configPath: """
                set keymap modern
                bind ctrl-f search.whereis
                bind f4 file.save
                bind tab table.next_cell table
                """
            ]
        )
        let loader = ConfigLoader(provider: provider)
        var config = EditorConfig()
        loader.parseConfigFile(at: configPath, into: &config)

        #expect(config.keymapPreset == "modern")
        #expect(config.customKeyBinds[.ctrl("f")] == "search.whereis")
        #expect(config.customKeyBinds[.f4] == "file.save")
        #expect(config.customModeKeyBinds["table"]?[.tab] == "table.next_cell")
    }

    @Test func testModernbindingsBooleanDirective() throws {
        let configPath = "/home/user/.zagorc"
        let provider = InMemoryConfigFileProvider(
            homePath: "/home/user",
            currentPath: "/home/user",
            files: [
                configPath: "set modernbindings on"
            ]
        )
        let loader = ConfigLoader(provider: provider)
        var config = EditorConfig()
        loader.parseConfigFile(at: configPath, into: &config)

        #expect(config.keymapPreset == "modern")

        let configOff = "set modernbindings off"
        let provider2 = InMemoryConfigFileProvider(
            homePath: "/home/user",
            currentPath: "/home/user",
            files: [
                configPath: configOff
            ]
        )
        let loader2 = ConfigLoader(provider: provider2)
        var config2 = EditorConfig()
        loader2.parseConfigFile(at: configPath, into: &config2)

        #expect(config2.keymapPreset == "classic")
    }

    @Test func testEditorOptionsKeymapPresetOverride() throws {
        var config = EditorConfig()
        config.keymapPreset = "modern"
        let configSource = EditorConfigSource(initial: config, reload: { config })
        let options = EditorOptions(language: .en, keymapPreset: .classic)

        let editor = Editor(
            options: options,
            configSource: configSource,
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )

        #expect(editor.keymapManager.activePreset == .classic)
        #expect(editor.keymapManager.resolve(key: .ctrl("a"), in: .text) == .moveHome)
    }

    @Test func testModernKeyDispatchActualExecution() throws {
        let editor = Editor(language: .en)
        editor.buffer.lines = ["Hello World"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0

        // In classic mode:
        // ^A moves cursor to home
        editor.buffer.columnIndex = 5
        editor.processKey(.ctrl("a"))
        #expect(editor.buffer.columnIndex == 0)
        #expect(editor.buffer.selectionMark == nil)

        // Switch to Modern preset
        editor.apply(.keymap(.modern))

        // In modern mode:
        // 1. ^A selects all text
        editor.processKey(.ctrl("a"))
        #expect(editor.buffer.selectionMark != nil)
        #expect(editor.hasActiveTextSelection())

        // 2. ^C copies selected text
        editor.processKey(.ctrl("c"))
        #expect(editor.clipboardText == "Hello World")

        // 3. ^X cuts selected text
        editor.processKey(.ctrl("x"))
        #expect(editor.buffer.lines == [""])
        #expect(editor.clipboardText == "Hello World")

        // 4. ^V pastes text
        editor.processKey(.ctrl("v"))
        #expect(editor.buffer.lines == ["Hello World"])

        // 5. ^Z undoes paste
        editor.processKey(.ctrl("z"))
        #expect(editor.buffer.lines == [""])

        // 6. ^Y redoes paste
        editor.processKey(.ctrl("y"))
        #expect(editor.buffer.lines == ["Hello World"])

        // 7. ^F opens search prompt
        editor.processKey(.ctrl("f"))
        guard case .search = editor.currentPromptMode else {
            Issue.record("Expected search prompt mode on ^F in modern preset")
            return
        }
        editor.currentPromptMode = .none

        // 8. ^E evaluates LOGO code
        editor.buffer.lines = ["SUM 1 6"]
        editor.buffer.lineIndex = 0
        editor.processKey(.ctrl("e"))
        #expect(editor.statusMessage == "[Eval] 7")

        // 9. ^T and F12 trigger spell check
        #expect(editor.keymapManager.resolve(key: .ctrl("t"), in: .text) == .editSpell)
        #expect(editor.keymapManager.resolve(key: .f12, in: .text) == .editSpell)

        // 10. F11 and Alt+C trigger cursorPos
        #expect(editor.keymapManager.resolve(key: .f11, in: .text) == .cursorPos)
        #expect(editor.keymapManager.resolve(key: .alt("c"), in: .text) == .cursorPos)

        // 11. ^Q initiates exit
        editor.buffer.isModified = false
        editor.processKey(.ctrl("q"))
        #expect(editor.isRunning == false)
    }

    @Test func testMenuDropdownDynamicShortcuts() throws {
        let editor = Editor(language: .en)
        let renderer = Renderer()

        // Open menu bar in Classic mode
        editor.menuBarController.isActive = true
        editor.menuBar.categoryIndex = 0 // File Menu
        editor.menuBar.setupCategories()

        let (_, _, classicFileLines) = renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let classicFileStr = classicFileLines.joined(separator: "\n")
        #expect(classicFileStr.contains("^X"))
        #expect(!classicFileStr.contains("^Q"))

        // Tools Menu in Classic mode: Eval LOGO is ^Q
        editor.menuBar.updateCategories(for: editor)
        if let toolsIdx = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.tools" }) {
            editor.menuBar.categoryIndex = toolsIdx
        }
        let (_, _, classicToolsLines) = renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let classicToolsStr = classicToolsLines.joined(separator: "\n")
        #expect(classicToolsStr.contains("^Q"))

        // Switch to Modern mode
        editor.apply(.keymap(.modern))
        editor.menuBar.updateCategories(for: editor)

        editor.menuBar.categoryIndex = 0 // File Menu
        let (_, _, modernFileLines) = renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let modernFileStr = modernFileLines.joined(separator: "\n")
        #expect(modernFileStr.contains("^Q"))

        // Check Edit menu in Modern mode
        editor.menuBar.categoryIndex = 1 // Edit Menu
        let (_, _, modernEditLines) = renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let modernEditStr = modernEditLines.joined(separator: "\n")
        #expect(modernEditStr.contains("^X")) // Cut is ^X
        #expect(modernEditStr.contains("^C")) // Copy is ^C
        #expect(modernEditStr.contains("^V")) // Paste is ^V
        #expect(modernEditStr.contains("^F")) // Search is ^F
        #expect(modernEditStr.contains("^Z")) // Undo is ^Z

        // Check Tools menu in Modern mode: Eval LOGO is ^E
        if let toolsIdx = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.tools" }) {
            editor.menuBar.categoryIndex = toolsIdx
        }
        let (_, _, modernToolsLines) = renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let modernToolsStr = modernToolsLines.joined(separator: "\n")
        #expect(modernToolsStr.contains("^E"))
    }

    @Test func testCommandDescriptionKey() throws {
        let moveCmd = MoveRightCommand()
        #expect(moveCmd.descriptionKey == "command.move.right.description")

        let blockCmd = BlockCommand(id: .customMacro, name: "Custom", description: "Custom description") { _ in }
        #expect(blockCmd.descriptionKey == "command.custom.macro.description")
    }

    @Test func testHelpContentKeymapPresetReflection() throws {
        let classicEditor = Editor(language: .en)
        let classicLines = HelpContent.lines(editor: classicEditor).joined(separator: "\n")
        #expect(classicLines.contains("^F / Right Arrow"))
        #expect(classicLines.contains("^K / F9"))
        #expect(classicLines.contains("^U / F10"))
        #expect(classicLines.contains("^X / F2"))

        let modernEditor = Editor(language: .en)
        modernEditor.apply(.keymap(.modern))
        let modernLines = HelpContent.lines(editor: modernEditor).joined(separator: "\n")
        #expect(modernLines.contains("Right Arrow"))
        #expect(modernLines.contains("^X / F9"))
        #expect(modernLines.contains("^V / F10"))
        #expect(modernLines.contains("^Q"))

        // Chinese localization
        let twEditor = Editor(language: .zh_TW)
        let twLines = HelpContent.lines(editor: twEditor).joined(separator: "\n")
        #expect(twLines.contains("游標向前移動一個字元"))
        #expect(twLines.contains("^F / 右方向鍵"))
    }
}
