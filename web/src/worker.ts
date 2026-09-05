import {
  WASI,
  PreopenDirectory,
  ConsoleStdout,
  Fd,
  File,
  Directory,
  Inode,
} from "@bjorn3/browser_wasi_shim";
import { SharedStdin, SharedFileChannel } from "./shared-stdin";
import {
  VFSNode,
  VirtualOSStorage,
  buildInodeTree,
  dumpInodeTree,
} from "./vfs";

let workspaceDir = new Map<string, Inode>();
let isRunning = false;

function insertFileIntoWorkspace(path: string, contentBytes: Uint8Array) {
  let relPath = path;
  if (relPath.startsWith("/workspace/")) {
    relPath = relPath.slice("/workspace/".length);
  } else if (relPath.startsWith("/")) {
    relPath = relPath.slice(1);
  }
  const parts = relPath.split("/").filter(Boolean);
  if (parts.length === 0) return;

  const fileName = parts.pop()!;
  let currentMap = workspaceDir;

  for (const part of parts) {
    let entry = currentMap.get(part);
    if (!entry || !(entry instanceof Directory)) {
      const newMap = new Map<string, Inode>();
      entry = new Directory(newMap);
      currentMap.set(part, entry);
      currentMap = newMap;
    } else {
      currentMap = entry.contents as Map<string, Inode>;
    }
  }

  currentMap.set(fileName, new File(contentBytes));
}

function getFileBytesFromWorkspace(path: string): Uint8Array | null {
  let relPath = path;
  if (relPath.startsWith("/workspace/")) {
    relPath = relPath.slice("/workspace/".length);
  } else if (relPath.startsWith("/")) {
    relPath = relPath.slice(1);
  }
  const parts = relPath.split("/").filter(Boolean);
  if (parts.length === 0) return null;

  const fileName = parts.pop()!;
  let currentMap = workspaceDir;

  for (const part of parts) {
    let entry = currentMap.get(part);
    if (!entry || !(entry instanceof Directory)) {
      return null;
    }
    currentMap = entry.contents as Map<string, Inode>;
  }

  const fileEntry = currentMap.get(fileName);
  if (fileEntry && fileEntry instanceof File) {
    return fileEntry.data;
  }
  return null;
}

function triggerFileDownload(filePath: string) {
  const bytes = getFileBytesFromWorkspace(filePath);
  const fileName = filePath.split("/").pop() || filePath;
  if (bytes) {
    self.postMessage({
      type: "download",
      filename: fileName,
      data: bytes,
    });
  } else {
    console.warn(`[triggerFileDownload] File not found in workspace: ${filePath}`);
  }
}

class SharedStdinFd extends Fd {
  constructor(
    private stdin: SharedStdin,
    private fileChannel?: SharedFileChannel
  ) {
    super();
  }

  private drainPendingFiles() {
    if (this.fileChannel) {
      let pending = this.fileChannel.pullFile();
      while (pending) {
        insertFileIntoWorkspace(pending.path, pending.content);
        pending = this.fileChannel.pullFile();
      }
    }
  }

  override fd_read(size: number): { ret: number; data: Uint8Array } {
    this.drainPendingFiles();
    const data = this.stdin.read(size);
    this.drainPendingFiles();
    return { ret: 0, data };
  }

  override fd_fdstat_get(): { ret: number; fdstat: any } {
    return {
      ret: 0,
      fdstat: {
        fs_filetype: 2, // Character device
        fs_flags: 0,
        fs_rights_base: BigInt(2),
        fs_rights_inheriting: BigInt(0),
      },
    };
  }
}

let sharedStdin: SharedStdin | null = null;
let sharedFileChannel: SharedFileChannel | null = null;

self.onmessage = async (event: MessageEvent) => {
  const { type, data, nodes, sharedBuffer, sharedFileBuffer } = event.data;

  switch (type) {
    case "init":
      if (sharedBuffer) {
        sharedStdin = new SharedStdin(sharedBuffer);
      }
      if (sharedFileBuffer) {
        sharedFileChannel = new SharedFileChannel(sharedFileBuffer);
      }
      const rawFiles = data?.targetFiles || (data?.targetFile ? [data.targetFile] : ["/workspace/welcome.md"]);
      const targetFiles = Array.isArray(rawFiles) ? rawFiles : [rawFiles];
      await startWasm(
        data?.wasmBytes || data?.wasmUrl || "./zago.wasm",
        nodes || [],
        targetFiles,
        data?.lang || "en"
      );
      break;

    case "flush_vfs":
      await flushVFSToIndexedDB();
      break;
  }
};

async function flushVFSToIndexedDB() {
  if (!isRunning) {
    self.postMessage({ type: "vfs_synced", count: 0 });
    return;
  }
  try {
    const nodes = dumpInodeTree(workspaceDir, "/workspace");
    await VirtualOSStorage.saveNodes(nodes);
    self.postMessage({ type: "vfs_synced", count: nodes.length });
  } catch (err) {
    console.error("[VFS Flush Error]", err);
  }
}

async function startWasm(
  wasmSource: string | ArrayBuffer,
  initialNodes: VFSNode[],
  targetFiles: string[] = ["/workspace/welcome.md"],
  lang: string = "en"
) {
  if (!sharedStdin) {
    sharedStdin = new SharedStdin();
  }
  const stdinFd = new SharedStdinFd(sharedStdin, sharedFileChannel || undefined);

  // Build hierarchical Inode tree from initial VFS nodes
  workspaceDir = buildInodeTree(initialNodes);

  const stdoutDecoder = new TextDecoder("utf-8");
  let stdoutPending = "";
  const stdoutFd = new ConsoleStdout((buffer: Uint8Array) => {
    const unshared = buffer.buffer instanceof ArrayBuffer ? buffer : new Uint8Array(buffer);
    const chunk = stdoutDecoder.decode(unshared, { stream: true });
    stdoutPending += chunk;

    const downloadRegex = /\x1b\]zago:download;([^\x07\x1b]+)(?:\x07|\x1b\\)/g;
    let match;
    while ((match = downloadRegex.exec(stdoutPending)) !== null) {
      const filename = match[1];
      triggerFileDownload(filename);
    }
    stdoutPending = stdoutPending.replace(downloadRegex, "");

    const partialDownloadIndex = stdoutPending.lastIndexOf("\x1b]zago:download");
    if (
      partialDownloadIndex !== -1 &&
      !stdoutPending.slice(partialDownloadIndex).includes("\x07") &&
      !stdoutPending.slice(partialDownloadIndex).includes("\x1b\\")
    ) {
      const toSend = stdoutPending.slice(0, partialDownloadIndex);
      stdoutPending = stdoutPending.slice(partialDownloadIndex);
      if (toSend.length > 0) {
        self.postMessage({ type: "stdout", data: toSend });
      }
    } else {
      if (stdoutPending.length > 0) {
        self.postMessage({ type: "stdout", data: stdoutPending });
        stdoutPending = "";
      }
    }
  });

  const fds: Fd[] = [
    stdinFd,
    stdoutFd,
    stdoutFd,
    new PreopenDirectory("/workspace", workspaceDir),
    new PreopenDirectory(".", workspaceDir),
  ];

const LOCALE_MAP: Record<string, string> = {
  "zh-TW": "zh_TW.UTF-8",
  "zh-CN": "zh_CN.UTF-8",
  "zh-HK": "zh_HK.UTF-8",
  "ja": "ja_JP.UTF-8",
  "ko": "ko_KR.UTF-8",
  "en": "en_US.UTF-8",
};

const DEFAULT_LOCALE = "en_US.UTF-8";

function getLocaleString(lang: string): string {
  return LOCALE_MAP[lang] ?? DEFAULT_LOCALE;
}

  const lcAll = getLocaleString(lang);
  const rawArgs = ["zago", ...targetFiles];
  const rawEnv = [
    "LINES=24",
    "COLUMNS=80",
    "TERM=xterm-256color",
    "COLORTERM=truecolor",
    `LC_ALL=${lcAll}`,
    `LANG=${lcAll}`,
    `LANGUAGE=${lcAll}`,
    "HOME=/workspace",
  ];

  const wasiInstance = new WASI(
    rawArgs,
    rawEnv,
    fds,
    { debug: false }
  );

  // Patch @bjorn3/browser_wasi_shim's bug where args_sizes_get and environ_sizes_get
  // compute JS UTF-16 character length (arg.length) instead of UTF-8 byte length,
  // causing heap buffer overflows / memory access out of bounds for CJK/Unicode filenames!
  const textEncoder = new TextEncoder();
  wasiInstance.wasiImport.args_sizes_get = (argc: number, argv_buf_size: number): number => {
    const memory = (wasiInstance as any).inst.exports.memory;
    const buffer = new DataView(memory.buffer);
    buffer.setUint32(argc, rawArgs.length, true);
    let buf_size = 0;
    for (const arg of rawArgs) {
      buf_size += textEncoder.encode(arg).length + 1;
    }
    buffer.setUint32(argv_buf_size, buf_size, true);
    return 0;
  };

  wasiInstance.wasiImport.environ_sizes_get = (environ_count: number, environ_size: number): number => {
    const memory = (wasiInstance as any).inst.exports.memory;
    const buffer = new DataView(memory.buffer);
    buffer.setUint32(environ_count, rawEnv.length, true);
    let buf_size = 0;
    for (const environ of rawEnv) {
      buf_size += textEncoder.encode(environ).length + 1;
    }
    buffer.setUint32(environ_size, buf_size, true);
    return 0;
  };

  try {
    let wasmBytes: ArrayBuffer;
    if (wasmSource instanceof ArrayBuffer) {
      wasmBytes = wasmSource;
    } else {
      self.postMessage({ type: "status", status: "Loading WebAssembly binary..." });
      const response = await fetch(wasmSource);
      if (!response.ok) {
        throw new Error(`Failed to fetch ${wasmSource}: HTTP ${response.status}`);
      }
      wasmBytes = await response.arrayBuffer();
    }

    self.postMessage({ type: "status", status: "Instantiating zago.wasm Virtual OS..." });

    const { instance } = await WebAssembly.instantiate(wasmBytes, {
      wasi_snapshot_preview1: wasiInstance.wasiImport,
    });

    self.postMessage({ type: "ready" });
    isRunning = true;

    // Debounced automatic background sync (every 1000ms)
    const syncInterval = setInterval(flushVFSToIndexedDB, 1000);

    let exitCode = 0;
    try {
      exitCode = wasiInstance.start(instance as any) ?? 0;
    } catch (startErr: any) {
      if (
        startErr &&
        (startErr.name === "WASIProcExit" ||
          startErr.code !== undefined ||
          String(startErr.message || startErr).includes("exit"))
      ) {
        exitCode = startErr.code ?? 0;
      } else {
        throw startErr;
      }
    } finally {
      clearInterval(syncInterval);
    }

    await flushVFSToIndexedDB();
    isRunning = false;
    self.postMessage({ type: "exit", code: exitCode });
  } catch (error: any) {
    console.error("[WORKER FATAL ERROR]", error, error?.stack);
    if (
      error &&
      (error.name === "WASIProcExit" ||
        error.code !== undefined ||
        String(error.message || error).includes("exit"))
    ) {
      await flushVFSToIndexedDB();
      isRunning = false;
      self.postMessage({ type: "exit", code: error.code ?? 0 });
    } else {
      self.postMessage({
        type: "error",
        message: `${error?.message || String(error)}${error?.stack ? "\n" + error.stack : ""}`,
      });
      isRunning = false;
    }
  }
}
