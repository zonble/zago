# Styles

## Style set

A box/table stye set is composed by

- Border Style (enum)
- Round (bool)

A line style set is composed by

- Border Style (enum)
- Arrow (enum)

## Border Styles

| Name                 | Logo param        | Style DSL |
| -------------------- | ----------------- | --------- |
| Single               | single            | -         |
| Heavy                | heavy             | +         |
| Double               | double            | =         |
| Ascii                | ascii             | A         |
| Double Dash          | double-hash       | --        |
| Heavy Double Dash    | heavy-double-dash | ++        |
| Triple Dash          | triple-dash       | ---       |
| Heavy Triple Dash    | heavy-triple-dash | +++       |
| Quadruple Dash       | quard-dash        | ----      |
| Heavy Quadruple Dash | heavy-quad-dash   | ++++      |

## Arrow Styles

| Name      | Symbols | Style DSL |
| --------- | ------- | --------- |
| Solid     | ▲▼◀▶    | << >>     |
| Stemmed   | ↑↓←→    | <~ ~>     |
| Hollow    | △▽◁▷    | <\| \|>   |
| Small     | ▴▾◂▸    | <.  .>    |
| [Default] |         | < >       |

## LOGO Syntax

### BOX

BOX [content] [w] [h] [text] [border-style] [round]

or

BOX [content] [w] [h] [text] [style-dsl]

### Table

TABLE [content] [row] [col] [border-style] [round]

or

BOX [content] [row] [col] [style-dsl]

### LINE & VLINE

LINE [length] [border-style] [arrow|backarrow|bothaarrow] [arrow-style]

or

LINE length [style-dsl]


## Boxes with Border Styles but not rounded

### Single
┌────────┐
│        │
└────────┘
### Heavy
┏━━━━━━━━┓
┃        ┃
┗━━━━━━━━┛
### Double
╔════════╗
║        ║
╚════════╝
### Ascii
+--------+
|        |
+--------+
### Double Dash
┌╌╌╌╌╌╌╌╌┐
╎        ╎
└╌╌╌╌╌╌╌╌┘
### Heavy Double Dash
┏╍╍╍╍╍╍╍╍┓
╏        ╏
┗╍╍╍╍╍╍╍╍┛
### Triple Dash
┌┄┄┄┄┄┄┄┄┐
┆        ┆
└┄┄┄┄┄┄┄┄┘
### Heavy Triple Dash
┏┅┅┅┅┅┅┅┅┓
┇        ┇
┗┅┅┅┅┅┅┅┅┛
### Quad Dash
┌┈┈┈┈┈┈┈┈┐
┊        ┊
└┈┈┈┈┈┈┈┈┘
### Heavy Quad Dash
┏┉┉┉┉┉┉┉┉┓
┋        ┋
┗┉┉┉┉┉┉┉┉┛

## Boxes with Border Styles and rounded

### Single
╭────────╮
│        │
╰────────╯
### Heavy
╭━━━━━━━━╮
┃        ┃
╰━━━━━━━━┛
### Double
╭════════╮
║        ║
╰════════╯
### Ascii
/--------\
|        |
\--------/
### Double Dash
╭╌╌╌╌╌╌╌╌╮
╎        ╎
╰╌╌╌╌╌╌╌╌╯
### Heavy Double Dash
╭╍╍╍╍╍╍╍╍╮
╏        ╏
╰╍╍╍╍╍╍╍╍╯
### Triple Dash
╭┄┄┄┄┄┄┄┄╮
┆        ┆
╰┄┄┄┄┄┄┄┄╯
### Heavy Triple Dash
╭┅┅┅┅┅┅┅┅╮
┇        ┇
╰┅┅┅┅┅┅┅┅╯
### Quad Dash
╭┈┈┈┈┈┈┈┈╮
┊        ┊
╰┈┈┈┈┈┈┈┈╯
### Heavy Quad Dash
╭┉┉┉┉┉┉┉┉╮
┋        ┋
╰┉┉┉┉┉┉┉┉╯

## BOX Style DSL

Syntax: [border-enum][rounded]

Examples:

- "-": single
- "-)": single + round
- "+": heavy
- "+)": heavy + round
- "+++)": heavy triple dash + round
- "a": ascii border

## LINE/VLINE Style DSL

Syntax: [begin arrow][border style][end arrow]

Examples:

- "-" single
- "->" single with default arrow
- "<-" single with default back arrow
- "<->" single with default both arrow
- "<~+|>" Stemmed back arrow, heavy border and hollow arrow
