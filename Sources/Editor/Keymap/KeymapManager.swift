import Config
import Foundation

/// Manages layered keymaps (Base Keymap + Mode Overlays) and Keymap Presets.
final class KeymapManager {
    private(set) var baseKeymap = Keymap()
    private(set) var modeKeymaps: [EditorMode: Keymap] = [:]
    private(set) var activePreset: KeymapPreset = .classic

    init(preset: KeymapPreset = .classic) {
        loadPreset(preset)
    }

    /// Loads an entire preset of default keybindings.
    func loadPreset(_ preset: KeymapPreset) {
        self.activePreset = preset
        baseKeymap.removeAll()
        modeKeymaps.removeAll()

        // 1. Load Universal / Base Keybindings
        loadBasePreset(preset)

        // 2. Load Mode Overlays (Table, Canvas, Prompt)
        loadModeOverlays(for: preset)
    }

    /// Binds a key to a command, optionally restricted to a specific mode overlay.
    func bind(key: Key, commandID: CommandID, mode: EditorMode? = nil) {
        if let mode {
            var map = modeKeymaps[mode, default: Keymap()]
            map.bind(key: key, to: commandID)
            modeKeymaps[mode] = map
        } else {
            baseKeymap.bind(key: key, to: commandID)
        }
    }

    /// Unbinds a key, optionally restricted to a specific mode overlay.
    func unbind(key: Key, mode: EditorMode? = nil) {
        if let mode {
            modeKeymaps[mode]?.unbind(key: key)
        } else {
            baseKeymap.unbind(key: key)
            for m in EditorMode.allCases {
                modeKeymaps[m]?.unbind(key: key)
            }
        }
    }

    /// Resolves a Key event to a CommandID based on the active mode (Mode Overlay -> Base Keymap).
    func resolve(key: Key, in mode: EditorMode) -> CommandID? {
        if let cmd = modeKeymaps[mode]?.resolve(key: key) {
            return cmd
        }
        return baseKeymap.resolve(key: key)
    }

    /// Returns the primary shortcut key for a command in the given mode.
    func shortcut(for commandID: CommandID, in mode: EditorMode = .text) -> Key? {
        if let modeKey = modeKeymaps[mode]?.shortcut(for: commandID) {
            return modeKey
        }
        return baseKeymap.shortcut(for: commandID)
    }

    /// Returns the display label for a command's shortcut key in the given mode.
    func shortcutLabel(for commandID: CommandID, in mode: EditorMode = .text) -> String? {
        shortcut(for: commandID, in: mode)?.helpBarLabel
    }

    /// Backwards compatible alias for shortcutLabel
    func primaryKeyLabel(for commandID: CommandID, in mode: EditorMode) -> String? {
        shortcutLabel(for: commandID, in: mode)
    }

    /// Returns the keys associated with a command in the given mode.
    func keys(for commandID: CommandID, in mode: EditorMode = .text) -> [Key] {
        if let modeMap = modeKeymaps[mode] {
            let modeKeys = modeMap.keys(for: commandID)
            if !modeKeys.isEmpty {
                return modeKeys
            }
        }
        return baseKeymap.keys(for: commandID)
    }

    // MARK: - Private Registration Helpers

    private func register(_ commandID: CommandID, _ keys: Key..., mode: EditorMode? = nil) {
        register(commandID, keys: keys, mode: mode)
    }

    private func register(_ commandID: CommandID, keys: [Key], mode: EditorMode? = nil) {
        if let mode {
            var map = modeKeymaps[mode, default: Keymap()]
            map.register(commandID, keys: keys)
            modeKeymaps[mode] = map
        } else {
            baseKeymap.register(commandID, keys: keys)
        }
    }

    private func loadBasePreset(_ preset: KeymapPreset) {
        // Universal Navigation
        register(.moveWordBackward, .ctrlArrowLeft, .ctrlShift("B"), .ctrlShift("b"), .alt("B"), .alt("b"))
        register(.moveWordForward, .ctrlArrowRight, .ctrlShift("F"), .ctrlShift("f"), .alt("F"), .alt("f"))

        // Selection (Shift + Navigation)
        register(.selectLeft, .shiftArrowLeft)
        register(.selectRight, .shiftArrowRight)
        register(.selectUp, .shiftArrowUp)
        register(.selectDown, .shiftArrowDown)
        register(.selectHome, .shiftHome)
        register(.selectEnd, .shiftEnd)
        register(.selectPgup, .shiftPageUp)
        register(.selectPgdn, .shiftPageDown)
        register(.selectWordBackward, .ctrlShiftArrowLeft)
        register(.selectWordForward, .ctrlShiftArrowRight)

        // Common UI, Dialogs & Actions
        register(.macroLogo, .esc, .alt(":"))
        register(.editDelete, .delete, .ctrl("D"), .ctrl("d"))
        register(.editDeleteLine, .ctrlBackspace, .altBackspace)
        register(.editBacktab, .backtab)
        register(.tableToggle, .f7, .alt("T"), .alt("t"))
        register(.canvasToggle, .f8, .alt("V"), .alt("v"))
        register(.borderStyle, .alt("S"), .alt("s"))
        register(.editMark, .ctrl("^"), .mark)
        register(.logoOutput, .alt("L"), .alt("l"))
        register(.logoCanvas, .alt("C"), .alt("c"))
        register(.editToggleComment, .ctrl("/"))
        register(.editJoinLine, .alt("J"), .alt("j"))
        register(.editSplitLine, .alt("K"), .alt("k"))
        register(.bufferNext, .alt("."), .alt(">"))
        register(.bufferPrev, .alt(","), .alt("<"))
        register(.documentOpenLink, .alt("O"), .alt("o"))
        register(.documentOutline, .alt("\\"))
        register(.documentHeadingNext, .alt("]"))
        register(.documentHeadingPrevious, .alt("["))
        register(.cursorGotoLine, .alt("/"), .alt("G"), .alt("g"), .ctrl("_"))
        register(.proposalAccept, .alt("A"), .alt("a"))
        register(.proposalReject, .alt("R"), .alt("r"))
        register(.proposalNext, .alt("P"))
        register(.proposalPrev, .alt("p"))

        switch preset {
        case .classic:
            // Navigation
            register(.moveRight, .ctrl("F"), .ctrl("f"), .arrowRight)
            register(.moveLeft, .ctrl("B"), .ctrl("b"), .arrowLeft)
            register(.moveUp, .ctrl("P"), .ctrl("p"), .arrowUp)
            register(.moveDown, .ctrl("N"), .ctrl("n"), .arrowDown)
            register(.moveHome, .ctrl("A"), .ctrl("a"), .home)
            register(.moveEnd, .ctrl("E"), .ctrl("e"), .end)
            register(.movePgdn, .ctrl("V"), .ctrl("v"), .pageDown)
            register(.movePgup, .ctrl("Y"), .ctrl("y"), .pageUp)

            // Editing & Clipboard
            register(.editDelete, .ctrl("D"), .ctrl("d"), .delete)
            register(.editCut, .ctrl("K"), .ctrl("k"), .f9)
            register(.editUncut, .ctrl("U"), .ctrl("u"), .f10)
            register(.editTab, .ctrl("I"), .ctrl("i"), .tab)
            register(.editUndo, .ctrl("Z"), .ctrl("z"), .alt("U"), .alt("u"))
            register(.editRedo, .ctrlShift("Z"), .ctrlShift("z"), .alt("E"), .alt("e"))
            register(.editCopy, .alt("W"), .alt("w"))
            register(.editJustify, .ctrl("J"), .ctrl("j"))
            register(.editEvalLogo, .ctrl("Q"), .ctrl("q"))
            register(.editCancelSelection, .ctrl("G"), .ctrl("g"))

            // Files & Buffers
            register(.fileSave, .ctrl("S"), .ctrl("s"))
            register(.fileWriteOut, .ctrl("O"), .ctrl("o"), .f3)
            register(.fileInsert, .ctrl("R"), .ctrl("r"), .f5)
            register(.fileExit, .ctrl("X"), .ctrl("x"), .f2)
            register(.fileSaveExit, .f4)
            register(.fileRunLogo, .f5)
            register(.bufferNew, .ctrl("N"), .ctrl("n"))
            register(.screenRefresh, .ctrl("L"), .ctrl("l"))

            // Search & Tools
            register(.searchWhereIs, .ctrl("W"), .ctrl("w"), .f6)
            register(.searchReplace, .ctrl("\\"), .alt("R"), .alt("r"))
            register(.searchNext, .alt("N"), .alt("n"))
            register(.searchPrevious, .alt("P"), .alt("p"))
            register(.cursorGotoLine, .alt("G"), .alt("g"), .ctrl("_"))
            register(.cursorPos, .ctrl("C"), .ctrl("c"), .f11)
            register(.editSpell, .ctrl("T"), .ctrl("t"), .f12)

            // UI
            register(.menuShow, .f1, .alt("M"), .alt("m"), .ctrl("M"), .ctrl("m"))

        case .modern:
            // Navigation
            register(.moveRight, .arrowRight)
            register(.moveLeft, .arrowLeft)
            register(.moveUp, .arrowUp)
            register(.moveDown, .arrowDown)
            register(.moveHome, .home)
            register(.moveEnd, .end)
            register(.movePgdn, .pageDown)
            register(.movePgup, .pageUp)

            // Editing & Clipboard
            register(.editDelete, .delete)
            register(.editCut, .ctrl("X"), .ctrl("x"), .f9, .ctrl("K"), .ctrl("k"))
            register(.editCopy, .ctrl("C"), .ctrl("c"))
            register(.editUncut, .ctrl("V"), .ctrl("v"), .f10, .ctrl("U"), .ctrl("u"))
            register(.editUndo, .ctrl("Z"), .ctrl("z"))
            register(.editRedo, .ctrl("Y"), .ctrl("y"), .ctrlShift("Z"), .ctrlShift("z"))
            register(.selectAll, .ctrl("A"), .ctrl("a"))
            register(.editTab, .tab)
            register(.editCancelSelection, .ctrl("G"), .ctrl("g"))

            // Files & Buffers
            register(.fileSave, .ctrl("S"), .ctrl("s"))
            register(.fileWriteOut, .ctrl("O"), .ctrl("o"))
            register(.fileExit, .ctrl("Q"), .ctrl("q"), .ctrl("W"), .ctrl("w"))
            register(.fileSaveExit, .f4)
            register(.fileRunLogo, .f5)
            register(.bufferNew, .ctrl("N"), .ctrl("n"))
            register(.screenRefresh, .ctrl("L"), .ctrl("l"))

            // Search & Tools
            register(.searchWhereIs, .ctrl("F"), .ctrl("f"), .f3)
            register(.searchReplace, .ctrl("H"), .ctrl("h"))
            register(.searchNext, .f3, .alt("N"), .alt("n"))
            register(.searchPrevious, .alt("P"), .alt("p"))
            register(.cursorGotoLine, .ctrl("G"), .ctrl("g"), .alt("G"), .alt("g"))
            register(.editJustify, .ctrl("J"), .ctrl("j"))
            register(.editEvalLogo, .ctrl("E"), .ctrl("e"))
            register(.editSpell, .ctrl("T"), .ctrl("t"), .f12)
            register(.cursorPos, .f11, .alt("C"), .alt("c"), .ctrlShift("C"), .ctrlShift("c"))

            // UI
            register(.menuShow, .f1)
        }
    }

    private func loadModeOverlays(for preset: KeymapPreset) {
        // Table Mode Overlays
        register(.tableNextCell, .tab, mode: .table)
        register(.tablePrevCell, .backtab, mode: .table)
        register(.tableAdjustWidthInc, .ctrlShiftArrowRight, mode: .table)
        register(.tableAdjustWidthDec, .ctrlShiftArrowLeft, mode: .table)
        register(.tableAdjustHeightInc, .ctrlShiftArrowDown, mode: .table)
        register(.tableAdjustHeightDec, .ctrlShiftArrowUp, mode: .table)
        register(.tableCellStart, .home, mode: .table)
        register(.tableCellEnd, .end, mode: .table)
        register(.tableCenterText, .ctrl("J"), .ctrl("j"), mode: .table)
        register(.tableClearCell, .ctrl("K"), .ctrl("k"), .f9, mode: .table)

        // Canvas Mode Overlays
        register(.canvasDrawLine, .shiftArrowRight, .shiftArrowLeft, .shiftArrowUp, .shiftArrowDown, mode: .canvas)
        register(
            .canvasDrawArrow, .ctrlShiftArrowRight, .ctrlShiftArrowLeft, .ctrlShiftArrowUp, .ctrlShiftArrowDown,
            mode: .canvas)
        register(.editMark, .alt("B"), .alt("b"), .ctrl("^"), .mark, mode: .canvas)

        switch preset {
        case .classic:
            register(.editCut, .ctrl("K"), .ctrl("k"), mode: .canvas)
            register(.editCopy, .alt("W"), .alt("w"), mode: .canvas)
            register(.editUncut, .ctrl("U"), .ctrl("u"), mode: .canvas)

        case .modern:
            register(.editCut, .ctrl("X"), .ctrl("x"), .ctrl("K"), .ctrl("k"), mode: .canvas)
            register(.editCopy, .ctrl("C"), .ctrl("c"), .alt("W"), .alt("w"), mode: .canvas)
            register(.editUncut, .ctrl("U"), .ctrl("u"), mode: .canvas)
        }

        // Canvas mode keeps ^Y/^V as page navigation in every keymap preset.
        register(.movePgup, .ctrl("Y"), .ctrl("y"), mode: .canvas)
        register(.movePgdn, .ctrl("V"), .ctrl("v"), mode: .canvas)

        // Prompt Mode Overlays
        register(.promptConfirm, .enter, mode: .prompt)
        register(.promptComplete, .tab, mode: .prompt)
        register(.promptHistoryPrev, .arrowUp, mode: .prompt)
        register(.promptHistoryNext, .arrowDown, mode: .prompt)
        register(.promptClearLine, .ctrlBackspace, .altBackspace, mode: .prompt)
        register(.selectLeft, .shiftArrowLeft, .ctrlShiftArrowLeft, .ctrlShift("B"), .ctrlShift("b"), mode: .prompt)
        register(.selectRight, .shiftArrowRight, .ctrlShiftArrowRight, .ctrlShift("F"), .ctrlShift("f"), mode: .prompt)

        switch preset {
        case .classic:
            register(.promptCancel, .esc, .ctrl("G"), .ctrl("g"), .ctrl("C"), .ctrl("c"), mode: .prompt)
            register(.editCut, .ctrl("K"), .ctrl("k"), mode: .prompt)
            register(.editCopy, .alt("W"), .alt("w"), mode: .prompt)
            register(.editUncut, .ctrl("U"), .ctrl("u"), mode: .prompt)
            register(.moveHome, .ctrl("A"), .ctrl("a"), .home, mode: .prompt)
            register(.moveEnd, .ctrl("E"), .ctrl("e"), .end, mode: .prompt)

        case .modern:
            register(.promptCancel, .esc, .ctrl("G"), .ctrl("g"), mode: .prompt)
            register(.editCut, .ctrl("X"), .ctrl("x"), mode: .prompt)
            register(.editCopy, .ctrl("C"), .ctrl("c"), mode: .prompt)
            register(.editUncut, .ctrl("V"), .ctrl("v"), mode: .prompt)
            register(.selectAll, .ctrl("A"), .ctrl("a"), mode: .prompt)
            register(.moveHome, .home, mode: .prompt)
            register(.moveEnd, .end, mode: .prompt)
        }
    }
}
