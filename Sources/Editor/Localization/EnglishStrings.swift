import Foundation

/// English translation table for zago text editor.
public struct EnglishStrings {
    public static let table: [String: String] = [
        // Help Bar Labels
        "help.get_help":   "Get Help",
        "help.cancel":     "Cancel",
        "help.write_out":  "WriteOut",
        "help.read_file":  "Read File",
        "help.prev_pg":    "Prev Pg",
        "help.cut_text":   "Cut Text",
        "help.cur_pos":    "Cur Pos",
        "help.exit":       "Exit",
        "help.justify":    "Justify",
        "help.where_is":   "Where Is",
        "help.next_pg":    "Next Pg",
        "help.uncut_text": "UnCut Text",
        "help.to_spell":   "To Spell",
        "chrome.end_of_file": "End of File",

        // Prompts
        "prompt.write_name": "File Name to Write: ",
        "prompt.confirm_exit_save": "Save modified buffer? (Answering \"N\" will discard changes) : ",
        "prompt.confirm_reload": "File changed on disk. Reload? (Answering \"N\" will keep local buffer): ",
        "prompt.search": "Search",
        "prompt.insert_file": "File to insert: ",
        "prompt.edit_spelled_word": "Edit misspelled word \"%@\": ",
        "prompt.logo": "❯ ",
        "prompt.fill_text": "Fill with: ",
        "prompt.table_dimensions": "Table rows cols width: ",
        "prompt.goto_line": "Enter line number, column number: ",
        "textview.footer": "  Up/Down: scroll   PgUp/PgDn: page   Home/End: jump   Any other key: close",
        "logoview.reference_title": "  zago - LOGO Reference",
        "logoview.workspace_title": "  zago - LOGO Workspace",
        "logoref.content": """
  LOGO Reference
  ================================================================

  Editor LOGO is an editor macro language. Commands edit the current
  text buffer, cursor, selection, tables, status bar, and buffers.

  Essential editing
    TYPE text                    Insert text or expression result
    SHOW expr                    Show a status message
    MAKE "name value             Define a variable
    :name                        Read a variable
    MOVE UP|DOWN|LEFT|RIGHT      Move the cursor
    GOTO row [col]               Jump to 1-based row/column
    FIND "query                  Search text

  Shapes and tables
    BOX text [align] [style]     Insert a framed box
    DRAWBOX width height [style] Draw an overlay frame
    LINE [len] [style] [arrow]   Draw/connect a horizontal line
    VLINE [height] [style]       Draw/connect a vertical line
    FILL text                    Fill selected region or box interior
    TABLE [rows cols width]      Insert a table
    TABLE BORDER style           Set default border style
    TABLE NEXTSTYLE              Cycle border style
    Bounds: BOX/DRAWBOX clamp to width 3...200, height 2...100;
            LINE clamps to 1...200 and VLINE clamps to 1...100.

  Border styles
    single, double, round, double-round, ascii, markdown

  Turtle-like drawing
    PD / PU                      Pen down/up
    FD n / BK n                  Move forward/back
    RT angle / LT angle          Turn right/left
    SETHEADING angle|direction   Set heading
    HEADING                      Return current heading
    Turtle stops at the top/left minimum edges; outward moves from
    those edges draw nothing. Down/right moves may extend the buffer.

  Control flow and procedures
    REPEAT n [ commands ]        Repeat block; # and repcount are 1-based
    IF test [ commands ]         Conditional execution
    IFELSE test [ yes ] [ no ]   Conditional branch
    FOREACH list [ commands ]    Iterate with ? as current item
    TO name :arg ... END         Define a user procedure
    OUTPUT value                 Return from a reporter procedure
    STOP                         Return from a procedure

  Useful predicates
    PROCEDURE? name              Built-in or user-defined procedure exists
    PRIMITIVE? name              Built-in primitive exists
    DEFINED? name                User-defined procedure exists
    NAME? name                   Variable exists
    WORD? LIST? ARRAY? NUMBER? EMPTY?

  Data operations
    WORD, LIST, SENTENCE, FIRST, LAST, BUTFIRST, BUTLAST
    ITEM, PICK, REMOVE, REMDUP, SPLIT, SORT
    ARRAY, MDARRAY, SETITEM, MDSETITEM, ARRAYTOLIST, LISTTOARRAY

  Math and logic
    SUM, DIFFERENCE, MINUS, PRODUCT, QUOTIENT, POWER
    REMAINDER, MODULO, ABS, INT, ROUND, SQRT, EXP, LN, LOG10
    SIN, COS, TAN, ARCTAN, RADSIN, RADCOS, RADTAN, RADARCTAN
    LESS? GREATER? LESSEQUAL? GREATEREQUAL? EQUAL? NOTEQUAL?
    TRUE, FALSE, AND, OR, XOR, NOT

  Buffers and files
    BUFFERS, BUFFER, NEXTBUFFER, PREVBUFFER, OPENBUFFER, CLOSEBUFFER
    SAVE, FILE, CLEARBUFFER, GETLINE, SETLINE, BUFFERTEXT
    ROW, COL, LINECOUNT, FILENAME, MODIFIED?

  All primitive aliases
""",
        "logoworkspace.heading": "  LOGO Workspace",
        "logoworkspace.procedures": "  User Procedures:",
        "logoworkspace.variables": "  Variables:",
        "logoworkspace.none": "    (none)",
        "logoworkspace.tip_1": "  Use PROCEDURE?, PRIMITIVE?, DEFINED?, and NAME? in LOGO scripts",
        "logoworkspace.tip_2": "  when you need a programmable existence check.",

        // Status Messages
        "status.mark_set": "Mark Set",
        "status.mark_unset": "Mark Unset",
        "status.cut_text": "Cut text",
        "status.cut_one_line": "Cut 1 line",
        "status.uncut_text": "Uncut text",
        "status.clipboard_empty": "Clipboard is empty",
        "status.no_selection": "No selection",
        "status.no_block_marked": "No block marked",
        "status.fill_text_required": "Fill text required",
        "status.justified_paragraph": "Justified paragraph",
        "status.already_oldest": "Already at oldest change",
        "status.undo_performed": "Undo performed",
        "status.unknown_command": "Unknown command",
        "status.cancelled": "Cancelled",
        "status.cancelled_exit": "Cancelled exit",
        "status.cancelled_search": "Cancelled search",
        "status.cancelled_insert": "Cancelled insert",
        "status.spell_check_skipped": "Spell check skipped",
        "status.word_kept": "Word kept",
        "status.no_misspelled": "[ No misspelled words found ]",
        "status.file_reloaded": "[ File reloaded from disk ]",
        "status.kept_local": "[ Kept local modifications ]",
        "status.logo_executed": "[ LOGO script executed ]",
        "status.logo_evaluated": "[ LOGO script evaluated ]",
        "menu.tools.eval_logo": "Eval LOGO Code\t^Q",

        // Help Viewer (HelpView.swift)
        "helpview.title": "  zago - Full Help & Command Reference",
        "helpview.header": "  KEYBINDINGS & COMMANDS REFERENCE",
        "helpview.sec_nav": "  NAVIGATION & CURSOR MOVEMENT:",
        "helpview.nav_1": "    ^F / Right Arrow   Move forward one character",
        "helpview.nav_2": "    ^B / Left Arrow    Move backward one character",
        "helpview.nav_3": "    ^P / Up Arrow      Move to previous line",
        "helpview.nav_4": "    ^N / Down Arrow    Move to next line",
        "helpview.nav_5": "    ^A / Home          Move to beginning of current line",
        "helpview.nav_6": "    ^E / End           Move to end of current line",
        "helpview.nav_7": "    ^V / F8 / PgDn     Move forward one page of text",
        "helpview.nav_8": "    ^Y / F7 / PgUp     Move backward one page of text",

        "helpview.sec_edit": "  EDITING & SELECTION:",
        "helpview.edit_1": "    ^D / Delete        Delete character at cursor position",
        "helpview.edit_2": "    Shift+Arrow        Extend text/table selection",
        "helpview.edit_3": "    ^K / F9            Cut selected text, canvas block, or current line",
        "helpview.edit_4": "    ^U / F10           Uncut (paste) last cut text at cursor position",
        "helpview.edit_5": "    ^I / Tab           Insert tab (4 spaces) at cursor position",

        "helpview.sec_search": "  SEARCH & PARAGRAPH FORMATTING:",
        "helpview.search_1": "    ^W / F6            Where Is (case-insensitive text search)",
        "helpview.search_2": "    ^J                 Justify (format) current paragraph (CJK/Latin reflow)",
        "helpview.search_3": "    ^L                 Refresh screen display",
        "helpview.search_4": "    ^C / F11           Display current cursor position info",
        "helpview.search_5": "    ^T / F12           Spell checker status",

        "helpview.sec_file": "  FILE & BUFFER OPERATIONS:",
        "helpview.file_1": "    ^S                 Save current file; ^O / F3 WriteOut (choose path)",
        "helpview.file_2": "    ^R / F5            Read file (insert external file into buffer)",
        "helpview.file_3": "    ^N                 New Buffer (open a new empty buffer)",
        "helpview.file_4": "    M+. / M+>          Next Buffer (switch to next open buffer)",
        "helpview.file_5": "    M+, / M+<          Previous Buffer (switch to previous buffer)",
        "helpview.file_6": "    ^X / F2            Close buffer / Exit editor",
        "helpview.file_7": "    F4                 Save & Exit (save buffer and close/exit)",
        "helpview.file_8": "    ^G                 Cancel active selection or canvas mark",
        "helpview.file_10": "    ^^ (Canvas)        Set / unset rectangular canvas block mark",
        "helpview.file_9": "    F1 / M+M / ^M      Toggle top Menu Bar",

        "helpview.sec_logo": "  LOGO MACRO & TURTLE GRAPHICS REFERENCE:",
        "helpview.logo_1": "    Esc / M+:          Command prompt",
        "helpview.logo_2": "    TYPE / PRINT       Insert text into buffer at cursor",
        "helpview.logo_3": "    MAKE / VAR / :var  Declare variables and arithmetic expressions",
        "helpview.logo_4": "    REPEAT / TO / EXEC Loop execution and custom procedure calls",
        "helpview.logo_5": "    BOX / DRAWBOX / LINE / VLINE Draw box frames and separator lines with smart fusion",
        "helpview.logo_6": "    PD / PU / FD / BK  Turtle Graphics: Pen Down, Pen Up, Forward, Back",
        "helpview.logo_7": "    RT / LT / GOTO     Turtle Graphics: Turn Right/Left 90°, Jump line/col",
        "helpview.logo_8": "    DATE / TIME / SET  Insert date/time, configure editor settings",
        "helpview.logo_9": "    IF / IFELSE        Conditional logic (IF cond [...] / IFELSE cond [...] [...])",

        "helpview.footer": "  [ Up/Dn/PgUp/PgDn: Scroll | Press any key to return ]",

        // Common Messages
        "msg.cancelled": "[ Cancelled ]",
        "buffer.new_buffer": "New Buffer",
        "buffer.modified": "Modified",

        // Format Messages
        "msg.read_lines": "[ Read %d line(s) ]",
        "msg.wrote_to_file": "[ Wrote to %@ ]",
        "msg.config_loaded_with_errors": "[ Config loaded with %d syntax error(s) ]",
        "msg.cursor_info": "line %d/%d (%d%%), col %d/%d, visual col %d/%d",
        "msg.found_query_at_line": "Found \"%1$@\" at line %2$d",
        "msg.search_wrapped_found": "Search wrapped, found \"%1$@\" at line %2$d",
        "msg.not_found": "\"%@\" not found",
        "msg.inserted_lines": "[ Inserted %d lines ]",
        "msg.error_inserting_file": "Error inserting file: %@",
        "msg.error_saving_file": "Error saving file: %@",
        "msg.replaced_word": "Replaced '%@' with '%@'",

        // Menu Bar Titles
        "menu.file": "File",
        "menu.edit": "Edit",
        "menu.buffer": "Buffer",
        "menu.shapes": "Shapes",
        "menu.borders": "Borders",
        "menu.tools": "Tools",
        "menu.diagrams": "Diagrams",
        "menu.help": "Help",

        // Menu Bar Items
        "menu.file.new": "New Buffer\t^N",
        "menu.file.open": "Read File...\t^R",
        "menu.file.save": "Save File\t^S",
        "menu.file.write_out": "Write Out...\t^O",
        "menu.file.save_exit": "Save & Exit\tF4",
        "menu.file.exit": "Exit Buffer / Editor\t^X",
        "menu.file.edit_config": "Edit Config",
        "menu.file.reload_config": "Reload Config",

        "menu.edit.undo": "Undo\t^Z",
        "menu.edit.mark": "Toggle Canvas Mark\t^^",
        "menu.edit.cut": "Cut Text\t^K",
        "menu.edit.paste": "UnCut (Paste)\t^U",
        "menu.edit.delete_line": "Delete Line\t^BS",
        "menu.edit.search": "WhereIs (Search)...\t^W",
        "menu.edit.spell": "Spell Checker...\t^T",
        "menu.edit.goto_line": "Goto Line...\t^/",
        "menu.edit.justify": "Justify Paragraph\t^J",
        "menu.edit.text_editing_mode": "Text Editing Mode",
        "menu.edit.canvas_mode": "Canvas Mode\tM+V",
        "menu.edit.table_editing_mode": "Table Editing Mode\tM+T",

        "menu.buffer.next": "Next Buffer\tM+.",
        "menu.buffer.prev": "Previous Buffer\tM+,",

        "menu.shapes.box": "Box",
        "menu.shapes.draw_box": "Draw Box",
        "menu.shapes.line": "Line",
        "menu.shapes.vline": "Vertical Line",
        "menu.shapes.table": "Table",
        "menu.shapes.frame_mode": "Frame Mode",
        "menu.shapes.fill": "Fill Region",

        "menu.borders.single": "Single",
        "menu.borders.double": "Double",
        "menu.borders.round": "Round",
        "menu.borders.double_round": "Double Round",
        "menu.borders.ascii": "ASCII",
        "menu.borders.markdown": "Markdown",
        "menu.borders.next_style": "Next Style\tM+S",

        "menu.tools.logo": "Command Prompt...\tEsc",
        "menu.tools.line_numbers": "Toggle Line Numbers",
        "menu.tools.ruler": "Toggle Ruler Bar",
        "menu.tools.wrap_80": "Wrap Column: 80",
        "menu.tools.wrap_60": "Wrap Column: 60",
        "menu.tools.wrap_40": "Wrap Column: 40",
        "menu.tools.wrap_reset": "Wrap Column: Dynamic",

        "menu.diagrams.mermaid_sequence": "Mermaid Sequence Diagram",
        "menu.diagrams.mermaid_flowchart": "Mermaid Flowchart",
        "menu.diagrams.mermaid_class": "Mermaid Class Diagram",
        "menu.diagrams.mermaid_state": "Mermaid State Diagram",
        "menu.diagrams.mermaid_er": "Mermaid ER Diagram",
        "menu.diagrams.mermaid_mindmap": "Mermaid Mindmap",

        "menu.diagrams.puml_sequence": "PlantUML Sequence Diagram",
        "menu.diagrams.puml_flowchart": "PlantUML Flowchart",
        "menu.diagrams.puml_class": "PlantUML Class Diagram",
        "menu.diagrams.puml_state": "PlantUML State Diagram",
        "menu.diagrams.puml_er": "PlantUML ER Diagram",

        "menu.diagrams.dot_digraph": "Graphviz Directed Graph (digraph)",
        "menu.diagrams.dot_graph": "Graphviz Undirected Graph (graph)",

        "menu.help.show": "Show Help Reference",
        "menu.help.logo_reference": "LOGO Reference",
        "menu.help.logo_workspace": "Procedures & Variables"
    ]
}
