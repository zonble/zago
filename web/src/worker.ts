import {
  WASI,
  PreopenDirectory,
  ConsoleStdout,
  Fd,
  Inode,
} from "@bjorn3/browser_wasi_shim";
import { SharedStdin } from "./shared-stdin";
import {
  VFSNode,
  VirtualOSStorage,
  buildInodeTree,
  dumpInodeTree,
} from "./vfs";

class SharedStdinFd extends Fd {
  constructor(private stdin: SharedStdin) {
    super();
  }

  override fd_read(size: number): { ret: number; data: Uint8Array } {
    const data = this.stdin.read(size);
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
let workspaceDir = new Map<string, Inode>();
let isRunning = false;

self.onmessage = async (event: MessageEvent) => {
  const { type, data, nodes, sharedBuffer } = event.data;

  switch (type) {
    case "init":
      if (sharedBuffer) {
        sharedStdin = new SharedStdin(sharedBuffer);
      }
      await startWasm(
        data?.wasmBytes || data?.wasmUrl || "./zago.wasm",
        nodes || [],
        data?.targetFile || "/workspace/welcome.md",
        data?.lang || "en"
      );
      break;

    case "flush_vfs":
      await flushVFSToIndexedDB();
      break;
  }
};

async function flushVFSToIndexedDB() {
  if (!isRunning) return;
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
  targetFile: string = "/workspace/welcome.md",
  lang: string = "en"
) {
  if (!sharedStdin) {
    sharedStdin = new SharedStdin();
  }
  const stdinFd = new SharedStdinFd(sharedStdin);

  // Build hierarchical Inode tree from initial VFS nodes
  workspaceDir = buildInodeTree(initialNodes);

  const stdoutDecoder = new TextDecoder("utf-8");
  const stdoutFd = new ConsoleStdout((buffer: Uint8Array) => {
    const text = stdoutDecoder.decode(buffer, { stream: true });
    if (text.length > 0) {
      self.postMessage({ type: "stdout", data: text });
    }
  });

  const fds: Fd[] = [
    stdinFd,
    stdoutFd,
    stdoutFd,
    new PreopenDirectory("/workspace", workspaceDir),
    new PreopenDirectory(".", workspaceDir),
  ];

  const lcAll = lang === "zh-TW" ? "zh_TW.UTF-8" : "en_US.UTF-8";

  const wasiInstance = new WASI(
    ["zago", targetFile],
    [
      "LINES=24",
      "COLUMNS=80",
      "TERM=xterm-256color",
      "COLORTERM=truecolor",
      `LC_ALL=${lcAll}`,
      `LANG=${lcAll}`,
      `LANGUAGE=${lcAll}`,
      "HOME=/workspace",
    ],
    fds,
    { debug: false }
  );

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
        message: error?.message || String(error),
      });
      isRunning = false;
      self.postMessage({ type: "exit", code: 1 });
    }
  }
}
