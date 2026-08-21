# Editor LOGO Security Architecture & Sandbox Design: Why `zago` Rejects Shell Commands

This document formalizes the security architecture of `zago` and the **Editor LOGO** dialect, explaining why shell command execution, process spawning, and arbitrary OS system calls are strictly excluded from the language engine and editor commands.

---

## 🎯 Core Architectural Principle: Pure Sandbox

`zago` and its embedded **Editor LOGO** runtime enforce a strict **Zero-OS-Execution / Pure Layout & Computation Sandbox**:

> **Non-Negotiable Rule**:  
> Neither the `zago` interactive editor nor the Editor LOGO language engine will ever provide primitives or command hooks to spawn subshells, execute arbitrary system binaries, or invoke OS shell commands (such as `SHELL`, `EXEC`, `SYSTEM`, `POPOUT`, or `!cmd`).

All operations in Editor LOGO are strictly constrained to:
1. **Memory & AST evaluation** (variables, loops, procedures, recursion limits).
2. **Pure data transformations** (string manipulations, regular expressions, CJK width calculations, formatters, calendar conversions).
3. **Buffer and canvas rendering** (box drawing, table layouts, connector lines, typography, ghost overlay proposals).

---

## 🏛️ Historical Precedents and Why We Depart From Them

### 1. The UCBLogo Trap (`SHELL`, `POPIN`, `POPOUT`)
In the 1980s and 1990s, Brian Harvey's UCBLogo aimed to serve as a general-purpose Unix programming environment alongside languages like Lisp and Tcl. To achieve this, UCBLogo introduced OS interaction primitives:
- `SHELL [command string]` — spawned a Unix subshell.
- `POPIN` / `POPOUT` — opened bidirectional pipes to external processes.
- `COPEN` / `NETSTART` — raw network socket interfaces.

While flexible for its era, embedding arbitrary process spawning into a DSL blurs the boundary between layout computation and system orchestration, turning a domain language into an uncontrolled attack surface.

### 2. The Classic Editor Escape Problem (`nano`, `vi`, `ed`)
Traditional Unix text editors frequently included shell escape hatches:
- **`nano`**: `Ctrl+R` $\rightarrow$ `Ctrl+X` ("Execute Command") and `Ctrl+T` shell suspension.
- **`vi` / `vim`**: `:!command` and `:r !command`.
- **`ed`**: `!command`.

In modern security, these escape hatches represent well-known security liabilities documented across **GTFOBins**:
- **Privilege Escalation**: When administrators grant constrained editing permissions (e.g. via `sudo` or restricted shells like `rbash`), built-in shell escape commands allow users to immediately escape and spawn an unrestricted root shell.
- **Supply-Chain & Macro Injections**: Opening an untrusted file or running a third-party editor macro can trigger hidden shell commands behind the scenes.

---

## 🔒 Why Rejection of Shell Commands Is Vital for `zago`

### 1. Safe AI & Remote IPC Automation (JSON-RPC / MCP)
`zago` is built for modern AI pair-programming and remote editor automation:
- It exposes a JSON-RPC 2.0 IPC socket (`/tmp/zago-<pid>.sock`).
- It integrates with the **Model Context Protocol (MCP)** and AI agent sidecars.
- AI models generate Editor LOGO code to draw ASCII art, format Markdown tables, and automate repetitive prose editing.

If Editor LOGO supported shell execution:
- Any prompt injection in an LLM could lead to **Remote Code Execution (RCE)** on the user's host machine.
- With a strict sandbox, executing or previewing AI-generated LOGO code is **100% safe** by design.

### 2. Proposal & Ghost Overlay Preview Safety
`zago` provides Dim Gray ghost text overlays for proposing changes before the user accepts them:
- When a macro or IPC request generates a proposal, the script is evaluated to render the prospective buffer state.
- Because the engine is completely pure and has zero OS side effects, generating or discarding proposals is guaranteed never to alter the filesystem, make network calls, or launch external processes.

### 3. Determinism & Testability
Without non-deterministic OS environment dependencies:
- LOGO scripts produce identical rendering and data output across macOS, Linux, and Windows.
- The entire test suite (800+ automated unit and integration tests) runs purely in memory without flaky process mocks or OS-level side effects.

### 4. Separation of Concerns
`zago` adheres to the Unix philosophy of doing one thing and doing it best:
- **`zago`'s domain**: Buffer editing, typography, CJK alignment, Unicode drawing, and structured text manipulation.
- **External orchestration**: Handled by the user's shell, terminal emulator, or explicit MCP host tools — *outside* the editor sandbox.

---

## 📊 Security Boundary Summary

| Capability | Supported in Editor LOGO? | Rationale |
| :--- | :---: | :--- |
| **Arithmetic & Logic** | ✅ Yes | Safe, bounded in-memory computation |
| **String & Text Transforms (ICU / Regex)** | ✅ Yes | Pure data processing |
| **ASCII / Unicode Drawing & Layout** | ✅ Yes | Constrained to editor canvas/buffer matrix |
| **Procedures & Recursion** | ✅ Yes | Protected by call stack depth limits |
| **Buffer Ghost Overlays & Proposals** | ✅ Yes | In-memory preview, undoable |
| **Arbitrary Shell Execution (`SHELL`)** | ❌ **Strictly Rejected** | Prevents RCE and privilege escalation |
| **Process Piping / Spawning (`POPIN`/`POPOUT`)** | ❌ **Strictly Rejected** | Eliminates subshell escape vulnerabilities |
| **Arbitrary Network Socket Primitives** | ❌ **Strictly Rejected** | Prevents unauthorized network egress |

---

## 🛡️ Summary

By explicitly rejecting shell command execution, `zago` ensures that Editor LOGO remains a **powerful, expressive, yet entirely safe and predictable DSL** for human editors, automated scripts, and AI agents alike.
