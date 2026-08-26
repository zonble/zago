import type { TranslationSchema } from "./en";

export const zhTW: TranslationSchema = {
  pageTitle: "zago — 為 AI Prompt 打造的終端機編輯器",
  pageDescription:
    "zago 是一套以鍵盤為中心的終端機文字編輯器，內建現代文字繪圖引擎，專為 AI 工作流、Markdown 文件、表格與 Editor LOGO 繪圖量身打造。",
  tabDocs: "📖 關於 zago",
  tabDemo: "💻 線上 Demo",
  heroTagline: "為 AI Prompt 打造的終端機編輯器",
  quickInstallTitle: "安裝方式",
  platformMac: "macOS (Homebrew)",
  platformLinux: "Linux (x86_64 / arm64)",
  platformWin: "Windows (PowerShell)",
  whyTitle: "zago 要解決的問題",
  whyItem1:
    "<strong>LLM 與 AI Agent 經常在用文件中繪製文字圖</strong>，一般編輯器極易跑版破壞格線文字圖的格線，編輯困難。國外文字圖工具也往往忽視亞洲文字是兩倍寬度，遇到中文一樣跑版。",
  whyItem2:
    "<strong>文字圖早成為了給 AI Prompt 的一部分</strong>，我們因此需要更有效率的編輯工具。",
  howTitle: "zago 怎麼解決問題？",
  howItem1:
    "<strong>畫布模式：</strong> 游標可以任意自由移動，不用為了對齊框線輸入一堆空白。",
  howItem2:
    "<strong>表格模式：</strong> 將編輯範圍限制在格線中，不會推擠破壞外框格線。",
  howItem3:
    "<strong>快速繪圖指令：</strong> 透過 <code>BOX</code>、<code>LINE</code> 與 <code>VLINE</code> 等指令，數秒內即可完成架構圖繪製。",
  howItem4:
    "<strong>中文與 Emoji 精確對齊：</strong> 全形中文與 Emoji 均以精準顯示寬度計算排版，框線整齊不跑版。",
  howItem5:
    "<strong>完整語法引擎：</strong> <code>BOX</code>、<code>LINE</code> 語法還可以與簡繁轉換、日期、度量單位格式結合，方便快速輸入內容。",
  jumpDemoBtn: "💻 在瀏覽器中啟動線上終端機",
  toolbarTitle: "互動式工作區 (<code>/workspace</code>)",
  btnImport: "匯入",
  btnExportZip: "匯出 ZIP",
  btnResetVFS: "重設工作區",
  btnHelp: "說明",
  loadingTitle: "正在啟動 zago 虛擬系統",
  loadingStatusInit: "正在下載 zago.wasm...",
  loadingDetailInit: "正在準備 WebAssembly 執行環境",
  loadingStatusCached: "正在從快取載入 zago.wasm...",
  loadingDetailCached: "快取秒開啟動中",
  startingStatus: "正在啟動 zago 虛擬系統...",
  startingDetail: "正在建立 WASI 執行環境",
  readyStatus: "準備完成！",
  readyDetail: "正在啟動編輯器...",
  wasmLoadingStatus: "正在載入 WebAssembly 二進位檔...",
  wasmInstantiatingStatus: "正在建立 zago.wasm 虛擬系統...",
  editorExited: 'zago 已退出。輸入「zago」重新啟動',
  failedToStart: "啟動失敗",
  shellPrompt: "zago $ ",
  shellCommandNotFound: (command: string) =>
    `找不到指令：${command}。請輸入「zago [檔名]」啟動，或輸入「clear」清除畫面。`,
  copied: "已複製！",
  unsupportedTitle: "瀏覽器環境不支援",
  unsupportedMsg:
    "社群 App 內建瀏覽器（如 X/Twitter、LINE、Facebook）或受限環境不支援 WebAssembly 跨來源隔離（SharedArrayBuffer）。",
  unsupportedHint:
    "請改用 <strong>Safari</strong>、<strong>Chrome</strong> 或系統預設瀏覽器開啟本頁面，即可體驗完整終端機編輯器。",
  btnCopyLink: "複製頁面網址",
  btnViewDocs: "閱讀說明文件",
  helpDialogTitle: "zago Web 虛擬系統",
  helpDialogIntro:
    "<strong>zago</strong> 在 WebAssembly 中運行具備 POSIX 相容的虛擬檔案系統（VFS）。",
  helpDialogSubtitle: "常用指令與快捷鍵：",
  helpItemDir:
    "<code>:dir</code> 或 <code>:ls</code> : 開啟目錄瀏覽器檢視資料夾",
  helpItemSave: "<code>Ctrl + O</code> : 儲存目前緩衝區至 IndexedDB VFS",
  helpItemQuit:
    "<code>Ctrl + Q</code> 或 <code>Ctrl + X</code> : 退出編輯器返回命令列（輸入 <code>zago</code> 可重新開啟）",
  helpItemCanvas: "<code>F8</code> : 切換 2D 畫布模式（自由畫線、箭頭與方框）",
  helpItemTable: "<code>F7</code> : 切換表格模式（編輯儲存格不破壞格線）",
  helpItemHelp: "<code>Ctrl + G</code> : 開啟線上說明選單",
  btnCloseHelp: "關閉",
  resetConfirm: "確定要將虛擬檔案系統與 IndexedDB 重設為預設狀態嗎？",
  importZipSuccess: (count: number, filename: string) =>
    `成功從「${filename}」匯入 ${count} 個檔案至 /workspace。\n即將重新載入以掛載檔案系統...`,
  importFileSuccess: (filename: string) =>
    `已將「${filename}」匯入至 /workspace。\n即將重新載入以開啟...`,
  importFailed: (err: string) => `匯入檔案失敗：${err}`,
  binaryFileNotSupported: (filename: string) =>
    `「${filename}」為二進位檔案，無法在 zago 中開啟。`,
};
