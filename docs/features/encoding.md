# File Encoding & Auto-Detection Architecture

This document outlines the architecture, detection strategy, and save/fallback workflow for `zago`'s multi-encoding file handling system.

---

## Overview

`zago` is a terminal text and Markdown editor designed to open, edit, and save files across various character encodings (such as UTF-8, Big5, GB18030, Shift-JIS, Windows-1252, and ISO-8859-1) without corrupting legacy files or requiring manual encoding selection upon open.

---

## Core Principles

1. **Automatic Detection on Open**:
   When opening a file, `zago` inspects Byte Order Marks (BOM), UTF-8 validity, and localized multi-byte / single-byte encodings in a strict deterministic order.
2. **Buffer Encoding State**:
   Each `TextBuffer` retains its detected initial encoding in `buffer.fileEncoding: String.Encoding`.
3. **Preserve Original Encoding on Save**:
   Saving defaults to writing back using `buffer.fileEncoding`.
4. **UTF-8 Fallback Prompt on Character Overflow**:
   If edits introduce characters unsupported by the original encoding (e.g. adding emojis or CJK characters to a Windows-1252 file), saving in the original encoding fails. `zago` prompts the user to convert and save as UTF-8.
5. **No Manual Non-UTF-8 Encoding Picker**:
   To keep the terminal UI minimal and intuitive, `zago` does not provide an encoding selection picker menu. All fallback conversions are fixed to **UTF-8**.

---

## Encoding Auto-Detection Strategy

When reading raw file bytes (`Data`), `zago` attempts decoding in the following sequence:

1. **Byte Order Mark (BOM)**:
   - UTF-8 BOM (`EF BB BF`) -> `String.Encoding.utf8`
   - UTF-16LE BOM (`FF FE`) -> `String.Encoding.utf16LittleEndian`
   - UTF-16BE BOM (`FE FF`) -> `String.Encoding.utf16BigEndian`
2. **UTF-8 (No BOM)**:
   - Validated via `String(data: data, encoding: .utf8)`. UTF-8 is strict and fails when invalid byte sequences exist.
3. **Multi-Byte Localized Encodings**:
   - Traditional Chinese (`.big5`)
   - Simplified Chinese (`.gb_18030_2000` / `.dosChineseSimpl`)
   - Japanese (`.shiftJIS`, `.japaneseEUC`)
4. **Single-Byte Fallback Encodings (8-Bit)**:
   - `.windowsCP1252` / `.isoLatin1`
   - *Note*: Single-byte 8-bit encodings map every byte (0x00–0xFF) to a valid character and never fail. Therefore, they MUST be evaluated last as a catch-all fallback to prevent misdetecting multi-byte encodings.

---

## Save & Fallback Workflow

```
[ User triggers Save (^O / ^S / :w) ]
                │
                ▼
   [ Attempt encoding with buffer.fileEncoding ]
                │
         ┌──────┴──────┐
      Success         Failure (Incompatible characters)
         │                   │
         ▼                   ▼
 [ Write to Disk ]    [ Prompt User ]
                      "Current encoding [Big5] cannot represent new characters.
                       Convert and save as UTF-8? (Y/N)"
                             │
                      ┌──────┴──────┐
                    [Y]           [N]
                     │             │
                     ▼             ▼
              [ Save as UTF-8 ] [ Cancel Save ]
              [ Set fileEncoding = .utf8 ]
```

---

## Architecture & API Specifications

### 1. `TextBuffer`
```swift
public final class TextBuffer {
    /// Character encoding used when reading or saving this buffer
    public var fileEncoding: String.Encoding = .utf8
}
```

### 2. `EditorFileIOStrategy` Protocol
```swift
public struct TextReadResult {
    public let content: String
    public let encoding: String.Encoding
}

public protocol EditorFileIOStrategy: Sendable {
    func readTextFile(at path: String) throws -> TextReadResult
    func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws
}
```

### 3. Prompt Mode Integration
```swift
public enum PromptMode {
    case confirmEncodingFallback(targetEncoding: String.Encoding, originalEncoding: String.Encoding, completion: (Bool) -> Void)
}
```

---

## Localization & User Messages

| Key | English | Traditional Chinese |
| :--- | :--- | :--- |
| `prompt.encoding_fallback` | `Encoding "%@" cannot represent new text. Convert and save as UTF-8? (y/n) ` | `編碼 "%@" 無法支援新文字，是否改以 UTF-8 格式儲存？(y/n) ` |
| `status.saved_as_utf8` | `[ Saved as UTF-8 ]` | `[ 已改用 UTF-8 儲存 ]` |
| `status.save_cancelled` | `[ Save cancelled ]` | `[ 存檔已取消 ]` |
