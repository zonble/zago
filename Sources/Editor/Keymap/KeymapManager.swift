import Foundation
import Config

/// Manages layered keybindings (Base Keymap + Mode Overlays) and Keymap Presets.
public final class KeymapManager {
    public private(set) var baseKeymap: [Key: CommandID] = [:]
    public private(set) var modeKeymaps: [EditorMode: [Key: CommandID]] = [:]
    public private(set) var primaryDisplayKeys: [CommandID: [Key]] = [:]
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
        loadModeOverlays(for: preset)
    }

    /// Binds a key to a command, optionally restricted to a specific mode overlay.
    public func bind(key: Key, commandID: CommandID, mode: EditorMode? = nil) {
        primaryDisplayKeys[commandID] = [key]
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
        for (cmd, keys) in primaryDisplayKeys {
            let remaining = keys.filter { $0 != key }
            if remaining.isEmpty {
                primaryDisplayKeys.removeValue(forKey: cmd)
            } else {
                primaryDisplayKeys[cmd] = remaining
            }
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
        // 1. Check if the active preset's primary display key is bound in this mode
        if let primaryKey = primaryDisplayKeys[commandID]?.first {
            if let modeKeys = modeKeymaps[mode], modeKeys[primaryKey] == commandID {
                let label = primaryKey.helpBarLabel
                if !label.isEmpty { return label }
            }
        }
        // 2. Check mode-specific overlay for mode-unique commands
        if let modeKey = modeKeymaps[mode]?.first(where: { $0.value == commandID })?.key {
            let label = modeKey.helpBarLabel
            if !label.isEmpty { return label }
        }
        // 3. Check canonical primary key
        if let primaryKey = primaryDisplayKeys[commandID]?.first {
            let label = primaryKey.helpBarLabel
            if !label.isEmpty { return label }
        }
        // 4. Check base keymap
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
        baseKeymap[.ctrlShift("b")] = .moveWordBackward
        baseKeymap[.ctrlShift("B")] = .moveWordBackward
        baseKeymap[.ctrlShift("f")] = .moveWordForward
        baseKeymap[.ctrlShift("F")] = .moveWordForward

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
        baseKeymap[.esc] = .macroLogo
        baseKeymap[.alt(":")] = .macroLogo
        baseKeymap[.delete] = .editDelete
        baseKeymap[.ctrl("d")] = .editDelete
        baseKeymap[.ctrl("D")] = .editDelete
        baseKeymap[.ctrlBackspace] = .editDeleteLine
        baseKeymap[.ctrl("h")] = .editDeleteLine
        baseKeymap[.ctrl("H")] = .editDeleteLine
        baseKeymap[.tab] = .editTab
        baseKeymap[.ctrl("i")] = .editTab
        baseKeymap[.ctrl("I")] = .editTab
        baseKeymap[.backtab] = .editBacktab
        baseKeymap[.f1] = .menuShow
        baseKeymap[.ctrl("m")] = .menuShow
        baseKeymap[.ctrl("M")] = .menuShow
        baseKeymap[.alt("m")] = .menuShow
        baseKeymap[.alt("M")] = .menuShow
        baseKeymap[.f7] = .tableToggle
        baseKeymap[.alt("t")] = .tableToggle
        baseKeymap[.alt("T")] = .tableToggle
        baseKeymap[.f8] = .canvasToggle
        baseKeymap[.alt("v")] = .canvasToggle
        baseKeymap[.alt("V")] = .canvasToggle
        baseKeymap[.alt("s")] = .borderStyle
        baseKeymap[.alt("S")] = .borderStyle
        baseKeymap[.alt("l")] = .logoOutput
        baseKeymap[.alt("L")] = .logoOutput
        baseKeymap[.alt("c")] = .logoCanvas
        baseKeymap[.alt("C")] = .logoCanvas
        baseKeymap[.ctrlShift("z")] = .editRedo
        baseKeymap[.ctrlShift("Z")] = .editRedo
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

        primaryDisplayKeys[.menuShow] = [.f1]
        primaryDisplayKeys[.tableToggle] = [.f7]
        primaryDisplayKeys[.canvasToggle] = [.alt("V"), .f8]
        primaryDisplayKeys[.borderStyle] = [.alt("S")]
        primaryDisplayKeys[.proposalAccept] = [.alt("A")]
        primaryDisplayKeys[.proposalReject] = [.alt("R")]
        primaryDisplayKeys[.proposalNext] = [.alt("P")]
        primaryDisplayKeys[.proposalPrev] = [.alt("P")]

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
            baseKeymap[.f9] = .editCut
            baseKeymap[.ctrl("u")] = .editUncut
            baseKeymap[.ctrl("U")] = .editUncut
            baseKeymap[.f10] = .editUncut
            baseKeymap[.f4] = .fileSaveExit
            baseKeymap[.f5] = .fileRunLogo

            baseKeymap[.ctrl("i")] = .editTab
            baseKeymap[.alt("j")] = .editJoinLine
            baseKeymap[.alt("J")] = .editJoinLine
            baseKeymap[.alt("k")] = .editSplitLine
            baseKeymap[.alt("K")] = .editSplitLine
            baseKeymap[.ctrl("g")] = .editCancelSelection
            baseKeymap[.ctrl("G")] = .editCancelSelection
            baseKeymap[.alt(".")] = .bufferNext
            baseKeymap[.alt(">")] = .bufferNext
            baseKeymap[.alt(",")] = .bufferPrev
            baseKeymap[.alt("<")] = .bufferPrev
            baseKeymap[.ctrl("n")] = .bufferNew
            baseKeymap[.ctrl("l")] = .screenRefresh
            baseKeymap[.ctrl("L")] = .screenRefresh
            baseKeymap[.alt("o")] = .documentOpenLink
            baseKeymap[.alt("O")] = .documentOpenLink

            baseKeymap[.alt("u")] = .editUndo
            baseKeymap[.alt("U")] = .editUndo
            baseKeymap[.ctrl("z")] = .editUndo
            baseKeymap[.ctrl("Z")] = .editUndo
            baseKeymap[.alt("e")] = .editRedo
            baseKeymap[.alt("E")] = .editRedo

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
            baseKeymap[.ctrl("v")] = .movePgdn
            baseKeymap[.ctrl("V")] = .movePgdn
            baseKeymap[.ctrl("y")] = .movePgup
            baseKeymap[.ctrl("Y")] = .movePgup

            baseKeymap[.ctrl("q")] = .editEvalLogo
            baseKeymap[.ctrl("Q")] = .editEvalLogo
            baseKeymap[.ctrl("c")] = .cursorPos
            baseKeymap[.ctrl("C")] = .cursorPos
            baseKeymap[.ctrl("t")] = .editSpell
            baseKeymap[.ctrl("T")] = .editSpell
            baseKeymap[.f11] = .cursorPos
            baseKeymap[.f12] = .editSpell

            primaryDisplayKeys[.moveRight] = [.ctrl("F"), .arrowRight]
            primaryDisplayKeys[.moveLeft] = [.ctrl("B"), .arrowLeft]
            primaryDisplayKeys[.moveUp] = [.ctrl("P"), .arrowUp]
            primaryDisplayKeys[.moveDown] = [.ctrl("N"), .arrowDown]
            primaryDisplayKeys[.moveHome] = [.ctrl("A"), .home]
            primaryDisplayKeys[.moveEnd] = [.ctrl("E"), .end]
            primaryDisplayKeys[.movePgdn] = [.ctrl("V"), .pageDown]
            primaryDisplayKeys[.movePgup] = [.ctrl("Y"), .pageUp]
            primaryDisplayKeys[.editDelete] = [.ctrl("D"), .delete]
            primaryDisplayKeys[.editCut] = [.ctrl("K"), .f9]
            primaryDisplayKeys[.editUncut] = [.ctrl("U"), .f10]
            primaryDisplayKeys[.editTab] = [.ctrl("I"), .tab]
            primaryDisplayKeys[.fileSave] = [.ctrl("S")]
            primaryDisplayKeys[.fileWriteOut] = [.ctrl("O"), .f3]
            primaryDisplayKeys[.fileInsert] = [.ctrl("R"), .f5]
            primaryDisplayKeys[.fileExit] = [.ctrl("X"), .f2]
            primaryDisplayKeys[.fileSaveExit] = [.f4]
            primaryDisplayKeys[.searchWhereIs] = [.ctrl("W"), .f6]
            primaryDisplayKeys[.searchNext] = [.alt("N")]
            primaryDisplayKeys[.searchPrevious] = [.alt("P")]
            primaryDisplayKeys[.cursorPos] = [.ctrl("C"), .f11]
            primaryDisplayKeys[.editSpell] = [.ctrl("T"), .f12]
            primaryDisplayKeys[.editUndo] = [.alt("U")]
            primaryDisplayKeys[.editRedo] = [.alt("E")]
            primaryDisplayKeys[.editCopy] = [.alt("W")]
            primaryDisplayKeys[.editJustify] = [.ctrl("J")]
            primaryDisplayKeys[.editEvalLogo] = [.ctrl("Q")]
            primaryDisplayKeys[.editJoinLine] = [.alt("J")]
            primaryDisplayKeys[.editSplitLine] = [.alt("K")]
            primaryDisplayKeys[.editCancelSelection] = [.ctrl("G")]
            primaryDisplayKeys[.bufferNew] = [.ctrl("N")]
            primaryDisplayKeys[.bufferNext] = [.alt(".")]
            primaryDisplayKeys[.bufferPrev] = [.alt(",")]
            primaryDisplayKeys[.screenRefresh] = [.ctrl("L")]
            primaryDisplayKeys[.documentOpenLink] = [.alt("O")]
            primaryDisplayKeys[.canvasDrawLine] = [.shiftArrowRight]
            primaryDisplayKeys[.canvasDrawArrow] = [.ctrlShiftArrowRight]
            primaryDisplayKeys[.documentOutline] = [.alt("\\")]
            primaryDisplayKeys[.menuShow] = [.f1, .alt("M"), .ctrl("M")]
            primaryDisplayKeys[.helpShow] = [.f1]

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
            baseKeymap[.f9] = .editCut
            baseKeymap[.ctrl("v")] = .editUncut
            baseKeymap[.ctrl("V")] = .editUncut
            baseKeymap[.f10] = .editUncut
            baseKeymap[.f4] = .fileSaveExit
            baseKeymap[.f5] = .fileRunLogo

            baseKeymap[.alt("j")] = .editJoinLine
            baseKeymap[.alt("J")] = .editJoinLine
            baseKeymap[.alt("k")] = .editSplitLine
            baseKeymap[.alt("K")] = .editSplitLine
            baseKeymap[.ctrl("g")] = .editCancelSelection
            baseKeymap[.ctrl("G")] = .editCancelSelection
            baseKeymap[.alt(".")] = .bufferNext
            baseKeymap[.alt(">")] = .bufferNext
            baseKeymap[.alt(",")] = .bufferPrev
            baseKeymap[.alt("<")] = .bufferPrev
            baseKeymap[.ctrl("l")] = .screenRefresh
            baseKeymap[.ctrl("L")] = .screenRefresh
            baseKeymap[.alt("o")] = .documentOpenLink
            baseKeymap[.alt("O")] = .documentOpenLink

            baseKeymap[.ctrl("t")] = .editSpell
            baseKeymap[.ctrl("T")] = .editSpell
            baseKeymap[.f12] = .editSpell
            baseKeymap[.alt("c")] = .cursorPos
            baseKeymap[.alt("C")] = .cursorPos
            baseKeymap[.f11] = .cursorPos
            baseKeymap[.ctrlShift("c")] = .cursorPos
            baseKeymap[.ctrlShift("C")] = .cursorPos
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

            primaryDisplayKeys[.moveRight] = [.arrowRight]
            primaryDisplayKeys[.moveLeft] = [.arrowLeft]
            primaryDisplayKeys[.moveUp] = [.arrowUp]
            primaryDisplayKeys[.moveDown] = [.arrowDown]
            primaryDisplayKeys[.moveHome] = [.home]
            primaryDisplayKeys[.moveEnd] = [.end]
            primaryDisplayKeys[.movePgdn] = [.pageDown]
            primaryDisplayKeys[.movePgup] = [.pageUp]
            primaryDisplayKeys[.editDelete] = [.delete]
            primaryDisplayKeys[.editCut] = [.ctrl("X"), .f9]
            primaryDisplayKeys[.editUncut] = [.ctrl("V"), .f10]
            primaryDisplayKeys[.editCopy] = [.ctrl("C")]
            primaryDisplayKeys[.editUndo] = [.ctrl("Z")]
            primaryDisplayKeys[.editRedo] = [.ctrl("Y")]
            primaryDisplayKeys[.selectAll] = [.ctrl("A")]
            primaryDisplayKeys[.editTab] = [.tab]
            primaryDisplayKeys[.fileSave] = [.ctrl("S")]
            primaryDisplayKeys[.fileWriteOut] = [.ctrl("O")]
            primaryDisplayKeys[.fileExit] = [.ctrl("Q")]
            primaryDisplayKeys[.fileSaveExit] = [.f4]
            primaryDisplayKeys[.searchWhereIs] = [.ctrl("F"), .f3]
            primaryDisplayKeys[.searchReplace] = [.ctrl("H")]
            primaryDisplayKeys[.editEvalLogo] = [.ctrl("E")]
            primaryDisplayKeys[.editSpell] = [.ctrl("T"), .f12]
            primaryDisplayKeys[.cursorPos] = [.f11, .alt("C")]
            primaryDisplayKeys[.editJoinLine] = [.alt("J")]
            primaryDisplayKeys[.editSplitLine] = [.alt("K")]
            primaryDisplayKeys[.editCancelSelection] = [.ctrl("G")]
            primaryDisplayKeys[.bufferNew] = [.ctrl("N")]
            primaryDisplayKeys[.bufferNext] = [.alt(".")]
            primaryDisplayKeys[.bufferPrev] = [.alt(",")]
            primaryDisplayKeys[.screenRefresh] = [.ctrl("L")]
            primaryDisplayKeys[.documentOpenLink] = [.alt("O")]
            primaryDisplayKeys[.canvasDrawLine] = [.shiftArrowRight]
            primaryDisplayKeys[.canvasDrawArrow] = [.ctrlShiftArrowRight]
            primaryDisplayKeys[.documentOutline] = [.alt("\\")]
            primaryDisplayKeys[.menuShow] = [.f1]
            primaryDisplayKeys[.helpShow] = [.f1]
        }
    }

    private func loadModeOverlays(for preset: KeymapPreset) {
        // Table Mode Overlays
        var table: [Key: CommandID] = [:]
        table[.tab] = .tableNextCell
        table[.backtab] = .tablePrevCell
        table[.ctrlShiftArrowRight] = .tableAdjustWidthInc
        table[.ctrlShiftArrowLeft] = .tableAdjustWidthDec
        table[.ctrlShiftArrowDown] = .tableAdjustHeightInc
        table[.ctrlShiftArrowUp] = .tableAdjustHeightDec
        table[.home] = .tableCellStart
        table[.end] = .tableCellEnd
        table[.ctrl("j")] = .tableCenterText
        table[.ctrl("J")] = .tableCenterText
        table[.ctrl("k")] = .tableClearCell
        table[.ctrl("K")] = .tableClearCell
        table[.f9] = .tableClearCell
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
        canvas[.alt("b")] = .editMark
        canvas[.alt("B")] = .editMark
        canvas[.ctrl("^")] = .editMark
        canvas[.mark] = .editMark

        switch preset {
        case .classic:
            canvas[.ctrl("k")] = .editCut
            canvas[.ctrl("K")] = .editCut
            canvas[.alt("w")] = .editCopy
            canvas[.alt("W")] = .editCopy
            canvas[.ctrl("u")] = .editUncut
            canvas[.ctrl("U")] = .editUncut

        case .modern:
            canvas[.ctrl("x")] = .editCut
            canvas[.ctrl("X")] = .editCut
            canvas[.ctrl("c")] = .editCopy
            canvas[.ctrl("C")] = .editCopy
            canvas[.ctrl("v")] = .editUncut
            canvas[.ctrl("V")] = .editUncut
            canvas[.ctrl("k")] = .editCut
            canvas[.ctrl("K")] = .editCut
            canvas[.ctrl("u")] = .editUncut
            canvas[.ctrl("U")] = .editUncut
            canvas[.alt("w")] = .editCopy
            canvas[.alt("W")] = .editCopy
        }
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

    /// Returns the keys associated with a command in the given mode.
    public func keys(for commandID: CommandID, in mode: EditorMode = .text) -> [Key] {
        if let modeKey = modeKeymaps[mode]?.first(where: { $0.value == commandID })?.key {
            return [modeKey]
        }
        if let displayKeys = primaryDisplayKeys[commandID], !displayKeys.isEmpty {
            return displayKeys
        }
        var result: [Key] = []
        let baseKeys = baseKeymap.filter { $0.value == commandID }.map(\.key)
        for key in baseKeys {
            if !result.contains(key) {
                result.append(key)
            }
        }
        return result
    }
}
