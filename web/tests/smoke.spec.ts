import { test, expect, type Page } from "@playwright/test";

const welcomeTitle = "# zago Interactive Tutorial";

async function waitForEditor(page: Page): Promise<void> {
  await expect(page.locator("#wasm-loading-overlay")).toHaveClass(/hidden/, {
    timeout: 90_000,
  });
  await expect(page.locator(".xterm-rows")).toBeVisible();
}

function terminalText(page: Page) {
  return page.locator(".xterm-rows");
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
    await expect(terminalText(page)).toContainText(welcomeTitle);
    await expect(page.locator("#terminal-container")).toBeVisible();
  });

  test("accepts keyboard input in the terminal editor", async ({ page }) => {
    const marker = `playwright-${Date.now()}`;

    await page.locator("#terminal-container").click();
    await page.keyboard.type(marker);

    await expect(terminalText(page)).toContainText(marker);
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
    await page.locator("#btn-clear-storage").click();
    await waitForEditor(page);

    await expect(terminalText(page)).toContainText(welcomeTitle);
    await expect
      .poll(() => readVFSFile(page, "/workspace/playwright-reset.md"))
      .toBe("");
  });
});
