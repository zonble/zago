The following diagram represents the layout the zago web, a static web
site hosted on GitHub pages.

The web is composed by two parts. In the left, there are text to
describe what is zago, what it does and other basic infofrmation. In the
right, there is a web editor running wasm of zago to let the users to
exprience how it works - an interactive tutorial will be the placeholder
in the editor.

┌──────────────────────────────────────────────────────────────────────────────┐
│                            ┌────────────────────────────────────────────────┐│
│ zago                       │     [Import files][Exprt Workspace][Reset VFS] ││
│                            ├────────────────────────────────────────────────┤│
│ - Terminal Editor to       │                                                ││
│   work with AI generated   │                                                ││
│   text diagrams, using     │                                                ││
│   purely keyboard          │                                                ││
│                            │                                                ││
│                            │                                                ││
│ Why zago?                  │                                                ││
│                            │                                                ││
│ - AI brings text diagrams  │                                                ││
│   to you for planning,     │                                                ││
│   system design and so on  │                                                ││
│   but they are hard to be  │                                                ││
│   edited again.            │                                                ││
│ - Text diagrams in         │                                                ││
│   Markdown files are       │                                                ││
│   already a part of AI     │                                                ││
│   prompts.                 │                                                ││
│                            │                                                ││
│ How?                       │                                                ││
│                            │                                                ││
│ - Canvas mode editing      │                                                ││
│   allows you to move the   │                Main Editor Area                ││
│   cursor freely to edit    │                                                ││
│   anywhere in a text file  │            (need a loading progress)           ││
│ - Table mode lets you      │            (since wasm is about 6xmb)          ││
│   edit content in ascii/   │                                                ││
│   unicode tables/boxes     │                                                ││
│   without effecting the    │                                                ││
│   frames                   │                                                ││
│ - Quick drawing commands   │                                                ││
│   like "BOX", "LINE" and   │                                                ││
│   "VLINE" let you complete │                                                ││
│   a diagram in seconds.    │                                                ││
│ - CJK characters aware.    │                                                ││
│   They are layed perfectly │                                                ││
│   in boxes.                │                                                ││
│ - And more!                │                                                ││
│                            │                                                ││
│                            │                                                ││
│ Support                    │                                                ││
│                            │                                                ││
│ - macOS/Linux/Windows      │                                                ││
│ - UTF8 Terminals           │                                                ││
│                            │                                                ││
│                            └────────────────────────────────────────────────┘│
├──────────────────────────────────────────────────────────────────────────────┤
│                       2026 Weizhong Yang a.k.a zonble                        │
└──────────────────────────────────────────────────────────────────────────────┘