import { Terminal } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";
import { WebLinksAddon } from "@xterm/addon-web-links";
import "@xterm/xterm/css/xterm.css";
import { WorkspaceStorage } from "./storage";
import { SharedStdin } from "./shared-stdin";

async function main() {
  const container = document.getElementById("terminal-container");
  if (!container) return;

  container.addEventListener("click", () => {
    term.focus();
  });

  // Initialize storage with defaults
  await WorkspaceStorage.initializeDefaults();

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

  // Load all existing files from storage
  const fileNames = await WorkspaceStorage.listFiles();
  const initialFiles: Record<string, string> = {};
  for (const name of fileNames) {
    const content = await WorkspaceStorage.getFile(name);
    if (content !== undefined) {
      initialFiles[name] = content;
    }
  }

  // Shared Stdin ring buffer between UI thread and Worker
  const sharedStdin = new SharedStdin();

  // Spawn Web Worker
  const worker = new Worker(new URL("./worker.ts", import.meta.url), {
    type: "module",
  });

  function setupWorker(w: Worker) {
    w.onmessage = async (event: MessageEvent) => {
      const { type, data, status, message, files } = event.data;

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

        case "files_synced":
          if (files) {
            for (const [filename, content] of Object.entries(files)) {
              if (typeof content === "string") {
                await WorkspaceStorage.saveFile(filename, content);
              }
            }
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
      files: initialFiles,
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
  const btnOpenFile = document.getElementById("btn-open-file");
  const fileInput = document.getElementById("file-input") as HTMLInputElement;
  const btnDownload = document.getElementById("btn-download-file");
  const btnReset = document.getElementById("btn-clear-storage");

  if (btnOpenFile && fileInput) {
    btnOpenFile.addEventListener("click", () => fileInput.click());
    fileInput.addEventListener("change", async (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;

      const text = await file.text();
      await WorkspaceStorage.saveFile(file.name, text);
      alert(`File "${file.name}" imported to workspace. Restart to open.`);
    });
  }

  if (btnDownload) {
    btnDownload.addEventListener("click", async () => {
      const content = (await WorkspaceStorage.getFile("welcome.md")) || "";
      const blob = new Blob([content], { type: "text/markdown;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "welcome.md";
      a.click();
      URL.revokeObjectURL(url);
    });
  }

  if (btnReset) {
    btnReset.addEventListener("click", async () => {
      if (confirm("Reset virtual workspace storage to defaults?")) {
        await WorkspaceStorage.clearAll();
        location.reload();
      }
    });
  }
}

main().catch(console.error);
