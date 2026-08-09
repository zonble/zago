# Proposal & Architectural Plan: `zago` AI-Native Terminal Canvas & IPC

## 1. Multi-File Workspace Proposals (多檔案跨文件提案)

An AI agent (e.g. a Cross-Doc Refactoring Agent, Workspace Formatter, or Project Renaming Tool) may propose edits across **multiple files simultaneously** (e.g. updating `ARCHITECTURE.md`, `README.md`, and `config.json` in a single cohesive proposal).

To handle multi-file edits cleanly, `zago` supports **`WorkspaceProposal`** items containing an array of `affectedFiles`.

```
┌─────────────────────────────────────────────────────────────┐
│             Multi-File Workspace Proposal                   │
├─────────────────────────────────────────────────────────────┤
│ Proposal ID: ws-prop-909 (Refactoring-Bot)                  │
│  ├── File #1: ARCHITECTURE.md (Update Component Names)      │
│  ├── File #2: README.md       (Update Quickstart Diagram)   │
│  └── File #3: config.json     (Update Schema Version)       │
└──────────────────────────────┬──────────────────────────────┘
                               │ Composition & Tab Badges
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 TUI Rendering & Tab Navigation              │
│ Tab Bar:  [1: ARCHITECTURE.md (AI)]  [2: README.md (AI)]    │
│ Status:   [Workspace Proposal: Refactoring-Bot (3 Files)]   │
│ Controls: Alt+Y: Accept All Files | Alt+m: Jump Next File   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Multi-File Review & Workspace Atomic Undo

### 1. Tab Bar Multi-File Badges (`[1: ARCHITECTURE.md (AI)]`)
- Every file affected by the multi-file proposal displays a visual AI indicator tag on the tab bar.

### 2. Multi-File Switch Shortcut (`Alt+m`)
- Pressing **`Alt+m`** / **`Alt+Shift+Right`** automatically switches `zago`'s active buffer to the next affected file in the multi-file proposal, positioning the cursor and ghost overlay at the edit site.

### 3. Workspace Atomic Undo (`Ctrl+Z`)
- Accepting a multi-file proposal (`Alt+Y`) records a **`WorkspaceUndoSnapshot`** covering all modified `TextBuffer` instances.
- Pressing **`Ctrl+Z`** in any open buffer reverts all modified files across the workspace simultaneously in a single atomic transaction.

---

## 3. Multi-Chunk Proposal Architecture (多區塊非連續提案)

A single proposal within a file consists of an array of **`ProposalChunk`** items (`targetLine`, `targetCol`, `lines`, `insertMode`). Chunk navigation shortcuts (`Alt+n` / `Alt+p`) allow jumping between disjoint edit regions within a file.

---

## 4. Many-to-Many Multi-Agent & Multi-Buffer Architecture ($M \times N$ Matrix)

`zago` supports a **Many-to-Many ($M \times N$) topology**, where $M$ external AI agents can concurrently query, draft, and push multi-chunk proposals to $N$ active editor text buffers (`TextBuffer` instances).

---

## 5. Client Identification & Registration Architecture

To manage multiple concurrent AI agents safely, `zago` implements a **Handshake & Client Identity Protocol (`zago.client.register`)** with POSIX `SO_PEERCRED` kernel credential verification.

---

## 6. Atomic AI Undo & Rollback Architecture (Undo 機制)

To guarantee safety, every AI proposal transaction integrates seamlessly into `TextBuffer`'s `UndoSnapshot` stack. Accepting proposals records a single atomic undo point (`Ctrl+Z`), reverting all chunks across all files and restoring the proposal back into the active `ProposalQueue`.

---

## 7. Feature Toggles & Privacy Control

To respect user privacy, security, and resource usage, **the IPC Socket Server & AI Co-Pilot features are DISABLED by default** and can be toggled dynamically (`set ipc.enabled`, `zago --ipc`, `:toggle-ipc`).

---

## 8. Milestones Summary

| Milestone | Deliverable | Target Artifacts |
| :--- | :--- | :--- |
| **M1: IPC Server & Client Registration** | Socket / Named Pipe listener + `SO_PEERCRED` Auth + `zago.client.register` | `Sources/IPC/`, `ZagoIPCServer.swift` |
| **M2: Multi-File Proposal Queue** | `WorkspaceProposal` + Multi-File Tab Badges + `Alt+m` multi-file jump | `Sources/Editor/Models/ProposalQueue.swift` |
| **M3: Workspace Atomic Undo & History** | `WorkspaceUndoSnapshot` + `AIHistoryLogManager` + `:ai-history` picker | `Sources/Editor/Models/AIHistoryLog.swift` |
| **M4: JSON-RPC & Sandbox** | LOGO execution RPC + 500ms Watchdog timeout | `Sources/LogoEngine/LogoEngine+IPC.swift` |
| **M5: AI Skill & Docs** | Updated `.agents/skills/zago/SKILL.md` & specs | `docs/zago_ipc_ai_plan.md`, `SKILL.md` |
