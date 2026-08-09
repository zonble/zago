# Proposal & Architectural Plan: `zago` AI-Native Terminal Canvas & IPC

## 1. User Experience & Application Scenarios

`zago` integrates AI not to replace background file modifications, but to act as a **live interactive co-pilot for terminal text canvas drawing, table alignment, and visual formatting**. Below are 3 concrete real-world application scenarios:

---

### Scenario A: Live ASCII Flowchart Drafting
- **Pain Point**: A user is writing `ARCHITECTURE.md` on line 42: *"The system consists of Client App, Auth Server, and Payment Gateway."* Manually drawing boxes (`┌───┐`) and arrows (`──►`) in the terminal using the keyboard takes 3–5 minutes of repositioning lines.
- **AI Intervention**: The user presses **`Alt+A`** to prompt the AI: *"Draw a 3-step payment flowchart at my cursor."* The AI queries the active cursor position via IPC (line 42) and invokes Editor LOGO `BOX` and `LINE` primitives.

---

### Scenario B: Formatting Broken Markdown Tables & CJK Spacing
- **Pain Point**: Pasting a Markdown table from a web page or API response results in misaligned pipe delimiters (`|`) and jammed CJK/Latin characters (e.g. `|ID|Name|iOSAppAPI|`).
- **AI Intervention**: The user selects the paragraph and presses **`Alt+A`**. The AI calculates visual display widths (accounting for double-width CJK characters), executes `zago`'s `SPACING.CJK` and `TABLE` alignment engines, and pushes a perfectly formatted preview.

---

### Scenario C: Generating Field Tables from JSON API Specs
- **Pain Point**: The user has a `response.json` file and wants to generate a Markdown table describing the fields.
- **AI Intervention**: The AI parses the JSON schema and invokes a `zago` table script to push a multi-column Markdown table preview directly into the editor.

---

## 2. Visual Representation in the Terminal UI

When an AI agent interacts with `zago`, 3 distinct visual components appear on the TUI canvas:

```
 Line 14 │ # System Architecture
 Line 15 │ ┌───────────────┐     ┌───────────────┐     ┌───────────────┐  ◄─── 2. Dim Gray Ghost Text
 Line 16 │ │  Client App   │ ──► │  Auth Server  │ ──► │ Payment Gate  │
 Line 17 │ └───────────────┘     └───────────────┘     └───────────────┘
 Line 18 │                       ▲
         │                       └─── 1. Ghost Cursor [AI: Architect-Bot]
         ├────────────────────────────────────────────────────────────────────────
 Status  │ [IPC] [AI Queue 1/3: Architect-Bot] Reason: Drafted 3-step payment flow
         │ Alt+Y: Accept | Alt+N: Reject | Alt+i: Reason | Alt+]: Next Queue
```

### 1. Ghost Cursor (`[AI: ClientName]`)
- **Appearance**: Beside the user's solid white/black cursor, a **blinking dim-purple or cyan virtual cursor** appears with an `[AI: ClientName]` tag, indicating the target line and column position of the AI proposal.

### 2. Dim Gray Ghost Text Overlay
- **Appearance**: Proposed box borders, arrows, and table text appear as **Dim Gray (30% contrast shadow)** layered over the active screen.
- **Key Property**: The ghost text is transient; it has **NOT** mutated the `TextBuffer` or set `isModified = true`.

### 3. Status Bar Execution & Keybinding Prompts
- **Appearance**: Displays live AI status: `[AI Executing: BOX "Auth Server" "round"]`.
- **Prompts**: Shows clear shortcut hints: `Alt+Y: Accept | Alt+N: Reject | Alt+i: Reason | Alt+]: Next Queue`.

---

## 3. Dedicated Non-Typing Adoption Keybindings

To **100% prevent accidental triggers while typing** (avoiding standard keys like `Enter` or `Tab`), adoption and rejection use **dedicated modifier shortcuts**:

```
                          ┌──────────────────────────┐
                          │  AI Pushes Ghost Overlay │
                          └────────────┬─────────────┘
                                       │
                ┌──────────────────────┼──────────────────────┐
                ▼                      ▼                      ▼
    [ Alt+Y / Ctrl+Y ]        [ Alt+N / Ctrl+N / Esc ]        [ Alt+R / Ctrl+R ]
                │                      │                      │
       ┌────────┴─────────┐   ┌────────┴─────────┐   ┌────────┴─────────┐
       │   Accept Proposal│   │  Reject Proposal │   │   Refine Proposal│
       └──────────────────┘   └──────────────────┘   └──────────────────┘
```

### 1. Accept Proposal
- **Dedicated Shortcut**: **`Alt+Y`** or **`Ctrl+Y`** (Y = Yes).
- **Execution Effect**:
  1. Dim Gray Ghost Text instantly converts to **standard white real text**.
  2. Mutates `TextBuffer.lines` and marks `isModified = true`.
  3. Records a **single atomic `UndoSnapshot`** (`Ctrl+Z` undoes the entire AI proposal in one step).
  4. Clears ghost text and AI cursor, displaying `[AI Changes Accepted]`.
  5. Appends the transaction to `AIHistoryLog`.

### 2. Reject Proposal
- **Dedicated Shortcut**: **`Alt+N`**, **`Ctrl+N`**, or **`Esc`** (N = No).
- **Execution Effect**: Ghost text and AI cursor vanish instantly. `TextBuffer` remains 100% untouched.

### 3. Refine Proposal
- **Dedicated Shortcut**: **`Alt+R`** or **`Ctrl+R`** (R = Refine).
- **Execution Effect**: Keeps ghost text active and opens a prompt bar for follow-up instructions (e.g. *"Change round box to double-line box"*).

---

## 4. AI Rationale & Transparency Architecture (`reason` Field)

Every proposal pushed by an AI agent **MUST include a human-readable `reason` field** explaining the rationale behind the edits.

- **Status Bar Summary**: The AI's explanation appears prominently on the status bar alongside shortcut prompts.
- **Full Rationale Mini-Popup (`Alt+i`)**: Pressing **`Alt+i`** (or typing `:ai-reason`) opens a transient mini-window displaying the full multi-line explanation, prompt context, and executed LOGO statements.
- **Audit Log Transparency**: The `reason` field is recorded into `AIHistoryLogManager` (`.zago-ai-history.json`).

---

## 5. Multi-Agent Proposal Queue UX

When multiple AI agents interact with `zago` concurrently, proposals form an **Interactive AI Proposal Queue**.

```
┌─────────────────────────────────────────────────────────────┐
│                 Multi-Agent Proposal Queue                  │
├─────────────────────────────────────────────────────────────┤
│ Queue Item 1/3: [Architect-Bot] 3-Step ASCII Flowchart      │
│ Queue Item 2/3: [Table-Bot] CJK Markdown Table Alignment    │
│ Queue Item 3/3: [Linter-Bot] Spacing & Grammar Correction   │
└──────────────────────────────┬──────────────────────────────┘
```

- **`Alt+]` / `Alt+Right`**: Skip to Next Proposal in queue.
- **`Alt+[` / `Alt+Left`**: Return to Previous Proposal in queue.
- **`Alt+Y`**: Accept Current Proposal.
- **`Alt+Shift+Y`**: **Accept ALL Proposals in Queue** in a single atomic transaction.
- **`Alt+N`**: Reject Current Proposal.
- **`Alt+Shift+N`**: Clear/Reject ALL Proposals in Queue.

---

## 6. Multi-Chunk Proposal Architecture (多區塊非連續提案)

A single AI proposal within a file may modify **multiple disjoint regions** (e.g., updating line 5, line 42, and line 100 simultaneously) via an array of **`ProposalChunk`** items.

- **Multi-Region Dim Gray Overlay**: Ghost text displays at all target line regions simultaneously.
- **Chunk Navigation Shortcuts**:
  - **`Alt+n`** / **`Alt+Down`**: Jump viewport to Next Chunk within the active proposal.
  - **`Alt+p`** / **`Alt+Up`**: Jump viewport to Previous Chunk within the active proposal.
- **Atomic Multi-Region Acceptance**: Pressing `Alt+Y` applies ALL disjoint chunks simultaneously in a single atomic `UndoSnapshot`.

---

## 7. Multi-File Workspace Proposals (多檔案跨文件提案)

An AI agent may propose edits across **multiple files simultaneously** (e.g. updating `ARCHITECTURE.md`, `README.md`, and `config.json` in a single proposal) via an array of `affectedFiles`.

```
┌─────────────────────────────────────────────────────────────┐
│             Multi-File Workspace Proposal                   │
├─────────────────────────────────────────────────────────────┤
│ Proposal ID: ws-prop-909 (Refactoring-Bot)                  │
│ Reason: "Synchronized component names across architecture,  │
│          README diagram, and project config schema."        │
│  ├── File #1: ARCHITECTURE.md (Update Component Names)      │
│  ├── File #2: README.md       (Update Quickstart Diagram)   │
│  └── File #3: config.json     (Update Schema Version)       │
└──────────────────────────────┬──────────────────────────────┘
```

- **Tab Bar Multi-File Badges (`[1: ARCHITECTURE.md (AI)]`)**: Displays a visual AI badge on all affected tabs.
- **Multi-File Switch Shortcut (`Alt+m`)**: Switches `zago`'s active buffer to the next affected file in the multi-file proposal.
- **Workspace Atomic Undo (`Ctrl+Z`)**: Accepts all files via `Alt+Y` in a single `WorkspaceUndoSnapshot`. Pressing `Ctrl+Z` in any file reverts all affected files across the workspace.

---

## 8. Many-to-Many Multi-Agent & Multi-Buffer Architecture ($M \times N$ Matrix)

`zago` supports a **Many-to-Many ($M \times N$) topology**, where $M$ external AI agents can concurrently query, draft, and push multi-chunk proposals to $N$ active editor text buffers (`TextBuffer` instances).

- **Per-Buffer Proposal Queues**: Each `TextBuffer` maintains its own isolated `ProposalQueue`.
- **Target Routing (`bufferTarget`)**: `bufferTarget: "active"` or `bufferTarget: { "filePath": "ARCHITECTURE.md" }`.
- **Background Execution**: Background agents process proposals without interrupting typing in the active foreground buffer.

---

## 9. Action Authorship & Attributed Undo Stack (`UndoSnapshot.author`)

Every edit in `zago` records explicit **Authorship Metadata** inside `UndoSnapshot`:

```swift
public enum ActionAuthor: Equatable, Codable {
    case user                             // Human editing in editor
    case logoScript(name: String?)        // Local Editor LOGO macro execution
    case aiAgent(id: String, name: String, reason: String) // External AI Agent via IPC
}
```

- **Informative Undo Feedback**: Pressing `Ctrl+Z` displays the author and rationale: `[Undo AI: Architect-Bot (Reason: Drafted 3-step payment flow)]`.
- **Interactive Undo History Picker (`:undo-history`)**: Timeline picker showing who changed what and when.

---

## 10. Dynamic Ghost Line Offset Auto-Adjustment

When an AI proposal is pending and the user continues typing above the edit site (e.g. inserting 2 lines at Line 10 while a proposal targets Line 15):
- `TextBuffer` automatically adjusts the target line indices of all pending ghost overlays (`targetLine` becomes `15 + 2 = 17`).
- Ghost text overlays automatically shift on screen, remaining perfectly aligned with the intended document section.

---

## 11. Client Identification & Registration Architecture

- **POSIX Kernel Credentials (`SO_PEERCRED` / `LOCAL_PEERCRED`)**: Verifies the client's actual **PID (Process ID)** and **User ID (UID)**.
- **Connection Lifecycle (`connectionId`)**: Un-accepted proposals are automatically purged if a client process crashes or disconnects.
- **Visual Branding (`clientName` & `color`)**: Overlay text, status prompts, and ghost cursors render using the client's registered name and visual theme color (`cyan`, `purple`, `green`, `magenta`).

---

## 12. Protocol Error Handling & Standard Error Codes

| Error Code | Error Message | Description |
| :--- | :--- | :--- |
| **`-32700`** | `Parse error` | Invalid JSON payload received. |
| **`-32600`** | `Invalid Request` | JSON-RPC structure missing required fields. |
| **`401`** | `Unauthorized` | Session token validation failed. |
| **`408`** | `Execution Timeout` | LOGO script execution exceeded 500ms watchdog timeout. |
| **`409`** | `Queue Conflict / Locked` | Proposal queue depth exceeded or target locked. |
| **`422`** | `Unprocessable Entity` | 2D matrix coordinates out of bounds or exceeding canvas width. |

---

## 13. Resource Quotas & DoS Safeguards

- **`maxPayloadBytes`**: `1 MB` per JSON-RPC request.
- **`maxOverlayLines`**: `1,000` lines per proposal.
- **`maxQueueDepth`**: `50` pending proposals per buffer.
- **`executionTimeout`**: `500 ms` watchdog per script invocation.

---

## 14. 4-Quadrant Text Manipulation Matrix (`insertMode`)

| Enum Value | Paradigm | Behavior | Primary Use Case |
| :--- | :--- | :--- | :--- |
| **`"1d_insert"`** | 1D Stream Insert | Inserts text at line/col; subsequent lines shift downward. | New paragraphs, Markdown lists. |
| **`"1d_overwrite"`** | 1D Stream Overwrite | Overwrites characters on line without shifting line length. | Replacing word or inline token. |
| **`"2d_insert"`** | 2D Matrix Insert | Inserts 2D block at $(X,Y)$, shifting text right **ONLY on touched lines**. | Inserting box between canvas boxes. |
| **`"2d_overwrite"`** | 2D Matrix Overwrite | Overwrites visual X-Y matrix without shifting line lengths. | ASCII flowcharts, box frames. |
| **`"2d_transparent"`** | 2D Transparent Overlay | Overwrites non-space characters; spaces preserve underlying text. | Diagram labels, text annotations. |
| **`"2d_fuse_corners"`** | 2D Corner Fusing | Overwrites matrix and automatically fuses overlapping corners. | Connected ASCII flowcharts. |

---

## 15. Bi-Directional Prompts (`Alt+A` Selection Context Request)

When a user selects text in `zago` and presses **`Alt+A`** (Trigger AI Co-Pilot), `zago` sends an outbound IPC event payload (`zago.event.selectionTriggered`) to connected clients with current file, cursor, mode, and selected text.

---

## 16. Feature Toggles & Privacy Control

**The IPC Socket Server & AI Co-Pilot features are DISABLED by default**:
- Configuration: `set ipc.enabled true|false` in `.zagorc`.
- CLI Flags: `zago --ipc` / `zago --no-ipc`.
- Command Bar Toggle: `:toggle-ipc` or LOGO `TOGGLE.IPC`.
- Status Bar Indicator: `[IPC]` tag shown when active.

---

## 17. Reference Python IPC Client (`examples/ipc_client/zago_client.py`)

```python
import socket, json

sock_path = "/tmp/zago-1234.sock"
client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
client.connect(sock_path)

# 1. Register Client
client.sendall(json.dumps({
    "jsonrpc": "2.0", "method": "zago.client.register",
    "params": {"auth": "secret-token", "clientId": "py-bot", "clientName": "PyBot", "color": "cyan"}, "id": 1
}).encode() + b"\n")

# 2. Push Ghost Text Proposal
client.sendall(json.dumps({
    "jsonrpc": "2.0", "method": "zago.overlay.showPreview",
    "params": {
        "clientId": "py-bot", "reason": "Drafted sample ASCII box",
        "affectedFiles": [{"filePath": "active", "chunks": [{"targetLine": 15, "targetCol": 1, "lines": ["┌─────────┐", "│ PyBot   │", "└─────────┘"], "insertMode": "2d_insert"}]}]
    }, "id": 2
}).encode() + b"\n")
```

---

## 18. Milestones Summary

| Milestone | Deliverable | Target Artifacts |
| :--- | :--- | :--- |
| **M1: IPC Server & Client Registration** | Socket / Named Pipe listener + `SO_PEERCRED` Auth + `zago.client.register` | `Sources/IPC/`, `ZagoIPCServer.swift` |
| **M2: Multi-File Queue & Multi-Chunk Overlay**| `WorkspaceProposal` + `reason` field + 4-quadrant `insertMode` enum + `Alt+i` popup | `Sources/Editor/Models/ProposalQueue.swift` |
| **M3: Attributed Undo & History** | `ActionAuthor` in `UndoSnapshot` + `AIHistoryLogManager` + `:ai-history` picker | `Sources/Editor/Models/AIHistoryLog.swift` |
| **M4: JSON-RPC & Sandbox** | LOGO execution RPC + 500ms Watchdog timeout | `Sources/LogoEngine/LogoEngine+IPC.swift` |
| **M5: AI Skill & Docs** | Updated `examples/ipc_client/zago_client.py` & `.agents/skills/zago/SKILL.md` | `docs/zago_ipc_ai_plan.md`, `SKILL.md` |
