import Foundation
import TextMetrics

public enum HelpContent {
    public struct HelpItem: Sendable {
        public let commandID: CommandID?
        public let customKeyLabelKey: String?
        public let descriptionKey: String
        public let mode: EditorMode

        public init(commandID: CommandID, descriptionKey: String? = nil, mode: EditorMode = .text) {
            self.commandID = commandID
            self.customKeyLabelKey = nil
            self.descriptionKey = descriptionKey ?? "command.\(commandID.rawValue).description"
            self.mode = mode
        }

        public init(customKeyLabelKey: String, descriptionKey: String, mode: EditorMode = .text) {
            self.commandID = nil
            self.customKeyLabelKey = customKeyLabelKey
            self.descriptionKey = descriptionKey
            self.mode = mode
        }
    }

    public enum SectionContent: Sendable {
        case items([HelpItem])
        case staticKeys(prefix: String, range: ClosedRange<Int>)
    }

    public struct Section: Sendable {
        public let titleKey: String
        public let content: SectionContent

        public init(titleKey: String, items: [HelpItem]) {
            self.titleKey = titleKey
            self.content = .items(items)
        }

        public init(titleKey: String, itemPrefix: String, itemRange: ClosedRange<Int>) {
            self.titleKey = titleKey
            self.content = .staticKeys(prefix: itemPrefix, range: itemRange)
        }
    }

    private static let sections: [Section] = [
        Section(
            titleKey: "helpview.sec_nav",
            items: [
                HelpItem(commandID: .moveRight),
                HelpItem(commandID: .moveLeft),
                HelpItem(commandID: .moveUp),
                HelpItem(commandID: .moveDown),
                HelpItem(commandID: .moveHome),
                HelpItem(commandID: .moveEnd),
                HelpItem(commandID: .movePgdn),
                HelpItem(commandID: .movePgup),
            ]
        ),
        Section(
            titleKey: "helpview.sec_edit",
            items: [
                HelpItem(commandID: .editDelete),
                HelpItem(customKeyLabelKey: "help.keys.selection_extend", descriptionKey: "command.select.extend.description"),
                HelpItem(commandID: .editCut),
                HelpItem(commandID: .editUncut),
                HelpItem(commandID: .editTab),
                HelpItem(commandID: .editJoinLine),
                HelpItem(commandID: .editSplitLine),
            ]
        ),
        Section(
            titleKey: "helpview.sec_canvas",
            items: [
                HelpItem(commandID: .canvasToggle, mode: .canvas),
                HelpItem(commandID: .canvasDrawLine, mode: .canvas),
                HelpItem(commandID: .canvasDrawArrow, mode: .canvas),
                HelpItem(customKeyLabelKey: "help.keys.canvas_block_mark", descriptionKey: "command.canvas.block_mark.description", mode: .canvas),
            ]
        ),
        Section(
            titleKey: "helpview.sec_search",
            items: [
                HelpItem(commandID: .searchWhereIs),
                HelpItem(commandID: .documentOpenLink),
                HelpItem(customKeyLabelKey: "help.keys.document_outline", descriptionKey: "command.document.outline.description"),
                HelpItem(commandID: .screenRefresh),
                HelpItem(commandID: .cursorPos),
                HelpItem(commandID: .editSpell),
                HelpItem(commandID: .editJustify),
            ]
        ),
        Section(
            titleKey: "helpview.sec_file",
            items: [
                HelpItem(commandID: .fileSave),
                HelpItem(commandID: .fileInsert),
                HelpItem(commandID: .bufferNew),
                HelpItem(commandID: .bufferNext),
                HelpItem(commandID: .bufferPrev),
                HelpItem(commandID: .fileExit),
                HelpItem(commandID: .fileSaveExit),
                HelpItem(commandID: .editCancelSelection),
                HelpItem(customKeyLabelKey: "help.keys.canvas_block_mark_canvas", descriptionKey: "command.canvas.block_mark.description", mode: .canvas),
                HelpItem(commandID: .menuShow),
            ]
        ),
        Section(titleKey: "helpview.sec_set", itemPrefix: "helpview.set", itemRange: 1...14),
        Section(titleKey: "helpview.sec_logo", itemPrefix: "helpview.logo", itemRange: 1...9),
    ]

    public static func lines(
        language: Language = .detectSystemLanguage(),
        keymapManager: KeymapManager? = nil
    ) -> [String] {
        [""] + sectionLines(language: language, keymapManager: keymapManager ?? KeymapManager(preset: .classic))
    }

    public static func lines(editor: Editor) -> [String] {
        lines(language: editor.language, keymapManager: editor.keymapManager)
    }

    private static func label(for key: Key, language: Language) -> String {
        switch key {
        case .arrowRight: return L10n.string("key.arrow_right", language: language)
        case .arrowLeft: return L10n.string("key.arrow_left", language: language)
        case .arrowUp: return L10n.string("key.arrow_up", language: language)
        case .arrowDown: return L10n.string("key.arrow_down", language: language)
        case .shiftArrowLeft, .shiftArrowRight, .shiftArrowUp, .shiftArrowDown:
            return L10n.string("key.shift_arrow", language: language)
        case .ctrlShiftArrowLeft, .ctrlShiftArrowRight, .ctrlShiftArrowUp, .ctrlShiftArrowDown:
            return L10n.string("key.ctrl_shift_arrow", language: language)
        case .pageUp: return L10n.string("key.page_up", language: language)
        case .pageDown: return L10n.string("key.page_down", language: language)
        case .home: return L10n.string("key.home", language: language)
        case .end: return L10n.string("key.end", language: language)
        case .delete: return L10n.string("key.delete", language: language)
        case .tab: return L10n.string("key.tab", language: language)
        case .enter: return L10n.string("key.enter", language: language)
        case .esc: return L10n.string("key.esc", language: language)
        case .ctrl(let ch): return "^\(ch.uppercased())"
        case .alt(let ch): return "M+\(ch.uppercased())"
        case .ctrlShift(let ch): return "C+⇧+\(ch.uppercased())"
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        default: return key.helpBarLabel
        }
    }

    private static func formatHelpKeys(for commandID: CommandID, in mode: EditorMode, keymapManager: KeymapManager, language: Language) -> String {
        let isClassic = keymapManager.activePreset == .classic
        switch commandID {
        case .moveRight where isClassic:
            return L10n.string("help.keys.nav_right_classic", language: language)
        case .moveLeft where isClassic:
            return L10n.string("help.keys.nav_left_classic", language: language)
        case .moveUp where isClassic:
            return L10n.string("help.keys.nav_up_classic", language: language)
        case .moveDown where isClassic:
            return L10n.string("help.keys.nav_down_classic", language: language)
        case .moveHome where isClassic:
            return L10n.string("help.keys.nav_home_classic", language: language)
        case .moveEnd where isClassic:
            return L10n.string("help.keys.nav_end_classic", language: language)
        case .movePgdn where isClassic:
            return L10n.string("help.keys.nav_pgdn_classic", language: language)
        case .movePgup where isClassic:
            return L10n.string("help.keys.nav_pgup_classic", language: language)
        case .editDelete where isClassic:
            return L10n.string("help.keys.delete_classic", language: language)
        case .editCut:
            return isClassic
                ? L10n.string("help.keys.cut_classic", language: language)
                : L10n.string("help.keys.cut_modern", language: language)
        case .editUncut:
            return isClassic
                ? L10n.string("help.keys.uncut_classic", language: language)
                : L10n.string("help.keys.uncut_modern", language: language)
        case .editTab where isClassic:
            return L10n.string("help.keys.tab_classic", language: language)
        case .fileExit:
            return isClassic
                ? L10n.string("help.keys.exit_classic", language: language)
                : "^Q"
        case .cursorPos:
            return isClassic
                ? L10n.string("help.keys.cursor_pos_classic", language: language)
                : L10n.string("help.keys.cursor_pos_modern", language: language)
        case .editSpell where isClassic:
            return L10n.string("help.keys.spell_classic", language: language)
        case .fileWriteOut where isClassic:
            return L10n.string("help.keys.write_out_classic", language: language)
        case .fileInsert where isClassic:
            return L10n.string("help.keys.insert_file_classic", language: language)
        case .searchWhereIs:
            return isClassic
                ? L10n.string("help.keys.search_classic", language: language)
                : L10n.string("help.keys.search_modern", language: language)
        case .documentOutline:
            return L10n.string("help.keys.document_outline", language: language)
        case .menuShow:
            return L10n.string("help.keys.menu_show", language: language)
        case .canvasDrawArrow:
            return L10n.string("help.keys.canvas_draw_arrow", language: language)
        case .canvasDrawLine:
            return L10n.string("help.keys.canvas_draw_line", language: language)
        default:
            let keys = keymapManager.keys(for: commandID, in: mode)
            var labels: [String] = []
            for key in keys {
                let lbl = label(for: key, language: language)
                if !lbl.isEmpty && !labels.contains(lbl) {
                    labels.append(lbl)
                }
            }
            return labels.joined(separator: " / ")
        }
    }

    private static func sectionLines(language: Language, keymapManager: KeymapManager) -> [String] {
        sections.enumerated().flatMap { index, section in
            let title = L10n.string(section.titleKey, language: language)
            let itemLines: [String]
            switch section.content {
            case .staticKeys(let prefix, let range):
                itemLines = range.map { L10n.string("\(prefix)_\($0)", language: language) }
            case .items(let items):
                itemLines = items.map { item in
                    let keyLabel: String
                    if let customKey = item.customKeyLabelKey {
                        keyLabel = L10n.string(customKey, language: language)
                    } else if let cmdID = item.commandID {
                        keyLabel = formatHelpKeys(for: cmdID, in: item.mode, keymapManager: keymapManager, language: language)
                    } else {
                        keyLabel = ""
                    }
                    let desc = L10n.string(item.descriptionKey, language: language)
                    let padCount = keyLabel == L10n.string("help.keys.canvas_draw_arrow", language: language) && language == .zh_TW
                        ? 2
                        : max(1, 19 - keyLabel.displayWidth)
                    let paddedKey = keyLabel + String(repeating: " ", count: padCount)
                    return "    \(paddedKey)\(desc)"
                }
            }
            let lines = [title] + itemLines
            return index == sections.indices.last ? lines : lines + [""]
        }
    }
}
