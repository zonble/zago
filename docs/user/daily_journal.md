# Daily Journal Shortcut (日記快捷入口)

This is a planned convenience shortcut, not a separate editor mode.

The idea is simple: when Zago is opened without an explicit file, a shortcut can
open today's journal file. After it opens, the user remains in the normal Zago
editing environment and can use Text, Table, Canvas, Logo, and AI assistance as
usual.

The journal shortcut should help a person get to the text they are thinking about;
it should not introduce another document model or make Zago manage a collection
of notes.

No journal shortcut or related configuration is implemented yet.

## Possible Configuration

The following is a possible future configuration. It is not currently accepted
by `.zagorc`:

```nanorc
# Planned: launch into today's journal when zago starts without CLI file arguments
# set launch-to-journal on

# Planned: set the journal directory
# set journal-folder ~/Journal

# Planned: customize the daily journal filename
# set journal-filename-format YYYY_MM_DD.md
```

Possible settings:

| Setting Key | Values / Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `launch-to-journal` | `on` / `off` | `off` | Planned startup shortcut for opening today's journal. |
| `journal-folder` | String / Path | `~/Journal` | Planned destination directory for the journal. |
| `journal-filename-format` | String | `YYYY_MM_DD.md` | Planned filename template for the daily journal. |

## Possible Startup Behavior

1. An explicit CLI file always wins over the shortcut.
2. The shortcut may create the journal directory if it is missing, subject to
   normal file-system permissions.
3. If today's journal does not exist, the shortcut may open a new buffer bound to
   that path.

Cloud-storage keyword resolution is intentionally a later consideration, not a
current design commitment.

## Possible In-Editor Shortcut

- `:journal`: command for opening today's journal.

This command opens or switches to the journal file and leaves all normal editor modes and AI workflows unchanged.
