# Daily Journal Shortcut (日記快捷入口)

This is a convenience shortcut, not a separate editor mode.

The idea is simple: when Zago is opened without an explicit file (or with the `-j / --journal` flag), a shortcut can
open today's journal file (`YYYY_MM_DD.md`, e.g. `2026_08_22.md`). After it opens, the user remains in the normal Zago
editing environment and can use Text, Table, Canvas, Logo, and AI assistance as usual.

The journal shortcut helps a person get to the text they are thinking about; it does not introduce another document model or make Zago manage a collection of notes.

## Configuration

In `~/.zagorc`:

```nanorc
## Launch into today's journal when zago starts without CLI file arguments
# set launch-to-journal on

## Set destination directory for the daily journal
# set journal-folder ~/Documents/zago_journal

## Cloud storage examples:
## iCloud Drive (macOS):
# set journal-folder ~/Library/Mobile\ Documents/com~apple~CloudDocs/zago_journal
## Google Drive (macOS):
# set journal-folder ~/Library/CloudStorage/GoogleDrive-user@example.com/My\ Drive/zago_journal
## Google Drive (Windows):
# set journal-folder G:/My Drive/zago_journal
## Dropbox (macOS / Windows):
# set journal-folder ~/Dropbox/zago_journal
## OneDrive (macOS / Windows):
# set journal-folder ~/OneDrive/zago_journal
```

Settings:

| Setting Key | Values / Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `launch-to-journal` | `on` / `off` | `off` | Startup shortcut for opening today's journal. |
| `journal-folder` | String / Path | `~/Documents/zago_journal` | Destination directory for daily journals. |

Daily journal files are automatically named in `YYYY_MM_DD.md` format (for example `2026_08_22.md`).

## CLI Options

- `-j` / `--journal`: Launch directly into today's journal file.
- An explicit CLI file argument (e.g. `zago doc.txt`) always takes precedence over `launch-to-journal`.

## In-Editor Shortcuts

- **Command Bar**: `:journal` opens or switches to today's journal buffer.
- **Menu Bar**: **Tools (工具)** → **Today's Journal (今日日記)** (`menu.tools.journal`).

This shortcut opens or switches to the journal file and leaves all normal editor modes and AI workflows unchanged.
