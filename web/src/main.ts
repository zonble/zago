import { Terminal } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";
import { WebLinksAddon } from "@xterm/addon-web-links";
import "@xterm/xterm/css/xterm.css";
import { VirtualOSStorage } from "./vfs";
import { SharedStdin } from "./shared-stdin";

async function main() {
  const container = document.getElementById("terminal-container");
  if (!container) return;

  container.addEventListener("click", () => {
    term.focus();
  });

  // Initialize VFS storage with defaults
  await VirtualOSStorage.initializeDefaults();

  // Create and configure xterm.js instance
  const term = new Terminal({
    cursorBlink: true,
    fontFamily: 'Menlo, Monaco, "Courier New", "Noto Sans Mono CJK TC", monospace',
    fontSize: 14,
    lineHeight: 1.2,
    theme: {
      background: "#0d1117",
      foreground: "#c9d1d9",
      cursor: "#58a6ff",
      selectionBackground: "#3b5070",
      black: "#484f58",
      red: "#ff7b72",
      green: "#3fb950",
      yellow: "#d29922",
      blue: "#58a6ff",
      magenta: "#bc8cff",
      cyan: "#39c5cf",
      white: "#b1bac4",
      brightBlack: "#6e7681",
      brightRed: "#ffa198",
      brightGreen: "#56d364",
      brightYellow: "#e3b341",
      brightBlue: "#79c0ff",
      brightMagenta: "#d2a8ff",
      brightCyan: "#56d4dd",
      brightWhite: "#f0f6fc",
    },
    allowProposedApi: true,
  });

  const fitAddon = new FitAddon();
  term.loadAddon(fitAddon);
  term.loadAddon(new WebLinksAddon());

  term.open(container);
  fitAddon.fit();

  // Load all VFS nodes from IndexedDB
  const nodes = await VirtualOSStorage.getAllNodes();

  // Shared Stdin ring buffer between UI thread and Worker
  const sharedStdin = new SharedStdin();

  // Spawn Web Worker
  const worker = new Worker(new URL("./worker.ts", import.meta.url), {
    type: "module",
  });

  function setupWorker(w: Worker) {
    w.onmessage = async (event: MessageEvent) => {
      const { type, data, status, message } = event.data;

      switch (type) {
        case "stdout":
          if (data) term.write(data);
          break;

        case "status":
          term.write(`\r\n\x1b[36m[zago]\x1b[0m ${status}\r\n`);
          break;

        case "ready":
          term.focus();
          // Initial resize sync
          const dims = fitAddon.proposeDimensions();
          if (dims) {
            sharedStdin.write(`\x1b[8;${dims.rows};${dims.cols}t`);
          }
          break;

        case "error":
          term.write(`\r\n\x1b[31;1m[zago error]\x1b[0m ${message}\r\n`);
          break;
      }
    };

    term.onData((inputData) => {
      sharedStdin.write(inputData);
    });

    const wasmUrl = new URL("zago.wasm", window.location.href).href;
    w.postMessage({
      type: "init",
      data: { wasmUrl },
      nodes,
      sharedBuffer: sharedStdin.sharedBuffer,
    });
  }

  setupWorker(worker);

  // Resize handling
  const handleResize = () => {
    fitAddon.fit();
    const dims = fitAddon.proposeDimensions();
    if (dims) {
      sharedStdin.write(`\x1b[8;${dims.rows};${dims.cols}t`);
    }
  };

  window.addEventListener("resize", handleResize);

  // UI Button Bindings
  const btnImport = document.getElementById("btn-import");
  const fileInput = document.getElementById("file-input") as HTMLInputElement;
  const btnExportZip = document.getElementById("btn-export-zip");
  const btnReset = document.getElementById("btn-clear-storage");
  const btnHelp = document.getElementById("btn-help");
  const helpDialog = document.getElementById("help-dialog") as HTMLDialogElement;
  const btnCloseHelp = document.getElementById("btn-close-help");

  if (btnImport && fileInput) {
    btnImport.addEventListener("click", () => fileInput.click());
    fileInput.addEventListener("change", async (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;

      try {
        if (file.name.endsWith(".zip")) {
          const zipData = await file.arrayBuffer();
          const count = await VirtualOSStorage.importWorkspaceZip(zipData);
          alert(`Successfully imported ${count} files from "${file.name}" into /workspace.\nReloading to mount new filesystem...`);
          location.reload();
        } else {
          const buffer = await file.arrayBuffer();
          await VirtualOSStorage.importSingleFile(file.name, new Uint8Array(buffer));
          alert(`Imported "${file.name}" to /workspace.\nReloading to open...`);
          location.reload();
        }
      } catch (err: any) {
        alert(`Failed to import file: ${err?.message || err}`);
      }
    });
  }

  if (btnExportZip) {
    btnExportZip.addEventListener("click", async () => {
      // First ask worker to flush latest Inode state
      worker.postMessage({ type: "flush_vfs" });
      setTimeout(async () => {
        const blob = await VirtualOSStorage.exportWorkspaceZip();
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `zago-workspace-${new Date().toISOString().slice(0, 10)}.zip`;
        a.click();
        URL.revokeObjectURL(url);
      }, 200);
    });
  }

  if (btnReset) {
    btnReset.addEventListener("click", async () => {
      if (confirm("Reset Virtual OS and IndexedDB filesystem to default state?")) {
        await VirtualOSStorage.clearAll();
        location.reload();
      }
    });
  }

  if (btnHelp && helpDialog) {
    btnHelp.addEventListener("click", () => helpDialog.showModal());
  }

  if (btnCloseHelp && helpDialog) {
    btnCloseHelp.addEventListener("click", () => helpDialog.close());
  }
}

main().catch(console.error);
