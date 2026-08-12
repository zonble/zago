# Zago AI/IPC Protocol

This document describes the currently implemented protocol. It uses line-delimited
JSON-RPC 2.0 over the Zago IPC endpoint. Clients must register before calling
buffer or proposal methods.

The protocol is intentionally local in scope: an agent works with the selected
text, current cursor, active table cell, Canvas region, or current LOGO state. It
is not a contract for simultaneous multi-document editing.

## 1. IPC Lifecycle

1. Connect to the Zago IPC socket or named pipe.
2. Call `zago.client.register` with the session token and client identity.
3. Use the registered connection for subsequent calls.
4. Unregistering or disconnecting removes the registered client identity.

Example registration:

```json
{
  "jsonrpc": "2.0",
  "method": "zago.client.register",
  "params": {
    "auth": "session-token",
    "clientId": "agent-01",
    "clientName": "Diagram Agent",
    "agentType": "diagram_forge",
    "color": "cyan"
  },
  "id": 1
}
```

## 2. Implemented JSON-RPC Methods

| Method | Purpose |
| --- | --- |
| `zago.client.register` | Authenticate and register a client connection. |
| `zago.buffer.getBuffers` | Return open buffers and the focused buffer. |
| `zago.buffer.getText` | Read all or a line range from a buffer. |
| `zago.buffer.getSelection` | Read selected text and its one-based range. |
| `zago.buffer.getCursor` | Read cursor line, column, visual column, and mode. |
| `zago.overlay.showPreview` | Queue a ghost proposal without mutating the buffer. |
| `zago.buffer.executeLogo` | Execute LOGO through the proposal path. |
| `zago.history.getEntries` | Read recorded AI proposal history entries. |

`bufferTarget` accepts the active buffer target or a buffer identifier/path as
defined by the current IPC server implementation. `getSelection` returns:

```json
{
  "hasSelection": true,
  "text": "selected text",
  "lines": ["selected text"],
  "startLine": 4,
  "startColumn": 3,
  "endLine": 4,
  "endColumn": 16
}
```

When there is no selection, `hasSelection` is `false`, `text` and `lines` are
empty, and the range fields are `null`.

## 3. Preview Payload

`zago.overlay.showPreview` accepts a rationale and a proposal payload. The normal
interaction is one active buffer and one visible focus. The wire model still has
`affectedFiles` and `chunks` so the transport can evolve without changing the
basic preview representation, but clients should send one focused proposal at a
time.

```json
{
  "jsonrpc": "2.0",
  "method": "zago.overlay.showPreview",
  "params": {
    "clientId": "agent-01",
    "reason": "Drafted a payment flow from the selected text.",
    "affectedFiles": [
      {
        "filePath": "active",
        "chunks": [
          {
            "targetLine": 15,
            "targetCol": 1,
            "lines": [
              "┏━━━━━━━━━━━━━━━┓",
              "┃  Payment API  ┃",
              "┗━━━━━━━━━━━━━━━┛"
            ],
            "insertMode": "2d_overwrite"
          }
        ]
      }
    ]
  },
  "id": 2
}
```

The preview is transient. Accepting it is an editor action and is recorded in
the undo/history model; showing it alone does not set the target buffer modified.
The human remains focused on the current text while reviewing it.

Supported `insertMode` values:

| Value | Behavior |
| --- | --- |
| `1d_insert` | Insert a stream and shift following content. |
| `1d_overwrite` | Replace content on the affected line. |
| `2d_insert` | Insert a two-dimensional block on affected lines. |
| `2d_overwrite` | Overwrite a visual matrix without shifting lines. |
| `2d_transparent` | Preserve spaces from the underlying canvas. |
| `2d_fuse_corners` | Fuse overlapping box corners and line junctions. |

## 4. LOGO Execution

`zago.buffer.executeLogo` accepts a script and optional execution mode. LOGO
execution is routed through the editor delegate and can produce a proposal rather
than silently changing the buffer.

LOGO's operational model is a single turtle in a single text space. A script
changes the current position, heading, drawing state, and visible buffer context;
it does not require the agent to coordinate a set of documents.

The current border styles are:

| Style | Example |
| --- | --- |
| `single` | `┌──┐` |
| `heavy` | `┏━━┓` |
| `double` | `╔══╗` |
| `round` | `╭──╮` |
| `double-round` | `╭══╮` |
| `ascii` | `+--+` |
| `ascii-round` | `/--\\` |

Heavy is supported by `BOX`, `TABLE BORDER heavy`, `LINE heavy`, `VLINE heavy`,
Canvas junction fusion, and table-cell detection.

## 5. MCP Mapping

The MCP server exposes the following tools after the normal MCP initialize flow:

| MCP Tool | IPC Capability |
| --- | --- |
| `zago_list_instances` | Discover running Zago instances. |
| `zago_select_instance` | Select the target instance. |
| `zago_overlay_preview` | Show a ghost overlay in the selected instance. |
| `zago_execute_logo` | Execute LOGO in the selected instance. |
| `zago_get_buffers` | Read open buffers. |
| `zago_get_text` | Read buffer text. |
| `zago_get_selection` | Read current selected text and range. |
| `zago_get_cursor` | Read cursor and mode state. |

MCP clients call these through `tools/list` and `tools/call`. Instance selection
is explicit so a client does not accidentally operate on an arbitrary running
editor. After selection, the intended workflow is to read the current focus,
make one proposal or LOGO operation, and let the human review it.

## 6. Error and Limit Notes

The server returns standard JSON-RPC parse/request errors and authorization or
execution failures from the IPC layer. Current implementation limits include a
maximum overlay of 1,000 lines and a maximum LOGO script payload of 1 MiB.
Clients should treat error codes and exact limits as implementation details until
they are promoted into a versioned compatibility contract.

The following are planned, but are not current methods: outbound selection
events, pending-queue inspection, history reapply, accept-all/reject-all, and
workspace-wide atomic undo. These are deliberately lower priority because they
would make the human manage parallel AI work in a single-focus terminal editor.
