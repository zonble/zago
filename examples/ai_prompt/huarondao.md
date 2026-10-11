# Huarong Dao (Klotski) Sliding Block Puzzle

Create an interactive web game for the classic Huarong Dao (Klotski) sliding block puzzle based on the board layout illustrated below.

```
╔══════════════════════════╗
║ ┌────┐┌──────────┐┌────┐ ║
║ │ 馬 ││          ││ 黃 │ ║
║ │    ││          ││    │ ║
║ │    ││ 曹    操 ││    │ ║
║ │ 超 ││          ││ 忠 │ ║
║ └────┘└──────────┘└────┘ ║
║ ┌────┐┌──────────┐┌────┐ ║
║ │ 趙 ││ 關    羽 ││ 張 │ ║
║ │    │└──────────┘│    │ ║
║ │    │┌────┐┌────┐│    │ ║
║ │ 雲 ││ 卒 ││ 卒 ││ 飛 │ ║
║ └────┘└────┘└────┘└────┘ ║
║ ┌────┐            ┌────┐ ║
║ │ 卒 │            │ 卒 │ ║
║ └────┘            └────┘ ║
╠═══════            ═══════╣
```

## Board Layout & Rules

- **Board size**: 4 columns × 5 rows
- **Pieces**:
  - `曹操` (Cao Cao): 1 large block (2×2)
  - `關羽` (Guan Yu): 1 horizontal block (2×1)
  - `馬超`, `黃忠`, `趙雲`, `張飛`: 4 vertical blocks (1×2 each)
  - `卒` (Soldiers): 4 small blocks (1×1 each)
- **Goal**: Slide the blocks into the empty spaces without overlapping so that the `曹操` (2×2) block can escape through the exit at the bottom center.