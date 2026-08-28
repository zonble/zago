# Editor LOGO Style DSL & Typography Reference

`zago` features a concise, visual **Style DSL** (Domain Specific Language) for styling ASCII and Unicode boxes, tables, and connector lines directly in Editor LOGO and editor drawing commands.

---

## 🧭 Overview

The Style DSL allows expressing borders, rounded corners, line weights, dashed patterns, and directional arrows with intuitive shorthand character combinations (e.g. `-`, `-)]`, `+)`, `==`, `->`, `<~+|>`, `<<+++>>`).

### Core Applications:
- **`BOX` & `TABLE`**: Sets border weight/dash pattern and optional rounded corners (`)`).
- **`LINE` & `VLINE`**: Sets border weight/dash pattern along with start/end arrow styles.

---

## 📦 1. Box & Table Style DSL

### Syntax

```text
[border-shorthand][)]
```

- **`border-shorthand`**: Defines the border style and line weight.
- **`)`** *(optional)*: Appending a closing parenthesis `)` toggles **rounded corners**.

### Border Shorthands & Primitive Names

| Border Style | Style DSL | LOGO Keywords | Chinese Dialect | Description |
| :--- | :---: | :--- | :--- | :--- |
| **Single** | `-` | `single`, `normal` | `單線`, `一般` | Standard single light line (`┌─┐`) |
| **Heavy** | `+` | `heavy`, `bold` | `粗線`, `粗體` | Bold heavy line (`┏━┓`) |
| **Double** | `=` | `double` | `雙線` | Double line (`╔═╗`) |
| **ASCII** | `a` / `A` | `ascii` | `ascii`, `純文字` | Plain ASCII characters (`+--+`) |
| **Double Dash** | `--` | `double-dash` | `二段虛線`, `雙虛線` | 2-dash segmented line (`┌╌┐`) |
| **Heavy Double Dash** | `++` | `heavy-double-dash` | `粗二段虛線` | Heavy 2-dash line (`┏╍┓`) |
| **Triple Dash** | `---` | `triple-dash` | `三段虛線` | 3-dash segmented line (`┌┄┐`) |
| **Heavy Triple Dash** | `+++` | `heavy-triple-dash` | `粗三段虛線` | Heavy 3-dash line (`┏┅┓`) |
| **Quadruple Dash** | `----` | `quad-dash`, `quadruple-dash` | `四段虛線` | 4-dash dotted line (`┌┈┐`) |
| **Heavy Quadruple Dash** | `++++` | `heavy-quad-dash` | `粗四段虛線` | Heavy 4-dash line (`┏┉┓`) |

---

## 🔲 Box Visual Preview Matrix

### Standard Square Corners (`[border]`)

```text
Single (-)          Heavy (+)           Double (=)          ASCII (a)
┌────────┐          ┏━━━━━━━━┓          ╔════════╗          +--------+
│ Text   │          ┃ Text   ┃          ║ Text   ║          | Text   |
└────────┘          ┗━━━━━━━━┛          ╚════════╝          +--------+

Double Dash (--)    Triple Dash (---)   Quad Dash (----)
┌╌╌╌╌╌╌╌╌┐          ┌┄┄┄┄┄┄┄┄┐          ┌┈┈┈┈┈┈┈┈┐
╎ Text   ╎          ┆ Text   ┆          ┊ Text   ┊
└╌╌╌╌╌╌╌╌┘          └┄┄┄┄┄┄┄┄┘          └┈┈┈┈┈┈┈┈┘

Heavy Double (++)   Heavy Triple (+++)  Heavy Quad (++++)
┏╍╍╍╍╍╍╍╍┓          ┏┅┅┅┅┅┅┅┅┓          ┏┉┉┉┉┉┉┉┉┓
╏ Text   ╏          ┇ Text   ┇          ┋ Text   ┋
┗╍╍╍╍╍╍╍╍┛          ┗┅┅┅┅┅┅┅┅┛          ┗┉┉┉┉┉┉┉┉┛
```

### Rounded Corners (`[border])`)

```text
Single (-))         Heavy (+))          Double (=))         ASCII (a))
╭────────╮          ╭━━━━━━━━╮          ╭════════╮          /--------\
│ Text   │          ┃ Text   ┃          ║ Text   ║          | Text   |
╰────────╯          ╰━━━━━━━━╯          ╰════════╯          \--------/

Double Dash (--))   Triple Dash (---))  Quad Dash (----))
╭╌╌╌╌╌╌╌╌╮          ╭┄┄┄┄┄┄┄┄╮          ╭┈┈┈┈┈┈┈┈╮
╎ Text   ╎          ┆ Text   ┆          ┊ Text   ┊
╰╌╌╌╌╌╌╌╌╯          ╰┄┄┄┄┄┄┄┄╯          ╰┈┈┈┈┈┈┈┈╯

Heavy Double (++))  Heavy Triple (+++)) Heavy Quad (++++))
╭╍╍╍╍╍╍╍╍╮          ╭┅┅┅┅┅┅┅┅╮          ╭┉┉┉┉┉┉┉┉╮
╏ Text   ╏          ┇ Text   ┇          ┋ Text   ┋
╰╍╍╍╍╍╍╍╍╯          ╰┅┅┅┅┅┅┅┅╯          ╰┉┉┉┉┉┉┉┉╯
```

---

## 🏹 2. Line & Connector Style DSL

### Syntax

```text
[start-arrow][border-shorthand][end-arrow]
```

- **`start-arrow`** *(optional)*: Arrowhead pointing backwards / upwards.
- **`border-shorthand`** *(optional, defaults to `-`)*: Line style and dash weight.
- **`end-arrow`** *(optional)*: Arrowhead pointing forwards / downwards.

### Arrowhead Styles

| Arrow Style | Start Symbol | End Symbol | Start DSL | End DSL | Horizontal Symbols | Vertical Symbols |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **ASCII / Default** | `<` | `>` | `<` | `>` | `←` / `→` or `<` / `>` | `^` / `v` |
| **Solid** | `◀` / `▲` | `▶` / `▼` | `<<` | `>>` | `◀` `▶` | `▲` `▼` |
| **Hollow** | `◁` / `△` | `▷` / `▽` | `<\|` | `\|>` | `◁` `▷` | `△` `▽` |
| **Small** | `◂` / `▴` | `▸` / `▾` | `<.` | `.>` | `◂` `▸` | `▴` `▾` |
| **Stemmed** | `←` / `↑` | `→` / `↓` | `<~` | `~>` | `←` `→` | `↑` `↓` |
| **Heavy** | `⬅` / `⬆` | `➡` / `⬇` | `<+|` | `|+>` | `⬅` `➡` | `⬆` `⬇` |
| **Double** | `⇐` / `⇑` | `⇒` / `⇓` | `<=|` | `|=>` | `⇐` `⇒` | `⇑` `⇓` |
| **Solid Diamond** | `◆` | `◆` | `<*>` | `<*>` | `◆` | `◆` |
| **Hollow Diamond** | `◇` | `◇` | `<>` | `<>` | `◇` | `◇` |
| **Solid Circle** | `●` | `●` | `*` | `*` | `●` | `●` |
| **Open Circle** | `○` | `○` | `o` / `O` | `o` / `O` | `○` | `○` |
| **Cross** | `✕` | `✕` | `x` / `X` | `x` / `X` | `✕` | `✕` |
| **Crow's Foot** | `⤙` / `⤘` | `⤚` / `⤛` | `<:` | `:>` | `⤙` `⤚` | `⤘` `⤛` |
| **Harpoon (Half-Arrow)** | `↼` / `↿` | `⇀` / `⇂` | `<^` | `^>` | `↼` `⇀` | `↿` `⇂` |

### Common Line DSL Combinations

| Line DSL | Visual Rendering (`LINE 6`) | Visual Rendering (`VLINE 4`) | Description |
| :--- | :--- | :--- | :--- |
| `-` | `──────` | `│` `│` `│` `│` | Plain single line |
| `->` | `─────>` | `│` `│` `│` `v` | Forward standard arrow |
| `<-` | `<─────` | `^` `│` `│` `│` | Backward standard arrow |
| `<->` | `<────>` | `^` `│` `│` `v` | Bidirectional standard arrow |
| `<<=>>` | `◀════▶` | `▲` `║` `║` `▼` | Double line with solid triangles |
| `<~+~>` | `←━━━━→` | `↑` `┃` `┃` `↓` | Heavy line with stemmed arrows |
| `<\|---\|>` | `◁┄┄┄┄▷` | `△` `┆` `┆` `▽` | Triple-dash line with hollow arrows |
| `<.++.>` | `◂╍╍╍╍▸` | `▴` `╏` `╏` `▾` | Heavy double-dash line with small arrows |
| `<=|==|=>` | `⇐════⇒` | `⇑` `║` `║` `⇓` | Double line with double arrows |
| `<+|++|+>` | `⬅━━━━➡` | `⬆` `┃` `┃` `⬇` | Heavy line with heavy arrows |
| `<>--->` | `◇────>` | `◇` `│` `│` `v` | Hollow diamond line with arrow |
| `<*>--->` | `◆────>` | `◆` `│` `│` `v` | Solid diamond line with arrow |
| `*---*` | `●────●` | `●` `│` `│` `●` | Line with solid circle endpoints |
| `o---o` | `○────○` | `○` `│` `│` `○` | Line with open circle endpoints |
| `x---x` | `✕────✕` | `✕` `│` `│` `✕` | Line with cross endpoints |
| `<:---:>` | `⤙────⤚` | `⤘` `│` `│` `⤛` | Crow's foot line |
| `<~+\|>` | `←━━━━▷` | `↑` `┃` `┃` `▽` | Asymmetric: stemmed start, hollow end |

---

## 💻 3. LOGO Command Integration

### `BOX`

Draws an ASCII/Unicode box with optional content, dimensions, text alignment, and style.

```logo
; Using Style DSL
BOX "Title 16 5 CENTER -)
BOX 20 4 =)
BOX "Alert 18 3 +)

; Using Keywords
BOX "Title 16 5 CENTER DOUBLE ROUND
BOX 20 4 HEAVY
```

### `TABLE`

Draws a grid table with specified rows, columns, cell width, and style.

```logo
; Using Style DSL
TABLE 2 3 6 =)
TABLE 3 2 8 -)

; Using Keywords
TABLE 2 3 6 DOUBLE ROUND
TABLE 3 2 8 TRIPLE-DASH
```

### `LINE` & `VLINE`

Draws horizontal or vertical connector lines with lengths and style DSL.

```logo
; Horizontal lines
LINE 10 ->
LINE 12 <<=>>
LINE 8 <~+~>

; Vertical lines
VLINE 6 ->
VLINE 5 <<=>>
VLINE 4 <|---| >
```

---

## 🌐 4. Traditional Chinese Dialect Support

All border and arrow keywords are fully supported in Traditional Chinese:

```logo
; 中文方言繪圖範例
畫框 "系統架構 20 5 居中 雙線 圓角
畫表格 2 3 8 三段虛線 圓角
橫線 12 ->
直線 6 <<=>>
```

| 中文關鍵字 | 對應 Style DSL | 說明 |
| :--- | :---: | :--- |
| `單線` / `一般` | `-` | 單線細框 |
| `粗線` / `粗體` | `+` | 粗線實心框 |
| `雙線` | `=` | 雙實線框 |
| `二段虛線` | `--` | 兩段式虛線 |
| `三段虛線` | `---` | 三段式虛線 |
| `四段虛線` | `----` | 四段式點狀虛線 |
| `圓角` | `)` | 圓弧轉角 |

---

## 🛠️ Implementation References

- **Parser Engine**: [`Sources/Drawing/StyleDSL.swift`](file:///Users/zonble/Work/zago/Sources/Drawing/StyleDSL.swift)
- **Box Rendering**: [`Sources/Drawing/BoxStyle.swift`](file:///Users/zonble/Work/zago/Sources/Drawing/BoxStyle.swift)
- **Line Rendering**: [`Sources/Drawing/LineDrawer.swift`](file:///Users/zonble/Work/zago/Sources/Drawing/LineDrawer.swift)
- **Unit & Property Tests**: [`Tests/StyleDSLTests.swift`](file:///Users/zonble/Work/zago/Tests/StyleDSLTests.swift)
