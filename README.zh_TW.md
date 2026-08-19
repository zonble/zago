# `zago`: 二十一世紀的台灣式編輯器

![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![macOS + Linux + Windows](https://img.shields.io/badge/macOS%20%2B%20Linux%20%2B%20Windows-supported-blue)
![Terminal UI](https://img.shields.io/badge/Terminal-UI-334155)
![Markdown first](https://img.shields.io/badge/Markdown-first-2563eb)
![Tables](https://img.shields.io/badge/Pipe%20Tables-editable-0f766e)
![Diagrams](https://img.shields.io/badge/Text%20Diagrams-inline-7c3aed)
![CJK aware](https://img.shields.io/badge/CJK-aware-16a34a)
![Emoji safe](https://img.shields.io/badge/Emoji-safe-f59e0b)

在 AI 普及之後，可以發現 AI 產生的文字檔案—尤其是 Markdown 檔案—往往會同
時混合多種性質的內容，包括一般文章、程式碼、還有使用文字—用框線字元—繪製
的圖表。我們讓 AI 產生這類的文件後，往往有繼續修改的需求—AI 一開始幫我們
寫好了規劃，但之後可能發生需求變動或擴充，或是要繼續潤色之後才適合提供給
其他人，但—現在流行的編輯器，其實不適合編輯當中的圖表。

現在大多的純文字編輯器，都把文字當成一維空間，如果要修改圖表，往往要自己
手動輸入一大堆的空白。西方為了編輯這些圖表，還發展了 ASCIIflow/MonoDraw
等專屬工具，但使用這些工具時，一來會打斷在終端機當中的工作流，二來往往忽
略了中文等亞洲文字其實是兩倍寬度，用這些工具輸入中文後，排出來的版面都會
跑版。

台灣 90 年代的本土編輯器，反而有將文字視為二維空間的傳統，在編輯器中，游
標可以自由移動到任何還沒有輸入文字的部分，而且加上大量用來繪製框線的巨集
。台灣人用這樣的編輯器，製作公文、法律與商業文書，而加上顏色控制碼之後，
也打造了文字模式 BBS 的看板畫面等獨特在地文化。這種編輯器，反而更適合處
理 AI 時代的 Markdown 檔案—在終端機因為 AI 復興之後，一些過往的設計，反
而更符合 AI 時代的需求。

可惜的是，90 年代雖然本土編輯器百花齊放，但大部分都沒有延續到二十一世紀
，大多都在千禧年前後電腦走向圖形介面時逐漸凋零。我們也不可能直接回頭用
DOS 時代的軟體—需要模擬器才可以執行，也不支援 Unicode 這樣的現代文字編碼
，顯然不符現在的日常所需。

`zago` 是一套為了滿足編輯 AI 產生的文件的現代終端機編輯器。在 nano 編輯
器的操作習慣的基礎上，增加了台灣本土編輯器的畫布模式與表格模式，畫布模式
沿用過去的游標移動與區塊複製貼上，表格模式則可以只編輯格線構成的格子中的
內容，不會破壞格線。並且可以精確處理中文、Emoji 字元，在各種圖表中都不會
跑版。

在這樣的基礎上，`zago` 還有一整套用來快速繪製圖表的命令—像是，只要輸入「
BOX "hi"」，就可以直接在文件中畫好一個內容是「hi」的方框，然後用「LINE」
命令，就可以直接接好連接線。

![zago 編輯 Markdown 檔案、純文字架構圖與 LOGO 指令示範](zago.gif)

- [`zago`: 二十一世紀的台灣式編輯器](#zago-二十一世紀的台灣式編輯器)
  - [zago 適合誰？](#zago-適合誰)
  - [主要功能](#主要功能)
  - [安裝](#安裝)
    - [macOS / Linux (Homebrew Tap)](#macos--linux-homebrew-tap)
    - [Mint (Swift 套件管理器)](#mint-swift-套件管理器)
    - [Linux (x86\_64 / aarch64 預編譯二進制檔)](#linux-x86_64--aarch64-預編譯二進制檔)
    - [Arch Linux (AUR)](#arch-linux-aur)
    - [Windows (PowerShell)](#windows-powershell)
  - [文字模式與畫布模式](#文字模式與畫布模式)
  - [表格模式](#表格模式)
  - [文字處理與文章編修功能](#文字處理與文章編修功能)
  - [用來與 AI Agent 互動的 IPC 模式](#用來與-ai-agent-互動的-ipc-模式)
  - [指令範例 (Editor LOGO)](#指令範例-editor-logo)
  - [CLI 命令列與管道 (Pipe) 過濾器](#cli-命令列與管道-pipe-過濾器)
    - [1. 互動編輯器與系統 `$EDITOR`](#1-互動編輯器與系統-editor)
    - [2. Headless 無介面指令與管道過濾器](#2-headless-無介面指令與管道過濾器)
    - [命令列選項說明](#命令列選項說明)
  - [文件連結](#文件連結)
  - [授權條款](#授權條款)

## zago 適合誰？

- **AI Agent 使用者**：希望在終端機中與 AI Ahent 互動時，同時也在終端機
  中編寫 Markdown 提示詞、規格書等文件。
- **Markdown 作者**：希望在單一終端機工具中處理內文表格與純文字架構圖。
- **技術文件作者**：偏好純文字文件，在 Git Diff、SSH 連線、PR 與 README
  保持高可讀性。
- **純文字繪圖愛好者**：可直接在文字檔內繪製框線與流程圖。
- **CJK 與 Emoji 重度使用者**：需要終端機顯示寬度在表格、框線、尺規與段
  落換行時絕對精準對齊。
- **鍵盤優先使用者**：喜愛 Nano 風格的直覺操作，但需要處理圖表的工具箱。

## 主要功能

- **Markdown 基本文字編輯**：包括語法上色，支援文件內部連結跳轉 (`M+O`)、大綱跳轉與語法高亮。
- **Markdown Pipe 表格編輯**：可以用 Tab 按鍵幫 Markdown 表格排版、在儲存格中快捷鍵跳轉，編輯內容不破壞框線。
- **純文字圖表功能**：支援 2D 矩形區塊選取、箭頭連線、區域填滿與框線自動熔接（T Junction）。
- **中英文排版與文字處理**：中英文/Emoji 字數統計、繁簡轉換、羅馬拼音轉換、CJK與英數字半形空格自動正規化。
- **全角 CJK 與 Emoji 精確計算**：包含 ✅, ❌, ⚠️ 等 Emoji 與中文字元，確保表格與框線不歪斜。
- **文字與畫布雙模式**：
  - **文字模式**：與 Nano 相同的輸入模式
  - **Canvas Mode** (`F8`)：使用 `Shift+Arrows` 直接畫線、支援區塊剪貼 (`^K` / `^U`)。
- **Nano 相容快捷鍵**：`^O` 存檔, `^X` 離開, `^W` 搜尋, `M+W` 複製, `^K` 剪切, `^U` 貼上, `^J` 段落重排, `^Z` 復原。
- **多文件編輯**：每份文件擁有完全獨立的還原/重作歷史紀錄與設定。

## 安裝

### macOS / Linux (Homebrew Tap)

```bash
brew tap zonble/zago
brew tap --trust zonble/zago  # 信任第三方 Tap
brew install zago
zago notes.md
```

### Mint (Swift 套件管理器)

在 macOS 上也可以使用 Mint 安裝

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

## 文字模式與畫布模式

`zago` 提供兩種互相互補的空間編輯模式。在兩種模式下，打字輸入皆保持無模式（Modeless）狀態，可直接輸入字元：

- **文字模式 (Text Mode)**（預設）：適用於文章與程式碼的標準線性文字編輯，選取範圍遵循傳統文字流。
- **畫布模式 (Canvas Mode)** (`M+V`)：解鎖超越行尾限制的 2D 虛擬空間導覽。支援 2D 矩形區塊選取 (`Shift+方向鍵`)、區塊複製 (`M+W`)、區塊剪切 (`^K`) 與區塊貼上 (`^U`)，且不會破壞周圍文字與段落排版。

> [!TIP]
>
> **Windows Terminal 快捷鍵提醒**：在 Windows Terminal 中，
> `Ctrl+Shift+Up` 與 `Ctrl+Shift+Down` 預設被綁定為終端機視窗捲動。若欲
> 在 Canvas Mode 中使用此快捷鍵繪製垂直箭頭，請至 Windows Terminal 的 **
> 設定 -> 動作 (Settings -> Actions)** 中取消該快捷鍵綁定。

關於選取規則與剪貼簿隔離機制，請參閱 [標記、選取與 Canvas 模式說明](docs/user/mark.md)。

## 表格模式

在任何用框線組成的格子中，按下` F7` 按鍵，就可以進入表格模式，之後就只會
編輯格子中的內容，不會破壞格線。

## 文字處理與文章編修功能

`zago` 本質上仍是一款文字編輯器，包括以下功能

- **選取/複製/貼上**：包含 `Shift+方向鍵` 與 `Shift+Home` / `Shift+End`
  的文字選取，選取之後可以用快速鍵複製貼上，符合大部分編輯器習慣。。
- **正確處理中英文字寬**：使用自動折行或是強制段落重排時（^J），都正確處
  理中英文寬度。
- **文字轉換**：選取文字後，可以做繁簡體轉換、日文假名/羅馬字轉譯，以及
  在 CJK 與英數字之間加上半形空格。
- **精準字數統計**：提供字元數、英文單詞數、行數統計。有選取範圍時統計該
  選取區塊，無選取時統計全檔；僅在文件中存在中文字元或 Emoji 時顯示
  CJK/Emoji 統計項目。
- **子行號與段落計數**：開啟軟換行 (Softwrap) 欄寬時，可顯示視覺行號
  (Visual Line Numbers) 與段落字數，方便固定欄寬草稿寫作。
- **文件連結跳轉 (`M+O`)**：支援本機 Markdown, Org, reStructuredText 與
  AsciiDoc 文件內部連結跳轉。
- **標題導覽與大綱選單 (`M+I`)**：自動解析 Markdown, Org,
  reStructuredText 與 AsciiDoc 的標題階層大綱並快速跳轉。

## 用來與 AI Agent 互動的 IPC 模式

`zago` 支援一套可以與 AI Aget 互動的 IPC 模式，讓 AI 往 `zago` 輸入內容
或是執行特定命令。要開始使用 IPC 命令，請先安裝屬於 `zago` 的 AI Skill
與 MCP server。

```sh
zago --install-skill
```

接著，用以下命令啟動 `zago`：

```sh
zago --ipc notes.txt
```

您可以在 AI Agent 中，使用像是「請用 zago skill 幫目前的文件寫一份摘要」
之類的 prompt，讓 AI 產生內容提案。當 AI 將內容送到 zago 之後，可以按下
M+A 接受提案。

## 指令範例 (Editor LOGO)

按下 `Esc` 鍵後，即可進入指令列。指令採用簡潔的語法，可用於文字繪圖，輸
入日期等特殊內容，甚至是自動化巨集：

- **繪製外框與區域填滿**：

  ```logo
  BOX 30 5 CENTER ROUND
  DRAWBOX 30 4 ROUND
  GOTO 2 2
  FILL "hi
  ```

- **文字移動與插入**：

  ```logo
  MOVE HOME
  TYPE "# "
  MOVE END
  ```

- **迴圈與自動列表**：

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

完整指令語法請參閱 [Editor LOGO 指令說明](docs/logo/reference.md) 與 [線上繁體中文手冊](https://github.com/zonble/zago/wiki/zago-help-zh-tw)。

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

| 選項                             | 旗標 | 說明                                                                    |
| :------------------------------- | :--- | :---------------------------------------------------------------------- |
| `files`                          |      | 開啟檔案，`-` 代表 stdin 管道，或傳入 `+LINE[:COL]` 指定跳轉行號/欄號。 |
| `-w`, `--wrap <col>`             |      | 指定軟換行欄寬 (例如 80)。                                              |
| `-r`, `--ruler`                  |      | 在視窗上方顯示經典 WordStar 風格標尺。                                  |
| `-R`, `--readonly`               |      | 以唯讀模式開啟檔案。                                                    |
| `-e`, `--eval <code>`            |      | 無介面模式下執行單行 LOGO 程式碼並輸出至 stdout (支援 Pipe 輸入)。      |
| `-s`, `--run`, `--script <file>` |      | 無介面模式下執行 LOGO 腳本檔並輸出至 stdout (支援 Pipe 輸入)。          |
| `--init`                         |      | 產生預設的 `~/.zagorc` 設定檔。                                         |

---

## 文件連結

- [繁體中文使用手冊 (Wiki)](https://github.com/zonble/zago/wiki/zago-help-zh-tw)
- [編輯器基礎操作](docs/user/editor.md)
- [搜尋與取代機制](docs/user/search.md)
- [選取與 2D Canvas 模式說明](docs/user/mark.md)
- [Editor LOGO 指令語法](docs/logo/reference.md)
- [設定檔與快捷鍵綁定](docs/user/configuration.md)
- [繪圖模式與海龜指令](docs/logo/pen_mode.md)
- [預設圖表範本與選單規則](docs/features/diagram_snippets.md)
- [拼字檢查器架構](docs/features/spell_checker.md)
- [文字編碼自動偵測](docs/features/encoding.md)
- [Homebrew Tap 說明](docs/development/homebrew_tap.md)
- [發行與編譯說明](docs/development/release.md)
- [版本變更紀錄](CHANGELOG.md)

---

## 授權條款

MIT License. Copyright (c) 2026 Weizhong Yang a.k.a. zonble.
