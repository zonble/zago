# Zago AI/IPC Architecture & Completed Milestone

## 1. Overview & Core Philosophy

The AI and IPC subsystems in `zago` have reached a stable milestone. This document summarizes the completed architecture, capabilities, and established design boundaries.

Zago is an editor for text whose visual and structured form is not fixed in advance. Plain text, Markdown tables, ASCII/Unicode box diagrams, and Editor LOGO scripts exist in the same buffer space. The AI/IPC integration is built around a single foundational premise:

> **"Zago helps a human with this text."**

Zago is not a background multi-document agent workspace or an autonomous file writer. Instead, it provides external AI agents with:
1. A controlled, read-only view of the live editor's current focus (selection, cursor, buffer, or active table/canvas region).
2. A reversible, human-in-the-loop proposal channel using non-destructive ghost text overlays.
3. Safe execution of Editor LOGO scripts to generate structured drawings and tables.

The human user remains in full control of deciding what text enters the buffer and when.

---

## 2. Completed Capabilities (現況總結)

### 2.1 Cross-Platform IPC Transport
* **JSON-RPC 2.0 over Local Sockets**:
  * **POSIX (macOS & Linux)**: Unix domain sockets in `/tmp/zago-<pid>-<nonce>.sock` with signal-safe lifecycle and non-blocking shutdown.
  * **Windows**: Named pipes (`\\.\pipe\zago-<pid>-<nonce>`) using `PIPE_NOWAIT` polling during listen and transitioning to `PIPE_WAIT` upon connection for thread-safe, hang-free teardown.
* **Authentication & Session Tokens**:
  * Ephemeral token files (`.token`) with strict permissions restrict IPC access to the local user session.
  * Explicit client registration handshake (`zago.client.register`).

### 2.2 Thread-Safe Editor Loop Dispatch
* **Single-Writer Actor Model**: IPC worker threads never mutate buffer lines or cursor state directly.
* **`performOnEditorLoop` & Wakeup Bridge**:
  * External requests enqueue closures into `editorLoopRequests` and unblock the main editor thread via `terminal.wakeup()`.
  * **POSIX**: Self-pipe write unblocking `poll()`.
  * **Windows**: Synthetic NUL `KEY_EVENT` via `WriteConsoleInputW` paired with atomic `wakeupRequested` tracking.
  * Timeouts (default 0.5s–10s) prevent stalled client connections from hanging the editor.

### 2.3 Buffer & Focus Inspection APIs
* `zago.buffer.getBuffers`: Discovers open buffers and active buffer target.
* `zago.buffer.getText`: Reads full buffer contents or sliced line ranges.
* `zago.buffer.getSelection`: Retrieves selected text, individual lines, and 1-based start/end coordinates.
* `zago.buffer.getCursor`: Reads line, column, visual column, and current editor mode (Text, Canvas, Table).

### 2.4 Ghost Overlay Proposals
* `zago.overlay.showPreview`: Injects tentative text proposals rendered in Dim Gray (`#808080`) ghost overlays.
* **Insertion Modes**:
  * `1d_insert` & `1d_overwrite` (line-oriented text changes).
  * `2d_insert`, `2d_overwrite`, `2d_transparent`, and `2d_fuse_corners` (2D spatial ASCII/Unicode box and diagram placement).
* Buffers are only mutated when the user explicitly accepts the proposal via editor keybindings.

### 2.5 Safe Editor LOGO Execution
* `zago.buffer.executeLogo`: Evaluates Editor LOGO scripts within a sandboxed context and routes output as a ghost proposal onto the active buffer, preserving undo history.

### 2.6 AI History & Attribution
* Records AI client identity, rationale, affected lines, and timestamps.
* `zago.history.getEntries`: Allows clients to inspect previous proposal actions.

### 2.7 Model Context Protocol (MCP) Server
* Built-in `zago --mcp` binary mode implementing the Model Context Protocol (MCP) over stdio.
* Exposes 8 standard tools:
  * `zago_list_instances`
  * `zago_select_instance`
  * `zago_get_buffers`
  * `zago_get_text`
  * `zago_get_selection`
  * `zago_get_cursor`
  * `zago_overlay_preview`
  * `zago_execute_logo`
* Ready out-of-the-box for Antigravity, Claude Desktop, and OpenAI Codex CLI.

### 2.8 CLI Integration & Skill Installer
* `zago --install-skill` and `zago --uninstall-skill` automate deployment of Zago skills and MCP server configuration into `~/.agents` and `~/.codex`.

---

## 3. Established Design Invariants & Boundaries

The following design decisions are intentionally finalized:

| Boundary | Decision & Rationale |
| :--- | :--- |
| **Human-in-the-Loop** | Agents propose; humans review and accept/reject. No silent background file writes. |
| **Single Active Focus** | Interactions target the currently focused buffer/region rather than complex multi-document batch edits. |
| **No Global Workspace Mutations** | Workspace-wide multi-file atomic transactions are out of scope. |
| **Visual Geometry as Shared Engine Logic** | CJK display widths, box borders (`┏━┓┃┗━┛`), Table cells, and Canvas coordinates are handled by Zago's layout engine, not re-implemented by agents. |

---

## 4. Maintenance & Future Backlog

With the core AI/IPC foundation completed, the subsystem is in **maintenance mode**. Potential future enhancements are backlog candidates rather than active development requirements:

1. **`Alt+A` / `selectionTriggered` Outbound Event**:
   * An optional event notification when the user presses `Alt+A` to push current selection to a connected agent.
2. **Watchdog for External LOGO Evaluation**:
   * A 500ms execution safeguard to terminate runaway loops (`WHILE true [...]`) generated by external scripts.
3. **Protocol Fixtures Generator**:
   * Automated schema validation tests to prevent JSON-RPC and MCP schema drift.
