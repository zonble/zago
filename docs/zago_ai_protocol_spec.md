# Specification: `zago` AI Editor Operation Protocol (JSON-RPC 2.0)

## 1. User Experience & Multi-File Workspace Flow

The protocol supports **Multi-File Workspace Proposals**, enabling an AI agent to modify multiple files across a project in a single atomic transaction.

```
 [ Workspace Proposal (Refactoring-Bot) ]
    ├── File #1: ARCHITECTURE.md (Update Component Names)
    ├── File #2: README.md       (Update Quickstart Diagram)
    └── File #3: config.json     (Update Schema Version)
```

---

## 2. Multi-File Protocol Payload (`zago.overlay.showPreview`)

Clients send an `affectedFiles` array to push multi-file workspace proposals:

```json
{
  "jsonrpc": "2.0",
  "method": "zago.overlay.showPreview",
  "params": {
    "auth": "256-bit-token",
    "clientId": "Refactoring-Bot",
    "affectedFiles": [
      {
        "filePath": "ARCHITECTURE.md",
        "chunks": [
          {
            "targetLine": 15,
            "targetCol": 1,
            "lines": ["┌───────────────┐", "│  API Gateway  │", "└───────────────┘"],
            "insertMode": "overwrite"
          }
        ]
      },
      {
        "filePath": "README.md",
        "chunks": [
          {
            "targetLine": 30,
            "targetCol": 1,
            "lines": ["| Field | Type | Description |"],
            "insertMode": "overwrite"
          }
        ]
      }
    ]
  },
  "id": 2
}
```

---

## 3. Protocol Method Specifications

### Domain 1: Client Registration & Handshake

#### 1.1 `zago.client.register`
Registers client identity and returns allocated `connectionId`.

---

### Domain 2: Multi-File Ghost Overviews & Workspace Queue

#### 2.1 `zago.overlay.showPreview` (Pushes Multi-File Proposal)
Pushes a multi-file proposal into the workspace proposal queue.
- **Parameters**: `clientId`, `affectedFiles` (Array of `{ filePath, chunks }`).

#### 2.2 `zago.queue.getPending`
Returns list of all pending queued workspace proposals and affected file lists.

---

### Domain 3: AI History & Audit Trail

#### 3.1 `zago.history.getEntries`
Queries recent AI proposal history entries, including multi-file details.

---

## 4. Permission Matrix & Security Policy

| Method | Target Scope | Permission Level | Default Behavior | Human Approval Required |
| :--- | :--- | :--- | :--- | :--- |
| `zago.client.register` | Global | `Auth` | Validates token + OS `SO_PEERCRED` | No |
| `zago.buffer.getText` | Multi-File | `Read` | Allowed | No |
| `zago.overlay.showPreview` | Multi-File | `Transient Queue` | Pushes multi-file proposal to Workspace Queue | No (User reviews in Queue) |
| `zago.buffer.executeLogo` | Workspace | `Mutate` | Sandboxed | **Yes (Pushes to Queue; Press Alt+Y to Accept)** |
