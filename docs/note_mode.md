# `zago` Note Mode (筆記模式)

`zago` includes a dedicated **Note Mode** designed for frictionless daily journaling, note-taking, and rapid markdown entry. When enabled, `zago` automatically navigates to today's note file upon startup or via in-editor commands.

---

## Quick Configuration (`.zagorc`)

Add the following directives to your `~/.zagorc` or `./.zagorc`:

```nanorc
# Enable launching into today's note when zago starts without CLI file arguments
set launch-to-note on

# Set the destination directory (supports Cloud Storage keywords: gdrive, onedrive, icloud, dropbox)
set note-folder gdrive/Notes

# Custom daily note filename format (default: YYYY_MM_DD.md)
set note-filename-format YYYY_MM_DD.md
```

---

## Configuration Options

| Setting Key | Alias | Values / Type | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `launch-to-note` | `launch_to_note` | `on` / `off` | `off` | When `on`, launching `zago` without file path arguments automatically opens today's note. |
| `note-folder` | `note_folder` | String / Path | `~/Notes` | Target directory for daily notes. Supports absolute paths, `~`, env vars, spaces, and Cloud Storage presets. |
| `note-filename-format` | `note_filename_format` | String | `YYYY_MM_DD.md` | Date formatting template for daily note files (e.g. `YYYY_MM_DD.md`, `YYYY-MM-DD.md`). |

---

## 🌐 Cross-Platform Cloud Storage Auto-Discovery

`note-folder` supports cloud storage provider keywords and optional subdirectories (e.g., `gdrive/Journal`). `zago` automatically resolves physical sync paths on macOS, Windows, and Linux:

| Provider Keyword | macOS Search Paths | Windows Search Paths | Linux Search Paths | Fallback Path |
| :--- | :--- | :--- | :--- | :--- |
| `gdrive` / `google-drive` | `~/Library/CloudStorage/GoogleDrive-*`<br>`~/Google Drive` | `%LOCALAPPDATA%\Google\DriveFS\*`<br>`%USERPROFILE%\Google Drive` | `~/Google Drive`<br>`~/Insync/*/Google Drive` | `~/Google Drive` |
| `onedrive` | `~/Library/CloudStorage/OneDrive-*`<br>`~/OneDrive` | `%OneDrive%`<br>`%USERPROFILE%\OneDrive` | `~/OneDrive`<br>`~/Insync/*/OneDrive` | `~/OneDrive` |
| `icloud` / `icloud-drive` | `~/Library/Mobile Documents/com~apple~CloudDocs` | `%USERPROFILE%\iCloudDrive` | N/A | `~/iCloudDrive` |
| `dropbox` | `~/Library/CloudStorage/Dropbox`<br>`~/Dropbox` | `%USERPROFILE%\Dropbox`<br>`%APPDATA%\Dropbox` | `~/Dropbox` | `~/Dropbox` |

---

## Startup & Directory Creation Behavior

1. **CLI File Override**: If you start `zago` with an explicit file argument (e.g., `zago main.swift`), `launch-to-note` is bypassed for that session.
2. **Directory Creation**: If the resolved `note-folder` does not exist, `zago` automatically creates it recursively (`mkdir -p`).
3. **File Creation**: If today's note file does not exist on disk yet, `zago` opens a new buffer bound to that path, allowing you to edit and save (`:w` / `^O`).

---

## In-Editor Commands & LOGO Integration

### Command Bar Shorthand
- `:note` or `:today`: Instantly open or switch to today's note buffer from within an active editing session.

### Editor LOGO Commands & Shortcuts
- `OPEN-NOTE` / `NOTE`: LOGO command to navigate to today's note.
- Key Binding Example in `.zagorc`:
  ```nanorc
  bind ^N logo:open-note
  ```
