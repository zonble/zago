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

const DEFAULT_WELCOME_MD = `# Welcome to zago Web Virtual OS! 🐢

zago is running inside WebAssembly with a full POSIX-compatible Virtual File System (VFS) backed by IndexedDB.

## Features
- **Hierarchical VFS**: Supports subdirectories (\`/workspace/examples/\`, \`/workspace/src/\`).
- **Terminal File Navigation**: Type \`:dir\` or \`:ls\` to open the interactive Directory Browser.
- **Canvas Mode**: Press \`ESC ESC\` to draw boxes, lines, tables, and flowcharts.
- **Editor LOGO**: Built-in macro interpreter for programmable document generation.
- **Persistence**: All changes are automatically persisted to IndexedDB across reloads.
- **ZIP Import / Export**: Use the top toolbar to import project archives or export the workspace.

## Sample ASCII Diagram
┌──────────────────────────────────────────────────────────┐
│                   Browser Main Thread                    │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Web UI Toolbar [Import/Export ZIP]                 │  │
│  └────────────────────────────────────────────────────┘  │
│                           │                              │
│                           ▼ (SharedArrayBuffer Stdin)    │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Web Worker (WASI Runtime + zago.wasm)              │  │
│  │  - Hierarchical Inode Tree (/workspace)            │  │
│  │  - Directory Navigation (:dir / :ls)               │  │
│  └────────────────────────────────────────────────────┘  │
│                           │                              │
│                           ▼ (Debounced Flush)            │
│  ┌────────────────────────────────────────────────────┐  │
│  │ IndexedDB Virtual OS VFS Store                     │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘

Happy Editing!
`;

const DEFAULT_DEMO_LOGO = `; Editor LOGO Demo Script
; Draw a styled double-line box and type text

CLEAR
GOTO 2 2
BOX 42 8 DOUBLE
GOTO 4 4
TYPE "Hello from zago Virtual OS!"
GOTO 5 4
TYPE "Full VFS + Directory Navigation Enabled"
`;

const DEFAULT_CONFIG = `# zago Editor Configuration
tab_size = 4
expand_tab = true
line_numbers = true
status_bar = true
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
          path: "/workspace/.zago.conf",
          name: ".zago.conf",
          isDirectory: false,
          content: encoder.encode(DEFAULT_CONFIG),
          mtime: now,
          size: DEFAULT_CONFIG.length,
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
