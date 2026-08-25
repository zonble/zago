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

import welcomeEn from "./templates/welcome.en.md?raw";
import welcomeZhTw from "./templates/welcome.zh-TW.md?raw";
import demoLogo from "./templates/demo.logo?raw";
import exampleDiagram from "./templates/diagram.txt?raw";

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
          path: "/workspace/welcome.en.md",
          name: "welcome.en.md",
          isDirectory: false,
          content: encoder.encode(welcomeEn),
          mtime: now,
          size: welcomeEn.length,
        },
        {
          path: "/workspace/welcome.zh-TW.md",
          name: "welcome.zh-TW.md",
          isDirectory: false,
          content: encoder.encode(welcomeZhTw),
          mtime: now,
          size: welcomeZhTw.length,
        },
        {
          path: "/workspace/demo.logo",
          name: "demo.logo",
          isDirectory: false,
          content: encoder.encode(demoLogo),
          mtime: now,
          size: demoLogo.length,
        },
        {
          path: "/workspace/examples/diagram.txt",
          name: "diagram.txt",
          isDirectory: false,
          content: encoder.encode(exampleDiagram),
          mtime: now,
          size: exampleDiagram.length,
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
    const nextPaths = new Set(nodes.map((node) => node.path));
    const allKeys = await keys();

    // The worker sends a complete workspace snapshot. Remove entries that no
    // longer exist in the in-memory inode tree before saving the snapshot.
    for (const key of allKeys) {
      const keyString = String(key);
      if (!keyString.startsWith(VFS_PREFIX)) continue;
      const nodePath = keyString.slice(VFS_PREFIX.length);
      if ((nodePath === "/workspace" || nodePath.startsWith("/workspace/")) && !nextPaths.has(nodePath)) {
        await del(key);
      }
    }

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

      const normRelPath = normalizeWorkspaceRelativePath(relPath);
      if (!normRelPath) continue;
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
    const normName = normalizeWorkspaceRelativePath(name);
    if (!normName) {
      throw new Error("Invalid file name");
    }

    const bytes = typeof content === "string" ? new TextEncoder().encode(content) : content;
    const fullPath = `/workspace/${normName}`;
    const node: VFSNode = {
      path: fullPath,
      name: normName.split("/").pop() || normName,
      isDirectory: false,
      content: bytes,
      mtime: Date.now(),
      size: bytes.length,
    };
    await set(VFS_PREFIX + fullPath, node);
  }
}

/**
 * Detects whether a byte array is binary data based on the first 8192 bytes.
 * Matches zago's Swift LocalEditorFileIOStrategy.isBinaryFile logic.
 */
export function isBinaryData(rawBytes: Uint8Array): boolean {
  const prefix = rawBytes.subarray(0, 8192);
  if (prefix.length === 0) return false;

  const hasUTF16BOM =
    prefix.length >= 2 &&
    ((prefix[0] === 0xfe && prefix[1] === 0xff) || (prefix[0] === 0xff && prefix[1] === 0xfe));

  if (!hasUTF16BOM) {
    for (let i = 0; i < prefix.length; i++) {
      if (prefix[i] === 0) {
        return true;
      }
    }
  }

  // Check UTF-8 validity with boundary truncation trimming for up to 3 bytes
  let checkBuffer = prefix;
  while (checkBuffer.length > 0) {
    try {
      const safeBuffer = checkBuffer.buffer instanceof ArrayBuffer ? checkBuffer : new Uint8Array(checkBuffer);
      new TextDecoder("utf-8", { fatal: true }).decode(safeBuffer);
      return false;
    } catch {
      const last = checkBuffer[checkBuffer.length - 1];
      if ((last & 0x80) !== 0) {
        checkBuffer = checkBuffer.subarray(0, checkBuffer.length - 1);
      } else {
        break;
      }
    }
  }

  return true;
}

/**
 * Resolves an available non-conflicting filename within /workspace.
 * If filename exists, auto-increments with `_1`, `_2`, etc.
 */
export function resolveAvailableFilename(
  desiredName: string,
  existingPathsOrNames: Iterable<string>
): string {
  const existingNames = new Set<string>();
  for (const item of existingPathsOrNames) {
    const name = item.startsWith("/workspace/")
      ? item.slice("/workspace/".length)
      : item.startsWith("/")
      ? item.slice(1)
      : item;
    existingNames.add(name.toLowerCase());
  }

  const cleanName = desiredName.split("/").pop() || desiredName;
  if (!existingNames.has(cleanName.toLowerCase())) {
    return cleanName;
  }

  const lastDot = cleanName.lastIndexOf(".");
  const base = lastDot > 0 ? cleanName.slice(0, lastDot) : cleanName;
  const ext = lastDot > 0 ? cleanName.slice(lastDot) : "";

  let counter = 1;
  while (true) {
    const candidate = `${base}_${counter}${ext}`;
    if (!existingNames.has(candidate.toLowerCase())) {
      return candidate;
    }
    counter++;
  }
}

function normalizeWorkspaceRelativePath(path: string): string | null {
  const segments = path.replaceAll("\\", "/").split("/");
  if (segments.some((segment) => segment === "." || segment === "..")) {
    return null;
  }

  const normalized = segments.filter(Boolean).join("/");
  return normalized && !normalized.startsWith("/") ? normalized : null;
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
