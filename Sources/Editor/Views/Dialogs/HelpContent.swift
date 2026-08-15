import Foundation
import TextMetrics

enum HelpContent {
    struct HelpItem: Sendable {
        let commandID: CommandID
        let descriptionKey: String
        let mode: EditorMode

        init(commandID: CommandID, descriptionKey: String? = nil, mode: EditorMode = .text) {
            self.commandID = commandID
            self.descriptionKey = descriptionKey ?? "command.\(commandID.rawValue).description"
            self.mode = mode
        }
    }

    enum SectionContent: Sendable {
        case items([HelpItem])
        case staticKeys(prefix: String, range: ClosedRange<Int>)
    }

    struct Section: Sendable {
        let titleKey: String
        let content: SectionContent

        init(titleKey: String, items: [HelpItem]) {
            self.titleKey = titleKey
            self.content = .items(items)
        }

        init(titleKey: String, itemPrefix: String, itemRange: ClosedRange<Int>) {
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
                HelpItem(commandID: .selectRight, descriptionKey: "command.select.extend.description"),
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
                HelpItem(commandID: .editMark, mode: .canvas),
            ]
        ),
        Section(
            titleKey: "helpview.sec_search",
            items: [
                HelpItem(commandID: .searchWhereIs),
                HelpItem(commandID: .searchReplace),
                HelpItem(commandID: .documentOpenLink),
                HelpItem(commandID: .documentOutline),
                HelpItem(commandID: .screenRefresh),
                HelpItem(commandID: .cursorPos),
                HelpItem(commandID: .editSpell),
                HelpItem(commandID: .editJustify),
                HelpItem(commandID: .editEvalLogo),
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
                HelpItem(commandID: .editMark, descriptionKey: "command.canvas.block_mark.description", mode: .canvas),
                HelpItem(commandID: .menuShow),
            ]
        ),
        Section(titleKey: "helpview.sec_set", itemPrefix: "helpview.set", itemRange: 1...23),
        Section(titleKey: "helpview.sec_logo", itemPrefix: "helpview.logo", itemRange: 1...9),
    ]

    static func lines(
        language: Language = .detectSystemLanguage(),
        keymapManager: KeymapManager? = nil
    ) -> [String] {
        [""] + sectionLines(language: language, keymapManager: keymapManager ?? KeymapManager(preset: .classic))
    }

    static func lines(editor: Editor) -> [String] {
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

    private static func sectionLines(language: Language, keymapManager: KeymapManager) -> [String] {
        sections.enumerated().flatMap { index, section in
            let title = L10n.string(section.titleKey, language: language)
            let itemLines: [String]
            switch section.content {
            case .staticKeys(let prefix, let range):
                itemLines = range.map { L10n.string("\(prefix)_\($0)", language: language) }
            case .items(let items):
                itemLines = items.map { item in
                    let keyLabel = formatHelpKeys(for: item.commandID, in: item.mode, keymapManager: keymapManager, language: language)
                    let desc = L10n.string(item.descriptionKey, language: language)
                    let padCount = keyLabel == L10n.string("key.ctrl_shift_arrow", language: language) && language == .zh_TW
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
