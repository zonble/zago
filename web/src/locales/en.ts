export const en = {
  pageTitle: "zago — Terminal Text for AI Prompts",
  pageDescription:
    "zago is a keyboard-driven terminal text editor and ASCII/Unicode diagramming engine for AI workflows, Markdown documents, tables, and Editor LOGO graphics.",
  tabDocs: "📖 About zago",
  tabDemo: "💻 Live Demo",
  heroTagline: "A terminal editor built for AI prompts.",
  quickInstallTitle: "Quick Install",
  platformMac: "macOS (Homebrew)",
  platformLinux: "Linux (x86_64 / arm64)",
  platformWin: "Windows (PowerShell)",
  whyTitle: "Why zago?",
  whyItem1:
    "<strong>LLMs & AI agents</strong> frequently generate plain-text ASCII/Unicode diagrams for architecture and planning, but editing them by hand in traditional editors quickly breaks alignment and borders.",
  whyItem2:
    "<strong>Plain-text diagrams in Markdown</strong> are natively prompt-friendly, version-controllable, and zero-dependency across all terminals.",
  howTitle: "How?",
  howItem1:
    "<strong>Canvas mode editing:</strong> Move the cursor freely anywhere in the 2D text canvas without inserting empty lines or spaces manually.",
  howItem2:
    "<strong>Table mode:</strong> Edit text inside ASCII/Unicode tables and boxes seamlessly without breaking or shifting surrounding frames.",
  howItem3:
    "<strong>Quick drawing commands:</strong> Commands like <code>BOX</code>, <code>LINE</code>, and <code>VLINE</code> let you draft complete architecture diagrams in seconds.",
  howItem4:
    "<strong>CJK & Emoji Aware:</strong> Fullwidth CJK characters and emojis are rendered with exact display widths, keeping box boundaries perfectly aligned.",
  howItem5:
    "<strong>Editor LOGO Engine:</strong> Built-in turtle graphics, macros, and scriptable text transformations.",
  jumpDemoBtn: "💻 Launch Live Demo in Browser",
  toolbarTitle: "Interactive Workspace (<code>/workspace</code>)",
  btnImport: "Import",
  btnExportZip: "Export ZIP",
  btnResetVFS: "Reset VFS",
  btnHelp: "Help",
  loadingTitle: "Starting zago Virtual OS",
  loadingStatusInit: "Downloading zago.wasm...",
  loadingDetailInit: "Preparing WebAssembly runtime",
  loadingStatusCached: "Loading zago.wasm from browser cache...",
  loadingDetailCached: "Instant startup from cache",
  startingStatus: "Starting zago Virtual OS...",
  startingDetail: "Instantiating WASI runtime",
  readyStatus: "Ready!",
  readyDetail: "Starting editor...",
  wasmLoadingStatus: "Loading WebAssembly binary...",
  wasmInstantiatingStatus: "Instantiating zago.wasm Virtual OS...",
  editorExited: 'zago exited. Type "zago" to start',
  failedToStart: "Failed to start",
  shellPrompt: "zago $ ",
  shellCommandNotFound: (command: string) =>
    `zago: command not found: ${command}. Type "zago [filename]" to start or "clear" to clear screen.`,
  copied: "Copied!",
  unsupportedTitle: "Browser Not Supported",
  unsupportedMsg:
    "In-app browsers (such as X/Twitter, LINE, or Facebook) or restricted browsers do not support WebAssembly cross-origin isolation (SharedArrayBuffer).",
  unsupportedHint:
    "Please open this page in <strong>Safari</strong>, <strong>Chrome</strong>, or your default browser to run the live terminal.",
  btnCopyLink: "Copy Page Link",
  btnViewDocs: "View Documentation",
  helpDialogTitle: "zago Web Virtual OS",
  helpDialogIntro:
    "<strong>zago</strong> runs with a POSIX-compatible Virtual File System (VFS) in WebAssembly.",
  helpDialogSubtitle: "Useful Commands & Shortcuts:",
  helpItemDir:
    "<code>:dir</code> or <code>:ls</code> : Open interactive Directory Browser for subfolders",
  helpItemSave: "<code>Ctrl + O</code> : Save current buffer to IndexedDB VFS",
  helpItemQuit:
    "<code>Ctrl + Q</code> or <code>Ctrl + X</code> : Exit editor to mini-shell (type <code>zago</code> to return)",
  helpItemCanvas:
    "<code>F8</code> : Toggle 2D Canvas Mode (draw boxes, arrows, and lines)",
  helpItemTable: "<code>F7</code> : Toggle Table Mode",
  helpItemHelp: "<code>Ctrl + G</code> : Open help / command list",
  btnCloseHelp: "Close",
  resetConfirm: "Reset Virtual OS and IndexedDB filesystem to default state?",
  importZipSuccess: (count: number, filename: string) =>
    `Successfully imported ${count} files from "${filename}" into /workspace.\nReloading to mount new filesystem...`,
  importFileSuccess: (filename: string) =>
    `Imported "${filename}" to /workspace.\nReloading to open...`,
  importFailed: (err: string) => `Failed to import file: ${err}`,
  binaryFileNotSupported: (filename: string) =>
    `"${filename}" is a binary file and cannot be opened in zago.`,
};

export type TranslationSchema = typeof en;
