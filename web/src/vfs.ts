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

Note: Use your keybaord to have fun with the document here.
Left/Right/Page Up/Page Down to move the cursor.

## Canvas Mode

\`\`\`
┌────────┐          ┌────────┐
│        │          │        │
│ Begin  x          │  End   │
│        │          │        │
└────────┘          └────────┘
\`\`\`

- Move the cursor to "x".
- Press F8 to enter the canvas mode.
- Press Shift + Right to draw a line.
- Continue to extend the line.
- Press Ctrl + Any arrow key, or Crtl + Shift + Arrow for arrows.
- Press F1 to show the menu and select another style in "borders".
- Press F8 again to exit the canvas mode.

## Table Mode

\`\`\`
┌────────────────┬────────────────┬────────────────┐
│ Press F7 Here  │                │                │
├────────────────┼────────────────┼────────────────┤
│                │                │                │
└────────────────┴────────────────┴────────────────┘
\`\`\`

- Press F7 in any cell to enter table mode
- You will edit the context in the cell.

## LINE command

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

- ESC shows the command prompt.
- ESC again to exit the command prompt.
- Move cursor to "x".
- ESC, then input "LINE". Case does not matter.
- A connecting line will be there.

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
- ESC, then input "VLINE".
- A vertical line will be there.

## Additioan Border and Arrow Styles

Try these commands for creating lines with specific styles:

- LINE ->>
- LINE =~>
- VLINE <|+|>

The syntax is [begin arrow][border][end aarrow]

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
- Heavy Quadruple Dash: +++

### Arrow Styles

- ASCII: < or >
- Solid: << or >>
- Stemmed: <~ or ~>
- Hollow: <| or |>

## BOX and DRAWBOX Commanads








Try the commands to create boxes above

- BOX "Hi"        ; Inserts a box with "Hi" inside.
- DRAWBOX "There" ; Overlays a box over current content.
- BOX 20 5 "Hi"   ; Inserts a box with the given size.
- BOX "Hi" =      ; Inserts a box with a specific border style.
- BOX "Hi" =)     ; ")" indicates round corner.

You can use border styles including - = + A -- ++ --- +++ ---- ++++

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
- ESC, input "FILL <any text>". Enter. 
  The box your be filled with your text.
- Move to "i".
- ESC, input "INSET <any text>". Enter.
  The text will be placed in the center of the box.

## Combined Commands

You can combine the commands with other commands in the ES command
prompt

- BOX DATE             ; Put the date into a box.
- BOX DATE =)          ; Put it into a box with double line.
- REPEAT 3 [BOX "hi"]  ; Draw 3 boxes

Date formats for various locales are available on macOS/Linux/Windows.

## Run Commands Inline

Besides using the ESC command prompt, you can run any line in your text
as commands by pressing ^Q.

You can simply use commands in follwing example to convert text inline
when you are working on a multi-lingua document.

move end newline type tohiragana Sakura      ; Press ^Q
move end newline type tokatakana Ramen       ; Press ^Q
move end newline type toromaji ラメン        ; Press ^Q
move end newline type tohant 简体中文转繁体  ; Press ^Q
move end newline type tohans 繁體中文轉簡體  ; Press ^Q
move end newline box "Zago rocks" se newline ; Press ^Q

## And More!

Zago has a rich command set and a syntax to help you to work with text
diagrams and writing. and make your text file as a playground. By the
default, the reference is hidden. You can input "set debug on" ESC
prompt to enable the reference in the menu.

For advanced usage, you can always use "help-cmd" and "help-key"
commands to leran zago better.

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
