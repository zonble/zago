# Specification: `zago` AI Editor Operation Protocol (JSON-RPC 2.0)

## 1. User Experience & Multi-File Workspace Flow

The protocol is designed around a single core user experience principle: **The AI proposes live ghost previews, and the human user stays in control with dedicated non-typing modifier keybindings.**

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

### Multi-File Workspace Proposal Flow:
An AI agent (e.g. a Cross-Doc Refactoring Agent or Workspace Formatter) can push edits affecting multiple files across a project simultaneously:

```
 [ Workspace Proposal (Refactoring-Bot) ]
    ├── File #1: ARCHITECTURE.md (Update Component Names)
    ├── File #2: README.md       (Update Quickstart Diagram)
    └── File #3: config.json     (Update Schema Version)
```

---

## 2. Multi-File Protocol Payload Example (`zago.overlay.showPreview`)

Clients must register on the same connection before calling this method. zago takes the identity from that registered connection; the payload `clientId` must match it. Clients pass `reason` (String), `insertMode` enum, and `affectedFiles` in the JSON-RPC `showPreview` payload:

```json
{
  "jsonrpc": "2.0",
  "method": "zago.overlay.showPreview",
  "params": {
    "clientId": "Refactoring-Bot",
    "reason": "Synchronized component names across architecture diagram, README quickstart, and project config schema.",
    "affectedFiles": [
      {
        "filePath": "ARCHITECTURE.md",
        "chunks": [
          {
            "targetLine": 15,
            "targetCol": 1,
            "lines": [
              "┌───────────────┐     ┌───────────────┐",
              "│  Frontend App │ ──► │  API Gateway  │",
              "└───────────────┘     └───────────────┘"
            ],
            "insertMode": "2d_overwrite"
          }
        ]
      },
      {
        "filePath": "README.md",
        "chunks": [
          {
            "targetLine": 30,
            "targetCol": 1,
            "lines": [
              "| Component | Status | Version |",
              "| API Gateway | Active | v2.1 |"
            ],
            "insertMode": "1d_insert"
          }
        ]
      }
    ]
  },
  "id": 2
}
```

---

## 3. Parameter Reference: `insertMode` Enum Options

| Enum Value | Paradigm | Behavior | Primary Use Case |
| :--- | :--- | :--- | :--- |
| **`"1d_insert"`** | 1D Stream Insert | Inserts text at target line/col; subsequent lines shift downward. | New paragraphs, Markdown bullet lists, code blocks. |
| **`"1d_overwrite"`** | 1D Stream Overwrite | Overwrites characters on target line without shifting line length. | Replacing word or inline token. |
| **`"2d_insert"`** | 2D Matrix Insert | Inserts 2D block at $(X,Y)$, shifting text right **ONLY on touched lines**. | Inserting box diagram between existing canvas boxes. |
| **`"2d_overwrite"`** | 2D Matrix Overwrite | Overwrites visual X-Y matrix without shifting line lengths. | ASCII flowcharts, box frames, card boundaries. |
| **`"2d_transparent"`** | 2D Transparent Overlay | Overwrites non-whitespace characters; spaces preserve underlying text. | Diagram labels, text annotations, stamps. |
| **`"2d_fuse_corners"`** | 2D Corner Fusing | Overwrites matrix and automatically fuses overlapping box corners (`┌` + `│` $\rightarrow$ `├`). | Multi-box connected ASCII flowcharts. |

---

## 4. Action Authorship & Attributed Undo Stack

`UndoSnapshot` records explicit authorship attribution for every mutation:

```swift
public enum ActionAuthor: Equatable, Codable {
    case user                             // Human editing in editor
    case logoScript(name: String?)        // Local Editor LOGO macro execution
    case aiAgent(id: String, name: String, reason: String) // External AI Agent via IPC
}
```

When undoing an AI mutation (`Ctrl+Z`), the status bar displays attribution:
`[Undo AI: Architect-Bot (Reason: Drafted 3-step payment flow)]`

---

## 5. Standard JSON-RPC 2.0 Error Codes Matrix

| Error Code | Error Message | Description |
| :--- | :--- | :--- |
| **`-32700`** | `Parse error` | Invalid JSON payload received. |
| **`-32600`** | `Invalid Request` | JSON-RPC structure missing required fields. |
| **`401`** | `Unauthorized` | Session token validation failed. |
| **`408`** | `Execution Timeout` | LOGO script execution exceeded 500ms watchdog timeout. |
| **`409`** | `Queue Conflict / Locked` | Proposal queue depth exceeded or target locked. |
| **`422`** | `Unprocessable Entity` | 2D matrix coordinates out of bounds or exceeding canvas width. |

---

## 6. Complete Method Specifications

### Domain 1: Client Registration & Handshake

#### 1.1 `zago.client.register`
Registers client identity and returns allocated `connectionId`.
```json
{
  "jsonrpc": "2.0",
  "method": "zago.client.register",
  "params": {
    "auth": "256-bit-session-token",
    "clientId": "agent-architect-01",
    "clientName": "Architect-Bot",
    "agentType": "diagram_forge",
    "color": "cyan"
  },
  "id": 1
}
```

---

### Domain 2: Multi-File Ghost Overviews & Proposal Queue

#### 2.1 `zago.overlay.showPreview` (Pushes Proposal with Rationale)
Pushes a multi-file or single-file proposal into the workspace proposal queue.
- **Parameters**: `clientId` (must match the registered connection), `reason` *(Required String)*, `affectedFiles` (Array of `{ filePath, chunks: [{ targetLine, targetCol, lines, insertMode }] }`).

#### 2.2 `zago.queue.getPending`
Returns list of pending queued proposals, including `reason` fields and `insertMode` settings.

#### 2.3 `zago.event.selectionTriggered` (Outbound Event on Alt+A)
Notifies connected clients when a user triggers AI Co-Pilot on a selected text block.

#### 2.4 Acceptance Behavior & Mode Safety (Alt+a / `:accept`)
When the user accepts an AI proposal, the editor applies the proposed line chunks to the target buffer. If Table Mode (`isTableModeActive`) is enabled and the accepted text alters or breaks the surrounding table grid syntax/cell boundaries, the editor automatically exits Table Mode gracefully.

---

### Domain 3: AI History & Audit Trail

#### 3.1 `zago.history.getEntries`
Queries recent AI proposal history entries, including `author` metadata, `reason` fields, and user decisions.

#### 3.2 `zago.history.reapplyEntry`
Re-applies a previously rejected, undone, or past proposal from history as a Ghost Overlay preview.

---

## 7. Permission Matrix & Security Policy

| Method | Target Scope | Permission Level | Default Behavior | Human Approval Required |
| :--- | :--- | :--- | :--- | :--- |
| `zago.client.register` | Global | `Auth` | Validates token + OS `SO_PEERCRED` | No |
| `zago.overlay.showPreview` | Multi-File | `Transient Queue` | Pushes proposal with `reason` & `author` to Queue | No (User reviews in Queue) |
| `zago.buffer.executeLogo` | Workspace | `Mutate` | Sandboxed | **Yes (Pushes to Queue; Press Alt+Y to Accept)** |
