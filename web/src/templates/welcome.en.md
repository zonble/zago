# zago Interactive Tutorial

Note: Use your keyboard to interact with the document.
Arrow keys / Page Up / Page Down move the cursor.

## Canvas Mode

```
┌────────┐          ┌────────┐
│        │          │        │
│ Begin  x          │  End   │
│        │          │        │
└────────┘          └────────┘
```

- Move the cursor to "x".
- Press F8 to enter Canvas Mode.
- Press Shift + Right Arrow to draw a line.
- Continue pressing to extend the line.
- Press Ctrl + Arrow or Ctrl + Shift + Arrow to draw arrows.
- Press F1 to show the menu and select another style under "Borders".
- Press F8 again to exit Canvas Mode.

## Table Mode

```
┌────────────────┬────────────────┬────────────────┐
│ Press F7 Here  │                │                │
├────────────────┼────────────────┼────────────────┤
│                │                │                │
└────────────────┴────────────────┴────────────────┘
```

- Press F7 in any cell to enter Table Mode.
- You can edit the text content inside the cell without breaking table borders.
- Press F7 again to exit Table Mode.

## LINE Command

```
┌────────┐          ┌────────┐
│        │          │        │
│ Begin  │          │  End   │
│        ├──────────┤        │
└────────┘          └────────┘
┌────────┐          ┌────────┐
│        │          │        │
│ Begin  x          │  End   │
│        │          │        │
└────────┘          └────────┘
```

- ESC opens the command prompt.
- ESC again dismisses the prompt.
- Move cursor to "x".
- Press ESC, type "LINE", and press Enter (case-insensitive).
- A connecting line will automatically bridge to the next box!

```
┌────────┐   ┌────────┐ 
│        │   │        │ 
│ Begin  │   │  End   │ 
│        │   │        │        
└───x────┘   └────┬───┘ 
                  │
                  │
                  │
┌────────┐   ┌────┴───┐ 
│        │   │        │ 
│ Begin  │   │  End   │ 
│        │   │        │ 
└────────┘   └────────┘ 
```

- Move cursor to "x".
- Press ESC, type "VLINE", and press Enter.
- A vertical line will automatically bridge downwards!

## Additional Border and Arrow Styles

Try these commands for creating lines with specific styles:

- LINE ->>
- LINE =~>
- VLINE <|+|>

Syntax: [begin arrow][border][end arrow]

### Border Styles

- Single: -
- Double: =
- Heavy: +
- ASCII: A
- Double Dash: --
- Heavy Double Dash: ++
- Triple Dash: ---
- Heavy Triple Dash: +++
- Quadruple Dash: ----
- Heavy Quadruple Dash: ++++

### Arrow Styles

- ASCII: < or >
- Solid: << or >>
- Stemmed: <~ or ~>
- Hollow: <| or |>
- Small: <. or .>

## BOX and DRAWBOX Commands

Try these commands to create boxes:

- BOX "Hi"        ; Inserts a box with "Hi" inside.
- DRAWBOX "There" ; Overlays a box over current content without shifting lines.
- BOX 20 5 "Hi"   ; Inserts a box with specific width and height.
- BOX "Hi" =      ; Inserts a box with double border.
- BOX "Hi" =)     ; ")" indicates rounded corners.

Border styles available: - = + A -- ++ --- +++ ---- ++++

## FILL and INSET Commands

```
Fill                 Inset
┌──────────────────┐ ┌──────────────────┐
│f                 │ │i                 │
│                  │ │                  │
│                  │ │                  │
│                  │ │                  │
└──────────────────┘ └──────────────────┘
```

- Move cursor to "f".
- Press ESC, type "FILL <text>", and press Enter.
  The box will be filled with your text.
- Move cursor to "i".
- Press ESC, type "INSET <text>", and press Enter.
  The text will be centered inside the box.

## Combined Commands & Procedures

You can combine commands inside the ESC command prompt:

- BOX DATE             ; Place the current date inside a box.
- BOX DATE =)          ; Place date in a rounded double-line box.
- REPEAT 3 [BOX "hi"]  ; Draw 3 sequential boxes.

## Run Commands Inline

Besides using the ESC command prompt, you can run any line in your text
as commands by pressing ^Q (or F2 to run macro).

Try running these text transformation commands:

move end newline type tohiragana Sakura      ; Press ^Q
move end newline type tokatakana Ramen       ; Press ^Q
move end newline type toromaji ラメン        ; Press ^Q
move end newline type tohant 简体中文转繁体  ; Press ^Q
move end newline type tohans 繁體中文轉簡體  ; Press ^Q
move end newline box "Zago rocks" se newline ; Press ^Q

## And More!

zago has a rich command set and Editor LOGO syntax to turn your text files into
an interactive plain-text design canvas.

For advanced usage, run "help-cmd" or "help-key" in the ESC prompt to explore more.

Happy Editing!
