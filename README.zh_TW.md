# `zago`:  為 AI Agent 時代打造的輕量文字編輯器

[English README](README.md) | [繁體中文使用手冊 Wiki](https://github.com/zonble/zago/wiki/zago-help-zh-tw)

![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![macOS + Linux + Windows](https://img.shields.io/badge/macOS%20%2B%20Linux%20%2B%20Windows-supported-blue)
![Terminal UI](https://img.shields.io/badge/Terminal-UI-334155)
![Markdown first](https://img.shields.io/badge/Markdown-first-2563eb)
![Tables](https://img.shields.io/badge/Pipe%20Tables-editable-0f766e)
![Diagrams](https://img.shields.io/badge/Text%20Diagrams-inline-7c3aed)
![CJK aware](https://img.shields.io/badge/CJK-aware-16a34a)
![Emoji safe](https://img.shields.io/badge/Emoji-safe-f59e0b)

在 AI Agent 普及的時代，Markdown 已成為人機協作與軟體開發的核心控制介面：寫規格書、提示詞指令、程式碼審查筆記、實作計畫與 context。

然而在 Terminal 裡編輯 Markdown 往往被打斷——GUI 編輯器會抽離 Terminal 流程，而傳統 Terminal 編輯器缺少表格與純文字繪圖工具。若想快速畫個文字架構圖，往往得開啟網頁版 ASCII 繪圖器或專用畫圖 App。

`zago` 為此而生：一款專為 Markdown 打造的輕量級 Terminal 編輯器。它將文章寫作、Pipe 表格排版、文件連結跳轉、大綱導覽、純文字架構圖、CJK 中英對齊工具以及自動化巨集整合在同一個流暢的純文字工作流中——無論是在本機筆電，還是透過 SSH 在遠端伺服器上。

![zago 編輯 Markdown 檔案、純文字架構圖與 LOGO 指令示範](zago.gif)

- [`zago`:  為 AI Agent 時代打造的輕量文字編輯器](#zago--為-ai-agent-時代打造的輕量文字編輯器)
  - [zago 適合誰？](#zago-適合誰)
  - [主要特色](#主要特色)
  - [快速開始](#快速開始)
    - [macOS / Linux (Homebrew Tap)](#macos--linux-homebrew-tap)
    - [Mint (Swift 套件管理器)](#mint-swift-套件管理器)
    - [Linux (x86\_64 / aarch64 預編譯二進制檔)](#linux-x86_64--aarch64-預編譯二進制檔)
    - [Arch Linux (AUR)](#arch-linux-aur)
    - [Windows (PowerShell)](#windows-powershell)
  - [文字模式與 2D Canvas 畫布模式](#文字模式與-2d-canvas-畫布模式)
  - [文字處理與文章編修功能](#文字處理與文章編修功能)
  - [指令範例 (Editor LOGO)](#指令範例-editor-logo)
  - [文件連結](#文件連結)
  - [授權條款](#授權條款)


## zago 適合誰？

- **AI Agent 使用者**：在 Terminal 內編寫 Markdown 提示詞、規格書、測試與審查筆記。
- **Markdown 創作者**：希望在單一 Terminal 工具中同時處理內文、大綱標題、表格與純文字架構圖。
- **技術文件撰寫者**：偏好純文字文件，在 Git Diff、SSH 連線、PR 與 README 保持高可讀性。
- **純文字繪圖愛好者**：無需跳出文件即可直接在文字檔內繪製框線與流程圖。
- **CJK 與 Emoji 精確度要求者**：需要終端機顯示寬度在表格、框線、尺規與段落換行時絕對精準對齊。
- **鍵盤優先使用者**：喜愛 Nano 風格的直覺操作，但需要更強大的 Markdown 工具箱。

---

## 主要特色

- **Markdown 優先編輯**：專為 Markdown/Org 語法優化，支援文件內部連結 jump (`M+O`)、大綱跳轉與語法高亮。
- **互動式 Pipe 表格編輯**：動態排版 Markdown 表格、單元格快捷鍵跳轉、自動文字居中，編輯內容不破壞框線。
- **純文字架構圖繪製**：支援 2D 矩形區塊選取、箭頭連線、區域填滿與框線自動熔接（T Junction）。
- **中英文排版與文字處理**：字數/中文字數/Emoji 統計、繁簡轉換、羅馬拼音轉換、CJK與英數字半形空格自動正規化。
- **全角 CJK 與 Emoji 精確計算**：包含 ✅, ❌, ⚠️ 等 Emoji 與中文字元，確保表格與框線在 Terminal 中不歪斜。
- **雙空間模式（Text Mode & 2D Canvas Mode）**：
  - **Text Mode**（預設）：直覺的流式文字輸入。
  - **Canvas Mode** (`M+V`)：解鎖 2D 虛擬空間導覽與矩形區塊選取 (`Shift+Arrows`)、區塊剪貼 (`^K` / `^U`)。
- **Nano 相容快捷鍵**：`^O` 存檔, `^X` 離開, `^W` 搜尋, `M+W` 複製, `^K` 剪切, `^U` 貼上, `^J` 段落重排, `^Z` 復原。
- **多頁籤 / 多 Buffer 編輯**：每個 Buffer 擁有完全獨立的 Undo/Redo 歷史紀錄與檢視設定。

---

## 快速開始

### macOS / Linux (Homebrew Tap)

```bash
brew tap zonble/zago
brew tap --trust zonble/zago  # 信任第三方 Tap
brew install zago
zago notes.md
```

### Mint (Swift 套件管理器)

```bash
mint install zonble/zago
zago notes.md
```

### Linux (x86_64 / aarch64 預編譯二進制檔)

```bash
curl -fsSL https://raw.githubusercontent.com/zonble/zago/main/install.sh | sh
zago notes.md
```

### Arch Linux (AUR)

```bash
git clone https://github.com/cawa0505/aur-zago.git zago-bin
cd zago-bin
makepkg -si
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/zonble/zago/main/install.ps1 | iex
```

---

## 文字模式與 2D Canvas 畫布模式

`zago` 提供兩種互相互補的空間編輯模式。在兩種模式下，打字輸入皆保持無模式（Modeless）狀態，可直接輸入字元：

- **文字模式 (Text Mode)**（預設）：適用於文章與程式碼的標準線性文字編輯，選取範圍遵循傳統文字流。
- **畫布模式 (Canvas Mode)** (`M+V`)：解鎖超越行尾限制的 2D 虛擬空間導覽。支援 2D 矩形區塊選取 (`Shift+方向鍵`)、區塊複製 (`M+W`)、區塊剪切 (`^K`) 與區塊貼上 (`^U`)，且不會破壞周圍文字與段落排版。

> [!TIP]
> **Windows Terminal 快捷鍵提醒**：在 Windows Terminal 中，`Ctrl+Shift+Up` 與 `Ctrl+Shift+Down` 預設被綁定為終端機視窗捲動。若欲在 Canvas Mode 中使用此快捷鍵繪製垂直箭頭，請至 Windows Terminal 的 **設定 -> 動作 (Settings -> Actions)** 中取消該快捷鍵綁定。

關於選取規則與剪貼簿隔離機制，請參閱 [標記、選取與 Canvas 模式說明](docs/mark.md)。

## 文字處理與文章編修功能

`zago` 本質上仍是一款極致優化的文字編輯器，圖表與畫布工具是堆疊於文章寫作之上，而非取代日常文字編輯：

- **線性選取與直接覆蓋**：包含 `Shift+方向鍵` 與 `Shift+Home` / `Shift+End` 的文字選取，直接打字即可取代選取文字。
- **段落重排與左右對齊 (`^J`)**：專為中英混排 (CJK & Latin) 優化的左右對齊演算法，依據 Terminal 顯示寬度（Display Width）計算而非位元組或 Scalar。
- **工具選單之文字轉換**：提供選取文字之繁簡體轉換、日文假名/羅馬字轉譯，以及 CJK 與英數字半形空格自動正規化。
- **精準字數統計**：提供字元數、單詞數、行數統計。有選取範圍時統計該選取區塊，無選取時統計全檔；僅在文件中存在中文字元或 Emoji 時顯示 CJK/Emoji 統計項目。
- **子行號與段落計數**：開啟軟換行 (Softwrap) 欄寬時，可顯示視覺行號 (Visual Line Numbers) 與段落字數，方便固定欄寬草稿寫作。
- **文件連結跳轉 (`M+O`)**：支援本機 Markdown, Org, reStructuredText 與 AsciiDoc 文件內部連結跳轉。
- **標題導覽與大綱選單 (`M+I`)**：自動解析 Markdown, Org, reStructuredText 與 AsciiDoc 的標題階層大綱並快速跳轉。

---

## 指令範例 (Editor LOGO)

按下 `Esc` 鍵即可進入指令列。指令採用簡潔的 Editor LOGO 語法，可用於快速編輯、文字繪圖與自動化巨集：

- **文字移動與插入**：
  ```logo
  MOVE HOME; TYPE "# "; MOVE END
  ```

- **繪製外框與區域填滿**：
  ```logo
  BOX 30 5 CENTER ROUND
  DRAWBOX 30 4 ROUND; GOTO 2 2; FILL "hi
  ```

- **迴圈與自動清單**：
  ```logo
  REPEAT 5 [ TYPE :# ". 項目說明" NL ]
  ```

- **自訂副程式 (Procedure)**：
  ```logo
  TO TITLE :text
    BOX :text CENTER ROUND
  END
  ```

- **繪製 ASCII 簡圖**：
  ```logo
  DRAWBOX 18 3 "client" CENTER; GOTO 3 11; VLINE 3
  GOTO 5 1; DRAWBOX 18 5; GOTO 6 2; TYPE "     server     "
  ```
  ```text
  ┌────────────────┐
  │     client     │
  └─────────┬──────┘
            │
  ┌─────────┴──────┐
  │     server     │
  └────────────────┘
  ```

完整指令語法請參閱 [Editor LOGO 指令說明](docs/logo.md) 與 [線上繁體中文手冊](https://github.com/zonble/zago/wiki/zago-help-zh-tw)。

---

## CLI 命令列與管道 (Pipe) 過濾器

`zago` 支援全螢幕 TUI 互動編輯器、系統 `$EDITOR`、以及無介面 CLI 管道過濾器 (Unix Pipe Filter)：

### 1. 互動編輯器與系統 `$EDITOR`

可設定 `export EDITOR=zago`，支援開啟檔案、指定跳轉行號、或直接將 `stdin` 管道傳入編輯器：

```bash
# 在 TUI 編輯器中開啟檔案
zago notes.txt --wrap 80 --ruler

# 開啟檔案並直接跳轉至第 42 行第 10 欄
zago +42:10 notes.txt

# 將管道資料傳入互動編輯器 Buffer
cat server.log | zago

# 以唯讀模式開啟檔案
zago -R /var/log/syslog
```

### 2. Headless 無介面指令與管道過濾器

無需開啟 TUI 畫面，直接將 `stdin` 管道資料經由 LOGO 腳本處理後輸出至 `stdout`：

```bash
# 將管道文字自動畫上 ASCII 外框
uptime | zago -e "box buffertext"

# 執行單行 LOGO 指令並將結果輸出至 stdout
zago -e "BOX 20 4; MOVE DOWN MOVE RIGHT; FILL \"Hello World\""

# 利用 LOGO 腳本處理輸入檔案並重導向輸出
cat data.txt | zago -s format_report.logo > diagram.txt
```

### 命令列選項說明

| 選項 | 旗標 | 說明 |
| :--- | :--- | :--- |
| `files` | | 開啟檔案，`-` 代表 stdin 管道，或傳入 `+LINE[:COL]` 指定跳轉行號/欄號。 |
| `-w`, `--wrap <col>` | | 指定軟換行欄寬 (例如 80)。 |
| `-r`, `--ruler` | | 在視窗上方顯示經典 WordStar 風格標尺。 |
| `-R`, `--readonly` | | 以唯讀模式開啟檔案。 |
| `-e`, `--eval <code>` | | 無介面模式下執行單行 LOGO 程式碼並輸出至 stdout (支援 Pipe 輸入)。 |
| `-s`, `--run`, `--script <file>` | | 無介面模式下執行 LOGO 腳本檔並輸出至 stdout (支援 Pipe 輸入)。 |
| `--init` | | 產生預設的 `~/.zagorc` 設定檔。 |

---

## 文件連結

- [繁體中文使用手冊 (Wiki)](https://github.com/zonble/zago/wiki/zago-help-zh-tw)
- [編輯器基礎操作](docs/editor.md)
- [搜尋與取代機制](docs/search.md)
- [選取與 2D Canvas 模式說明](docs/mark.md)
- [Editor LOGO 指令語法](docs/logo.md)
- [設定檔與快捷鍵綁定](docs/configuration.md)
- [繪圖模式與海龜指令](docs/logo_pen_mode.md)
- [預設圖表範本與選單規則](docs/diagram_snippets.md)
- [拼字檢查器架構](docs/spell_checker.md)
- [文字編碼自動偵測](docs/encoding.md)
- [Homebrew Tap 說明](docs/homebrew_tap.md)
- [發行與編譯說明](docs/release.md)
- [版本變更紀錄](CHANGELOG.md)

---

## 授權條款

MIT License. Copyright (c) 2026 Weizhong Yang a.k.a. zonble.
