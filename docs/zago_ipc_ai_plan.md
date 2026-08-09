# Proposal & Architectural Plan: `zago` AI-Native Terminal Canvas & IPC

## 1. User Experience & Application Scenarios

`zago` integrates AI not to replace background file modifications, but to act as a **live interactive co-pilot for terminal text canvas drawing, table alignment, and visual formatting**. Below are 3 concrete real-world application scenarios:

---

### Scenario A: Live ASCII Flowchart Drafting (2D Canvas Overwrite Mode)
- **Pain Point**: A user is writing `ARCHITECTURE.md` on line 42: *"The system consists of Client App, Auth Server, and Payment Gateway."* Manually drawing boxes (`┌───┐`) and arrows (`──►`) in the terminal using the keyboard takes 3–5 minutes of repositioning lines.
- **AI Intervention**: The user presses **`Alt+A`** to prompt the AI: *"Draw a 3-step payment flowchart at my cursor."* The AI queries the active cursor position via IPC (line 42) and invokes Editor LOGO `BOX` and `LINE` primitives with `"insertMode": "overwrite"`.

---

### Scenario B: Formatting Broken Markdown Tables & CJK Spacing (Stream Replace)
- **Pain Point**: Pasting a Markdown table from a web page or API response results in misaligned pipe delimiters (`|`) and jammed CJK/Latin characters (e.g. `|ID|Name|iOSAppAPI|`).
- **AI Intervention**: The user selects the paragraph and presses **`Alt+A`**. The AI calculates visual display widths (accounting for double-width CJK characters), executes `zago`'s `SPACING.CJK` and `TABLE` alignment engines, and pushes a perfectly formatted preview.

---

### Scenario C: Generating Field Tables from JSON API Specs (1D Stream Insert)
- **Pain Point**: The user has a `response.json` file and wants to generate a Markdown table describing the fields.
- **AI Intervention**: The AI parses the JSON schema and invokes a `zago` table script to push a multi-column Markdown table preview directly into the editor with `"insertMode": "insert"`.

---

## 2. Text Manipulation Paradigms: 1D vs 2D & Insert vs Overwrite

External tools and AI agents manipulate text in `zago` through two distinct paradigms and explicit insertion modes:

```
                          ┌──────────────────────────┐
                          │  External AI Agent / IPC │
                          └────────────┬─────────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                ▼                                             ▼
┌───────────────────────────────┐             ┌───────────────────────────────┐
│   1D Stream Text Operations   │             │   2D Canvas Block Operations  │
│  - zago.buffer.insertText     │             │  - zago.canvas.drawBlock      │
│  - zago.buffer.replaceRange   │             │  - zago.canvas.drawLine       │
│  - Mode: "insert"             │             │  - Mode: "overwrite"          │
│  - Lines shift right/down     │             │    "transparent" / "fuse"    │
└───────────────────────────────┘             └───────────────────────────────┘
                               │                               │
                               └──────────────┬────────────────┘
                                              ▼
                               ┌───────────────────────────────┐
                               │  zago.buffer.executeLogo      │
                               │  (Unified LOGO DSL Interface) │
                               └───────────────────────────────┘
```

### Insertion Modes Summary

| Mode | Behavior | Primary Use Cases |
| :--- | :--- | :--- |
| **`"insert"`** | Inserts text/lines at cursor; existing lines shift downward. | New paragraphs, Markdown lists, code blocks. |
| **`"overwrite"`** | Overwrites X-Y matrix characters without shifting line lengths. | ASCII flowcharts, box diagrams, card frames. |
| **`"transparent"`** | Overwrites non-whitespace characters; spaces preserve underlying text. | Text annotations, diagram labels. |
| **`"fuse_corners"`** | Overwrites matrix and automatically fuses overlapping box corners (`┌` + `│` $\rightarrow$ `├`). | Multi-box connected ASCII flowcharts. |

---

## 3. Feature Toggles & Privacy Control (Feature Switches)

To respect user privacy, security, and resource usage, **the IPC Socket Server & AI Co-Pilot features are DISABLED by default** and can be toggled dynamically.

```
┌─────────────────────────────────────────────────────────────┐
│               Feature Toggle & Privacy Control              │
├─────────────────────────────────────────────────────────────┤
│ 1. Configuration (~/.zagorc): set ipc.enabled true|false    │
│ 2. CLI Override Flags:       zago --ipc / zago --no-ipc     │
│ 3. Command Bar Toggle:        :toggle-ipc / TOGGLE.IPC      │
│ 4. Status Bar Indicator:      [IPC] (shown when active)     │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Visual Representation in the Terminal UI

When an AI agent interacts with `zago`, 3 distinct visual components appear on the TUI canvas:

```
 Line 14 │ # System Architecture
 Line 15 │ ┌───────────────┐     ┌───────────────┐     ┌───────────────┐  ◄─── 2. Dim Gray Ghost Text
 Line 16 │ │  Client App   │ ──► │  Auth Server  │ ──► │ Payment Gate  │
 Line 17 │ └───────────────┘     └───────────────┘     └───────────────┘
 Line 18 │                       ▲
         │                       └─── 1. Ghost Cursor [AI]
         ├────────────────────────────────────────────────────────────────────────
 Status  │ [IPC] [AI Proposal] Alt+Y/Ctrl+Y: Accept | Alt+N/Esc: Reject | Alt+R: Refine
```

---

## 5. Dedicated Non-Typing Adoption Keybindings

To **100% prevent accidental triggers while typing**, adoption and rejection use **dedicated modifier shortcuts**:
- **`Alt+Y` / `Ctrl+Y`**: Accept Proposal
- **`Alt+N` / `Ctrl+N` / `Esc`**: Reject Proposal
- **`Alt+R` / `Ctrl+R`**: Refine Proposal

---

## 6. AI Collaboration History & Audit Log

`zago` incorporates `AIHistoryLogManager` to log all AI proposals, LOGO executions, and user decisions (`id`, `timestamp`, `logoScript`, `proposedText`, `userDecision`). Users can view and re-apply proposals via `:ai-history` or `SHOW.AI.HISTORY`.

---

## 7. Milestones Summary

| Milestone | Deliverable | Target Artifacts |
| :--- | :--- | :--- |
| **M1: IPC Server & Feature Toggle** | Socket / Named Pipe listener + `set ipc.enabled` config + 0600 Auth | `Sources/IPC/`, `ZagoIPCServer.swift` |
| **M2: Ghost Overlay & 1D/2D APIs** | Dual-Layer Renderer + Ghost Cursor + Insert/Overwrite APIs + Alt+Y/Alt+N keybindings | `Sources/Editor/Models/CanvasOverlay.swift` |
| **M3: AI History & Audit Log** | `AIHistoryLogManager` + `:ai-history` picker | `Sources/Editor/Models/AIHistoryLog.swift` |
| **M4: JSON-RPC & Sandbox** | LOGO execution RPC + 500ms Watchdog timeout | `Sources/LogoEngine/LogoEngine+IPC.swift` |
| **M5: AI Skill & Docs** | Updated `.agents/skills/zago/SKILL.md` & specs | `docs/zago_ipc_ai_plan.md`, `SKILL.md` |
