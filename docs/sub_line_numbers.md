# Sub Line Numbers

Sub line numbers are a writing aid for prose editing, especially for Chinese and other text where readability often depends on controlling paragraph length and visual line rhythm.

Unlike ordinary line numbers, sub line numbers describe how one physical buffer line is broken into visual lines by the editor's configured wrap column. They help an author see how long a paragraph will feel when rendered at a target width.

## Goal

When editing prose with a fixed wrap column, the editor should make two things visible without changing the buffer content:

1. How many characters are in the physical paragraph line.
2. Which visual wrapped segment the current screen row represents.

For example, one long buffer line may wrap into eleven visual rows. The first visual row displays the real line number and the paragraph character count. Continuation rows display the softwrap marker and their sub line number:

```text
   1 我在 2001 年，在當時相當普及的明日報個人 1 [123 chars]
   ↳ 新聞台服務上，發表了《防區狀況三生效－驗 2
   ↳ 證精實案》，中間有一些網站轉載，之後也曾 3
   ↳ 經發行過實體書籍，但只有刊出前九章。前兩 4
   ↳ 部的第一到第十四章，是 2001 年發表的內容 5
   ↳ ，至於十五章以後的第三部，是 2022 年新增 6
   ↳ 的章節。在 2001 年剛發表時，原文中隱藏了 7
   ↳ 一些防區的實際地點與事件的名稱，在當時有 8
   ↳ 些遮遮掩掩的樂趣，但二十多年去後，沒有刻 9
   ↳ 意隱藏的必要，而且反而影響了與後面一些章 10
   ↳ 節的連貫，因此改回原本的名稱。           11
```

The numbers on the right are display-only annotations. They are not inserted into the document.

## Terminology

- **Physical line**: One stored line in the editor buffer.
- **Visual line**: One rendered row after softwrap is applied.
- **Sub line number**: The 1-based visual line index within a physical line after wrapping.
- **Paragraph character count**: The number of Swift `Character` values in the physical line.

## Visibility Rules

Sub line numbers are shown only when all of these conditions are true:

- The feature is enabled.
- The editor is in normal text editing mode.
- A fixed wrap column is configured.
- The physical line wraps into more than one visual line.

The feature should not be shown in canvas mode, table mode, directory buffers, or when wrapping is dynamic with no fixed wrap column.

## Rendering Rules

The existing left gutter keeps its current meaning:

- The first visual line shows the ordinary physical line number.
- Wrapped continuation visual lines show the existing softwrap indicator `↳`.

Sub line information is rendered on the right side of the text area:

- The first visual line of a wrapped physical line shows the paragraph character count, for example `[123 chars]`.
- Every visual line in that physical line shows its 1-based sub line number.
- The first visual line's sub line number is `1`.
- Continuation lines are numbered `2`, `3`, and so on.

The right-side annotation should be visually dim or otherwise clearly secondary to document text. It must not be confused with editable content.

## Layout Rules

The right-side annotation occupies reserved horizontal space in the rendered text area. Text should not overlap the annotation.

When the terminal is too narrow, the editor should prefer preserving editable text and cursor correctness over showing the annotation. A truncated or hidden annotation is acceptable; corrupting the buffer display is not.

The annotation must not affect:

- Buffer contents.
- Cursor position in the buffer.
- Search behavior.
- Syntax highlighting tokenization.
- Copy/paste text operations.
- The physical line number gutter.

## Configuration

The feature must be configurable from `.zagorc`.

Expected directives:

```nanorc
set sublinenumbers on
set sublinenumbers off
unset sublinenumbers
```

`unset sublinenumbers` is equivalent to turning the feature off.

Suggested aliases:

```nanorc
set sublines on
set subline-numbers on
```

The generated default config should include a commented example.

## Menu

The feature must have a menu toggle. The toggle should live near other display-oriented options such as line numbers, ruler, wrap column, and syntax highlighting.

The checked state should reflect the current effective setting.

## Command Prompt

The setting should be available through the existing command prompt settings mechanism:

```text
set sublinenumbers on
set sublinenumbers off
```

Tab completion should include the setting name.

## Non-Goals

This feature is not a general outline numbering system.

It does not number sentences, paragraphs, Markdown list items, or visual rows across the whole file. It only numbers the visual wrap segments within one physical buffer line.

It also does not enforce a maximum paragraph length. It only provides visual feedback so the author can make editing decisions.
