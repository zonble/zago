import { get, set, del, keys } from "idb-keyval";

export interface WorkspaceFile {
  name: string;
  content: string;
}

const DEFAULT_WELCOME_CONTENT = `# Welcome to zago Web Edition! 🐢

zago is a terminal-based text editor with built-in Editor LOGO,
Unicode canvas diagramming, and multi-file editing.

## Quick Start
- Type \`ESC ESC\` to enter **Canvas Mode** for free-form box & line drawing.
- Press \`Ctrl + G\` (or \`F1\`) to open the interactive command & help menu.
- Press \`Ctrl + O\` to save your changes.
- Press \`Ctrl + X\` to exit or switch files.

## Sample ASCII Diagram (Draw with Canvas Mode):
┌───────────────────────────┐
│        zago.wasm          │
│   WebAssembly + Swift 6   │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│         xterm.js          │
│    Browser Web Terminal   │
└───────────────────────────┘

Happy Editing!
`;

const DEFAULT_DEMO_LOGO = `; Editor LOGO Demo Script
; Draw a box and insert a header

CLEAR
GOTO 2 2
BOX 40 10 DOUBLE
GOTO 4 4
TYPE "Hello from zago WebAssembly!"
GOTO 5 4
TYPE "Swift on WebAssembly in the Browser"
`;

export class WorkspaceStorage {
  private static readonly PREFIX = "zago_file:";

  static async initializeDefaults(): Promise<void> {
    const allKeys = await keys();
    const hasFiles = allKeys.some((k) => String(k).startsWith(this.PREFIX));

    if (!hasFiles) {
      await this.saveFile("welcome.md", DEFAULT_WELCOME_CONTENT);
      await this.saveFile("demo.logo", DEFAULT_DEMO_LOGO);
    }
  }

  static async listFiles(): Promise<string[]> {
    const allKeys = await keys();
    return allKeys
      .filter((k) => String(k).startsWith(this.PREFIX))
      .map((k) => String(k).slice(this.PREFIX.length));
  }

  static async getFile(filename: string): Promise<string | undefined> {
    return await get<string>(this.PREFIX + filename);
  }

  static async saveFile(filename: string, content: string): Promise<void> {
    await set(this.PREFIX + filename, content);
  }

  static async deleteFile(filename: string): Promise<void> {
    await del(this.PREFIX + filename);
  }

  static async clearAll(): Promise<void> {
    const allKeys = await keys();
    for (const key of allKeys) {
      if (String(key).startsWith(this.PREFIX)) {
        await del(key);
      }
    }
    await this.initializeDefaults();
  }
}
