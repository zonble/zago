# Search

This document defines zago's interactive search behavior.

## Goals

Search should be fast during writing. `^W` is used to enter or edit a query, but repeated navigation should not require reopening the prompt. Once a query is accepted, zago keeps it as the active search until the user clears it or starts another search.

## Key Bindings

| Key | Behavior |
| :--- | :--- |
| `^W` | Open the search prompt and enter or edit a query |
| `Enter` in search prompt | Accept the query, find the first match, close the prompt, and keep the query active |
| `M+N` | Find next match for the active query |
| `M+P` | Find previous match for the active query |
| `^G` | Cancel prompt; when no prompt is active, clear the active search highlight before falling back to ordinary selection/canvas cancel behavior |

`M+N` and `M+P` are the normal repeated-search workflow. Users should not need to press `^W` again just to continue searching for the same text.

## Active Search State

After a successful search, the editor stores:

- query text
- search direction
- match start line and column
- match length
- search options, such as case sensitivity or regex mode

The active search state is updated by `M+N`, `M+P`, or a new `^W` query. It is cleared by `^G`, opening another file/buffer context where the match no longer applies, or an editing action that changes the current buffer.

## Match Navigation

Search starts from the current cursor position when a query is first accepted.

For repeated search:

- `M+N` searches forward from after the current match.
- `M+P` searches backward from before the current match.
- Search wraps around the buffer when needed.
- Status messages should distinguish normal matches, wrapped matches, and no matches.

Suggested status messages:

```text
[ Found "foo" at line 12 ]
[ Search wrapped, found "foo" at line 2 ]
[ No match: "foo" ]
```

When match counting is implemented, the status may become:

```text
[ 3/18 "foo" ]
[ wrapped: 1/18 "foo" ]
```

## Highlighting

The current match should be highlighted. This is the first highlighting requirement.

All-match highlighting is optional and should be treated as a later feature. If added, it should be limited to visible viewport matches or cached search results so interactive rendering stays cheap.

Highlight behavior:

- Search success highlights the current match range.
- The cursor should land at the match start.
- `M+N` and `M+P` move the highlight to the new current match.
- Non-search cursor movement may clear the current match highlight.
- Text editing in the current buffer clears the active search because match positions may no longer be valid.

## Search Options

Plain text search is the default.

Case sensitivity and regex search are useful, but they are secondary to repeated search and current-match highlighting. They should be added as prompt toggles, not as separate primary commands:

| Key in search prompt | Behavior |
| :--- | :--- |
| `M+C` | Toggle case-sensitive search |
| `M+R` | Toggle regex search |
| `M+B` | Toggle backward search for the initial prompt search |
| `Up` / `Down` or `^P` / `^N` | Navigate older/newer search history |

The prompt should show active options compactly, for example:

```text
Search [case regex back]: foo
```

## Regex Rules

Regex search should not be the first implementation step, but the behavior should be defined now.

- Invalid regex patterns report an error instead of behaving like "no match".
- Empty regex matches are not allowed for navigation because they can make repeated search stall.
- Regex mode composes with case sensitivity.
- Regex match length is the full match range, not a capture group.
- Capture-group search navigation is out of scope for the initial regex feature.

Suggested error message:

```text
[ Invalid regex: <message> ]
```

## Implementation Phases

1. Active plain-text search query.
2. `M+N` and `M+P` repeated navigation.
3. Current-match highlight.
4. Search status messages for wrapped and missing matches.
5. Search history.
6. Case-sensitive and regex prompt toggles.
7. Optional visible all-match highlighting.
