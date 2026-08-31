import Diagram
import Foundation
import LogoEngine

struct MenuItem {
    let titleKey: String
    let hotkeyChar: Character
    let commandId: CommandID?
    let action: ((Editor) -> Void)?
    let isChecked: ((Editor) -> Bool)?
    let isVisible: ((Editor) -> Bool)?

    init(
        titleKey: String,
        hotkeyChar: Character,
        commandId: CommandID? = nil,
        action: ((Editor) -> Void)? = nil,
        isChecked: ((Editor) -> Bool)? = nil,
        isVisible: ((Editor) -> Bool)? = nil
    ) {
        self.titleKey = titleKey
        self.hotkeyChar = hotkeyChar
        self.commandId = commandId
        self.action = action
        self.isChecked = isChecked
        self.isVisible = isVisible
    }
}

struct MenuCategory {
    let titleKey: String
    let hotkeyChar: Character
    let items: [MenuItem]
    let isVisible: ((Editor) -> Bool)?

    init(
        titleKey: String,
        hotkeyChar: Character,
        items: [MenuItem],
        isVisible: ((Editor) -> Bool)? = nil
    ) {
        self.titleKey = titleKey
        self.hotkeyChar = hotkeyChar
        self.items = items
        self.isVisible = isVisible
    }
}

/// Menu Bar Data Engine handling menu categories, items, and keyboard navigation.
final class MenuBar {
    var categoryIndex: Int = 0
    var itemIndex: Int = 0

    var categories: [MenuCategory] = []

    init() {
        setupCategories()
    }

    func setupCategories() {
        updateCategories(for: nil)
    }

    func updateCategories(for editor: Editor? = nil) {
        func borderStyleItem(_ style: BorderStyle, titleKey: String, hotkeyChar: Character) -> MenuItem {
            MenuItem(
                titleKey: titleKey,
                hotkeyChar: hotkeyChar,
                action: { editor in
                    editor.defaultBorderStyle = style
                    editor.reportOperationResult(.succeeded(message: editor.l10n.defaultBorder(style.rawValue)))
                },
                isChecked: { $0.defaultBorderStyle == style })
        }

        func arrowStyleItem(_ style: ArrowStyle, titleKey: String, hotkeyChar: Character) -> MenuItem {
            MenuItem(
                titleKey: titleKey,
                hotkeyChar: hotkeyChar,
                action: { editor in
                    editor.defaultArrowStyle = style
                },
                isChecked: { $0.defaultArrowStyle == style })
        }

        func textTransformItem(id: String, labelKey: String, titleKey: String, hotkeyChar: Character) -> MenuItem {
            MenuItem(
                titleKey: titleKey,
                hotkeyChar: hotkeyChar,
                action: { editor in
                    editor.transformSelectedText(id: id, label: editor.l10n[labelKey])
                },
                isVisible: { $0.hasActiveTextSelection() })
        }

        func wrapColumnItem(_ width: Int?, titleKey: String, hotkeyChar: Character) -> MenuItem {
            MenuItem(
                titleKey: titleKey,
                hotkeyChar: hotkeyChar,
                action: { editor in
                    editor.layoutEngine.setWrapColumn(width)
                    if let width {
                        editor.reportOperationResult(.succeeded(message: editor.l10n.wrapColumnSet(width)))
                    } else {
                        editor.reportOperationResult(.succeeded(message: editor.l10n["status.wrap_column_reset"]))
                    }
                },
                isChecked: { $0.layoutEngine.wrapColumn == width })
        }

        var baseCategories: [MenuCategory] = [
            MenuCategory(
                titleKey: "menu.file", hotkeyChar: "f",
                items: [
                    MenuItem(titleKey: "menu.file.new", hotkeyChar: "n", commandId: .bufferNew),
                    MenuItem(titleKey: "menu.file.open", hotkeyChar: "o", commandId: .fileInsert),
                    MenuItem(titleKey: "menu.file.directory", hotkeyChar: "d", commandId: .fileDirectory),
                    MenuItem(titleKey: "menu.file.save", hotkeyChar: "s", commandId: .fileSave),
                    MenuItem(titleKey: "menu.file.write_out", hotkeyChar: "w", commandId: .fileWriteOut),
                    MenuItem(titleKey: "menu.file.save_exit", hotkeyChar: "e", commandId: .fileSaveExit),
                    MenuItem(titleKey: "menu.file.exit", hotkeyChar: "x", commandId: .fileExit),
                    MenuItem(titleKey: "menu.file.edit_config", hotkeyChar: "c", commandId: .fileEditConfig),
                    MenuItem(titleKey: "menu.file.reload_config", hotkeyChar: "r", commandId: .fileReloadConfig),
                ]),
            MenuCategory(
                titleKey: "menu.edit", hotkeyChar: "e",
                items: [
                    MenuItem(titleKey: "menu.edit.undo", hotkeyChar: "u", commandId: .editUndo),
                    MenuItem(titleKey: "menu.edit.redo", hotkeyChar: "r", commandId: .editRedo),
                    MenuItem(
                        titleKey: "menu.edit.mark", hotkeyChar: "m", commandId: .editMark,
                        isVisible: { $0.baseMode == .canvas }),
                    MenuItem(
                        titleKey: "menu.edit.cancel_selection", hotkeyChar: "k", commandId: .editCancelSelection,
                        isVisible: { $0.buffer.selectionMark != nil || $0.buffer.canvasBlockMark != nil }),
                    MenuItem(titleKey: "menu.edit.copy", hotkeyChar: "o", commandId: .editCopy),
                    MenuItem(titleKey: "menu.edit.cut", hotkeyChar: "c", commandId: .editCut),
                    MenuItem(titleKey: "menu.edit.paste", hotkeyChar: "p", commandId: .editUncut),
                    MenuItem(titleKey: "menu.edit.delete_line", hotkeyChar: "d", commandId: .editDeleteLine),
                    MenuItem(titleKey: "menu.edit.search", hotkeyChar: "s", commandId: .searchWhereIs),
                    MenuItem(titleKey: "menu.edit.open_link", hotkeyChar: "l", commandId: .documentOpenLink),
                    MenuItem(
                        titleKey: "menu.edit.outline", hotkeyChar: "i", commandId: .documentOutline,
                        isVisible: { $0.documentOutlineController.supportsDocumentOutlineForCurrentBuffer() }),
                    MenuItem(
                        titleKey: "menu.edit.next_heading", hotkeyChar: "]", commandId: .documentHeadingNext,
                        isVisible: { $0.documentOutlineController.supportsDocumentOutlineForCurrentBuffer() }),
                    MenuItem(
                        titleKey: "menu.edit.previous_heading", hotkeyChar: "[", commandId: .documentHeadingPrevious,
                        isVisible: { $0.documentOutlineController.supportsDocumentOutlineForCurrentBuffer() }),
                    MenuItem(titleKey: "menu.edit.goto_line", hotkeyChar: "g", commandId: .cursorGotoLine),
                    MenuItem(titleKey: "menu.edit.toggle_comment", hotkeyChar: "c", commandId: .editToggleComment),
                    MenuItem(titleKey: "menu.edit.spell", hotkeyChar: "t", commandId: .editSpell),
                    MenuItem(titleKey: "menu.edit.justify", hotkeyChar: "j", commandId: .editJustify),
                    MenuItem(
                        titleKey: "menu.edit.text_editing_mode", hotkeyChar: "x", commandId: .textMode,
                        isChecked: { $0.baseMode == .text }, isVisible: { !$0.buffer.isDirectoryBuffer }),
                    MenuItem(
                        titleKey: "menu.edit.canvas_mode", hotkeyChar: "v", commandId: .canvasToggle,
                        isChecked: { $0.baseMode == .canvas }, isVisible: { !$0.buffer.isDirectoryBuffer }),
                    MenuItem(
                        titleKey: "menu.edit.table_editing_mode", hotkeyChar: "b", commandId: .tableToggle,
                        isChecked: { $0.isTableModeActive }, isVisible: { !$0.buffer.isDirectoryBuffer }),
                ]),
            MenuCategory(
                titleKey: "menu.buffer", hotkeyChar: "b",
                items: [
                    MenuItem(titleKey: "menu.buffer.next", hotkeyChar: "n", commandId: .bufferNext),
                    MenuItem(titleKey: "menu.buffer.prev", hotkeyChar: "p", commandId: .bufferPrev),
                    MenuItem(
                        titleKey: "menu.buffer.logo_debugger", hotkeyChar: "d", commandId: .logoDebug,
                        isVisible: {
                            if $0.buffer.filePath?.lowercased().hasSuffix(".logo") == true {
                                return false
                            }
                            return $0.isLogoUIEnabled
                        }),
                    MenuItem(
                        titleKey: "menu.buffer.output", hotkeyChar: "o", commandId: .logoOutput,
                        isVisible: {
                            if $0.buffer.filePath?.lowercased().hasSuffix(".logo") == true {
                                return false
                            }
                            return $0.isLogoUIEnabled
                        }),
                    MenuItem(
                        titleKey: "menu.buffer.clear_output", hotkeyChar: "c", commandId: .logoClearOutput,
                        isVisible: {
                            if $0.buffer.filePath?.lowercased().hasSuffix(".logo") == true {
                                return false
                            }
                            return $0.isLogoUIEnabled
                        }),
                ]),
            MenuCategory(
                titleKey: "menu.run", hotkeyChar: "r",
                items: [
                    MenuItem(titleKey: "menu.run.script", hotkeyChar: "r", commandId: .fileRunLogo),
                    MenuItem(titleKey: "menu.buffer.logo_debugger", hotkeyChar: "d", commandId: .logoDebug),
                    MenuItem(titleKey: "menu.run.canvas", hotkeyChar: "c", commandId: .logoCanvas),
                    MenuItem(titleKey: "menu.run.output", hotkeyChar: "o", commandId: .logoOutput),
                    MenuItem(titleKey: "menu.buffer.clear_output", hotkeyChar: "k", commandId: .logoClearOutput),
                ],
                isVisible: { $0.buffer.filePath?.lowercased().hasSuffix(".logo") == true }),
            MenuCategory(
                titleKey: "menu.selection", hotkeyChar: "n",
                items: [
                    textTransformItem(
                        id: "Hans-Hant", labelKey: "transform.tohant", titleKey: "menu.tools.transform_tohant",
                        hotkeyChar: "h"),
                    textTransformItem(
                        id: "Hant-Hans", labelKey: "transform.tohans", titleKey: "menu.tools.transform_tohans",
                        hotkeyChar: "s"),
                    textTransformItem(
                        id: "Any-Latin", labelKey: "transform.tolatin", titleKey: "menu.tools.transform_tolatin",
                        hotkeyChar: "a"),
                    textTransformItem(
                        id: "Any-Hiragana", labelKey: "transform.hiragana", titleKey: "menu.tools.transform_hiragana",
                        hotkeyChar: "i"),
                    textTransformItem(
                        id: "Any-Katakana", labelKey: "transform.katakana", titleKey: "menu.tools.transform_katakana",
                        hotkeyChar: "k"),
                    textTransformItem(
                        id: "Any-Latin", labelKey: "transform.romaji", titleKey: "menu.tools.transform_romaji",
                        hotkeyChar: "j"),
                    textTransformItem(
                        id: "Zago-CJK-Spacing", labelKey: "transform.cjk_spacing",
                        titleKey: "menu.tools.transform_cjk_spacing", hotkeyChar: "c"),
                ],
                isVisible: { $0.hasActiveTextSelection() }
            ),
            MenuCategory(
                titleKey: "menu.shapes", hotkeyChar: "s",
                items: [
                    MenuItem(titleKey: "menu.shapes.box", hotkeyChar: "b", action: { $0.runLogoScript("BOX") }),
                    MenuItem(
                        titleKey: "menu.shapes.draw_box", hotkeyChar: "d", action: { $0.runLogoScript("DRAWBOX") }),
                    MenuItem(titleKey: "menu.shapes.line", hotkeyChar: "l", action: { $0.runLogoScript("LINE") }),
                    MenuItem(titleKey: "menu.shapes.vline", hotkeyChar: "v", action: { $0.runLogoScript("VLINE") }),
                    MenuItem(titleKey: "menu.shapes.table", hotkeyChar: "t", action: { $0.promptTableDimensions() }),
                    MenuItem(titleKey: "menu.shapes.fill", hotkeyChar: "f", action: { $0.promptFillText() }),
                    MenuItem(titleKey: "menu.shapes.symbols", hotkeyChar: "s", commandId: .symbolPicker),
                ],
                isVisible: { $0.buffer.allowsLogoExecution }),
            MenuCategory(
                titleKey: "menu.borders", hotkeyChar: "o",
                items: [
                    borderStyleItem(.single, titleKey: "menu.borders.single", hotkeyChar: "s"),
                    borderStyleItem(.heavy, titleKey: "menu.borders.heavy", hotkeyChar: "h"),
                    borderStyleItem(.double, titleKey: "menu.borders.double", hotkeyChar: "d"),
                    borderStyleItem(.ascii, titleKey: "menu.borders.ascii", hotkeyChar: "a"),
                    borderStyleItem(.doubleDash, titleKey: "menu.borders.double_dash", hotkeyChar: "j"),
                    borderStyleItem(.heavyDoubleDash, titleKey: "menu.borders.heavy_double", hotkeyChar: "k"),
                    borderStyleItem(.tripleDash, titleKey: "menu.borders.triple_dash", hotkeyChar: "t"),
                    borderStyleItem(.heavyTripleDash, titleKey: "menu.borders.heavy_triple", hotkeyChar: "g"),
                    borderStyleItem(.quadrupleDash, titleKey: "menu.borders.quad_dash", hotkeyChar: "q"),
                    borderStyleItem(.heavyQuadrupleDash, titleKey: "menu.borders.heavy_quad", hotkeyChar: "w"),
                    MenuItem(titleKey: "menu.borders.next_style", hotkeyChar: "n", commandId: .borderStyle),
                    MenuItem(
                        titleKey: "menu.borders.round", hotkeyChar: "r",
                        action: { editor in
                            editor.isBorderRounded.toggle()
                        },
                        isChecked: { $0.isBorderRounded }),
                ]),
            MenuCategory(
                titleKey: "menu.arrows", hotkeyChar: "a",
                items: [
                    arrowStyleItem(.solid, titleKey: "menu.arrows.solid", hotkeyChar: "1"),
                    arrowStyleItem(.hollow, titleKey: "menu.arrows.hollow", hotkeyChar: "2"),
                    arrowStyleItem(.small, titleKey: "menu.arrows.small", hotkeyChar: "3"),
                    arrowStyleItem(.stemmed, titleKey: "menu.arrows.stemmed", hotkeyChar: "4"),
                    arrowStyleItem(.heavy, titleKey: "menu.arrows.heavy", hotkeyChar: "5"),
                    arrowStyleItem(.double, titleKey: "menu.arrows.double", hotkeyChar: "6"),
                    arrowStyleItem(.solidDiamond, titleKey: "menu.arrows.solid_diamond", hotkeyChar: "7"),
                    arrowStyleItem(.diamond, titleKey: "menu.arrows.diamond", hotkeyChar: "8"),
                    arrowStyleItem(.circle, titleKey: "menu.arrows.circle", hotkeyChar: "9"),
                    arrowStyleItem(.openCircle, titleKey: "menu.arrows.open_circle", hotkeyChar: "0"),
                    arrowStyleItem(.cross, titleKey: "menu.arrows.cross", hotkeyChar: "x"),
                    arrowStyleItem(.crow, titleKey: "menu.arrows.crow", hotkeyChar: "w"),
                    arrowStyleItem(.harpoon, titleKey: "menu.arrows.harpoon", hotkeyChar: "h"),
                ]),
            MenuCategory(
                titleKey: "menu.tools", hotkeyChar: "t",
                items: [
                    MenuItem(
                        titleKey: "menu.tools.logo", hotkeyChar: "l", commandId: .macroLogo,
                        isVisible: { $0.buffer.allowsLogoExecution }),
                    MenuItem(
                        titleKey: "menu.tools.eval_logo", hotkeyChar: "q", commandId: .editEvalLogo,
                        isVisible: { $0.buffer.allowsLogoExecution }),
                    MenuItem(titleKey: "menu.tools.journal", hotkeyChar: "j", commandId: .openJournal),
                    MenuItem(
                        titleKey: "menu.tools.word_count", hotkeyChar: "w",
                        action: { editor in
                            editor.showTextCounts()
                        },
                        isVisible: { !$0.buffer.isDirectoryBuffer }),

                    MenuItem(
                        titleKey: "menu.tools.line_numbers", hotkeyChar: "n",
                        action: { editor in
                            editor.displayConfig.showLineNumbers.toggle()
                            let state = editor.displayConfig.showLineNumbers ? "shown" : "hidden"
                            editor.reportOperationResult(.succeeded(message: editor.l10n.lineNumbersState(state)))
                        },
                        isChecked: { $0.displayConfig.showLineNumbers }),
                    MenuItem(
                        titleKey: "menu.tools.sub_line_numbers", hotkeyChar: "u",
                        action: { editor in
                            editor.displayConfig.showSubLineNumbers.toggle()
                        },
                        isChecked: { $0.displayConfig.showSubLineNumbers }),
                    MenuItem(
                        titleKey: "menu.tools.ruler", hotkeyChar: "r",
                        action: { editor in
                            editor.displayConfig.showRuler.toggle()
                        },
                        isChecked: { $0.displayConfig.showRuler }),
                    MenuItem(
                        titleKey: "menu.tools.zero_mode", hotkeyChar: "z",
                        action: { editor in
                            editor.toggleZeroMode()
                        },
                        isChecked: { $0.displayConfig.isZeroMode }),
                    wrapColumnItem(80, titleKey: "menu.tools.wrap_80", hotkeyChar: "8"),
                    wrapColumnItem(60, titleKey: "menu.tools.wrap_60", hotkeyChar: "6"),
                    wrapColumnItem(40, titleKey: "menu.tools.wrap_40", hotkeyChar: "4"),
                    wrapColumnItem(nil, titleKey: "menu.tools.wrap_reset", hotkeyChar: "0"),
                ]),
        ]

        if let ed = editor, DiagramSnippets.shouldShowDiagramMenu(for: ed) {
            baseCategories.append(DiagramSnippets.makeMenuCategory(for: ed))
        }

        baseCategories.append(
            MenuCategory(
                titleKey: "menu.help", hotkeyChar: "h",
                items: [
                    MenuItem(titleKey: "menu.help.show", hotkeyChar: "h", commandId: .helpShow),
                    MenuItem(titleKey: "menu.help.describe_key", hotkeyChar: "k", commandId: .helpDescribeKey),
                    MenuItem(titleKey: "menu.help.describe_command", hotkeyChar: "c", commandId: .helpDescribeCommand),
                    MenuItem(
                        titleKey: "menu.help.style_dsl", hotkeyChar: "s", commandId: .styleDSLReference),
                    MenuItem(
                        titleKey: "menu.help.logo_reference", hotkeyChar: "l", commandId: .logoReference,
                        isVisible: { $0.isLogoUIEnabled }),
                    MenuItem(
                        titleKey: "menu.help.logo_workspace", hotkeyChar: "w", commandId: .logoWorkspace,
                        isVisible: { $0.isLogoUIEnabled }),
                ])
        )

        if let editor {
            self.categories = baseCategories.compactMap { category in
                guard category.isVisible?(editor) ?? true else { return nil }
                let visibleItems = category.items.filter { $0.isVisible?(editor) ?? true }
                guard !visibleItems.isEmpty else { return nil }
                return MenuCategory(
                    titleKey: category.titleKey, hotkeyChar: category.hotkeyChar, items: visibleItems,
                    isVisible: category.isVisible)
            }
        } else {
            self.categories = baseCategories
        }
        if categoryIndex >= categories.count {
            categoryIndex = max(0, categories.count - 1)
        }
        itemIndex = min(itemIndex, max(0, currentCategory.items.count - 1))
    }

    var currentCategory: MenuCategory {
        categories[categoryIndex]
    }

    var currentItem: MenuItem? {
        let items = currentCategory.items
        guard itemIndex >= 0 && itemIndex < items.count else { return nil }
        return items[itemIndex]
    }
}
