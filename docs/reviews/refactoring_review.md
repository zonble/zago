# Refactoring Review

This review examines the current zago project through the lens of Martin
Fowler's *Refactoring*. It focuses on code structure, responsibility boundaries,
duplication, coupling, and the ease of making future changes. It is a review of
the current state, not a committed implementation roadmap.

## Baseline

- Source tree: approximately 182 Swift source files and 35,000 lines.
- Test suite: 534 tests in 17 suites passed with `swift test`.
- Working tree was clean when this review was performed.
- The project has clear functional modules, but the editor and IPC layers are
  becoming the main change centres.

## Findings

### High: Editor is becoming a God Object

`Sources/Editor/Controllers/Editor.swift` owns buffers, cursor state, modes,
rendering, commands, configuration, Git state, LOGO execution, AI proposals,
external requests, and the editor loop. Its public mutable buffer state is also
exposed directly, and the type is declared `@unchecked Sendable`.

References:

- `Sources/Editor/Controllers/Editor.swift:12-34`
- `Sources/Editor/Controllers/Editor.swift:148-155`
- `Sources/Editor/Controllers/Editor.swift:425-439`

This creates a large change surface and makes thread-safety depend on convention
rather than the type system. Potential refactorings are to encapsulate the
buffer collection, extract editor-loop runtime state, and move external editor
operations into an application service.

### High: IPC transport is not separated from protocol handling

The POSIX IPC server combines Unix socket lifecycle, connection management,
framing, timeouts, payload limits, response writing, and JSON-RPC dispatch in a
single implementation. The Windows server is currently a stub, so implementing
named pipes directly beside the POSIX code would encourage another large,
platform-specific copy.

References:

- `Sources/IPCServer/ZagoIPCServer.swift:168-205`
- `Sources/IPCServer/ZagoIPCServer.swift:207-486`
- `Sources/IPCServer/ZagoIPCClient.swift:265-441`

The desirable boundary is JSON-RPC handler -> framed byte connection -> POSIX
socket or Windows named pipe. The JSON-RPC contract should remain independent of
the transport.

### Medium: MCP server has several unrelated responsibilities

`ZagoMCPServer` defines MCP protocol state, tool schemas, tool dispatch, session
selection, IPC calls, response formatting, and the stdio loop. Adding a tool,
changing MCP negotiation, or changing instance discovery all modifies the same
class.

References:

- `Sources/IPCServer/ZagoMCPServer.swift:4-12`
- `Sources/IPCServer/ZagoMCPServer.swift:222-381`
- `Sources/IPCServer/ZagoMCPServer.swift:403-650`

Possible extractions are `MCPProtocolSession`, `ZagoToolCatalog`,
`ZagoToolDispatcher`, `ZagoSessionSelector`, and `MCPStdioTransport`.

### Medium: LayoutEngine duplicates the wrapping algorithm (Resolved)

`computeLineChunks` and `visitWrappedLine` originally duplicated the ASCII and Unicode
wrapping loops. This was consolidated so `visitWrappedLine` delegates directly to
the cached `wrapLine` / `computeLineChunks` pipeline.

### Medium: AI history is global state (Resolved)

`AIHistoryLogManager.shared` was removed and replaced with an injected `AIHistoryStore`
(`InMemoryAIHistoryStore`) adhering to `AIHistoryStoring`, owned individually by each `Editor`
instance via `EditorDependencies`.

### Medium: Cross-module values are often Stringly Typed

History actions, cursor modes, LOGO modes, and related IPC values are represented
as strings. These values cross module boundaries, so spelling errors and missing
cases are discovered at runtime rather than at compile time.

References:

- `Sources/Editor/Models/AIHistoryLog.swift:3-10`
- `Sources/IPCServer/ZagoIPCServerContracts.swift:34-47`
- `Sources/IPCServer/ZagoIPCServerContracts.swift:83-101`
- `Sources/Editor/Controllers/Editor+ExternalRequests.swift:140-152`

Use enums internally and convert to protocol strings only at the IPC boundary.

### Medium: External LOGO execution constructs a complete scratch Editor (Resolved)

`externalExecuteLogo` previously created a full `Editor` to obtain a temporary LOGO
execution buffer. This was refactored by extracting `TextBufferLogoDelegate` and
`LogoExecutionService.render(script:...)`, allowing headless preview and execution
to run directly on standalone `TextBuffer` instances without Editor or UI dependencies.

## Recommended order

1. Use the Windows named-pipe work to establish a transport abstraction for IPC.
2. Separate MCP protocol/session/tool responsibilities.
3. Encapsulate `Editor` buffer and runtime state, then extract external request
   handling.
4. Consolidate the duplicated `LayoutEngine` wrapping algorithm.
5. Replace AI history global state and stringly typed internal values.

## Deliberately deferred

The size of `LogoEngine`, `TableModeController`, and `Renderer` is not by itself
enough reason to split them. Their current file boundaries largely follow
functional concerns. They should be refactored when a concrete change exposes a
responsibility boundary, rather than split mechanically by line count.
