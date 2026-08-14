import Foundation
import Config

/// Manages layered keybindings (Base Keymap + Mode Overlays) and Keymap Presets.
public final class KeymapManager {
    public private(set) var baseKeymap: [Key: CommandID] = [:]
    public private(set) var modeKeymaps: [EditorMode: [Key: CommandID]] = [:]
    public private(set) var primaryDisplayKeys: [CommandID: Key] = [:]
    public private(set) var activePreset: KeymapPreset = .classic

    public init(preset: KeymapPreset = .classic) {
        loadPreset(preset)
    }

    /// Loads an entire preset of default keybindings.
    public func loadPreset(_ preset: KeymapPreset) {
        self.activePreset = preset
        baseKeymap.removeAll()
        modeKeymaps.removeAll()
        primaryDisplayKeys.removeAll()

        // 1. Load Universal / Base Keybindings
        loadBasePreset(preset)

        // 2. Load Mode Overlays (Table, Canvas, Prompt, Menu)
        loadModeOverlays()
    }

    /// Binds a key to a command, optionally restricted to a specific mode overlay.
    public func bind(key: Key, commandID: CommandID, mode: EditorMode? = nil) {
        primaryDisplayKeys[commandID] = key
        if let mode {
            var map = modeKeymaps[mode, default: [:]]
            map[key] = commandID
            modeKeymaps[mode] = map
        } else {
            baseKeymap[key] = commandID
        }
    }

    /// Unbinds a key, optionally restricted to a specific mode overlay.
    public func unbind(key: Key, mode: EditorMode? = nil) {
        if let mode {
            modeKeymaps[mode]?.removeValue(forKey: key)
        } else {
            baseKeymap.removeValue(forKey: key)
            for m in EditorMode.allCases {
                modeKeymaps[m]?.removeValue(forKey: key)
            }
        }
        for (cmd, k) in primaryDisplayKeys where k == key {
            primaryDisplayKeys.removeValue(forKey: cmd)
        }
    }

    /// Resolves a Key event to a CommandID based on the active mode (Mode Overlay -> Base Keymap).
    public func resolve(key: Key, in mode: EditorMode) -> CommandID? {
        if let cmd = modeKeymaps[mode]?[key] {
            return cmd
        }
        return baseKeymap[key]
    }

    /// Reverse lookup: Finds the primary key label for a CommandID in a given mode.
    public func primaryKeyLabel(for commandID: CommandID, in mode: EditorMode) -> String? {
        // 1. Check mode-specific overlay
        if let modeKey = modeKeymaps[mode]?.first(where: { $0.value == commandID })?.key {
            let label = modeKey.helpBarLabel
            if !label.isEmpty { return label }
        }
        // 2. Check canonical primary key
        if let primaryKey = primaryDisplayKeys[commandID] {
            let label = primaryKey.helpBarLabel
            if !label.isEmpty { return label }
        }
        // 3. Check base keymap
        if let baseKey = baseKeymap.first(where: { $0.value == commandID })?.key {
            let label = baseKey.helpBarLabel
            if !label.isEmpty { return label }
        }
        return nil
    }

    // MARK: - Private Setup Helpers

    private func loadBasePreset(_ preset: KeymapPreset) {
        // Navigation (common across both presets)
        baseKeymap[.arrowUp] = .moveUp
        baseKeymap[.arrowDown] = .moveDown
        baseKeymap[.arrowLeft] = .moveLeft
        baseKeymap[.arrowRight] = .moveRight
        baseKeymap[.home] = .moveHome
        baseKeymap[.end] = .moveEnd
        baseKeymap[.pageUp] = .movePgup
        baseKeymap[.pageDown] = .movePgdn
        baseKeymap[.ctrlArrowLeft] = .moveWordBackward
        baseKeymap[.ctrlArrowRight] = .moveWordForward

        // Selection (Shift + Navigation)
        baseKeymap[.shiftArrowLeft] = .selectLeft
        baseKeymap[.shiftArrowRight] = .selectRight
        baseKeymap[.shiftArrowUp] = .selectUp
        baseKeymap[.shiftArrowDown] = .selectDown
        baseKeymap[.shiftHome] = .selectHome
        baseKeymap[.shiftEnd] = .selectEnd
        baseKeymap[.ctrlShiftArrowLeft] = .selectWordBackward
        baseKeymap[.ctrlShiftArrowRight] = .selectWordForward

        // Editing & UI (common across both presets)
        baseKeymap[.delete] = .editDelete
        baseKeymap[.ctrl("d")] = .editDelete
        baseKeymap[.ctrl("D")] = .editDelete
        baseKeymap[.ctrlBackspace] = .editDeleteLine
        baseKeymap[.tab] = .editTab
        baseKeymap[.backtab] = .editBacktab
        baseKeymap[.f1] = .menuShow
        baseKeymap[.ctrl("m")] = .menuShow
        baseKeymap[.ctrl("M")] = .menuShow
        baseKeymap[.f7] = .tableToggle
        baseKeymap[.f8] = .canvasToggle
        baseKeymap[.ctrl("/")] = .editToggleComment
        baseKeymap[.alt("b")] = .editMark
        baseKeymap[.alt("B")] = .editMark
        baseKeymap[.mark] = .editMark
        baseKeymap[.alt("j")] = .editJustify
        baseKeymap[.alt("J")] = .editJustify
        baseKeymap[.ctrl("j")] = .editJustify
        baseKeymap[.ctrl("J")] = .editJustify
        baseKeymap[.alt("w")] = .editCopy
        baseKeymap[.alt("W")] = .editCopy

        // AI Proposal bindings
        baseKeymap[.alt("a")] = .proposalAccept
        baseKeymap[.alt("A")] = .proposalAccept
        baseKeymap[.alt("r")] = .proposalReject
        baseKeymap[.alt("R")] = .proposalReject
        baseKeymap[.alt("p")] = .proposalNext
        baseKeymap[.alt("P")] = .proposalPrev

        // Document headings
        baseKeymap[.alt("]")] = .documentHeadingNext
        baseKeymap[.alt("[")] = .documentHeadingPrevious
        baseKeymap[.alt("\\")] = .documentOutline

        // Cursor & Goto
        baseKeymap[.alt("/")] = .cursorGotoLine
        baseKeymap[.alt("g")] = .cursorGotoLine
        baseKeymap[.alt("G")] = .cursorGotoLine
        baseKeymap[.ctrl("_")] = .cursorGotoLine

        primaryDisplayKeys[.menuShow] = .f1
        primaryDisplayKeys[.tableToggle] = .f7
        primaryDisplayKeys[.canvasToggle] = .f8
        primaryDisplayKeys[.borderStyle] = .alt("S")
        primaryDisplayKeys[.proposalAccept] = .alt("A")
        primaryDisplayKeys[.proposalReject] = .alt("R")
        primaryDisplayKeys[.proposalNext] = .alt("P")
        primaryDisplayKeys[.proposalPrev] = .alt("P")

        switch preset {
        case .classic:
            // Classic GNU Nano shortcuts
            baseKeymap[.ctrl("s")] = .fileSave
            baseKeymap[.ctrl("S")] = .fileSave
            baseKeymap[.ctrl("o")] = .fileWriteOut
            baseKeymap[.ctrl("O")] = .fileWriteOut
            baseKeymap[.f3] = .fileWriteOut
            baseKeymap[.ctrl("r")] = .fileInsert
            baseKeymap[.ctrl("R")] = .fileInsert
            baseKeymap[.f5] = .fileRunLogo
            baseKeymap[.ctrl("x")] = .fileExit
            baseKeymap[.ctrl("X")] = .fileExit
            baseKeymap[.f2] = .fileExit

            baseKeymap[.ctrl("w")] = .searchWhereIs
            baseKeymap[.ctrl("W")] = .searchWhereIs
            baseKeymap[.f6] = .searchWhereIs
            baseKeymap[.alt("n")] = .searchNext
            baseKeymap[.alt("N")] = .searchNext
            baseKeymap[.alt("p")] = .searchPrevious

            baseKeymap[.ctrl("k")] = .editCut
            baseKeymap[.ctrl("K")] = .editCut
            baseKeymap[.ctrl("u")] = .editUncut
            baseKeymap[.ctrl("U")] = .editUncut

            baseKeymap[.alt("u")] = .editUndo
            baseKeymap[.alt("U")] = .editUndo
            baseKeymap[.ctrl("z")] = .editUndo
            baseKeymap[.ctrl("Z")] = .editUndo
            baseKeymap[.alt("e")] = .editRedo
            baseKeymap[.alt("E")] = .editRedo
            baseKeymap[.ctrl("y")] = .editRedo
            baseKeymap[.ctrl("Y")] = .editRedo

            baseKeymap[.ctrl("a")] = .moveHome
            baseKeymap[.ctrl("A")] = .moveHome
            baseKeymap[.ctrl("e")] = .moveEnd
            baseKeymap[.ctrl("E")] = .moveEnd
            baseKeymap[.ctrl("p")] = .moveUp
            baseKeymap[.ctrl("P")] = .moveUp
            baseKeymap[.ctrl("n")] = .moveDown
            baseKeymap[.ctrl("N")] = .moveDown
            baseKeymap[.ctrl("b")] = .moveLeft
            baseKeymap[.ctrl("B")] = .moveLeft
            baseKeymap[.ctrl("f")] = .moveRight
            baseKeymap[.ctrl("F")] = .moveRight

            baseKeymap[.ctrl("q")] = .editEvalLogo
            baseKeymap[.ctrl("Q")] = .editEvalLogo
            baseKeymap[.ctrl("c")] = .cursorPos
            baseKeymap[.ctrl("C")] = .cursorPos
            baseKeymap[.ctrl("t")] = .editSpell
            baseKeymap[.ctrl("T")] = .editSpell
            baseKeymap[.f11] = .cursorPos
            baseKeymap[.f12] = .editSpell

            primaryDisplayKeys[.fileSave] = .ctrl("S")
            primaryDisplayKeys[.fileWriteOut] = .ctrl("O")
            primaryDisplayKeys[.fileInsert] = .ctrl("R")
            primaryDisplayKeys[.fileExit] = .ctrl("X")
            primaryDisplayKeys[.searchWhereIs] = .ctrl("W")
            primaryDisplayKeys[.searchNext] = .alt("N")
            primaryDisplayKeys[.searchPrevious] = .alt("P")
            primaryDisplayKeys[.editCut] = .ctrl("K")
            primaryDisplayKeys[.editUncut] = .ctrl("U")
            primaryDisplayKeys[.editUndo] = .ctrl("Z")
            primaryDisplayKeys[.editRedo] = .ctrl("Y")
            primaryDisplayKeys[.editCopy] = .alt("W")
            primaryDisplayKeys[.editJustify] = .ctrl("J")
            primaryDisplayKeys[.editSpell] = .ctrl("T")
            primaryDisplayKeys[.cursorPos] = .ctrl("C")
            primaryDisplayKeys[.editEvalLogo] = .ctrl("Q")
            primaryDisplayKeys[.movePgup] = .ctrl("Y")
            primaryDisplayKeys[.movePgdn] = .ctrl("V")
            primaryDisplayKeys[.helpShow] = .f1
            primaryDisplayKeys[.menuShow] = .f1

        case .modern:
            // VS Code / CUA modern shortcuts
            baseKeymap[.ctrl("s")] = .fileSave
            baseKeymap[.ctrl("S")] = .fileSave
            baseKeymap[.ctrl("q")] = .fileExit
            baseKeymap[.ctrl("Q")] = .fileExit
            baseKeymap[.ctrl("w")] = .fileExit
            baseKeymap[.ctrl("W")] = .fileExit

            baseKeymap[.ctrl("e")] = .editEvalLogo
            baseKeymap[.ctrl("E")] = .editEvalLogo

            baseKeymap[.ctrl("f")] = .searchWhereIs
            baseKeymap[.ctrl("F")] = .searchWhereIs
            baseKeymap[.f3] = .searchNext
            baseKeymap[.ctrl("h")] = .searchReplace
            baseKeymap[.ctrl("H")] = .searchReplace
            baseKeymap[.alt("n")] = .searchNext
            baseKeymap[.alt("N")] = .searchNext
            baseKeymap[.alt("p")] = .searchPrevious

            baseKeymap[.ctrl("z")] = .editUndo
            baseKeymap[.ctrl("Z")] = .editUndo
            baseKeymap[.ctrl("y")] = .editRedo
            baseKeymap[.ctrl("Y")] = .editRedo
            baseKeymap[.ctrlShift("z")] = .editRedo
            baseKeymap[.ctrlShift("Z")] = .editRedo

            baseKeymap[.ctrl("a")] = .selectAll
            baseKeymap[.ctrl("A")] = .selectAll

            baseKeymap[.ctrl("c")] = .editCopy
            baseKeymap[.ctrl("C")] = .editCopy
            baseKeymap[.ctrl("x")] = .editCut
            baseKeymap[.ctrl("X")] = .editCut
            baseKeymap[.ctrl("v")] = .editUncut
            baseKeymap[.ctrl("V")] = .editUncut

            baseKeymap[.ctrl("t")] = .editSpell
            baseKeymap[.ctrl("T")] = .editSpell
            baseKeymap[.alt("c")] = .cursorPos
            baseKeymap[.alt("C")] = .cursorPos
            baseKeymap[.ctrlShift("c")] = .cursorPos
            baseKeymap[.ctrlShift("C")] = .cursorPos

            baseKeymap[.ctrl("o")] = .fileWriteOut
            baseKeymap[.ctrl("O")] = .fileWriteOut
            baseKeymap[.ctrl("k")] = .editCut
            baseKeymap[.ctrl("K")] = .editCut
            baseKeymap[.ctrl("u")] = .editUncut
            baseKeymap[.ctrl("U")] = .editUncut

            baseKeymap[.f1] = .helpShow
            baseKeymap[.f11] = .cursorPos
            baseKeymap[.f12] = .editSpell
            baseKeymap[.pageUp] = .movePgup
            baseKeymap[.pageDown] = .movePgdn

            primaryDisplayKeys[.fileSave] = .ctrl("S")
            primaryDisplayKeys[.fileWriteOut] = .ctrl("O")
            primaryDisplayKeys[.fileExit] = .ctrl("Q")
            primaryDisplayKeys[.searchWhereIs] = .ctrl("F")
            primaryDisplayKeys[.searchNext] = .f3
            primaryDisplayKeys[.searchReplace] = .ctrl("H")
            primaryDisplayKeys[.editUndo] = .ctrl("Z")
            primaryDisplayKeys[.editRedo] = .ctrl("Y")
            primaryDisplayKeys[.selectAll] = .ctrl("A")
            primaryDisplayKeys[.editCut] = .ctrl("X")
            primaryDisplayKeys[.editCopy] = .ctrl("C")
            primaryDisplayKeys[.editUncut] = .ctrl("V")
            primaryDisplayKeys[.editEvalLogo] = .ctrl("E")
            primaryDisplayKeys[.editSpell] = .ctrl("T")
            primaryDisplayKeys[.cursorPos] = .f11
            primaryDisplayKeys[.movePgup] = .pageUp
            primaryDisplayKeys[.movePgdn] = .pageDown
            primaryDisplayKeys[.helpShow] = .f1
            primaryDisplayKeys[.menuShow] = .f1
        }
    }

    private func loadModeOverlays() {
        // Table Mode Overlays
        var table: [Key: CommandID] = [:]
        table[.tab] = .tableNextCell
        table[.backtab] = .tablePrevCell
        table[.ctrlShiftArrowRight] = .tableAdjustWidthInc
        table[.ctrlShiftArrowLeft] = .tableAdjustWidthDec
        table[.ctrlShiftArrowDown] = .tableAdjustHeightInc
        table[.ctrlShiftArrowUp] = .tableAdjustHeightDec
        table[.ctrl("j")] = .tableCenterText
        table[.ctrl("J")] = .tableCenterText
        table[.ctrl("k")] = .tableClearCell
        table[.ctrl("K")] = .tableClearCell
        table[.f9] = .tableClearCell
        table[.home] = .tableCellStart
        table[.end] = .tableCellEnd
        modeKeymaps[.table] = table

        // Canvas Mode Overlays
        var canvas: [Key: CommandID] = [:]
        canvas[.shiftArrowLeft] = .canvasDrawLine
        canvas[.shiftArrowRight] = .canvasDrawLine
        canvas[.shiftArrowUp] = .canvasDrawLine
        canvas[.shiftArrowDown] = .canvasDrawLine
        canvas[.ctrlShiftArrowLeft] = .canvasDrawArrow
        canvas[.ctrlShiftArrowRight] = .canvasDrawArrow
        canvas[.ctrlShiftArrowUp] = .canvasDrawArrow
        canvas[.ctrlShiftArrowDown] = .canvasDrawArrow
        canvas[.ctrl("k")] = .editCut
        canvas[.ctrl("K")] = .editCut
        canvas[.alt("w")] = .editCopy
        canvas[.alt("W")] = .editCopy
        canvas[.ctrl("u")] = .editUncut
        canvas[.ctrl("U")] = .editUncut
        canvas[.alt("b")] = .editMark
        canvas[.alt("B")] = .editMark
        canvas[.ctrl("^")] = .editMark
        canvas[.mark] = .editMark
        modeKeymaps[.canvas] = canvas

        // Prompt Mode Overlays
        var prompt: [Key: CommandID] = [:]
        prompt[.enter] = .promptConfirm
        prompt[.esc] = .promptCancel
        prompt[.tab] = .promptComplete
        prompt[.arrowUp] = .promptHistoryPrev
        prompt[.arrowDown] = .promptHistoryNext
        prompt[.ctrlBackspace] = .promptClearLine
        modeKeymaps[.prompt] = prompt
    }
}
