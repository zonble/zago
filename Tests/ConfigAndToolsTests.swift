import Foundation
import Testing

@testable import Config
@testable import Editor

@Suite(.serialized)
struct ConfigAndToolsTests {
    @Test func testZagoVersionAndTitleBarDisplay() throws {
    #expect(!ZagoVersion.current.isEmpty)
    #expect(ZagoVersion.current == "1.0.5")

    let editor = Editor()
    let titleLine = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
    #expect(titleLine.contains("zago \(ZagoVersion.current)"))

    editor.openNewBuffer(filePath: "test2.txt")
    let titleLineMulti = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
    #expect(titleLineMulti.contains("zago \(ZagoVersion.current) [2/2]"))
}

@Test func testHelpContent() throws {
    let terminal = TestEditorTerminal.shared
    let helpView = TextDocumentView(
        terminal: terminal,
        title: L10n["helpview.title"],
        lines: HelpContent.lines(),
        footer: L10n["helpview.footer"]
    )
    _ = helpView
    #expect(HelpContent.lines(language: .en).contains("  KEYBINDINGS & COMMANDS REFERENCE"))
    #expect(HelpContent.lines(language: .en).contains("  CANVAS MODE:"))
    #expect(HelpContent.lines(language: .en).contains("    Shift+Arrow        Draw box lines and move the canvas cursor"))
    #expect(HelpContent.lines(language: .en).contains("    Ctrl+Shift+Arrow   Draw arrow lines with an arrowhead at the endpoint"))
    #expect(HelpContent.lines(language: .zh_TW).contains("  快捷鍵與指令對照表"))
    #expect(HelpContent.lines(language: .zh_TW).contains("  Canvas 模式："))
    #expect(HelpContent.lines(language: .zh_TW).contains("    Shift+方向鍵       畫出框線並移動畫布游標"))
    #expect(HelpContent.lines(language: .zh_TW).contains("    Ctrl+Shift+方向鍵  畫出箭頭線，並在終點放置箭頭"))
}

@Test func testWrapColumnMenuActions() throws {
    let editor = Editor()
    #expect(editor.layoutEngine.wrapColumn == nil)
    #expect(editor.displayConfig.showLineNumbers == true)

    let menuBar = MenuBar()
    let toolsCategory = menuBar.categories.first(where: { $0.titleKey == "menu.tools" })
    #expect(toolsCategory != nil)

    let lineNumbersIndex = toolsCategory?.items.firstIndex(where: { $0.titleKey == "menu.tools.line_numbers" })
    #expect(lineNumbersIndex != nil)

    let lineNumbersItem = toolsCategory?.items.first(where: { $0.titleKey == "menu.tools.line_numbers" })
    let subLineNumbersItem = toolsCategory?.items.first(where: { $0.titleKey == "menu.tools.sub_line_numbers" })
    let wrap80Item = toolsCategory?.items.first(where: { $0.titleKey == "menu.tools.wrap_80" })
    let wrap60Item = toolsCategory?.items.first(where: { $0.titleKey == "menu.tools.wrap_60" })
    let wrap40Item = toolsCategory?.items.first(where: { $0.titleKey == "menu.tools.wrap_40" })
    let wrapResetItem = toolsCategory?.items.first(where: { $0.titleKey == "menu.tools.wrap_reset" })
    let helpCategory = menuBar.categories.first(where: { $0.titleKey == "menu.help" })

    #expect(lineNumbersItem != nil)
    #expect(subLineNumbersItem != nil)
    #expect(wrap80Item != nil && wrap60Item != nil && wrap40Item != nil && wrapResetItem != nil)

    let editCategory = menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
    let cutIndex = editCategory?.items.firstIndex(where: { $0.titleKey == "menu.edit.cut" })
    let searchIndex = editCategory?.items.firstIndex(where: { $0.titleKey == "menu.edit.search" })
    let openLinkItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.open_link" })
    let outlineItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.outline" })
    let nextHeadingItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.next_heading" })
    let previousHeadingItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.previous_heading" })
    let justifyIndex = editCategory?.items.firstIndex(where: { $0.titleKey == "menu.edit.justify" })
    let textModeItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.text_editing_mode" })
    let canvasModeItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.canvas_mode" })
    let tableEditingModeItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.table_editing_mode" })
    #expect(cutIndex != nil && searchIndex != nil && justifyIndex != nil)
    #expect(openLinkItem?.commandId == .documentOpenLink)
    #expect(outlineItem?.commandId == .documentOutline)
    #expect(nextHeadingItem?.commandId == .documentHeadingNext)
    #expect(previousHeadingItem?.commandId == .documentHeadingPrevious)
    #expect(cutIndex! < searchIndex! && searchIndex! < justifyIndex!)
    #expect(textModeItem?.commandId == .textMode)
    #expect(canvasModeItem?.commandId == .canvasToggle)
    #expect(textModeItem?.isChecked?(editor) == true)
    #expect(canvasModeItem?.isChecked?(editor) == false)
    #expect(tableEditingModeItem?.commandId == .tableToggle)
    #expect(tableEditingModeItem?.isChecked?(editor) == false)

    editor.switchToCanvasMode()
    #expect(textModeItem?.isChecked?(editor) == false)
    #expect(canvasModeItem?.isChecked?(editor) == true)

    editor.switchToTextMode()
    #expect(textModeItem?.isChecked?(editor) == true)
    #expect(canvasModeItem?.isChecked?(editor) == false)

    editor.isTableModeActive = true
    #expect(tableEditingModeItem?.isChecked?(editor) == true)
    editor.isTableModeActive = false

    let logoReferenceItem = helpCategory?.items.first(where: { $0.titleKey == "menu.help.logo_reference" })
    let logoWorkspaceItem = helpCategory?.items.first(where: { $0.titleKey == "menu.help.logo_workspace" })
    #expect(logoReferenceItem?.commandId == .logoReference)
    #expect(logoWorkspaceItem?.commandId == .logoWorkspace)

    let bordersCategory = menuBar.categories.first(where: { $0.titleKey == "menu.borders" })
    let singleItem = bordersCategory?.items.first(where: { $0.titleKey == "menu.borders.single" })
    let doubleItem = bordersCategory?.items.first(where: { $0.titleKey == "menu.borders.double" })
    #expect(singleItem?.isChecked?(editor) == true)
    #expect(doubleItem?.isChecked?(editor) == false)

    doubleItem?.action?(editor)
    #expect(editor.defaultBorderStyle == .double)
    #expect(singleItem?.isChecked?(editor) == false)
    #expect(doubleItem?.isChecked?(editor) == true)

    lineNumbersItem?.action?(editor)
    #expect(editor.displayConfig.showLineNumbers == false)
    #expect(editor.statusMessage == "[ Line Numbers hidden ]")

    lineNumbersItem?.action?(editor)
    #expect(editor.displayConfig.showLineNumbers == true)
    #expect(editor.statusMessage == "[ Line Numbers shown ]")

    #expect(editor.displayConfig.showSubLineNumbers == false)
    #expect(subLineNumbersItem?.isChecked?(editor) == false)
    subLineNumbersItem?.action?(editor)
    #expect(editor.displayConfig.showSubLineNumbers == true)
    #expect(subLineNumbersItem?.isChecked?(editor) == true)

    wrap80Item?.action?(editor)
    #expect(editor.layoutEngine.wrapColumn == 80)

    wrap60Item?.action?(editor)
    #expect(editor.layoutEngine.wrapColumn == 60)

    wrap40Item?.action?(editor)
    #expect(editor.layoutEngine.wrapColumn == 40)

    wrapResetItem?.action?(editor)
    #expect(editor.layoutEngine.wrapColumn == nil)

    editor.layoutEngine.setWrapColumn(4)
    #expect(editor.layoutEngine.wrapColumn == 10)

    editor.applyEditorSetting(setting: "wrap", arg: "4")
    #expect(editor.layoutEngine.wrapColumn == 10)
}

@Test func testConfigLoaderDirectivesAndLogoBlocks() throws {
    let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_zagorc_directives").path
    defer { try? FileManager.default.removeItem(atPath: tmpFile) }

    let configContent = """
    # Sample config file
    set wrap 80
    set ruler on
    set linenumbers off
    set sublinenumbers on
    set canvas-mode on
    set border round
    set spell-language en
    set trim-trailing-whitespace on
    set auto-reload on

    unset wrap
    unset ruler
    unset linenumbers
    unset canvas-mode

    bind Ctrl+A move-home
    unbind Ctrl+A

    logo-prelude
    MAKE "globalVar 123
    endlogo

    logo-script customMacro
    PRINT "MacroExecuted
    endlogo
    """

    try configContent.write(toFile: tmpFile, atomically: true, encoding: .utf8)

    let loader = ConfigLoader()
    var config = EditorConfig()
    loader.parseConfigFile(at: tmpFile, into: &config)

    #expect(config.loadedFilePath == tmpFile)
    #expect(config.defaultBorderStyle == .round)
    #expect(config.spellLanguage == "en")
    #expect(config.trimTrailingWhitespaceOnSave == true)
    #expect(config.autoReload == true)
    #expect(config.logoPrelude.contains("MAKE \"globalVar 123"))
}

@Test func testDisplaySettingsAreBufferLocal() throws {
    let editor = Editor()
    editor.buffer.filePath = "first.md"
    editor.openNewBuffer(filePath: "second.md")

    editor.displayConfig.showRuler = true
    editor.displayConfig.showLineNumbers = false
    editor.displayConfig.showSubLineNumbers = true
    editor.layoutEngine.setWrapColumn(80)

    editor.prevBuffer()
    #expect(editor.buffer.filePath == "first.md")
    #expect(editor.displayConfig.showRuler == false)
    #expect(editor.displayConfig.showLineNumbers == true)
    #expect(editor.displayConfig.showSubLineNumbers == false)
    #expect(editor.layoutEngine.wrapColumn == nil)

    editor.displayConfig.showRuler = false
    editor.displayConfig.showLineNumbers = true
    editor.displayConfig.showSubLineNumbers = false
    editor.layoutEngine.setWrapColumn(40)

    editor.nextBuffer()
    #expect(editor.buffer.filePath == "second.md")
    #expect(editor.displayConfig.showRuler == true)
    #expect(editor.displayConfig.showLineNumbers == false)
    #expect(editor.displayConfig.showSubLineNumbers == true)
    #expect(editor.layoutEngine.wrapColumn == 80)

    editor.prevBuffer()
    #expect(editor.buffer.filePath == "first.md")
    #expect(editor.displayConfig.showRuler == false)
    #expect(editor.displayConfig.showLineNumbers == true)
    #expect(editor.displayConfig.showSubLineNumbers == false)
    #expect(editor.layoutEngine.wrapColumn == 40)
}

@Test func testOutlineMenuItemsOnlyShowForSupportedDocumentFormats() throws {
    let editor = Editor()
    editor.buffer.filePath = "notes.md"
    editor.menuBar.updateCategories(for: editor)
    var editCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
    #expect(editCategory?.items.contains(where: { $0.titleKey == "menu.edit.outline" }) == true)
    #expect(editCategory?.items.contains(where: { $0.titleKey == "menu.edit.next_heading" }) == true)
    #expect(editCategory?.items.contains(where: { $0.titleKey == "menu.edit.previous_heading" }) == true)

    editor.buffer.filePath = "notes.txt"
    editor.menuBar.updateCategories(for: editor)
    editCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
    #expect(editCategory?.items.contains(where: { $0.titleKey == "menu.edit.outline" }) == false)
    #expect(editCategory?.items.contains(where: { $0.titleKey == "menu.edit.next_heading" }) == false)
    #expect(editCategory?.items.contains(where: { $0.titleKey == "menu.edit.previous_heading" }) == false)
}

@Test func testTextTransformMenuItemsOnlyShowWithTextSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["中文API測試"]
    editor.menuBar.updateCategories(for: editor)

    var toolsCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.tools" })
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.word_count" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_cjk_spacing" }) == false)

    editor.selectionMark = (line: 0, column: 0)
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = editor.buffer.lines[0].count
    editor.menuBar.updateCategories(for: editor)

    toolsCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.tools" })
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.word_count" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_tohant" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_tohans" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_tolatin" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_hiragana" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_katakana" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_romaji" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_cjk_spacing" }) == true)

    editor.switchToCanvasMode()
    editor.menuBar.updateCategories(for: editor)
    toolsCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.tools" })
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.word_count" }) == true)
    #expect(toolsCategory?.items.contains(where: { $0.titleKey == "menu.tools.transform_cjk_spacing" }) == false)
}

@Test func testCanvasMarkMenuItemOnlyVisibleInCanvasMode() throws {
    let editor = Editor()

    editor.menuBar.updateCategories(for: editor)
    let textEditCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
    #expect(textEditCategory?.items.contains(where: { $0.titleKey == "menu.edit.mark" }) == false)

    editor.switchToCanvasMode()
    editor.menuBar.updateCategories(for: editor)
    let canvasEditCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
    #expect(canvasEditCategory?.items.contains(where: { $0.titleKey == "menu.edit.mark" }) == true)

    editor.switchToTextMode()
    editor.isMenuBarActive = true
    editor.menuBar.updateCategories(for: editor)
    editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.edit" }) ?? 0

    let (_, _, lines) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
    let clean = lines.joined(separator: "\n")
        .replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
    #expect(!clean.contains("Toggle Canvas Mark"))
}

@Test func testModeTransitionCommandsAndMenuItems() throws {
    let editor = Editor()

    #expect(editor.baseMode == .text)
    #expect(editor.overlayMode == .none)
    #expect(editor.isCanvasModeActive == false)

    _ = editor.commandRegistry.dispatch(id: .canvasToggle, editor: editor)
    #expect(editor.baseMode == .canvas)
    #expect(editor.isCanvasModeActive == true)

    _ = editor.commandRegistry.dispatch(id: .canvasToggle, editor: editor)
    #expect(editor.baseMode == .text)

    _ = editor.commandRegistry.dispatch(id: .textMode, editor: editor)
    #expect(editor.baseMode == .text)
    #expect(editor.overlayMode == .none)

    let editCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
    let canvasItem = editCategory?.items.first(where: { $0.titleKey == "menu.edit.canvas_mode" })
    #expect(canvasItem?.commandId == .canvasToggle)
    #expect(canvasItem?.isChecked?(editor) == false)

    if let commandId = canvasItem?.commandId {
        _ = editor.commandRegistry.dispatch(id: commandId, editor: editor)
    }
    #expect(editor.baseMode == .canvas)
    #expect(canvasItem?.isChecked?(editor) == true)
}

@Test func testBaseModeIsLocalToEachEditorInstance() throws {
    let leftEditor = Editor()
    let rightEditor = Editor()

    leftEditor.switchToCanvasMode()

    #expect(leftEditor.baseMode == .canvas)
    #expect(rightEditor.baseMode == .text)

    rightEditor.switchToCanvasMode()
    leftEditor.switchToTextMode()

    #expect(leftEditor.baseMode == .text)
    #expect(rightEditor.baseMode == .canvas)
}

@Test func testBaseModeIsLocalToEachBuffer() throws {
    let editor = Editor()
    editor.switchToTextMode()
    editor.openNewBuffer(filePath: "second.md")
    editor.switchToTextMode()

    _ = editor.commandRegistry.dispatch(id: .canvasToggle, editor: editor)

    #expect(editor.currentBufferIndex == 1)
    #expect(editor.buffers[0].baseMode == .text)
    #expect(editor.buffers[1].baseMode == .canvas)

    editor.switchToBuffer(zeroBasedIndex: 0)
    #expect(editor.baseMode == .text)

    editor.applyEditorSetting(setting: "canvas-mode", arg: "on")
    #expect(editor.buffers[0].baseMode == .canvas)
    #expect(editor.buffers[1].baseMode == .canvas)

    editor.applyEditorSetting(setting: "canvas-mode", arg: "off")
    #expect(editor.buffers[0].baseMode == .text)
    #expect(editor.buffers[1].baseMode == .canvas)

    editor.switchToBuffer(zeroBasedIndex: 1)
    #expect(editor.baseMode == .canvas)
}

@Test func testCommandBarAliasesMatchCommands() throws {
    let editor = Editor()

    #expect(editor.commandRegistry.dispatch("outline", editor: editor) == .handled)
    #expect(editor.overlayMode == .none)

    #expect(editor.commandRegistry.dispatch("border", editor: editor) == .handled)
    #expect(editor.defaultBorderStyle == .double)
}

@Test func testReloadedConfigPreservesPerEditorRuntimeMode() throws {
    var config = EditorConfig()
    config.startInCanvasMode = false
    config.showRuler = true

    let canvasEditor = Editor()
    canvasEditor.switchToCanvasMode()
    canvasEditor.applyReloadedConfig(config)

    #expect(canvasEditor.baseMode == .canvas)
    #expect(canvasEditor.displayConfig.showRuler == true)

    config.startInCanvasMode = true

    let textEditor = Editor()
    textEditor.switchToTextMode()
    textEditor.applyReloadedConfig(config)

    #expect(textEditor.baseMode == .text)
    #expect(textEditor.displayConfig.showRuler == true)
}

@Test func testEditorConfigIsInjectedByAppEntrypoint() throws {
    let defaultEditor = Editor()
    #expect(defaultEditor.displayConfig.showLineNumbers == true)
    #expect(defaultEditor.displayConfig.showSubLineNumbers == false)

    var initialConfig = EditorConfig()
    initialConfig.showLineNumbers = false
    initialConfig.showSubLineNumbers = true

    var reloadedConfig = EditorConfig()
    reloadedConfig.showLineNumbers = true
    reloadedConfig.showSubLineNumbers = false
    reloadedConfig.showRuler = true

    let injectedEditor = Editor(
        configSource: EditorConfigSource(initial: initialConfig, reload: { reloadedConfig }),
        dependencies: EditorDependencies(
            fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
            terminal: TestEditorTerminal.shared
        )
    )
    #expect(injectedEditor.displayConfig.showLineNumbers == false)
    #expect(injectedEditor.displayConfig.showSubLineNumbers == true)

    injectedEditor.reloadConfig()
    #expect(injectedEditor.displayConfig.showLineNumbers == true)
    #expect(injectedEditor.displayConfig.showSubLineNumbers == false)
    #expect(injectedEditor.displayConfig.showRuler == true)
}

@Test func testShapeFillMenuPromptsForFillText() throws {
    let editor = Editor()
    editor.runLogoScript("CLEARBUFFER BOX 5 5 GOTO 2 2")

    let shapesCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.shapes" })
    let fillItem = shapesCategory?.items.first(where: { $0.titleKey == "menu.shapes.fill" })
    #expect(fillItem != nil)

    fillItem?.action?(editor)
    if case .fillText = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Fill menu item should ask for fill text before running FILL")
    }

    editor.processPromptKey(.char("."))
    editor.processPromptKey(.enter)

    #expect(editor.buffer.lines[1] == "│...│")
    #expect(editor.buffer.lines[2] == "│...│")
    #expect(editor.buffer.lines[3] == "│...│")
}

@Test func testShapeTableMenuPromptsForDimensions() throws {
    let editor = Editor()

    let shapesCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.shapes" })
    let tableItem = shapesCategory?.items.first(where: { $0.titleKey == "menu.shapes.table" })
    #expect(tableItem != nil)

    tableItem?.action?(editor)
    if case .tableDimensions = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Table menu item should ask for rows, cols, and width before creating a table")
    }
    #expect(editor.promptInputText == "3 3 16")
    #expect(editor.buffer.lines == [""])

    editor.promptInputText = "2 2 4"
    editor.promptCursorIndex = editor.promptInputText.count
    editor.processPromptKey(.enter)

    #expect(editor.buffer.lines[0] == "┌────┬────┐")
    #expect(editor.buffer.lines[1] == "│    │    │")
    #expect(editor.buffer.lines[2] == "├────┼────┤")
    #expect(editor.buffer.lines[4] == "└────┴────┘")
}

@Test func testEditConfigAndReloadConfigMenuItems() throws {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    let zagorcPath = (homeDir as NSString).appendingPathComponent(".zagorc")
    let existsBefore = FileManager.default.fileExists(atPath: zagorcPath)
    let contentBefore = try? String(contentsOfFile: zagorcPath, encoding: .utf8)

    defer {
        if !existsBefore {
            try? FileManager.default.removeItem(atPath: zagorcPath)
        } else if let content = contentBefore {
            try? content.write(toFile: zagorcPath, atomically: true, encoding: .utf8)
        }
    }

    let editor = Editor()
    let fileCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.file" })
    #expect(fileCategory != nil)

    let editConfigItem = fileCategory?.items.first(where: { $0.titleKey == "menu.file.edit_config" })
    let reloadConfigItem = fileCategory?.items.first(where: { $0.titleKey == "menu.file.reload_config" })

    #expect(editConfigItem != nil)
    #expect(reloadConfigItem != nil)
    #expect(editConfigItem?.commandId == .fileEditConfig)
    #expect(reloadConfigItem?.commandId == .fileReloadConfig)

    // Test editConfig() creates/opens buffer for ~/.zagorc
    editor.editConfig()
    #expect(editor.buffer.filePath?.hasSuffix(".zagorc") == true || editor.buffer.filePath?.hasSuffix(".serc") == true)
    #expect(editor.statusMessage.contains(".zagorc") || editor.statusMessage.contains(".serc"))

    // Test reloadConfig()
    editor.reloadConfig()
    #expect(editor.statusMessage == L10n["status.config_reloaded"])
}



@Test func testGenerateDefaultConfigFile() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_gen_.serc").path
    if FileManager.default.fileExists(atPath: tmpPath) {
        try? FileManager.default.removeItem(atPath: tmpPath)
    }

    let generatedPath = try ConfigLoader.generateDefaultConfigFile(targetPath: tmpPath)
    #expect(FileManager.default.fileExists(atPath: generatedPath) == true)

    let content = try String(contentsOfFile: generatedPath, encoding: .utf8)
    #expect(content.contains("set showRuler off"))
    #expect(content.contains("set lineNumbers on"))
    #expect(content.contains("set subLineNumbers off"))
    #expect(content.contains("# set canvas-mode off"))
    #expect(content.contains("set tabSize 4"))
    #expect(content.contains("set trimTrailingWhitespace off"))

    try? FileManager.default.removeItem(atPath: tmpPath)
}

@Test func testConfigLoaderAndKeyParser() throws {
    let parsedCtrlF = KeyParser.parse("ctrl-f")
    #expect(parsedCtrlF == .ctrl("f"))

    let parsedAltDot = KeyParser.parse("alt-.")
    #expect(parsedAltDot == .alt("."))

    let parsedMetaComma = KeyParser.parse("m-,")
    #expect(parsedMetaComma == .alt(","))

    let parsedF1 = KeyParser.parse("f1")
    #expect(parsedF1 == .f1)

    let parsedUp = KeyParser.parse("up")
    #expect(parsedUp == .arrowUp)
    #expect(KeyParser.parse("shift-home") == .shiftHome)
    #expect(KeyParser.parse("shift-end") == .shiftEnd)
    #expect(KeyParser.parse("ctrl-shift-right") == .ctrlShiftArrowRight)
    #expect(KeyParser.parse("ctrl-shift-arrow-left") == .ctrlShiftArrowLeft)

    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_.serc").path
    let sampleConfig = """
        # Sample serc configuration
        set wrap 80
        set showRuler true
        set lineNumbers off
        set subLineNumbers on
        set canvas-mode on
        set autoReload true
        set trimTrailingWhitespace on
        bind ctrl-f move.left
        bind alt-h "logo: MOVE HOME TYPE '# ' MOVE END"
        logo-prelude
          MAKE "boxWidth 30
          TO FILLBOX :text
            BOX :boxWidth 4
            MOVE LEFT (:boxWidth - 1) MOVE UP 2
            FILL :text
          END
        endlogo
        logo-script insert-title
          BOX 40 3 ROUND
          MOVE LEFT 38 MOVE UP 1
          FILL "-
        endlogo
        unbind f1
        invalid syntax line
        """
    try sampleConfig.write(toFile: tmpPath, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    let loader = ConfigLoader()
    var config = EditorConfig()
    loader.parseConfigFile(at: tmpPath, into: &config)

    #expect(config.wrapColumn == 80)
    #expect(config.showRuler == true)
    #expect(config.showLineNumbers == false)
    #expect(config.showSubLineNumbers == true)
    #expect(config.startInCanvasMode == true)
    #expect(config.autoReload == true)
    #expect(config.trimTrailingWhitespaceOnSave == true)
    #expect(config.customKeyBinds[.ctrl("f")] == "move.left")
    #expect(config.customKeyBinds[.alt("h")] == "logo: MOVE HOME TYPE '# ' MOVE END")
    #expect(config.unbindKeys.contains(.f1))
    #expect(config.logoPrelude.contains("MAKE \"boxWidth 30"))
    #expect(config.logoPrelude.contains("TO FILLBOX :text"))
    #expect(config.logoScripts["insert-title"]?.contains("BOX 40 3 ROUND") == true)
    #expect(config.syntaxErrorCount == 1)
}

@Test func testSubLineNumberSettingCommandSuggestionsAndAliases() throws {
    #expect(SettingCommand.settingNames.contains("sublinenumbers"))
    #expect(SettingCommand.valueSuggestions(for: "subline-numbers") == ["on", "off"])
    #expect(SettingCommand.settingNames.contains("canvas-mode"))
    #expect(SettingCommand.valueSuggestions(for: "canvas_mode") == ["on", "off"])
    #expect(SettingCommand.settingNames.contains("trim-trailing-whitespace"))
    #expect(SettingCommand.valueSuggestions(for: "trimTrailingWhitespace") == ["on", "off"])

    let editor = Editor()
    #expect(editor.displayConfig.showSubLineNumbers == false)

    editor.applyEditorSetting(setting: "sublines", arg: "on")
    #expect(editor.displayConfig.showSubLineNumbers == true)

    editor.applyEditorSetting(setting: "subline_numbers", arg: "off")
    #expect(editor.displayConfig.showSubLineNumbers == false)

    editor.applyEditorSetting(setting: "canvas-mode", arg: "on")
    #expect(editor.isCanvasModeActive == true)

    editor.applyEditorSetting(setting: "canvasmode", arg: "off")
    #expect(editor.isCanvasModeActive == false)

    editor.applyEditorSetting(setting: "trim-trailing-whitespace", arg: "on")
    #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == true)

    editor.applyEditorSetting(setting: "trim_trailing_spaces", arg: "off")
    #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == false)
}

@Test func testWrapColumnMinimumIsTen() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent(
        "test_min_wrap_\(UUID().uuidString).serc"
    ).path
    let sampleConfig = "set wrap 4\n"
    try sampleConfig.write(toFile: tmpPath, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    let loader = ConfigLoader()
    var config = EditorConfig()
    loader.parseConfigFile(at: tmpPath, into: &config)

    #expect(config.wrapColumn == 10)

    let engine = LayoutEngine(wrapColumn: 4)
    #expect(engine.wrapColumn == 10)
}

@Test func testFileWatcherAndAutoReload() throws {
    let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_fs_watcher.txt").path
    try "Initial line\n".write(toFile: tmpFile, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpFile) }

    let editor = Editor(filePath: tmpFile, autoReload: true)
    #expect(editor.displayConfig.autoReload == true)

    // Test external change reloading when unmodified
    try "Modified externally\n".write(toFile: tmpFile, atomically: true, encoding: .utf8)

    // Trigger reload
    editor.handleExternalFileChange()
    #expect(editor.buffer.lines.first == "Modified externally")
}

@Test func testNanoRCParser() throws {
    let rawPath = FileManager.default.temporaryDirectory
        .appendingPathComponent("test_\(UUID().uuidString).nanorc").path
    let tmpNanoRC = TestLocalEditorFileIOStrategy().normalizePath(rawPath, isDirectory: false)
    let content = """
        # Sample nanorc file
        syntax "customlang" "\\.custom$"
        color cyan "\\b(foo|bar)\\b"
        color green "\"([^\"]*)\""
        """
    try content.write(to: URL(fileURLWithPath: tmpNanoRC), atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpNanoRC) }

    let highlighter = SyntaxHighlighter()
    highlighter.parseNanoRCFile(at: tmpNanoRC)

    let customLang = highlighter.detectLanguage(for: "file.custom")
    #expect(customLang != nil)
    #expect(customLang?.name == "customlang")
}

@Test func testLocalization() throws {
    let previousLanguage = L10n.currentLanguage
    defer { L10n.currentLanguage = previousLanguage }
    L10n.currentLanguage = .en
    #expect(L10n.helpGetHelp == "Get Help")
    #expect(L10n.helpExit == "Exit")
    #expect(L10n.readLines(10) == "[ Read 10 line(s) ]")
    #expect(L10n.wroteToFile("test.txt") == "[ Wrote to test.txt ]")
    #expect(L10n.configLoadedWithErrors(2) == "[ Config loaded with 2 syntax error(s) ]")
    #expect(
        L10n.cursorInfo(
            currentLine: 5, totalLines: 20, percent: 25, currentCol: 3, totalCol: 10,
            visualCol: 4, totalVisualCol: 12)
            == "line 5/20 (25%), col 3/10, visual col 4/12")
    #expect(L10n.foundQueryAtLine(query: "foo", line: 12) == "Found \"foo\" at line 12")
    #expect(L10n.searchWrappedFound(query: "foo", line: 12) == "Search wrapped, found \"foo\" at line 12")
    #expect(L10n.notFound(query: "bar") == "\"bar\" not found")
    #expect(L10n.insertedLines(5) == "[ Inserted 5 lines ]")
    #expect(L10n.errorInsertingFile(error: "Access denied") == "Error inserting file: Access denied")
    #expect(L10n.errorSavingFile(error: "Disk full") == "Error saving file: Disk full")
    #expect(L10n.replacedWord(target: "helo", newWord: "hello") == "Replaced 'helo' with 'hello'")
    #expect(L10n["helpview.sec_logo"] == "  EDITOR LOGO MACRO & TURTLE GRAPHICS REFERENCE:")
    #expect(L10n["helpview.logo_6"].contains("Turtle Graphics"))
    #expect(L10n["menu.help.logo_reference"] == "Editor LOGO Reference")
    #expect(L10n["menu.help.logo_workspace"] == "Procedures & Variables")
    #expect(L10n["help.confirm"] == "Confirm")
    #expect(L10n["help.complete"] == "Complete")
    #expect(L10n["help.mark_block"] == "Mark Block")
    #expect(L10n["help.uncut_block"] == "UnCut Block")
    #expect(L10n["help.open_link"] == "Open Link")
    #expect(L10n["helpview.search_2"].contains("AsciiDoc"))
    #expect(L10n["helpview.search_3"].contains("outline"))
    #expect(L10n["menu.edit.outline"] == "Outline\tM+\\")
    #expect(L10n["menu.edit.next_heading"] == "Next Heading\tM+]")
    #expect(L10n["menu.edit.previous_heading"] == "Previous Heading\tM+[")
    #expect(L10n["status.no_headings"] == "[ No headings ]")
    #expect(L10n["status.heading_nav_unsupported_format"] == "[ Document outline not supported for this file type ]")
    #expect(String(format: L10n["status.heading_position"], 3, 18, "## Search") == "[ Heading 3/18: ## Search ]")
    #expect(L10n["outlineview.title"] == "  Document Outline")
    #expect(L10n["menu.tools.word_count"] == "Word Count")
    #expect(
        String(format: L10n["status.word_count_document"], "21 chars, 5 words, 4 CJK chars, 2 lines")
            == "[ Document: 21 chars, 5 words, 4 CJK chars, 2 lines ]")
    #expect(L10n["menu.tools.transform_cjk_spacing"] == "Transform: CJK Spacing")
    #expect(L10n["transform.tohant"] == "Traditional Chinese")

    #expect(L10n.defaultBorder("Round") == "[ Default Border: Round ]")
    #expect(L10n.disabledInTableMode("GOTO") == "[ GOTO disabled in Table Mode ]")
    #expect(L10n["status.table_mode_exited"] == "[ Table Mode Exited ]")
    #expect(L10n["status.canvas_mode_hint"] == "(F8 / M+V to exit)")
    #expect(L10n["mode.canvas"] == "CANVAS")
    #expect(L10n["mode.table"] == "TABLE")

    L10n.currentLanguage = .zh_TW
    #expect(L10n.helpGetHelp == "輔助說明")
    #expect(L10n.helpExit == "離開")
    #expect(L10n.readLines(10) == "[ 已讀取 10 行 ]")
    #expect(L10n.wroteToFile("test.txt") == "[ 已儲存至 test.txt ]")
    #expect(L10n.configLoadedWithErrors(2) == "[ 已載入設定檔（含有 2 個語法錯誤）]")
    #expect(
        L10n.cursorInfo(
            currentLine: 5, totalLines: 20, percent: 25, currentCol: 3, totalCol: 10,
            visualCol: 4, totalVisualCol: 12)
            == "第 5/20 行 (25%), 第 3/10 欄, 視覺欄 4/12")
    #expect(L10n.foundQueryAtLine(query: "foo", line: 12) == "於第 12 行找到 \"foo\"")
    #expect(L10n.searchWrappedFound(query: "foo", line: 12) == "搜尋回到開頭，於第 12 行找到 \"foo\"")
    #expect(L10n.notFound(query: "bar") == "找不到 \"bar\"")
    #expect(L10n.insertedLines(5) == "[ 已插入 5 行內容 ]")
    #expect(L10n.errorInsertingFile(error: "Access denied") == "插入檔案錯誤：Access denied")
    #expect(L10n.errorSavingFile(error: "Disk full") == "儲存檔案錯誤：Disk full")
    #expect(L10n.replacedWord(target: "helo", newWord: "hello") == "已將 'helo' 替換為 'hello'")
    #expect(L10n.defaultBorder("Round") == "[ 預設框線：Round ]")
    #expect(L10n.disabledInTableMode("GOTO") == "[ 表格模式下停用 GOTO ]")
    #expect(L10n["status.table_mode_exited"] == "[ 已退出表格模式 ]")
    #expect(L10n["status.canvas_mode_hint"] == "(F8 / M+V 退出)")
    #expect(L10n["mode.canvas"] == "畫布")
    #expect(L10n["mode.table"] == "表格")
    #expect(L10n["helpview.sec_logo"] == "  Editor LOGO 巨集語言與海龜繪圖指令：")
    #expect(L10n["helpview.logo_6"].contains("海龜繪圖"))
    #expect(L10n["menu.help.logo_reference"] == "Editor LOGO 指令參考")
    #expect(L10n["menu.help.logo_workspace"] == "Procedures 與變數")
    #expect(L10n["help.confirm"] == "確認")
    #expect(L10n["help.complete"] == "補完")
    #expect(L10n["help.mark_block"] == "標記區塊")
    #expect(L10n["help.uncut_block"] == "貼上區塊")
    #expect(L10n["help.open_link"] == "開啟連結")
    #expect(L10n["helpview.search_2"].contains("AsciiDoc"))
    #expect(L10n["helpview.search_3"].contains("文件大綱"))
    #expect(L10n["menu.edit.outline"] == "文件大綱\tM+\\")
    #expect(L10n["menu.edit.next_heading"] == "下一個標題\tM+]")
    #expect(L10n["menu.edit.previous_heading"] == "上一個標題\tM+[")
    #expect(L10n["status.no_headings"] == "[ 沒有標題 ]")
    #expect(L10n["status.heading_nav_unsupported_format"] == "[ 目前檔案格式不支援文件大綱 ]")
    #expect(String(format: L10n["status.heading_position"], 3, 18, "## Search") == "[ 標題 3/18：## Search ]")
    #expect(L10n["outlineview.title"] == "  文件大綱")
    #expect(L10n["menu.tools.word_count"] == "Word Count")
    #expect(
        String(format: L10n["status.word_count_document"], "21 chars, 5 words, 4 CJK chars, 2 lines")
            == "[ 文件：21 chars, 5 words, 4 CJK chars, 2 lines ]")
    #expect(L10n["menu.tools.transform_cjk_spacing"] == "轉換：CJK 空格")
    #expect(L10n["transform.tohant"] == "繁體中文")
}

@Test func testLogoReferenceAndWorkspaceContent() throws {
    let reference = LogoReferenceContent.lines(language: .en).joined(separator: "\n")
    #expect(reference.contains("TABLE BORDER style"))
    #expect(reference.contains("PROCEDURE? name"))
    #expect(reference.contains("GETLINE [row]"))
    #expect(reference.contains("logical buffer lines"))
    #expect(reference.contains("SETITEM n array value"))
    #expect(reference.contains("SUM a b"))
    #expect(reference.contains("SIN / COS / TAN degrees"))
    #expect(reference.contains("ASCII / ORD char"))
    #expect(reference.contains("RANGE / ISEQ start end"))
    #expect(reference.contains("AND / OR / XOR"))
    #expect(reference.contains("TOHIRAGANA text"))
    #expect(reference.contains("SPACING.CJK text"))
    #expect(reference.contains("CHARCOUNT.EMOJI text"))
    #expect(reference.contains("TRANSFORM.TOHANS"))
    #expect(reference.contains("All primitive aliases"))

    let editor = Editor()
    editor.logoEngine.execute("MAKE \"answer 42 TO TITLE :text BOX :text CENTER ROUND END")
    let workspace = LogoWorkspaceContent.lines(engine: editor.logoEngine, language: .en).joined(separator: "\n")
    #expect(workspace.contains("TITLE :text"))
    #expect(workspace.contains("answer = 42"))

    let zhReference = LogoReferenceContent.lines(language: .zh_TW).joined(separator: "\n")
    #expect(zhReference.contains("LOGO 指令參考"))
    #expect(zhReference.contains("設定預設框線樣式"))
    #expect(zhReference.contains("讀取邏輯行"))
    #expect(zhReference.contains("不是 soft wrap 後的視覺行"))
    #expect(zhReference.contains("數字相加"))
    #expect(zhReference.contains("以角度為單位的三角函數"))
    #expect(zhReference.contains("ASCII / ORD char"))
    #expect(zhReference.contains("產生 inclusive 整數序列 list"))
    #expect(zhReference.contains("文字轉換"))
    #expect(zhReference.contains("文字計數"))
    #expect(zhReference.contains("CHARCOUNT.CJK text"))
    #expect(zhReference.contains("TOROMAJI text"))

    let zhWorkspace = LogoWorkspaceContent.lines(engine: Editor().logoEngine, language: .zh_TW).joined(separator: "\n")
    #expect(zhWorkspace.contains("LOGO 工作區"))
    #expect(zhWorkspace.contains("（無）"))
}

@Test func testDefaultBorderStyleConfig() throws {
    let loader = ConfigLoader()
    var config = EditorConfig()
    let configContent = """
        set border round
        """
    let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_border_config.zagorc").path
    try configContent.write(toFile: tempFile, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tempFile) }

    loader.parseConfigFile(at: tempFile, into: &config)
    #expect(config.defaultBorderStyle == .round)

    let editor = Editor()
    editor.applyEditorSetting(setting: "border", arg: "double")
    #expect(editor.defaultBorderStyle == .double)
}

@Test func testZagorcCommentSyntaxHighlighting() throws {
    let highlighter = SyntaxHighlighter()
    guard let syntax = highlighter.detectLanguage(for: ".zagorc") else {
        Issue.record("Should detect syntax for .zagorc")
        return
    }

    let commentTokens = highlighter.tokenTypes(for: "# set wrap 80", syntax: syntax)
    #expect(commentTokens.allSatisfy { $0 == .comment })

    let commentedPreludeTokens = highlighter.tokenTypes(for: "#   MAKE \"boxWidth 30", syntax: syntax)
    #expect(commentedPreludeTokens.allSatisfy { $0 == .comment })

    let commentedVariableTokens = highlighter.tokenTypes(for: "#     FILL :text", syntax: syntax)
    #expect(commentedVariableTokens.allSatisfy { $0 == .comment })

    let codeTokens = highlighter.tokenTypes(for: "MAKE \"i\" 80", syntax: syntax)
    #expect(codeTokens.contains(.keyword))
    #expect(codeTokens.contains(.number))
}

    @Test func testHeadlessLogoScriptExecution() throws {
        let editor = Editor()
        editor.runLogoScript("BOX 20 4")
        let output = editor.buffer.lines.joined(separator: "\n")
        #expect(output.contains("┌──────────────────┐"))
        #expect(output.contains("└──────────────────┘"))
    }
}
