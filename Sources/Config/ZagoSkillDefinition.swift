import Foundation

/// Pure, platform-decoupled specification string for the zago AI skill definition.
/// Safe for Web/WASM targets without filesystem dependencies.
public enum ZagoSkillDefinition {
    public static let markdown: String = """
        ---
        name: zago
        description: >-
          Comprehensive guide for using the zago CLI, Editor LOGO dialect, and IPC socket protocol to draw plain-text ASCII/Unicode boxes, connector lines, tables, flowcharts, turtle graphics, CJK text transformations, buffer macros, and push Dim Gray ghost text overlays. Use this skill when asked to generate plain-text diagrams, flowcharts, tables, or control zago over IPC.
        ---

        # zago - Terminal Text Editor & LOGO Engine Specification

        `zago` is a lightweight terminal text editor with GNU Nano keybinding compatibility, a built-in **Editor LOGO** diagramming and text transformation engine, and a **POSIX local IPC server**.

        You can invoke `zago` from the command line in **headless mode**, connect over a local **IPC Unix domain socket** on supported POSIX systems, or run interactively to render boxes, connector lines, multi-cell tables, flowcharts, turtle drawings, and CJK text transformations directly to `stdout` or terminal buffers.

        ---

        ## 🚀 Quick CLI & IPC Reference

        > Current implementation note: IPC is available as a local POSIX Unix-domain socket. The socket path is generated per session and shown by zago; Windows named-pipe support is not available yet.

        | CLI Command / Option | Mode | Description |
        | :--- | :--- | :--- |
        | `zago -e "<LOGO code>"` | Inline Headless | Executes LOGO script string and prints resulting text buffer to `stdout` |
        | `zago -s <script.logo>` | File Script Headless | Executes a `.logo` script file and prints output to `stdout` |
        | `cat file.txt | zago -e "<LOGO code>"` | Stdin Pipe | Reads text from `stdin`, runs LOGO script on buffer, and outputs to `stdout` |
        | `zago --ipc` | IPC Server | Enables cross-platform IPC socket server (`/tmp/zago-<pid>.sock` or `\\\\.\\pipe\\zago-<pid>`) |
        | `zago --no-ipc` | IPC Disable | Force disables IPC socket server |
        | `zago --mcp` | MCP Server | Runs zago as an Stdio MCP (Model Context Protocol) server for AI co-pilot integration |
        | `zago --install-mcp` | MCP Setup | Installs `zago` MCP server configuration to local user AI directories and Codex (`~/.codex/config.toml`) |
        | `zago --install-skill` | AI Setup | Installs `zago` skill definition to Codex (`~/.codex/skills/zago`) and other local AI skill directories, plus MCP configuration |
        | `zago --uninstall-mcp` | MCP Setup | Removes only the `zago` entry from local user MCP server configurations |
        | `zago --uninstall-skill` | AI Setup | Removes the zago skill definition from local user AI directories |

        ---

        ## 📡 JSON-RPC 2.0 IPC Protocol Specification

        Every connection must first call `zago.client.register` with the session token. All later requests use that connection's registered identity and cannot impersonate another `clientId`.

        When `zago` runs with `--ipc` or `set ipc.enabled true`, external AI agents can connect to `/tmp/zago-<pid>.sock` (Unix) or `\\\\.\\pipe\\zago-<pid>` (Windows) using line-delimited JSON-RPC 2.0.

        ### 1. Registration (`zago.client.register`)
        ```json
        {
          "jsonrpc": "2.0",
          "method": "zago.client.register",
          "params": {
            "auth": "256-bit-token",
            "clientId": "py-architect-bot",
            "clientName": "Architect-Bot",
            "agentType": "diagram_forge",
            "color": "cyan"
          },
          "id": 1
        }
        ```

        ### 2. Read Current Selected Text (`zago.buffer.getSelection`)
        ```json
        {
          "jsonrpc": "2.0",
          "method": "zago.buffer.getSelection",
          "params": {
            "bufferTarget": "active"
          },
          "id": 2
        }
        ```

        Response includes `hasSelection`, `text`, `lines`, and one-based `startLine`, `startColumn`, `endLine`, `endColumn` fields. When no text is selected, `hasSelection` is `false` and `text` is empty.

        MCP exposes the same capability as `zago_get_selection`.

        ### 3. Push Dim Gray Ghost Text Overlay (`zago.overlay.showPreview`)
        ```json
        {
          "jsonrpc": "2.0",
          "method": "zago.overlay.showPreview",
          "params": {
            "auth": "256-bit-token",
            "clientId": "py-architect-bot",
            "reason": "Drafted 3-step payment flow diagram at cursor",
            "affectedFiles": [
              {
                "filePath": "active",
                "chunks": [
                  {
                    "targetLine": 15,
                    "targetCol": 1,
                    "lines": [
                      "┌───────────────┐     ┌───────────────┐",
                      "│  Client App   │ ──► │  Auth Server  │",
                      "└───────────────┘     └───────────────┘"
                    ],
                    "insertMode": "2d_insert"
                  }
                ]
              }
            ]
          },
          "id": 2
        }
        ```

        ### 4. `insertMode` 4-Quadrant Matrix Options
        - **`"1d_insert"`**: 1D Stream Insert (shifts text right and subsequent lines downward).
        - **`"1d_overwrite"`**: 1D Stream Overwrite (replaces characters on line without shifting line length).
        - **`"2d_insert"`**: 2D Matrix Insert (shifts text right **ONLY on lines touched by block height**).
        - **`"2d_overwrite"`**: 2D Matrix Overwrite (overwrites visual X-Y matrix without moving surrounding lines).
        - **`"2d_transparent"`**: 2D Transparent Overlay (spaces preserve underlying canvas text).
        - **`"2d_fuse_corners"`**: 2D Corner Fusing (automatically fuses overlapping box corners `┌` + `│` -> `├`).

        ---

        ## ⌨️ Dedicated Modifier Keybindings Reference

        - **`M+A` / `Ctrl+Y`**: Accept active ghost text proposal.
        - **`M+R` / `Esc`**: Reject active proposal.
        - **`M+P`**: Preview next proposal in queue.
        - **`M+Shift+P`**: Preview previous proposal in queue.

        ---

        ## 📐 Editor LOGO Full API Reference

        `zago` LOGO commands operate on lines, columns, display widths (`displayWidth`), and buffer text.

        ### 1. Drawing & Layout Primitives (`BOX`, `DRAWBOX`, `LINE`, `VLINE`, `TABLE`, `FILL`)

        #### `BOX [width height | "text"] [alignment] [style] [exitPos]`
        - **`BOX "Text"`**: Draws an auto-sized border frame around text.
        - **`BOX 30 5`**: Draws an empty frame of explicit width 30 and height 5.
        - **`BOX "Status" "center" "round"`**: Draws a rounded-corner frame centered on text.
        - **`BOX 20 4 ROUND AT:DOWN`**: Draws a box and moves cursor to line below (`DOWN`).
        - **`DRAWBOX`**: Draws a canvas overlay frame without pushing surrounding text.

        **Frame Styles**: `ROUND` (`╭───╮`), `DOUBLE` (`╔═══╗`), `HEAVY` (`┏━━━┓`), `LIGHT` (default `┌───┐`), `ASCII` (`+---+`), `SINGLE`, `DOUBLE-ROUND`

        **Exit Position Modifiers**:
        - `AT:NE` / `NE`: Top-right corner (default for side-by-side box placement)
        - `AT:SE` / `SE`: Bottom-right corner
        - `AT:NW` / `NW`: Top-left corner
        - `AT:SW` / `SW`: Bottom-left corner
        - `AT:DOWN` / `DOWN`: Line immediately below box (for vertical box stacking)

        #### `LINE [length] [style] [arrowModifier]` & `VLINE`
        - **`LINE 10`**: Horizontal line of length 10.
        - **`VLINE 5`**: Vertical line of height 5.
        - **`LINE ARROW`**: Scans forward to next box border and adds an arrowhead (`───▶`).
        - **`LINE BACKARROW`**: Adds a backward arrow (`◀───`).
        - **`LINE BOTHARROW`**: Adds arrows at both ends (`◀──▶`).

        #### `TABLE rows cols cellWidth [cellHeight]`
        - Example: `TABLE 3 3 12 1` (Draws a 3x3 grid table with cell width 12 and cell height 1).

        #### `FILL "text"`
        - Repeats text inside a box or table cell while preserving borders.

        ---

        ### 2. Turtle / Pen Mode Graphics (`PD`, `PU`, `FD`, `BK`, `RT`, `LT`)

        - **`PD`** (Pen Down): Enables turtle line drawing mode.
        - **`PU`** (Pen Up): Disables drawing during movement.
        - **`FD n`** / **`BK n`**: Moves turtle forward / backward by `n` steps.
        - **`RT angle`** / **`LT angle`**: Rotates turtle right / left by `angle` degrees.
        - **`SETH angle`** / **`HEADING`**: Sets or returns heading angle.
        - **`SETPC color`** / **`SETPS style`**: Sets pen color or pen line style.
        - **`HOME`**, **`CLEAN`**, **`CS`** / **`CLEAR`**: Resets position or clears canvas.

        ---

        ### 3. Text Transformations & CJK Processing (`TRANSLIT`, `TRANSFORM-TO-*`, `SPACING-CJK`)

        - **`TRANSLIT "zago-cjk-punctuation" "text"`**: Converts ASCII punctuation to fullwidth CJK (`,` -> `，`, `.` -> `。`, `?` -> `？`, `!` -> `！`, `:` -> `：`, `;` -> `；`).
        - **`TRANSLIT "zago-cjk-spacing" "text"`** / **`SPACING-CJK "text"`**: Standardizes spacing between CJK and Latin characters.
        - **`TRANSFORM-TO-HANS "text"`**: Converts Traditional Chinese to Simplified Chinese (`Hant-Hans`).
        - **`TRANSFORM-TO-HANT "text"`**: Converts Simplified Chinese to Traditional Chinese (`Hans-Hant`).
        - **`TRANSFORM-TO-LATIN "text"`**: Pinyin / Romanization (`Any-Latin`).
        - **`TRANSFORM-TO-HIRAGANA "text"`** / **`TRANSFORM-TO-KATAKANA "text"`**: Japanese script conversions.

        ---

        ### 4. Text Analysis & Statistics

        - **`CHARCOUNT "text"`** / **`CHAR-COUNT`**: Total character count.
        - **`CHARCOUNT-CJK "text"`**: CJK character count.
        - **`CHARCOUNT-WORDS "text"`**: Word count.
        - **`CHARCOUNT-EMOJI "text"`**: Emoji count.
        - **`CHARCOUNT-LINES "text"`**: Line count.

        ---

        ### 5. Interactive Input & Output

        - **`READWORD ["prompt"]`** / **`RW`**: Prompts user for a line of text input (or reads from stdin in CLI).
        - **`READCHAR ["prompt"]`** / **`RC`**: Prompts user for a single keypress.
        - **`TYPE "text"`** / **`PRINT "text"`**: Writes text to buffer.
        - **`SHOW "message"`**: Displays status bar notification.
        - **`DATE ["format"]`**, **`TIME ["format"]`**: Inserts current date / time.
        - **`BOLD "text"`**, **`ITALIC "text"`**, **`STRIKETHROUGH "text"`**, **`CODE "text"`**: Applies Markdown formatting.

        ---

        ### 6. Control Flow, Arithmetic, & Procedures

        - **Variables**: `MAKE "var value`, `:var`
        - **Loops**: `REPEAT n [ commands ]`, `WHILE condition [ commands ]`
        - **Conditionals**: `IF condition [ commands ]`, `IFELSE condition [ trueCmds ] [ falseCmds ]`, `TEST condition`, `IFT [ trueCmds ]`, `IFF [ falseCmds ]`
        - **Arithmetic**: `+`, `-`, `*`, `/`, `MOD`, `ROUND`, `SQRT`, `ABS`, `RANDOM`
        - **Relational**: `=`, `<>`, `<`, `>`, `<=`, `>=`
        - **Lists**: `FIRST`, `BUTFIRST` (`BF`), `LAST`, `BUTLAST` (`BL`), `COUNT`, `ITEM`, `WORD`, `LIST`
        - **Procedures**:
          ```logo
          TO STEPBOX :name
            BOX :name ROUND DOWN 1
            LINE ARROW 3 DOWN
          END
          ```

        ---

        ### 7. Editor & Buffer Navigation Commands

        - **Cursor Navigation**: `GOTO line col`, `MOVE line col`, `UP n`, `DOWN n`, `LEFT n`, `RIGHT n`
        - **Selection & Clipboard**: `MARK`, `UNMARK`, `CUT`, `COPY`, `PASTE`; IPC/MCP agents can read selected text with `zago.buffer.getSelection` / `zago_get_selection`.
        - **File & Buffer Actions**: `SAVE`, `WRITE path`, `OPEN path`, `EDIT path`, `BUFFER NEXT`, `BUFFER PREV`, `BUFFER n`

        ---

        ## 🤖 AI Copy-Pasteable Examples

        ### Example 1: 3-Step Vertical Flowchart
        ```bash
        zago -e 'BOX "Step 1: Input Data" "round" AT:DOWN LINE ARROW 3 DOWN BOX "Step 2: Processing" "double" AT:DOWN LINE ARROW 3 DOWN BOX "Step 3: Output Result" "round"'
        ```

        ### Example 2: Side-by-Side Architecture Diagram
        ```bash
        zago -e 'BOX "Client App" "round" NE LINE ARROW 10 RIGHT BOX "API Gateway" "double" NE LINE ARROW 10 RIGHT BOX "Database" "heavy"'
        ```

        ### Example 3: 3x3 Grid Table
        ```bash
        zago -e 'TABLE 3 3 15 1'
        ```

        ### Example 4: CJK Punctuation & Spacing Normalization via Stdin
        ```bash
        echo "Hello,world!這是測試." | zago -e 'TYPE TRANSLIT "zago-cjk-punctuation" TRANSLIT "zago-cjk-spacing" READWORD'
        ```

        ---

        ## 🛠️ Execution Rules for AI Agents

        1. **Use `zago -e` for inline plain-text diagrams**: Output clean ASCII/Unicode diagram text to stdout.
        2. **Use `zago --ipc` for interactive terminal previews**: Connect to Unix socket `/tmp/zago-<pid>.sock` and push `showPreview` ghost overlays.
        3. **Chain LOGO commands sequentially**: Write commands separated by spaces or newlines.
        4. **Respect CJK Display Width**: `zago` automatically calculates visual display width (CJK = 2 columns, ASCII = 1 column).
        """
}
