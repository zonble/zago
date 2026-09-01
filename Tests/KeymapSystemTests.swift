import Foundation
import Testing

@testable import ANSITerminal
@testable import Config
@testable import Editor
@testable import zago

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
        #expect(keymap.resolve(key: .ctrl("v"), in: .canvas) == .movePgdn)
    }

    @Test func testPageUpDownKeyBindingsAcrossPresetsAndModes() throws {
        let keymap = KeymapManager(preset: .classic)

        // Classic: ^Y is PageUp, ^V is PageDown (in text and canvas)
        #expect(keymap.resolve(key: .ctrl("y"), in: .text) == .movePgup)
        #expect(keymap.resolve(key: .ctrl("Y"), in: .text) == .movePgup)
        #expect(keymap.resolve(key: .ctrl("v"), in: .text) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("V"), in: .text) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("y"), in: .canvas) == .movePgup)
        #expect(keymap.resolve(key: .ctrl("Y"), in: .canvas) == .movePgup)
        #expect(keymap.resolve(key: .ctrl("v"), in: .canvas) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("V"), in: .canvas) == .movePgdn)

        // Modern text mode keeps ^Y/^V as redo/paste; Canvas Mode reserves them for paging.
        keymap.loadPreset(.modern)
        #expect(keymap.resolve(key: .ctrl("y"), in: .text) == .editRedo)
        #expect(keymap.resolve(key: .ctrl("Y"), in: .text) == .editRedo)
        #expect(keymap.resolve(key: .ctrl("v"), in: .text) == .editUncut)
        #expect(keymap.resolve(key: .ctrl("V"), in: .text) == .editUncut)
        #expect(keymap.resolve(key: .ctrl("y"), in: .canvas) == .movePgup)
        #expect(keymap.resolve(key: .ctrl("Y"), in: .canvas) == .movePgup)
        #expect(keymap.resolve(key: .ctrl("v"), in: .canvas) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("V"), in: .canvas) == .movePgdn)
        #expect(keymap.resolve(key: .pageUp, in: .text) == .movePgup)
        #expect(keymap.resolve(key: .pageDown, in: .text) == .movePgdn)
        #expect(keymap.resolve(key: .pageUp, in: .canvas) == .movePgup)
        #expect(keymap.resolve(key: .pageDown, in: .canvas) == .movePgdn)
    }

    @Test func testCtrlQKeyBindingsAcrossPresetsAndModes() throws {
        let keymap = KeymapManager(preset: .classic)

        // Classic: ^Q is evaluate Logo
        #expect(keymap.resolve(key: .ctrl("q"), in: .text) == .editEvalLogo)
        #expect(keymap.resolve(key: .ctrl("Q"), in: .text) == .editEvalLogo)
        #expect(keymap.resolve(key: .ctrl("q"), in: .canvas) == .editEvalLogo)
        #expect(keymap.resolve(key: .ctrl("Q"), in: .canvas) == .editEvalLogo)

        // Modern: ^Q is Exit
        keymap.loadPreset(.modern)
        #expect(keymap.resolve(key: .ctrl("q"), in: .text) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("Q"), in: .text) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("q"), in: .canvas) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("Q"), in: .canvas) == .fileExit)
    }

    @Test func testClipboardKeyBindingsAcrossPresetsAndModes() throws {
        let keymap = KeymapManager(preset: .classic)

        // Classic: ^X is Exit, ^C is CurPos, ^V is PageDown
        #expect(keymap.resolve(key: .ctrl("x"), in: .text) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("X"), in: .text) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("c"), in: .text) == .cursorPos)
        #expect(keymap.resolve(key: .ctrl("C"), in: .text) == .cursorPos)
        #expect(keymap.resolve(key: .ctrl("v"), in: .text) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("V"), in: .text) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("x"), in: .canvas) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("X"), in: .canvas) == .fileExit)
        #expect(keymap.resolve(key: .ctrl("c"), in: .canvas) == .cursorPos)
        #expect(keymap.resolve(key: .ctrl("C"), in: .canvas) == .cursorPos)
        #expect(keymap.resolve(key: .ctrl("v"), in: .canvas) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("V"), in: .canvas) == .movePgdn)

        // Modern text mode uses ^X/^C/^V for editing; Canvas Mode reserves ^Y/^V for paging.
        keymap.loadPreset(.modern)
        #expect(keymap.resolve(key: .ctrl("x"), in: .text) == .editCut)
        #expect(keymap.resolve(key: .ctrl("X"), in: .text) == .editCut)
        #expect(keymap.resolve(key: .ctrl("c"), in: .text) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("C"), in: .text) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("v"), in: .text) == .editUncut)
        #expect(keymap.resolve(key: .ctrl("V"), in: .text) == .editUncut)
        #expect(keymap.resolve(key: .ctrl("x"), in: .canvas) == .editCut)
        #expect(keymap.resolve(key: .ctrl("X"), in: .canvas) == .editCut)
        #expect(keymap.resolve(key: .ctrl("c"), in: .canvas) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("C"), in: .canvas) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("v"), in: .canvas) == .movePgdn)
        #expect(keymap.resolve(key: .ctrl("V"), in: .canvas) == .movePgdn)
    }

    @Test func testPromptModeKeyBindingsAcrossPresets() throws {
        let keymap = KeymapManager(preset: .classic)

        // Classic Prompt: ^K is editCut, ^U is editUncut, M-W is editCopy, ^C/^G/ESC is promptCancel
        #expect(keymap.resolve(key: .ctrl("k"), in: .prompt) == .editCut)
        #expect(keymap.resolve(key: .ctrl("u"), in: .prompt) == .editUncut)
        #expect(keymap.resolve(key: .alt("w"), in: .prompt) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("c"), in: .prompt) == .promptCancel)
        #expect(keymap.resolve(key: .ctrl("g"), in: .prompt) == .promptCancel)
        #expect(keymap.resolve(key: .esc, in: .prompt) == .promptCancel)

        // Modern Prompt: ^X is editCut, ^C is editCopy, ^V is editUncut, ^G/ESC is promptCancel
        keymap.loadPreset(.modern)
        #expect(keymap.resolve(key: .ctrl("x"), in: .prompt) == .editCut)
        #expect(keymap.resolve(key: .ctrl("c"), in: .prompt) == .editCopy)
        #expect(keymap.resolve(key: .ctrl("v"), in: .prompt) == .editUncut)
        #expect(keymap.resolve(key: .ctrl("g"), in: .prompt) == .promptCancel)
        #expect(keymap.resolve(key: .esc, in: .prompt) == .promptCancel)
        #expect(keymap.resolve(key: .ctrl("c"), in: .prompt) != .promptCancel)
    }

    @Test func testWordNavigationKeyBindingsAcrossPresetsAndModes() throws {
        let keymap = KeymapManager(preset: .classic)

        // In text mode: Alt+F / Alt+B are word navigation
        #expect(keymap.resolve(key: .alt("f"), in: .text) == .moveWordForward)
        #expect(keymap.resolve(key: .alt("F"), in: .text) == .moveWordForward)
        #expect(keymap.resolve(key: .alt("b"), in: .text) == .moveWordBackward)
        #expect(keymap.resolve(key: .alt("B"), in: .text) == .moveWordBackward)

        // In table mode: Alt+F / Alt+B are word navigation
        #expect(keymap.resolve(key: .alt("f"), in: .table) == .moveWordForward)
        #expect(keymap.resolve(key: .alt("b"), in: .table) == .moveWordBackward)

        // In canvas mode: Alt+B is editMark, Alt+F is moveWordForward (or not overridden)
        #expect(keymap.resolve(key: .alt("b"), in: .canvas) == .editMark)
        #expect(keymap.resolve(key: .alt("B"), in: .canvas) == .editMark)
        #expect(keymap.resolve(key: .alt("b"), in: .text) != .editMark)

        // In prompt mode: Alt+F / Alt+B are word navigation
        #expect(keymap.resolve(key: .alt("f"), in: .prompt) == .moveWordForward)
        #expect(keymap.resolve(key: .alt("b"), in: .prompt) == .moveWordBackward)
    }

    @Test func testHomeEndAndSelectAllKeyBindingsAcrossPresetsAndModes() throws {
        let keymap = KeymapManager(preset: .classic)

        // Classic: ^A is MoveHome, ^E is MoveEnd
        #expect(keymap.resolve(key: .ctrl("a"), in: .text) == .moveHome)
        #expect(keymap.resolve(key: .ctrl("A"), in: .text) == .moveHome)
        #expect(keymap.resolve(key: .ctrl("e"), in: .text) == .moveEnd)
        #expect(keymap.resolve(key: .ctrl("E"), in: .text) == .moveEnd)
        #expect(keymap.resolve(key: .ctrl("a"), in: .canvas) == .moveHome)
        #expect(keymap.resolve(key: .ctrl("A"), in: .canvas) == .moveHome)
        #expect(keymap.resolve(key: .ctrl("e"), in: .canvas) == .moveEnd)
        #expect(keymap.resolve(key: .ctrl("E"), in: .canvas) == .moveEnd)

        // Modern: ^A is SelectAll, ^E is evaluate Logo
        keymap.loadPreset(.modern)
        #expect(keymap.resolve(key: .ctrl("a"), in: .text) == .selectAll)
        #expect(keymap.resolve(key: .ctrl("A"), in: .text) == .selectAll)
        #expect(keymap.resolve(key: .ctrl("e"), in: .text) == .editEvalLogo)
        #expect(keymap.resolve(key: .ctrl("E"), in: .text) == .editEvalLogo)
        #expect(keymap.resolve(key: .ctrl("a"), in: .canvas) == .selectAll)
        #expect(keymap.resolve(key: .ctrl("A"), in: .canvas) == .selectAll)
        #expect(keymap.resolve(key: .ctrl("e"), in: .canvas) == .editEvalLogo)
        #expect(keymap.resolve(key: .ctrl("E"), in: .canvas) == .editEvalLogo)
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
        editor.menuBar.categoryIndex = 0  // File Menu
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

        editor.menuBar.categoryIndex = 0  // File Menu
        let (_, _, modernFileLines) = renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let modernFileStr = modernFileLines.joined(separator: "\n")
        #expect(modernFileStr.contains("^Q"))

        // Check Edit menu in Modern mode
        editor.menuBar.categoryIndex = 1  // Edit Menu
        let (_, _, modernEditLines) = renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let modernEditStr = modernEditLines.joined(separator: "\n")
        #expect(modernEditStr.contains("^X"))  // Cut is ^X
        #expect(modernEditStr.contains("^C"))  // Copy is ^C
        #expect(modernEditStr.contains("^V"))  // Paste is ^V
        #expect(modernEditStr.contains("^F"))  // Search is ^F
        #expect(modernEditStr.contains("^Z"))  // Undo is ^Z

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

    @Test func testZagorcEndToEndKeyBindsAndMacros() throws {
        let configPath = "/home/user/.zagorc"
        let provider = InMemoryConfigFileProvider(
            homePath: "/home/user",
            currentPath: "/home/user",
            files: [
                configPath: """
                bind ^T search.whereis
                bind alt-h 'logo: MOVE HOME TYPE "# " MOVE END'
                unbind ^K
                """
            ]
        )
        let loader = ConfigLoader(provider: provider)
        var config = EditorConfig()
        loader.parseConfigFile(at: configPath, into: &config)

        let configSource = EditorConfigSource(initial: config, reload: { config })
        let editor = Editor(
            configSource: configSource,
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )

        // 1. Verify ^T triggers search.whereis (opening search prompt)
        guard case .none = editor.currentPromptMode else {
            #expect(Bool(false), "Expected promptMode to be .none initially")
            return
        }
        editor.processKey(.ctrl("t"))
        guard case .search = editor.currentPromptMode else {
            #expect(Bool(false), "Expected promptMode to be .search after pressing ^T")
            return
        }
        editor.processKey(.esc)
        guard case .none = editor.currentPromptMode else {
            #expect(Bool(false), "Expected promptMode to be .none after pressing Esc")
            return
        }

        // 2. Verify alt-h executes the LOGO macro
        editor.buffer.lines = ["Hello World"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 5
        editor.processKey(.alt("h"))
        #expect(editor.buffer.lines[0] == "# Hello World")

        // 3. Verify ^K is unbound and no longer cuts the line
        editor.buffer.lines = ["Stay Intact"]
        editor.buffer.lineIndex = 0
        editor.processKey(.ctrl("k"))
        #expect(editor.buffer.lines[0] == "Stay Intact")
    }

    @Test func testSearchReplaceKeybindingsAcrossPresets() throws {
        let classicKeymap = KeymapManager(preset: .classic)
        #expect(classicKeymap.resolve(key: .ctrl("\\"), in: .text) == .searchReplace)
        #expect(classicKeymap.resolve(key: .alt("r"), in: .text) == .searchReplace)
        #expect(classicKeymap.resolve(key: .alt("R"), in: .text) == .searchReplace)

        let modernKeymap = KeymapManager(preset: .modern)
        #expect(modernKeymap.resolve(key: .ctrl("h"), in: .text) == .searchReplace)
        #expect(modernKeymap.resolve(key: .ctrl("H"), in: .text) == .searchReplace)

        // Verify editor pressing ^H in modern keymap opens replaceSearch prompt
        let editor = Editor()
        editor.apply(.keymap(.modern))
        editor.processKey(.ctrl("h"))
        if case .replaceSearch = editor.currentPromptMode {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected currentPromptMode to be .replaceSearch")
        }
    }

    @Test func testJoinLineAndSplitLineKeyBindings() throws {
        // Classic Keymap
        let classicEditor = Editor()
        classicEditor.buffer.lines = ["First Line", "Second Line"]
        classicEditor.processKey(.alt("j"))
        #expect(classicEditor.buffer.lines == ["First Line Second Line"])

        // Split Line
        classicEditor.buffer.columnIndex = 10
        classicEditor.processKey(.alt("k"))
        #expect(classicEditor.buffer.lines == ["First Line", " Second Line"])

        // Modern Keymap
        let modernEditor = Editor()
        modernEditor.apply(.keymap(.modern))
        modernEditor.buffer.lines = ["Alpha", "Beta"]
        modernEditor.processKey(.alt("j"))
        #expect(modernEditor.buffer.lines == ["Alpha Beta"])
    }

    @Test func testDescribeKeyFeature() throws {
        let editor = Editor(language: .en)

        // 1. Trigger via command bar
        let dispatchResult = editor.commandBarRegistry.dispatch("help-key", editor: editor)
        #expect(dispatchResult == .handled)

        // 2. Test DescribeKeyDialogView modal loop with scripted keys
        final class ScriptedKeyTerminal: EditorTerminal, @unchecked Sendable {
            var keysToReturn: [Key] = []
            var writtenOutput: String = ""
            var rows = 24
            var cols = 80

            func enableRawMode() throws {}
            func disableRawMode() {}
            func getWindowSize() -> (rows: Int, cols: Int) { (rows, cols) }
            func readKey() -> Key {
                if !keysToReturn.isEmpty {
                    return keysToReturn.removeFirst()
                }
                return .esc
            }
            func readPendingText(firstChar: Character) -> String { String(firstChar) }
            func write(_ text: String) { writtenOutput += text }
            func hideCursor() {}
            func showCursor() {}
            func clearScreen() {}
        }

        // Test 1: Inspect Esc key
        let term1 = ScriptedKeyTerminal()
        term1.keysToReturn = [.esc, .enter]
        let dialog1 = DescribeKeyDialogView(terminal: term1, editor: editor, language: .en)
        dialog1.show()
        #expect(term1.writtenOutput.contains("Key: ⎋"))

        // Test 2: Inspect ^K (has Table mode override)
        let term2 = ScriptedKeyTerminal()
        term2.keysToReturn = [.unknown, .ctrl("k"), .enter]
        let dialog2 = DescribeKeyDialogView(terminal: term2, editor: editor, language: .en)
        dialog2.show()
        #expect(term2.writtenOutput.contains("Key: ^K"))
        #expect(term2.writtenOutput.contains("edit.cut"))
        #expect(term2.writtenOutput.contains("Table Mode"))
        #expect(term2.writtenOutput.contains("table.clear_cell"))

        // Test 3: Traditional Chinese inspection
        let zhEditor = Editor(language: .zh_TW)
        let term3 = ScriptedKeyTerminal()
        term3.keysToReturn = [.ctrl("k"), .enter]
        let dialog3 = DescribeKeyDialogView(terminal: term3, editor: zhEditor, language: .zh_TW)
        dialog3.show()
        #expect(term3.writtenOutput.contains("按鍵：^K"))
        #expect(term3.writtenOutput.contains("文字編輯模式（預設）："))
        #expect(term3.writtenOutput.contains("表格模式（儲存格導航與調整）："))

        // Test 4: Custom LOGO macro description
        var macroConfig = EditorConfig()
        macroConfig.customKeyBinds = [
            Key.alt("t"): "logo:insert-title",
            Key.alt("h"):
                "logo:MOVE HOME TYPE \"# Long Header Description Section\" MOVE END TYPE \"\n---\n\" MOVE HOME",
        ]
        let configSource = EditorConfigSource(initial: macroConfig, reload: { macroConfig })
        let macroEditor = Editor(
            configSource: configSource,
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )
        let term4 = ScriptedKeyTerminal()
        term4.keysToReturn = [.alt("t"), .enter]
        let dialog4 = DescribeKeyDialogView(terminal: term4, editor: macroEditor, language: .en)
        dialog4.show()
        #expect(term4.writtenOutput.contains("Key: ⌥T"))
        #expect(term4.writtenOutput.contains("Execute LOGO script 'insert-title'"))

        // Test 5: Long inline LOGO script wraps cleanly
        let term5 = ScriptedKeyTerminal()
        term5.keysToReturn = [.alt("h"), .enter]
        let dialog5 = DescribeKeyDialogView(terminal: term5, editor: macroEditor, language: .en)
        dialog5.show()
        #expect(term5.writtenOutput.contains("Key: ⌥H"))
        #expect(term5.writtenOutput.contains("MOVE HOME TYPE"))

        // Test 6: Verify MenuBar item placement in Help menu
        let menuBar = MenuBar()
        menuBar.updateCategories(for: editor)
        let helpCategory = menuBar.categories.first(where: { $0.titleKey == "menu.help" })
        #expect(helpCategory != nil)
        let describeKeyItem = helpCategory?.items.first(where: { $0.commandId == CommandID.helpDescribeKey })
        #expect(describeKeyItem != nil)
        #expect(describeKeyItem?.titleKey == "menu.help.describe_key")
        #expect(describeKeyItem?.hotkeyChar == "k")
    }

    @Test func testBackspaceKeyResolutionAndMapping() throws {
        let keymap = KeymapManager(preset: .classic)
        #expect(keymap.resolve(key: .ctrlBackspace, in: .text) == .editDeleteLine)
        #expect(keymap.resolve(key: .altBackspace, in: .text) == .editDeleteLine)
        #expect(keymap.resolve(key: .ctrlBackspace, in: .prompt) == .promptClearLine)
        #expect(keymap.resolve(key: .altBackspace, in: .prompt) == .promptClearLine)

        #expect(KeyParser.parse("ctrl-backspace") == .ctrlBackspace)
        #expect(KeyParser.parse("c-bs") == .ctrlBackspace)
        #expect(KeyParser.parse("alt-backspace") == .altBackspace)
        #expect(KeyParser.parse("opt-backspace") == .altBackspace)
        #expect(KeyParser.parse("m-bs") == .altBackspace)

        #expect(ANSIKeyMapping.resolve("127;5u") == .ctrlBackspace)
        #expect(ANSIKeyMapping.resolve("8;5u") == .ctrlBackspace)
        #expect(ANSIKeyMapping.resolve("127;3u") == .altBackspace)
        #expect(ANSIKeyMapping.resolve("8;3u") == .altBackspace)
    }

    @Test func testAltEnterAndEscapeFallbackResolution() throws {
        #expect(KeyParser.parse("alt-enter") == .altEnter)
        #expect(KeyParser.parse("m-enter") == .altEnter)
        #expect(KeyParser.parse("opt-return") == .altEnter)
        #expect(KeyParser.parse("alt-tab") == .altTab)

        #expect(ANSIKeyMapping.resolve("13;3u") == .altEnter)
        #expect(ANSIKeyMapping.resolve("10;3u") == .altEnter)
        #expect(ANSIKeyMapping.resolve("9;3u") == .altTab)

        #expect(ANSIKeyMapping.resolveSS3Code(UInt8(ascii: "P")) == .f1)
        #expect(ANSIKeyMapping.resolveSS3Code(UInt8(ascii: "?")) == nil)
    }
}
