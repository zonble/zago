# Heading Navigation & Outline

This document defines zago's heading navigation and outline behavior.

## Purpose

Heading navigation is a writing-oriented document structure feature. It is not a programming-language symbol browser.

The goal is to help users move through long prose documents, technical notes, manuals, specifications, and local knowledge bases made of Markdown, Org, reStructuredText, or AsciiDoc files.

## Scope

The first implementation should support:

- jumping to the next heading
- jumping to the previous heading
- showing an outline picker for the current document
- jumping from the outline picker to a selected heading

The first implementation should not include:

- folding
- moving sections up or down
- copying the current section
- section-local word counts
- recursive embedded-language outlines
- programming-language symbol extraction

Those features may be added later on top of the same document outline model.

## Responsibility Boundary

Heading recognition belongs in the `Syntax` target because it is document-format knowledge. The editor should not need to know how Markdown, Org, reStructuredText, or AsciiDoc spell headings.

The boundary is:

- `Syntax` parses document lines into structural metadata.
- `Syntax` returns headings with logical line positions, heading levels, and display titles.
- `Editor` uses that structure for cursor movement, outline UI, key bindings, status messages, and menu commands.

`Syntax` must not depend on editor state. It should not know about buffers, cursor position, terminal size, menus, prompts, or modes.

Suggested API shape:

```swift
public struct DocumentHeading: Equatable, Sendable {
    public let lineIndex: Int
    public let level: Int
    public let title: String
    public let marker: String
}

public struct DocumentOutline: Equatable, Sendable {
    public let headings: [DocumentHeading]
}

public enum DocumentOutlineParser {
    public static func parse(lines: [String], language: Language?) -> DocumentOutline
}
```

`Language?` may be inferred from the current buffer file path or explicit editor language setting. If the language is unknown, the parser may use conservative multi-format detection for prose formats only.

## Supported Heading Forms

### Markdown

ATX headings:

```markdown
# Heading 1
## Heading 2
###### Heading 6
```

Setext headings:

```markdown
Heading 1
=========

Heading 2
---------
```

Markdown heading markers inside fenced code blocks should be ignored once code-block awareness is implemented. The first version may use the existing Syntax target's Markdown block knowledge if available; otherwise this limitation must be documented in tests.

### Org

```org
* Heading 1
** Heading 2
*** Heading 3
```

The heading level is the number of leading `*` markers.

### reStructuredText

```rst
Heading
=======

Subheading
----------
```

reStructuredText heading levels are inferred by underline marker order within the document. For example, the first underline marker style encountered is level 1, the next distinct style is level 2, and so on.

Supported underline markers should include:

```text
= - ` : . ' " ~ ^ _ * + #
```

The underline must be at least as wide as the heading title after trimming trailing whitespace.

### AsciiDoc

```asciidoc
= Heading 1
== Heading 2
====== Heading 6
```

The heading level is the number of leading `=` markers.

## Navigation Behavior

Heading navigation uses logical buffer lines, not visual soft-wrapped lines.

### Next Heading

`document.heading_next` should:

- search from the line after the current cursor line
- jump to the next heading if found
- wrap to the first heading if no later heading exists
- move the cursor to column 0 of the heading line
- clear active text selection and active search highlight

Suggested default key:

```text
M+]
```

Suggested status message:

```text
[ Heading 3/18: ## Search Workflow ]
```

### Previous Heading

`document.heading_previous` should:

- search from the line before the current cursor line
- jump to the previous heading if found
- wrap to the last heading if no earlier heading exists
- move the cursor to column 0 of the heading line
- clear active text selection and active search highlight

Suggested default key:

```text
M+[
```

Suggested status message:

```text
[ Heading 2/18: # Overview ]
```

### No Headings

If the current document has no detected headings:

```text
[ No headings ]
```

### Mode Rules

Directory buffers should not support heading navigation.

Canvas Mode and Table Mode may support heading navigation later, but the first implementation should disable it in non-text editing modes. This avoids ambiguous cursor synchronization and table-cell clamping behavior.

Suggested status messages:

```text
[ Heading navigation disabled in Directory Mode ]
[ Heading navigation disabled in Canvas Mode ]
[ Heading navigation disabled in Table Mode ]
```

## Outline View

The outline view is a temporary interactive view over the current document outline. It must not create a buffer and must not modify the document.

Suggested default key:

```text
M+\
```

The outline view should display:

- 1-based line number
- indentation derived from heading level
- heading marker or level
- heading title

Example:

```text
   1  # Overview
  12    ## Search Workflow
  37    ## Link Navigation
  44      ### Same-file links
  61    ## Text Transforms
```

Suggested outline controls:

| Key | Behavior |
| :--- | :--- |
| `Up` / `k` | Move selection up |
| `Down` / `j` | Move selection down |
| `PageUp` | Move one page up |
| `PageDown` / `Space` | Move one page down |
| `Home` | Move to first heading |
| `End` | Move to last heading |
| `Enter` | Jump to selected heading |
| `Esc` / `^G` / `^C` | Close without jumping |

The initial selection should be the nearest heading at or before the current cursor line. If the cursor is before the first heading, select the first heading.

## Command IDs

The first implementation should add these command IDs:

| Command ID | Description | Default key |
| :--- | :--- | :--- |
| `document.heading_next` | Jump to next document heading | `M+]` |
| `document.heading_previous` | Jump to previous document heading | `M+[` |
| `document.outline` | Open current document outline picker | `M+\` |

These command IDs should be available to `.zagorc` key bindings.

## Menus & Help

The menu should expose `Outline`, `Next Heading`, and `Previous Heading` in a navigation-oriented location. If the current menu layout has no Navigation menu, the Edit menu may host them near Search, Open Link, and Go To Line.

The dynamic help bar should not include these commands in the first implementation. The help bar is already dense, and heading navigation is a document-structure workflow rather than a core editing command.

The full help/reference view should include the shortcuts.

## Tests

The first implementation should include tests for:

- Markdown ATX headings
- Markdown Setext headings
- Org headings
- reStructuredText underline headings and inferred levels
- AsciiDoc headings
- next heading navigation with wrap
- previous heading navigation with wrap
- no-heading status
- command registry dispatch by key and by command ID
- outline view row formatting, separated from terminal input handling where possible

Interactive outline key handling can be tested through small pure helpers instead of requiring a real terminal read loop.
