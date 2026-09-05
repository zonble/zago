import { test, expect, type Page } from "@playwright/test";

const welcomeTitle = "# zago Interactive Tutorial";

async function waitForEditor(page: Page): Promise<void> {
  await expect(page.locator("#wasm-loading-overlay")).toHaveClass(/hidden/, {
    timeout: 90_000,
  });
  await expect(page.locator(".xterm-screen")).toBeVisible({ timeout: 90_000 });
}

async function getTerminalText(page: Page): Promise<string> {
  return page.evaluate(() => {
    const term = (window as any).term;
    if (!term) return "";
    const lines: string[] = [];
    const buf = term.buffer.active;
    for (let i = 0; i < buf.length; i++) {
      const line = buf.getLine(i);
      if (line) lines.push(line.translateToString(true));
    }
    return lines.join("\n");
  });
}

async function readVFSFile(page: Page, path: string): Promise<string> {
  return page.evaluate(async (filePath) => {
    const db = await new Promise<IDBDatabase>((resolve, reject) => {
      const request = indexedDB.open("keyval-store");
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });

    return await new Promise<string>((resolve, reject) => {
      const request = db
        .transaction("keyval", "readonly")
        .objectStore("keyval")
        .get(`zago_vfs:${filePath}`);
      request.onsuccess = () => {
        const content = request.result?.content;
        resolve(content ? new TextDecoder().decode(content) : "");
      };
      request.onerror = () => reject(request.error);
    });
  }, path);
}

async function importFile(page: Page, name: string, content: string): Promise<void> {
  page.once("dialog", (dialog) => dialog.accept());
  const reloaded = page.waitForEvent("load");
  await page.locator("#file-input").setInputFiles({
    name,
    mimeType: "text/markdown",
    buffer: Buffer.from(content),
  });
  await reloaded;
}

test.describe("web editor smoke tests", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForEditor(page);
  });

  test("starts the WebAssembly editor with the default document", async ({ page }) => {
    await expect.poll(() => getTerminalText(page), { timeout: 10_000 }).toContain(welcomeTitle);
    await expect(page.locator("#terminal-container")).toBeVisible();
  });

  test("accepts keyboard input in the terminal editor", async ({ page }) => {
    const marker = `playwright-${Date.now()}`;

    await page.locator("#terminal-container").click();
    await page.keyboard.type(marker);

    await expect.poll(() => getTerminalText(page), { timeout: 10_000 }).toContain(marker);
  });

  test("persists an imported workspace file through a page reload", async ({ page }) => {
    const filePath = "/workspace/playwright-integration.md";
    const content = `# Playwright integration\n\ncreated-${Date.now()}\n`;

    await importFile(page, "playwright-integration.md", content);
    await waitForEditor(page);

    await expect
      .poll(() => readVFSFile(page, filePath), { timeout: 10_000 })
      .toBe(content);
  });

  test("resets the IndexedDB workspace to its default files", async ({ page }) => {
    await importFile(page, "playwright-reset.md", "temporary test file\n");
    await waitForEditor(page);

    page.once("dialog", (dialog) => dialog.accept());
    await Promise.all([
      page.waitForNavigation({ waitUntil: "domcontentloaded" }).catch(() => {}),
      page.locator("#btn-clear-storage").click(),
    ]);
    await waitForEditor(page);

    await expect.poll(() => getTerminalText(page), { timeout: 10_000 }).toContain(welcomeTitle);
    await expect
      .poll(() => readVFSFile(page, "/workspace/playwright-reset.md"))
      .toBe("");
  });

  test("accepts dragged and dropped text files into VFS and opens them", async ({ page }) => {
    const fileName = "dropped-note.txt";
    const fileContent = "Hello from dropped file in zago!\n";

    await page.evaluate(({ name, content }) => {
      const dt = new DataTransfer();
      const file = new window.File([content], name, { type: "text/plain" });
      dt.items.add(file);
      const container = document.getElementById("terminal-container");
      container?.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer: dt }));
    }, { name: fileName, content: fileContent });

    await waitForEditor(page);
    await expect
      .poll(() => readVFSFile(page, `/workspace/${fileName}`), { timeout: 10_000 })
      .toBe(fileContent);
    await expect.poll(() => getTerminalText(page), { timeout: 10_000 }).toContain("Hello from dropped file");
  });

  test("resolves duplicate filename on drag and drop without overwriting", async ({ page }) => {
    const originalContent = "Original version\n";
    const secondContent = "Second duplicate version\n";

    await page.evaluate(({ content }) => {
      const dt = new DataTransfer();
      const file = new window.File([content], "dup-test.txt", { type: "text/plain" });
      dt.items.add(file);
      document.getElementById("terminal-container")?.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer: dt }));
    }, { content: originalContent });

    await waitForEditor(page);
    await expect
      .poll(() => readVFSFile(page, "/workspace/dup-test.txt"), { timeout: 10_000 })
      .toBe(originalContent);

    // Drop same filename again
    await page.evaluate(({ content }) => {
      const dt = new DataTransfer();
      const file = new window.File([content], "dup-test.txt", { type: "text/plain" });
      dt.items.add(file);
      document.getElementById("terminal-container")?.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer: dt }));
    }, { content: secondContent });

    await waitForEditor(page);
    // Original should remain intact
    await expect
      .poll(() => readVFSFile(page, "/workspace/dup-test.txt"), { timeout: 10_000 })
      .toBe(originalContent);
    // New file should be auto-renamed to dup-test_1.txt
    await expect
      .poll(() => readVFSFile(page, "/workspace/dup-test_1.txt"), { timeout: 10_000 })
      .toBe(secondContent);
  });

  test("rejects binary files dropped into the terminal container", async ({ page }) => {
    let dialogMessage = "";
    page.on("dialog", async (dialog) => {
      dialogMessage = dialog.message();
      await dialog.accept();
    });

    // Create a binary buffer containing null byte 0x00
    await page.evaluate(() => {
      const dt = new DataTransfer();
      const binaryData = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x00, 0x00, 0x00, 0x0d]);
      const file = new window.File([binaryData], "test-image.png", { type: "image/png" });
      dt.items.add(file);
      document.getElementById("terminal-container")?.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer: dt }));
    });

    await expect.poll(() => dialogMessage, { timeout: 5_000 }).toContain("test-image.png");
    // Binary file should NOT exist in VFS
    const vfsContent = await readVFSFile(page, "/workspace/test-image.png");
    expect(vfsContent).toBe("");
  });

  test("accepts dropping actual PRD file with CJK characters, emojis, and symbols", async ({ page }) => {
    const fs = await import("fs");
    const path = "/Users/zonble/Downloads/PRD變更到落地-完整流程.md";
    if (fs.existsSync(path)) {
      const realContent = fs.readFileSync(path, "utf-8");
      const realName = "PRD變更到落地-完整流程.md";

      await page.evaluate(({ name, content }) => {
        const dt = new DataTransfer();
        const file = new window.File([content], name, { type: "text/markdown" });
        dt.items.add(file);
        document.getElementById("terminal-container")?.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer: dt }));
      }, { name: realName, content: realContent });

      await waitForEditor(page);
      await expect
        .poll(() => readVFSFile(page, `/workspace/${realName}`), { timeout: 15_000 })
        .toBe(realContent);
    }
  });

  test("allows selecting a terminal font and persists preference", async ({ page }) => {
    const fontSelect = page.locator("#font-select");
    await expect(fontSelect).toBeVisible();

    await fontSelect.selectOption({ label: "JetBrains Mono" });
    const savedFont = await page.evaluate(() => localStorage.getItem("zago_editor_font"));
    expect(savedFont).toContain("JetBrains Mono");
  });

  test("opens directory buffer, correctly distinguishes folders from files, and opens file", async ({ page }) => {
    await page.locator("#terminal-container").click();
    await page.keyboard.press("Escape");
    await page.keyboard.type(":dir");
    await page.keyboard.press("Enter");

    // Verify directory buffer lists folders with ▸ and /
    await expect
      .poll(() => getTerminalText(page), { timeout: 10_000 })
      .toContain("▸ examples/");

    // Verify regular files are NOT treated as directories (do NOT have ▸ or trailing /)
    const termText = await getTerminalText(page);
    expect(termText).not.toContain("▸ welcome.en.md/");
    expect(termText).not.toContain("▸ welcome.zh-TW.md/");
    expect(termText).toContain("welcome.en.md");
    expect(termText).toContain("welcome.zh-TW.md");

    // DirectoryBuffer puts all folders before regular files. The workspace can
    // gain more folders over time, so locate the first regular file instead of
    // assuming that `examples/` is the only folder.
    const directoryCount = (termText.match(/▸ .*\//g) ?? []).length;
    for (let i = 0; i <= directoryCount; i++) {
      await page.keyboard.press("ArrowDown");
    }
    await page.keyboard.press("Enter");

    // Verify welcome.en.md is opened and its content is rendered
    await expect
      .poll(() => getTerminalText(page), { timeout: 10_000 })
      .toContain("Interactive Tutorial");
    await expect
      .poll(() => getTerminalText(page), { timeout: 10_000 })
      .not.toContain("Error opening file");
  });
});
