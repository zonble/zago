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

  const isMobileInitial = window.innerWidth < 600;

  // Create and configure xterm.js instance
  const term = new Terminal({
    cursorBlink: true,
    fontFamily: 'Menlo, Monaco, "Courier New", "Noto Sans Mono CJK TC", monospace',
    fontSize: isMobileInitial ? 12 : 14,
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

  // Shared Stdin ring buffer between UI thread and Worker
  const sharedStdin = new SharedStdin();

  let currentWorker: Worker | null = null;
  let mode: "editor" | "shell" = "editor";
  let shellInput = "";
  let cachedWasmBytes: ArrayBuffer | null = null;

  // Progress UI elements
  const loadingOverlay = document.getElementById("wasm-loading-overlay");
  const progressBar = document.getElementById("loading-progress-bar");
  const statusText = document.getElementById("loading-status");
  const detailText = document.getElementById("loading-detail");

  function showLoading(status: string, detail: string = "", percent: number = 0) {
    if (loadingOverlay) loadingOverlay.classList.remove("hidden");
    if (progressBar) progressBar.style.width = `${Math.min(100, Math.max(0, percent))}%`;
    if (statusText) statusText.textContent = status;
    if (detailText) detailText.textContent = detail;
  }

  function hideLoading() {
    if (loadingOverlay) loadingOverlay.classList.add("hidden");
  }

  async function fetchWasmWithProgress(url: string): Promise<ArrayBuffer> {
    if (cachedWasmBytes) {
      return cachedWasmBytes;
    }

    showLoading("Downloading zago.wasm...", "Connecting to server...", 5);

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch ${url}: HTTP ${response.status}`);
    }

    const contentLength = +(response.headers.get("Content-Length") || 0);
    const totalMB = contentLength ? (contentLength / (1024 * 1024)).toFixed(1) : "?";

    if (!response.body) {
      const buffer = await response.arrayBuffer();
      cachedWasmBytes = buffer;
      return buffer;
    }

    const reader = response.body.getReader();
    let receivedBytes = 0;
    const chunks: Uint8Array[] = [];

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (value) {
        chunks.push(value);
        receivedBytes += value.length;
        const currentMB = (receivedBytes / (1024 * 1024)).toFixed(1);
        const percent = contentLength ? Math.round((receivedBytes / contentLength) * 100) : 50;
        showLoading(
          `Downloading zago.wasm (${currentMB} MB / ${totalMB} MB)`,
          `${percent}% completed`,
          percent
        );
      }
    }

    showLoading("Preparing WebAssembly instance...", "Compiling WASM bytecode...", 95);

    // Combine chunks into single ArrayBuffer
    const combined = new Uint8Array(receivedBytes);
    let position = 0;
    for (const chunk of chunks) {
      combined.set(chunk, position);
      position += chunk.length;
    }

    cachedWasmBytes = combined.buffer;
    return cachedWasmBytes;
  }

  async function launchEditor(targetFile: string = "/workspace/welcome.md") {
    if (currentWorker) {
      currentWorker.terminate();
      currentWorker = null;
    }

    mode = "editor";
    shellInput = "";
    sharedStdin.clear();

    try {
      const wasmUrl = new URL("zago.wasm", window.location.href).href;
      const wasmBytes = await fetchWasmWithProgress(wasmUrl);

      showLoading("Starting Virtual OS...", "Instantiating WASI runtime", 98);

      const nodes = await VirtualOSStorage.getAllNodes();
      const worker = new Worker(new URL("./worker.ts", import.meta.url), {
        type: "module",
      });
      currentWorker = worker;

      worker.onmessage = async (event: MessageEvent) => {
        const { type, data, status, message } = event.data;

        switch (type) {
          case "stdout":
            if (mode === "editor" && data) term.write(data);
            break;

          case "status":
            if (statusText) statusText.textContent = status;
            break;

          case "ready":
            hideLoading();
            term.focus();
            fitAddon.fit();
            const dims = fitAddon.proposeDimensions();
            if (dims) {
              sharedStdin.write(`\x1b[8;${dims.rows};${dims.cols}t`);
            }
            break;

          case "exit":
            hideLoading();
            if (currentWorker === worker) {
              currentWorker.terminate();
              currentWorker = null;
            }
            mode = "shell";
            shellInput = "";
            term.write('\r\n\x1b[90m[zago exited. Type "zago" to start]\x1b[0m\r\nzago $ ');
            break;

          case "error":
            hideLoading();
            term.write(`\r\n\x1b[31;1m[zago error]\x1b[0m ${message}\r\n`);
            if (currentWorker === worker) {
              currentWorker.terminate();
              currentWorker = null;
            }
            mode = "shell";
            shellInput = "";
            term.write("zago $ ");
            break;
        }
      };

      // Transfer wasm buffer copy to worker
      worker.postMessage({
        type: "init",
        data: { wasmBytes: wasmBytes.slice(0), targetFile },
        nodes,
        sharedBuffer: sharedStdin.sharedBuffer,
      });
    } catch (err: any) {
      hideLoading();
      term.write(`\r\n\x1b[31;1m[Failed to start]\x1b[0m ${err?.message || err}\r\n`);
    }
  }

  // Keyboard input handler
  term.onData((inputData) => {
    if (mode === "editor") {
      sharedStdin.write(inputData);
      return;
    }

    // Mini-Shell mode
    for (let i = 0; i < inputData.length; i++) {
      const char = inputData[i];

      if (char === "\r") {
        term.write("\r\n");
        const trimmed = shellInput.trim();
        shellInput = "";

        if (trimmed.length === 0) {
          term.write("zago $ ");
        } else if (trimmed === "clear") {
          term.clear();
          term.write("zago $ ");
        } else if (trimmed === "zago" || trimmed.startsWith("zago ")) {
          const parts = trimmed.split(/\s+/).slice(1);
          let targetFile = "/workspace/welcome.md";
          if (parts.length > 0 && parts[0].length > 0) {
            targetFile = parts[0].startsWith("/") ? parts[0] : `/workspace/${parts[0]}`;
          }
          launchEditor(targetFile);
          return;
        } else {
          term.write(
            `zago: command not found: ${trimmed}. Type "zago [filename]" to start or "clear" to clear screen.\r\nzago $ `
          );
        }
      } else if (char === "\x7f" || char === "\b") {
        if (shellInput.length > 0) {
          shellInput = shellInput.slice(0, -1);
          term.write("\b \b");
        }
      } else if (char === "\x03") {
        // Ctrl+C
        shellInput = "";
        term.write("^C\r\nzago $ ");
      } else if (char === "\x0c") {
        // Ctrl+L
        term.clear();
        term.write(`zago $ ${shellInput}`);
      } else if (char >= " ") {
        shellInput += char;
        term.write(char);
      }
    }
  });

  // Mobile Virtual Key Bar Bindings
  const keyButtons = document.querySelectorAll<HTMLButtonElement>(".key-btn");
  keyButtons.forEach((btn) => {
    const keyAction = btn.dataset.key;
    const sendKey = (e: Event) => {
      e.preventDefault();
      if (!keyAction) return;

      switch (keyAction) {
        case "esc":
          if (mode === "editor") sharedStdin.write("\x1b");
          break;
        case "f8":
          // F8 toggles 2D Canvas mode in zago
          if (mode === "editor") sharedStdin.write("\x1b[19~");
          break;
        case "f7":
          // F7 toggles Table mode in zago
          if (mode === "editor") sharedStdin.write("\x1b[18~");
          break;
        case "tab":
          if (mode === "editor") sharedStdin.write("\t");
          break;
        case "arrow-left":
          if (mode === "editor") sharedStdin.write("\x1b[D");
          break;
        case "arrow-up":
          if (mode === "editor") sharedStdin.write("\x1b[A");
          break;
        case "arrow-down":
          if (mode === "editor") sharedStdin.write("\x1b[B");
          break;
        case "arrow-right":
          if (mode === "editor") sharedStdin.write("\x1b[C");
          break;
        case "save":
          // Ctrl+O
          if (mode === "editor") sharedStdin.write("\x0f");
          break;
        case "quit":
          // Ctrl+Q
          if (mode === "editor") sharedStdin.write("\x11");
          break;
        case "help":
          // Ctrl+G
          if (mode === "editor") sharedStdin.write("\x07");
          break;
      }
      term.focus();
    };

    btn.addEventListener("touchstart", sendKey, { passive: false });
    btn.addEventListener("click", sendKey);
  });

  // Mobile Navigation Tabs
  const tabDocs = document.getElementById("tab-docs");
  const tabDemo = document.getElementById("tab-demo");
  const docsPanel = document.getElementById("docs-panel");
  const demoPanel = document.getElementById("demo-panel");
  const btnJumpDemo = document.getElementById("btn-jump-demo");

  const switchToDocs = () => {
    tabDocs?.classList.add("active");
    tabDemo?.classList.remove("active");
    docsPanel?.classList.add("active");
    demoPanel?.classList.remove("active");
  };

  const switchToDemo = () => {
    tabDemo?.classList.add("active");
    tabDocs?.classList.remove("active");
    demoPanel?.classList.add("active");
    docsPanel?.classList.remove("active");
    setTimeout(() => {
      fitAddon.fit();
      term.focus();
    }, 50);
  };

  if (tabDocs) tabDocs.addEventListener("click", switchToDocs);
  if (tabDemo) tabDemo.addEventListener("click", switchToDemo);
  if (btnJumpDemo) btnJumpDemo.addEventListener("click", switchToDemo);

  // Resize handling
  const handleResize = () => {
    if (window.innerWidth < 600) {
      term.options.fontSize = 12;
    } else {
      term.options.fontSize = 14;
    }

    fitAddon.fit();
    const dims = fitAddon.proposeDimensions();
    if (dims && mode === "editor") {
      sharedStdin.write(`\x1b[8;${dims.rows};${dims.cols}t`);
    }
  };

  window.addEventListener("resize", handleResize);

  // Launch initial editor session
  await launchEditor("/workspace/welcome.md");

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
      // First ask worker to flush latest Inode state if running
      if (currentWorker) {
        currentWorker.postMessage({ type: "flush_vfs" });
      }
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

  // Copy Buttons for Quick Install
  const copyButtons = document.querySelectorAll<HTMLButtonElement>(".copy-btn");
  copyButtons.forEach((btn) => {
    btn.addEventListener("click", async () => {
      const textToCopy = btn.dataset.copy;
      if (!textToCopy) return;

      try {
        await navigator.clipboard.writeText(textToCopy);
        btn.classList.add("copied");
        setTimeout(() => {
          btn.classList.remove("copied");
        }, 1500);
      } catch (err) {
        console.error("Failed to copy text: ", err);
      }
    });
  });
}

main().catch(console.error);
