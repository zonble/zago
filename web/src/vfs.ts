import { get, set, del, keys } from "idb-keyval";
import JSZip from "jszip";
import { File, Directory, Inode } from "@bjorn3/browser_wasi_shim";

export interface VFSNode {
  path: string; // Absolute normalized path e.g. "/workspace/src/demo.logo"
  name: string;
  isDirectory: boolean;
  content?: Uint8Array;
  mtime: number;
  size: number;
}

const VFS_PREFIX = "zago_vfs:";

const DEFAULT_WELCOME_MD = `# zago Interactive Tutorial

Note: Use your keyboard to interact with the document.
Arrow keys / Page Up / Page Down move the cursor.

## Canvas Mode

\`\`\`
┌────────┐          ┌────────┐
│        │          │        │
│ Begin  x          │  End   │
│        │          │        │
└────────┘          └────────┘
\`\`\`

- Move the cursor to "x".
- Press F8 to enter Canvas Mode.
- Press Shift + Right Arrow to draw a line.
- Continue pressing to extend the line.
- Press Ctrl + Arrow or Ctrl + Shift + Arrow to draw arrows.
- Press F1 to show the menu and select another style under "Borders".
- Press F8 again to exit Canvas Mode.

## Table Mode

\`\`\`
┌────────────────┬────────────────┬────────────────┐
│ Press F7 Here  │                │                │
├────────────────┼────────────────┼────────────────┤
│                │                │                │
└────────────────┴────────────────┴────────────────┘
\`\`\`

- Press F7 in any cell to enter Table Mode.
- You can edit the text content inside the cell without breaking table borders.
- Press F7 again to exit Table Mode.

## LINE Command

\`\`\`
┌────────┐          ┌────────┐
│        │          │        │
│ Begin  │          │  End   │
│        ├──────────┤        │
└────────┘          └────────┘
┌────────┐          ┌────────┐
│        │          │        │
│ Begin  x          │  End   │
│        │          │        │
└────────┘          └────────┘
\`\`\`

- ESC opens the command prompt.
- ESC again dismisses the prompt.
- Move cursor to "x".
- Press ESC, type "LINE", and press Enter (case-insensitive).
- A connecting line will automatically bridge to the next box!

\`\`\`
┌────────┐   ┌────────┐ 
│        │   │        │ 
│ Begin  │   │  End   │ 
│        │   │        │        
└───x────┘   └────┬───┘ 
                  │
                  │
                  │
┌────────┐   ┌────┴───┐ 
│        │   │        │ 
│ Begin  │   │  End   │ 
│        │   │        │ 
└────────┘   └────────┘ 
\`\`\`

- Move cursor to "x".
- Press ESC, type "VLINE", and press Enter.
- A vertical line will automatically bridge downwards!

## Additional Border and Arrow Styles

Try these commands for creating lines with specific styles:

- LINE ->>
- LINE =~>
- VLINE <|+|>

Syntax: [begin arrow][border][end arrow]

### Border Styles

- Single: -
- Double: =
- Heavy: +
- ASCII: A
- Double Dash: --
- Heavy Double Dash: ++
- Triple Dash: ---
- Heavy Triple Dash: +++
- Quadruple Dash: ----
- Heavy Quadruple Dash: ++++

### Arrow Styles

- ASCII: < or >
- Solid: << or >>
- Stemmed: <~ or ~>
- Hollow: <| or |>
- Small: <. or .>

## BOX and DRAWBOX Commands

Try these commands to create boxes:

- BOX "Hi"        ; Inserts a box with "Hi" inside.
- DRAWBOX "There" ; Overlays a box over current content without shifting lines.
- BOX 20 5 "Hi"   ; Inserts a box with specific width and height.
- BOX "Hi" =      ; Inserts a box with double border.
- BOX "Hi" =)     ; ")" indicates rounded corners.

Border styles available: - = + A -- ++ --- +++ ---- ++++

## FILL and INSET Commands

\`\`\`
Fill                 Inset
┌──────────────────┐ ┌──────────────────┐
│f                 │ │i                 │
│                  │ │                  │
│                  │ │                  │
│                  │ │                  │
└──────────────────┘ └──────────────────┘
\`\`\`

- Move cursor to "f".
- Press ESC, type "FILL <text>", and press Enter.
  The box will be filled with your text.
- Move cursor to "i".
- Press ESC, type "INSET <text>", and press Enter.
  The text will be centered inside the box.

## Combined Commands & Procedures

You can combine commands inside the ESC command prompt:

- BOX DATE             ; Place the current date inside a box.
- BOX DATE =)          ; Place date in a rounded double-line box.
- REPEAT 3 [BOX "hi"]  ; Draw 3 sequential boxes.

## Run Commands Inline

Besides using the ESC command prompt, you can run any line in your text
as commands by pressing ^Q (or F2 to run macro).

Try running these text transformation commands:

move end newline type tohiragana Sakura      ; Press ^Q
move end newline type tokatakana Ramen       ; Press ^Q
move end newline type toromaji ラメン        ; Press ^Q
move end newline type tohant 简体中文转繁体  ; Press ^Q
move end newline type tohans 繁體中文轉簡體  ; Press ^Q
move end newline box "Zago rocks" se newline ; Press ^Q

## And More!

zago has a rich command set and Editor LOGO syntax to turn your text files into
an interactive plain-text design canvas.

For advanced usage, run "help-cmd" or "help-key" in the ESC prompt to explore more.

Happy Editing!
`;

const DEFAULT_DEMO_LOGO = `; Editor LOGO Demo Script
; Draw a styled double-line box and type text

CLEAR
GOTO 2 2
BOX 42 8 DOUBLE
GOTO 4 4
GOTO 5 4
TYPE "Full VFS + Directory Navigation Enabled"
`;

const DEFAULT_EXAMPLE_DIAGRAM = `Component Architecture
======================

+------------------+         +------------------+
|   Client UI      | <-----> |   Wasm Core      |
|  (xterm.js + VFS)|         |  (zago + LOGO)   |
+------------------+         +------------------+
          |                           |
          v                           v
+------------------+         +------------------+
|   IndexedDB VFS  |         |   Shared Stdin   |
+------------------+         +------------------+
`;

export class VirtualOSStorage {
  /**
   * Initializes default workspace files if IndexedDB VFS is empty.
   */
  static async initializeDefaults(): Promise<void> {
    const allKeys = await keys();
    const hasVFS = allKeys.some((k) => String(k).startsWith(VFS_PREFIX));

    if (!hasVFS) {
      const encoder = new TextEncoder();
      const now = Date.now();

      const defaults: VFSNode[] = [
        {
          path: "/workspace/welcome.md",
          name: "welcome.md",
          isDirectory: false,
          content: encoder.encode(DEFAULT_WELCOME_MD),
          mtime: now,
          size: DEFAULT_WELCOME_MD.length,
        },
        {
          path: "/workspace/demo.logo",
          name: "demo.logo",
          isDirectory: false,
          content: encoder.encode(DEFAULT_DEMO_LOGO),
          mtime: now,
          size: DEFAULT_DEMO_LOGO.length,
        },
        {
          path: "/workspace/examples/diagram.txt",
          name: "diagram.txt",
          isDirectory: false,
          content: encoder.encode(DEFAULT_EXAMPLE_DIAGRAM),
          mtime: now,
          size: DEFAULT_EXAMPLE_DIAGRAM.length,
        },
      ];

      for (const node of defaults) {
        await set(VFS_PREFIX + node.path, node);
      }
    }
  }

  /**
   * Loads all VFS nodes from IndexedDB.
   */
  static async getAllNodes(): Promise<VFSNode[]> {
    const allKeys = await keys();
    const vfsKeys = allKeys.filter((k) => String(k).startsWith(VFS_PREFIX));
    const nodes: VFSNode[] = [];

    for (const key of vfsKeys) {
      const node = await get<VFSNode>(key);
      if (node) {
        nodes.push(node);
      }
    }

    return nodes;
  }

  /**
   * Saves a batch of VFS nodes to IndexedDB.
   */
  static async saveNodes(nodes: VFSNode[]): Promise<void> {
    for (const node of nodes) {
      await set(VFS_PREFIX + node.path, node);
    }
  }

  /**
   * Deletes a node and any children from IndexedDB.
   */
  static async deleteNode(path: string): Promise<void> {
    const allKeys = await keys();
    for (const key of allKeys) {
      const keyStr = String(key);
      if (keyStr.startsWith(VFS_PREFIX)) {
        const nodePath = keyStr.slice(VFS_PREFIX.length);
        if (nodePath === path || nodePath.startsWith(path + "/")) {
          await del(key);
        }
      }
    }
  }

  /**
   * Clears entire Virtual OS storage and reinitializes defaults.
   */
  static async clearAll(): Promise<void> {
    const allKeys = await keys();
    for (const key of allKeys) {
      if (String(key).startsWith(VFS_PREFIX) || String(key).startsWith("zago_file:")) {
        await del(key);
      }
    }
    await this.initializeDefaults();
  }

  /**
   * Exports the entire `/workspace` hierarchy as a ZIP archive.
   */
  static async exportWorkspaceZip(): Promise<Blob> {
    const zip = new JSZip();
    const nodes = await this.getAllNodes();

    for (const node of nodes) {
      if (!node.isDirectory && node.content) {
        // Strip "/workspace/" prefix for the zip root
        const relPath = node.path.startsWith("/workspace/")
          ? node.path.slice("/workspace/".length)
          : node.path.replace(/^\//, "");
        zip.file(relPath, node.content);
      }
    }

    return await zip.generateAsync({
      type: "blob",
      compression: "DEFLATE",
      compressionOptions: { level: 6 },
    });
  }

  /**
   * Imports a ZIP archive into `/workspace`.
   */
  static async importWorkspaceZip(zipData: ArrayBuffer | Blob): Promise<number> {
    const zip = await JSZip.loadAsync(zipData);
    const now = Date.now();
    let fileCount = 0;

    for (const [relPath, zipEntry] of Object.entries(zip.files)) {
      if (zipEntry.dir) continue;

      const normRelPath = relPath.replace(/^\//, "");
      if (normRelPath.startsWith("__MACOSX") || normRelPath.includes(".DS_Store")) {
        continue;
      }

      const fullPath = `/workspace/${normRelPath}`;
      const content = await zipEntry.async("uint8array");
      const name = normRelPath.split("/").pop() || normRelPath;

      const node: VFSNode = {
        path: fullPath,
        name,
        isDirectory: false,
        content,
        mtime: zipEntry.date ? zipEntry.date.getTime() : now,
        size: content.length,
      };

      await set(VFS_PREFIX + fullPath, node);
      fileCount++;
    }

    return fileCount;
  }

  /**
   * Imports a single file into `/workspace`.
   */
  static async importSingleFile(name: string, content: string | Uint8Array): Promise<void> {
    const bytes = typeof content === "string" ? new TextEncoder().encode(content) : content;
    const fullPath = `/workspace/${name}`;
    const node: VFSNode = {
      path: fullPath,
      name,
      isDirectory: false,
      content: bytes,
      mtime: Date.now(),
      size: bytes.length,
    };
    await set(VFS_PREFIX + fullPath, node);
  }
}

/**
 * Builds a hierarchical Map<string, Inode> tree for WASI PreopenDirectory from flat VFS nodes.
 */
export function buildInodeTree(nodes: VFSNode[]): Map<string, Inode> {
  const rootContents = new Map<string, Inode>();

  // Helper to ensure directory path exists in Inode hierarchy
  function getOrCreateDirMap(parentMap: Map<string, Inode>, dirName: string): Map<string, Inode> {
    let entry = parentMap.get(dirName);
    if (!entry || !(entry instanceof Directory)) {
      const newContents = new Map<string, Inode>();
      entry = new Directory(newContents);
      parentMap.set(dirName, entry);
      return newContents;
    }
    return entry.contents as Map<string, Inode>;
  }

  for (const node of nodes) {
    if (node.isDirectory) continue;

    // Relative to /workspace/
    let relPath = node.path;
    if (relPath.startsWith("/workspace/")) {
      relPath = relPath.slice("/workspace/".length);
    } else if (relPath.startsWith("/")) {
      relPath = relPath.slice(1);
    }

    const parts = relPath.split("/").filter(Boolean);
    if (parts.length === 0) continue;

    const fileName = parts.pop()!;
    let currentMap = rootContents;

    for (const part of parts) {
      currentMap = getOrCreateDirMap(currentMap, part);
    }

    currentMap.set(fileName, new File(node.content || new Uint8Array(0)));
  }

  return rootContents;
}

/**
 * Recursively dumps an Inode tree to a flat list of VFSNodes.
 */
export function dumpInodeTree(
  currentMap: Map<string, Inode>,
  basePath: string = "/workspace",
  now: number = Date.now()
): VFSNode[] {
  const results: VFSNode[] = [];

  for (const [name, inode] of currentMap.entries()) {
    const fullPath = `${basePath}/${name}`;

    if (inode instanceof Directory) {
      results.push({
        path: fullPath,
        name,
        isDirectory: true,
        mtime: now,
        size: 0,
      });
      const subNodes = dumpInodeTree(inode.contents as Map<string, Inode>, fullPath, now);
      results.push(...subNodes);
    } else if (inode instanceof File) {
      results.push({
        path: fullPath,
        name,
        isDirectory: false,
        content: inode.data,
        mtime: now,
        size: inode.data ? inode.data.length : 0,
      });
    }
  }

  return results;
}
