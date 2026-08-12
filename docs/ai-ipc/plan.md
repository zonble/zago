# Zago AI/IPC Plan

## 1. Core Idea

Zago is an editor for text whose form is not fixed in advance. AI output may mix
prose, code, tables, diagrams, commands, and tentative proposals in one place.
The editor therefore needs to let a human inspect, select, transform, execute,
preview, accept, and reject different kinds of text without forcing the text into
a single format first.

The AI in Zago is not a multi-document workspace manager. It helps the human with
the text currently in focus: the current selection, line, table cell, Canvas
region, or LOGO program. The human chooses the focus; the agent proposes an
operation on that focus.

The goal of the AI/IPC work is not to let an agent silently edit files. It is to
give an external agent a controlled view of the live editor and a reversible
proposal path. The human remains responsible for deciding what the text becomes.

## 2. The LOGO Model

LOGO provides the right mental model for this scope. LOGO does not operate a
collection of documents. It operates one turtle:

- one current position;
- one heading and drawing state;
- one visible text space;
- one sequence of observable actions.

`BOX`, `LINE`, `TABLE`, and text transformations are consequences of that turtle
acting in a text space. The AI/IPC layer follows the same rule: one active editor
focus, one current proposal, and one human-visible result at a time.

## 3. Implemented Foundation

The following parts of the original plan are implemented:

- Cross-platform IPC server with JSON-RPC 2.0, client registration, session
  authentication, and request handling on the editor loop.
- Buffer discovery, text reads, cursor reads, and selected-text reads. Selection
  responses include text, individual lines, and one-based start/end positions.
- Ghost proposal overlays that do not mutate the target buffer until accepted.
- Multiple affected-file and chunk fields are accepted by the IPC payload model,
  but they are not the primary user interaction model.
- Four overlay insertion modes: `1d_insert`, `1d_overwrite`, `2d_insert`,
  `2d_overwrite`, `2d_transparent`, and `2d_fuse_corners`.
- External LOGO execution through a proposal-producing IPC request.
- AI-authored undo snapshots, proposal history entries, and history retrieval.
- MCP access to running Zago instances, including explicit instance selection.
- MCP tools for overlay preview, LOGO execution, buffers, text, selection, and
  cursor state.
- Editor LOGO support for light, heavy, double, round, double-round, ASCII, and
  ASCII-rounded borders. Heavy uses the Unicode box-drawing set
  `┏━┓┃┣╋┫┗┻┛`.

The current behavior is intentionally proposal-oriented: an IPC or MCP agent can
prepare a change, but buffer mutation still happens through the editor's normal
proposal acceptance flow.

## 4. Current User Scenarios

### Help with the current text

An agent reads the current selection or cursor context, generates LOGO or overlay
content, and sends a ghost preview. The user can inspect the result in the same
visible text space before accepting it.

### Transform this selection

An agent reads selected prose, code, or table content, transforms it externally,
and sends the result as an overlay. Selection reads are the main bridge between
the user's attention and the agent.

### Draw here

An agent parses a local piece of context, generates table or diagram lines, and
previews them at the current position. Zago's table, Canvas, LOGO, and display-
width logic remain available without asking the user to manage another document.

## 5. Current Boundaries

These ideas remain design targets rather than completed features:

- There is no implemented `zago.event.selectionTriggered` outbound event from an
  Alt+A command.
- Proposal navigation currently uses the editor's existing AI proposal controls;
  the planned Alt+Y/Alt+N/Alt+R and accept-all/reject-all key scheme is not the
  current contract.
- There is no implemented `zago.queue.getPending` or history reapply method.
- The editor can have multiple buffers, but AI interaction is intentionally
  centered on one active buffer and one visible focus. Workspace-wide atomic undo
  and multi-file proposal presentation are not promised.
- Ghost cursors, agent-colored cursors, rationale popups, and OS peer-credential
  verification are not part of the current stable surface.
- Payload and script size limits exist; a general-purpose background execution
  scheduler and a 500 ms LOGO watchdog are future safeguards, not current API
  guarantees.

## 6. Next Steps

1. Make the single-focus proposal state explicit in the editor and protocol.
2. Add a read-only selection-trigger event only if it improves the current-focus
   workflow; keep the existing pull-based `getSelection` path stable.
3. Avoid multi-agent queue features unless a concrete single-user workflow
   proves that they reduce attention cost.
4. Add protocol fixtures generated from the live JSON-RPC and MCP schemas so
   documentation and implementation cannot drift.
5. Continue treating border styles, table cells, Canvas coordinates, and CJK
   display widths as shared editor geometry rather than agent-specific logic.

## 7. Design Principle

> Zago helps a human with this text.

The IPC layer is successful when an agent can understand the current focus and
make a precise, inspectable proposal without taking ownership of the editor or
forcing the human to manage parallel work.
