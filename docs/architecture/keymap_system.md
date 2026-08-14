# Mode-Aware Keymap System & Dynamic Help Bar Architecture

This document specifies the architecture for **Mode-Aware Keymap Management**, **Command-Driven Input Dispatching**, **Alternative Keymap Presets** (Classic vs. Modern), and **Dynamic Help Bar Synchronization** in `zago`.

---

## 1. Motivation & Architectural Goals

### Problems with Previous Architecture
1. **Hardcoded Controller Key Handlers**: Controllers (`PromptController`, `TableModeController`, `SearchController`) directly matched raw `Key` values in local `switch` statements (e.g. intercepting `^A`, `^E`, `^W`, `^K`, `^U`), preventing user customization and causing conflicts with alternative keymaps.
2. **Decoupled Help Bar**: The Help Bar displayed static strings from localization files (`^O WriteOut`, `^W Where Is`), which did not reflect remapped keys or modern keybinding presets.
3. **Lack of Keymap Presets**: Users wanting standard modern shortcuts (`^S` save, `^F` find, `^Z` undo, `^Q` exit) had to manually rebind every key individually in `.zagorc`.

### Architectural Goals
1. **Mode-First Layered Resolution**: Identify the active editor mode first, then resolve `Key -> CommandID` through a layered keymap (Mode Overlay -> Global Base).
2. **Full Command Decentralization**: All editing, navigation, and modal actions are represented by typed `CommandID`s.
3. **Dynamic Help Bar**: The Help Bar queries the active keymap dynamically (`primaryKeyLabel(for:in:)`) as the Single Source of Truth.
4. **First-Class Presets**: Support switching between `.classic` (Nano/WordStar) and `.modern` (VS Code / CUA) keybindings with a single configuration flag (`set modernbindings` or `set keymap modern`).

---

## 2. System Architecture & Dispatch Pipeline

```
                     ┌────────────────────────────────┐
                     │    Raw Key Event (from Stdin)  │
                     └────────────────┬───────────────┘
                                      │
                                      ▼
                     ┌────────────────────────────────┐
                     │ 1. Determine Active EditorMode │
                     │ (.prompt / .table / .canvas /  │
                     │  .menu / .text)                │
                     └────────────────┬───────────────┘
                                      │
                                      ▼
                     ┌────────────────────────────────┐
                     │ 2. Layered Keymap Lookup       │
                     │ 1st: Mode Overlay Keymap       │
                     │ 2nd: Global Base Keymap        │
                     └────────────────┬───────────────┘
                                      │
                      ┌───────────────┴───────────────┐
                      ▼                               ▼
             【 Command Found 】             【 No Command Found 】
                      │                               │
                      ▼                               ▼
       ┌──────────────────────────────┐ ┌──────────────────────────────┐
       │ Dispatch Command to Handler  │ │ Printable Character (.char)  │
       │ (Active Mode / CommandRegistry)│ (Passed to Mode's Text Input)│
       └──────────────────────────────┘ └──────────────────────────────┘
                      ▲
                      │ (Reverse Lookup)
       ┌──────────────────────────────┐
       │ Help Bar Renderer            │
       │ Queries primaryKeyLabel()    │
       └──────────────────────────────┘
```

---

## 3. Core Data Structures

### A. Editor Mode Identification (`EditorMode`)

```swift
public enum EditorMode: String, CaseIterable, Sendable, Hashable {
    case text       // Standard text buffer editing
    case canvas     // 2D grid canvas drawing & block selection
    case table      // Table cell navigation & column manipulation
    case prompt     // CommandBar input prompt & dialogs
    case menu       // Top dropdown menu bar active
}
```

### B. Layered Keymap (`KeymapManager`)

The keymap resolution engine manages two levels of tables:
1. **`baseKeymap: [Key: CommandID]`**: Universal bindings across all modes (e.g. `fileSave`, `fileExit`, `editUndo`, `menuShow`).
2. **`modeKeymaps: [EditorMode: [Key: CommandID]]`**: Context-specific overrides that take precedence when the corresponding mode is active.

```swift
public final class KeymapManager {
    public private(set) var baseKeymap: [Key: CommandID] = [:]
    public private(set) var modeKeymaps: [EditorMode: [Key: CommandID]] = [:]
    public var activePreset: KeymapPreset = .classic

    /// Resolves a Key event into a CommandID based on the active mode.
    public func resolve(key: Key, in mode: EditorMode) -> CommandID? {
        if let modeCommand = modeKeymaps[mode]?[key] {
            return modeCommand
        }
        return baseKeymap[key]
    }

    /// Finds the primary display shortcut for a command in a given mode.
    public func primaryKeyLabel(for commandID: CommandID, in mode: EditorMode) -> String? {
        if let modeKey = modeKeymaps[mode]?.first(where: { $0.value == commandID })?.key {
            return modeKey.helpBarLabel
        }
        if let baseKey = baseKeymap.first(where: { $0.value == commandID })?.key {
            return baseKey.helpBarLabel
        }
        return nil
    }
}
```

---

## 4. Keymap Presets

### Preset Matrix

| Action | `CommandID` | `.classic` (Nano/WordStar) | `.modern` (VS Code / CUA) |
| :--- | :--- | :--- | :--- |
| **Save File** | `.fileSave` | `^S` | `^S` |
| **Write Out (Prompt)** | `.fileWriteOut` | `^O`, `F3` | `^O`, `F3` |
| **Search / Find** | `.searchWhereIs` | `^W`, `F6` | `^F`, `F6` |
| **Search Next** | `.searchNext` | `M-N` | `F3`, `^G`, `M-N` |
| **Replace** | `.searchReplace` | `^\`, `F14` | `^H`, `F14` |
| **Undo** | `.editUndo` | `M-U`, `^Z` | `^Z`, `M-U` |
| **Redo** | `.editRedo` | `M-E`, `^Y` | `^Y`, `^Shift-Z`, `M-E` |
| **Select All** | `.selectAll` | `Shift+Arrows` | `^A` |
| **Beginning of Line**| `.moveHome` | `^A`, `Home` | `Home` |
| **End of Line** | `.moveEnd` | `^E`, `End` | `End` |
| **Cut Selection/Line**| `.editCut` | `^K` | `^X` (with selection), `^K` |
| **Copy Selection** | `.editCopy` | `M-W`, `M-6` | `^C` (with selection), `M-W` |
| **Paste / Uncut** | `.editUncut` | `^U` | `^V`, `^U` |
| **Exit Editor** | `.fileExit` | `^X` | `^Q`, `^X` |
| **Toggle Menu** | `.menuShow` | `F1`, `^M` | `F1`, `^M` |
| **Toggle Canvas** | `.canvasToggle` | `F8` | `F8` |
| **Toggle Table** | `.tableToggle` | `F7` | `F7` |

---

## 5. Mode Overlays Specification

### 1. `TableMode` Overlay
- `Tab` $\rightarrow$ `.tableNextCell`
- `Shift+Tab` / `Backtab` $\rightarrow$ `.tablePrevCell`
- `Ctrl+Shift+Left/Right` $\rightarrow$ `.tableAdjustWidth`
- `Ctrl+Shift+Up/Down` $\rightarrow$ `.tableAdjustHeight`
- `Ctrl+J` $\rightarrow$ `.tableCenterText`
- `Home` / `^A` (in classic) $\rightarrow$ `.tableCellStart`
- `End` / `^E` (in classic) $\rightarrow$ `.tableCellEnd`

### 2. `CanvasMode` Overlay
- `Shift+Arrows` $\rightarrow$ `.canvasDrawLine`
- `Ctrl+Shift+Arrows` $\rightarrow$ `.canvasDrawArrow`
- `Alt+B` / `Mark` $\rightarrow$ `.canvasBlockMark`
- `Ctrl+K` $\rightarrow$ `.canvasCutBlock`
- `Alt+W` $\rightarrow$ `.canvasCopyBlock`
- `Ctrl+U` $\rightarrow$ `.canvasPasteBlock`

### 3. `PromptMode` Overlay
- `Enter` $\rightarrow$ `.promptConfirm`
- `Esc` / `^C` $\rightarrow$ `.promptCancel`
- `Tab` $\rightarrow$ `.promptComplete`
- `Up` / `Down` $\rightarrow$ `.promptHistoryNavigate`
- `Ctrl+Backspace` $\rightarrow$ `.promptClearLine`

---

## 6. Dynamic Help Bar Synchronization

### Data Model
Instead of hardcoded tuples of strings, Help Bar definitions store semantic `HelpBarItem` descriptors:

```swift
public struct HelpBarItem: Sendable {
    public let commandID: CommandID
    public let labelKey: String
    public let fallbackLabel: String

    public init(_ commandID: CommandID, labelKey: String, fallbackLabel: String = "") {
        self.commandID = commandID
        self.labelKey = labelKey
        self.fallbackLabel = fallbackLabel
    }
}
```

### Rendering Pipeline
```swift
// Dynamic label resolution in Renderer+StatusAndHelp.swift
let keyLabel = editor.keymapManager.primaryKeyLabel(for: item.commandID, in: currentMode)
    ?? item.fallbackLabel
let localizedText = tr(item.labelKey)
let entry = (key: keyLabel, label: localizedText)
```

This guarantees that whenever a key binding is modified in `.zagorc` or switched via a preset, the Help Bar instantly reflects the exact live shortcut without manual UI patching.

---

## 7. Configuration (.zagorc) Directives

```nanorc
## Apply full preset
set keymap modern        # Options: classic (default), modern
set modernbindings       # Alias for 'set keymap modern'

## Custom individual remapping
bind ^F search.whereis
bind ^H search.replace
bind ^S file.save
bind ^Q file.exit

## Mode-specific remapping (optional mode suffix)
bind ^A select.all text
bind ^A table.cell_start table
bind ^K prompt.clear prompt

## Unbind key
unbind ^W
```
