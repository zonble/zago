import Foundation

/// English translation table for zago text editor.
public struct EnglishStrings {
    public static let table: [String: String] = [
        // Help Bar Labels
        "help.get_help": "Get Help",
        "help.menu": "Menu",
        "help.cancel": "Cancel",
        "help.write_out": "WriteOut",
        "help.read_file": "Read File",
        "help.prev_pg": "Prev Pg",
        "help.cut_text": "Cut Text",
        "help.cur_pos": "Cur Pos",
        "help.exit": "Exit",
        "help.canvas_mode": "Canvas",
        "help.table_mode": "Table",
        "help.text_mode": "Text",
        "help.justify": "Justify",
        "help.where_is": "Where Is",
        "help.next_pg": "Next Pg",
        "help.uncut_text": "UnCut Text",
        "help.to_spell": "To Spell",
        "help.open_link": "Open Link",
        "help.table_exit": "Exit Table",
        "help.next_cell": "Next Cell",
        "help.prev_cell": "Prev Cell",
        "help.cell_width": "Cell Width -/+",
        "help.cell_height": "Cell Height -/+",
        "help.center_text": "Center",
        "help.clear_cell": "Clear Cell",
        "help.select_text": "Select",
        "help.complete": "Complete",
        "help.confirm": "Confirm",
        "help.yes": "Yes",
        "help.no": "No",
        "help.clear": "Clear",
        "help.move": "Move",
        "help.jump": "Jump",
        "help.command": "Command",
        "help.mark_block": "Mark Block",
        "help.cut_block": "Cut Block",
        "help.copy_block": "Copy Block",
        "help.uncut_block": "UnCut Block",
        "help.line": "Line",
        "help.arrow": "Arrow",
        "chrome.end_of_file": "End of File",

        // Prompts
        "prompt.write_name": "File Name to Write: ",
        "prompt.confirm_exit_save": "Save modified buffer? (Answering \"N\" will discard changes) : ",
        "prompt.confirm_reload": "File changed on disk. Reload? (Answering \"N\" will keep local buffer): ",
        "prompt.encoding_fallback": "Encoding \"%@\" cannot represent new text. Convert and save as UTF-8? (y/n) ",
        "prompt.search": "Search",
        "prompt.insert_file": "File to insert: ",
        "prompt.edit_spelled_word": "Edit misspelled word \"%@\": ",
        "prompt.logo": "❯ ",
        "prompt.fill_text": "Fill with: ",
        "prompt.table_dimensions": "Table rows cols width: ",
        "status.directory_buffer_readonly": "Directory buffer is read-only",
        "dirbuf.header_directory": "\" Directory: %@",
        "dirbuf.header_instructions": "\" Press Enter on a file to open, or on a folder to navigate",
        "dirbuf.up_dir": ".. (up a dir)",
        "status.cannot_open_binary_file": "Cannot open binary file",
        "prompt.goto_line": "Enter line number, column number: ",
        "textview.footer": "  Up/Down: scroll   PgUp/PgDn: page   Home/End: jump   Any other key: close",
        "logoview.reference_title": "  zago - Editor LOGO Reference",
        "logoview.workspace_title": "  zago - Editor LOGO Workspace",
        "logoref.content": """

          Editor LOGO is an editor macro language. Commands edit text buffers,
          cursors, selections, tables, status bar, and multi-buffer state.

          1. Shapes, lines & tables
            BOX [text|width height [style]]      Insert a framed box (auto-centered text)
            DRAWBOX [text|width height [style]]  Draw overlay box (frames canvas mark)
            LINE [len] [style] [arrow]           Draw/connect a horizontal line
            VLINE [height] [style]               Draw/connect a vertical line
            FILL text                            Fill selection region, table cell,
                                                 or box interior
            TABLE [rows cols width]              Insert ASCII table

            Bounds: BOX/DRAWBOX clamp to width 3...200, height 2...100;
                    LINE/VLINE clamp to length 1...200.
            Borders: single, double, round, double-round, ascii, markdown
            Arrows:  solid (▲▼◀▶), stemmed (↑↓←→), hollow (△▽◁▷), small (▴▾◂▸)

          2. Basic arithmetic & infix operators
            +  -  *  /  %  ^                     Infix math operators
                                                 (add, sub, mul, div, mod, pow)
            =  <>  !=  <  >  <=  >=              Infix comparison operators 
                                                 (eq, ne, lt, gt, le, ge)
            SUM a b                              Addition (+)
            DIFFERENCE a b                       Subtraction (-)
            PRODUCT a b                          Multiplication (*)
            QUOTIENT a b                         Division (/)
            MODULO a b                           Modulo (%)
            POWER base exp                       Exponentiation (^)

          3. Core editing
            TYPE text                            Insert text or expression result
            SHOW expr                            Show status message
            MAKE "name value                     Define a global variable
            :name                                Read variable value
            MOVE direction [n]                   Move cursor (UP, DOWN, LEFT, RIGHT)
            GOTO row [col]                       Jump to 1-based row/column
            FIND "query                          Search text
            INDENT / OUTDENT                     Indent / outdent line (4 spaces)
            JOINLINE / SPLITLINE                 Join next line / split current line
            MARK / CUT / UNCUT                   Mark selection / cut / paste clipboard

          4. String operations
            WORD a b ...                         Concatenate values into a single word
            SUBSTRING s start len / SUBSTR       Extract substring (1-based start index)
            INDEXOF s "sub"                      Find first index of substring (1-based)
            LASTINDEXOF s "sub"                  Find last index of substring
            STARTSWITH? s "prefix"               Check if string starts with prefix
            ENDSWITH? s "suffix"                 Check if string ends with suffix
            CONTAINS? s "sub"                    Check if string contains substring
            UPPERCASE s / LOWERCASE s            Convert string to uppercase / lowercase
            TRIM s                               Trim whitespace from both ends
            REPLACE s "old" "new"                Replace all occurrences of target substring
            REPEATSTR s count                    Repeat string n times
            SPLIT s "delim"                      Split string into list by delimiter
            JOIN list "delim"                    Join list items into string with delimiter
            PADLEFT s len [char]                 Pad string on left to target length
            PADRIGHT s len [char]                Pad string on right to target length
            FORMAT "fmt" val ...                 Format string using printf-style specifier
            COUNT item                           Count length of string or list
            ASCII char / CHAR code               ASCII code / character by ASCII code

          5. Lists, Arrays & Plist
            LIST a b ...                         Build a list, preserving each item
            SENTENCE a b / SE                    Merge words/lists into a flat list
            FIRST data / LAST data               First or last item from word/list
            BUTFIRST data / BUTLAST data         Remove first or last item
            ITEM n data                          1-based item from word/list/array
            FPUT item list / LPUT item list      Add item to front / end of list
            FIRSTS list / BUTFIRSTS list         First items / remaining items of sublists
            COMBINE a b / REVERSE list           Combine or reverse list
            PICK list|array                      Random item from list or array
            REMOVE item list                     Remove items matching target from list
            REMDUP list                          Remove duplicates from list
            SORT list [template]                 Sort list items
            ARRAY size / MDARRAY dims            Create 1D or multi-dimensional arrays
            MDITEM dims arr / MDSETITEM dims v   Get/set multi-dimensional array element
            LISTTOARRAY list / ARRAYTOLIST arr   Convert list to array / array to list
            PPROP "plist "prop val               Set property value on property list
            GPROP "plist "prop                   Get property value from property list
            REMPROP "plist "prop                 Remove property from property list
            PLIST "plist / PLISTS                Get full property list / list all plists

            • List: Enclosed in square brackets [ ... ], with elements separated by spaces.
              • Example: [apple banana orange] or [1 2 3]
              • Dynamic List: Resizable length; ideal for prepending, appending, and list
                concatenation.
              • Commonly used creation & manipulation primitives: LIST, SENTENCE (or SE), 
                FPUT (prepend), LPUT (append), FIRST / BUTFIRST.
           • Array: Enclosed in curly braces { ... }, with elements separated by spaces.
              • Example: {1 2 3} or {"apple" "banana"}
              • Fixed-size / Matrix Space: Typically initialized with a specific size
                or dimensions; ideal for indexed random access or multi-dimensional 
                calculations.
              • Commonly used creation primitives:
                • ARRAY size (Creates a 1D array of specified size, e.g., 
                  ARRAY 3 produces {"" "" ""})
                • MDARRAY dims (Creates a multi-dimensional array of specified dimensions, 
                  e.g., MDARRAY [3 3] produces a 3 × 3 matrix)

          6. Date / Datetime
            DATE                                 Get current date string ("YYYY-MM-DD")
            TIME                                 Get current time string ("HH:MM:SS")

          7. CJK text transforms & metrics
            TRANSFORM.TOHANS s / TOHANS          Convert Trad. Chinese to Simp.
            TRANSFORM.TOHANT s / TOHANT          Convert Simp. Chinese to Trad.
            TRANSFORM.TOHIRAGANA s               Convert to Hiragana
            TRANSFORM.TOKATAKANA s               Convert to Katakana
            TRANSFORM.TOROMAJI s                 Convert to Romaji
            SPACING.CJK s                        Add space between CJK and Latin/digits
            CHARCOUNT.CJK s                      Count CJK characters (ignore Latin/digits)
            CHARCOUNT.EMOJI s                    Count Emoji symbols
            CHARCOUNT.WORDS s                    Count words
            CHARCOUNT.LINES s                    Count total lines

          8. Turtle drawing
            PD / PU                              Pen down / pen up
            FD len / BK len                      Move forward / back
            RT / LT                              Turn right / left
            SETHEADING dir                       Set heading (UP, DOWN, LEFT, RIGHT)
            HEADING                              Return current heading

          9. RegEx operations
            REGEX_MATCH s "pattern"              Full string regex match (REMATCH?)
            REGEX_REPLACE s "pat" "repl"         Global regex find and replace (RREPLACE)
            REGEX_FIND s "pattern"               Find all regex match strings as a list (RFIND)

          10. Control flow
            REPEAT n [ commands ]                Repeat block n times (repcount or #)
            FOR [ var start end step ] [ ]       Numeric loop control
            DOTIMES [ var n ] [ commands ]       Repeat n times (var 0 to n-1)
            WHILE [ test ] [ commands ]          Execute loop while condition is true
            DO.WHILE [ commands ] [ test ]       Execute once, repeat while condition true
            UNTIL [ test ] [ commands ]          Execute loop until condition is true
            DO.UNTIL [ commands ] [ test ]       Execute once, repeat until condition true
            IF test [ commands ]                 Single-branch conditional execution
            IFELSE test [ yes ] [ no ]           Two-branch conditional execution
            CASE val [ [ match [cmds] ] ]        Multi-case pattern matching

          11. Interactive input (RC/RW)
            READWORD [prompt] / RW               Read line input from user or stdin
            READCHAR [prompt] / RC               Read single keypress from user or stdin

          12. Math & Bitwise operations
            ABS / INT / ROUND / SQRT             Absolute / floor / round / square root
            MIN a b ... / MAX a b ...            Minimum / maximum value
            SIN / COS / TAN degrees              Trigonometric functions (degrees)
            RANDOM n / RERANDOM [seed]           Random integer 0...n-1 / seed generator
            ISEQ start end                       Generate list of sequential integers
            BITAND a b / BIT.AND                 Bitwise logic AND
            BITOR a b / BIT.OR                   Bitwise logic OR
            BITXOR a b / BIT.XOR                 Bitwise logic XOR
            BITNOT a / BIT.NOT                   Bitwise logic NOT
            LSHIFT a bits / BIT.SHL              Bitwise logical shift left
            RSHIFT a bits / BIT.SHR              Bitwise logical shift right

          13. Program & workspace management
            TO name :arg ... END                 Define custom user procedure
            DEFINE "name [[args] [body]]         Define procedure dynamically from list
            TEXT "name                           Get procedure text representation / body
            ARITY "name                          Get procedure argument count (arity)
            PROCEDURES / PROCS                   List all user-defined procedure names
            PRIMITIVES / PRIMS                   List all built-in primitive names
            NAMES                                List all global variable names
            CONTENTS                             List workspace contents 
                                                 (procedures, vars, plists)
            ERASE "name / ER                     Erase procedure or variable
            ERPS / ERNS / ERALL                  Erase all user procedures / variables

          14. Higher-order functions
            MAP template list                    Map list items using template
                                                 (? is current item)
            MAPSE template list                  Map list items and flatten results
            FILTER template list                 Filter list items matching template condition
            REDUCE template list                 Reduce list items using template (?1, ?2)
            CROSSMAP template lists              Cartesian product map over lists
            APPLY "proc args                     Dynamically apply procedure with arg list
            INVOKE "proc arg1 arg2               Dynamically invoke procedure with arguments

          15. Exception handling
            CATCH "tag [ commands ]              Catch exception tag 
                                                 ("ERROR catches runtime errors)
            THROW "tag                           Throw exception tag
            ERROR                                Query last caught error info object

          16. Predicates
            WORD? LIST? ARRAY? NUMBER?           Check data type of value
            EMPTY? val                           Check if string or list is empty
            EQUAL? a b / NOTEQUAL? a b           Check equality / inequality
            LESS? a b / GREATER? a b             Compare values (less / greater)
            PROCEDURE? name                      Check if procedure exists (built-in or user)
            PRIMITIVE? name                      Check if built-in primitive exists
            DEFINED? name                        Check if user-defined procedure exists
            NAME? name                           Check if variable exists

          17. Buffer & multi-document operations
            BUFFERS / BUFFERLIST                 List all open buffer names
            BUFFER "name / BUFFER index          Switch to specified buffer by name or index
            CLEARBUFFER                          Clear all text in current active buffer
            GETLINE [row]                        Get logical line text (default current row)
            SETLINE row "text"                   Set logical line text at specified row
            LINECOUNT                            Return total line count of active buffer
            BUFFERTEXT                           Return full text of active buffer
            SELECTION                            Return currently selected text
            FILENAME                             Return active buffer file path
        """,
        "logoref.all_aliases_header": "All Primitive Keywords & Aliases",
        "logoworkspace.heading": "  Editor LOGO Workspace",
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
        "status.block_mark_canvas_only": "Block mark is available in canvas mode only",
        "status.copied_text": "Copied text",
        "status.copied_block": "Copied block",
        "status.path_required": "Path required",
        "status.no_such_buffer": "No such buffer",
        "status.buffer_position": "Buffer %d of %d",
        "status.invalid_line": "Invalid line",
        "status.invalid_column": "Invalid column",
        "status.command_completions": "%@: %@",
        "status.no_completions": "No completions",
        "status.fill_text_required": "Fill text required",
        "status.justified_paragraph": "Justified paragraph",
        "status.already_oldest": "Already at oldest change",
        "status.undo_performed": "Undo performed",
        "status.unknown_command": "Unknown command",
        "status.cancelled": "Cancelled",
        "status.cancelled_exit": "Cancelled exit",
        "status.cancelled_search": "Cancelled search",
        "status.search_cleared": "Search cleared",
        "status.no_active_search": "No active search",
        "status.invalid_regex": "Invalid regex: %@",
        "status.cancelled_insert": "Cancelled insert",
        "status.spell_check_skipped": "Spell check skipped",
        "status.word_kept": "Word kept",
        "status.no_misspelled": "[ No misspelled words found ]",
        "status.file_reloaded": "[ File reloaded from disk ]",
        "status.saved_as_utf8": "[ Saved as UTF-8 ]",
        "status.save_cancelled": "[ Save cancelled ]",
        "status.kept_local": "[ Kept local modifications ]",
        "status.logo_executed": "[ LOGO script executed ]",
        "status.logo_evaluated": "[ LOGO script evaluated ]",
        "status.filled_block": "[ Filled block ]",
        "status.filled_cell": "[ Filled cell ]",
        "status.goto_disabled_in_table_mode": "[ GOTO disabled in Table Mode ]",
        "status.default_border": "[ Default Border: %@ ]",
        "status.unknown_border_style": "[ Unknown border style: %@ ]",
        "status.unknown_table_border": "[ Unknown table border: %@ ]",
        "status.disabled_in_table_mode": "[ %@ disabled in Table Mode ]",
        "status.table_mode_exited": "[ Table Mode Exited ]",
        "status.table_mode_hint": "(F7 / M+T to exit | Tab to navigate)",
        "status.canvas_mode_hint": "(F8 / M+V to exit)",
        "status.canvas_row_limit_exceeded": "[ Canvas row limit exceeded ]",
        "status.canvas_column_limit_exceeded": "[ Canvas column limit exceeded ]",
        "mode.canvas": "CANVAS",
        "mode.table": "TABLE",
        "subline.char_count": "%d chars",
        "status.table_mode_cancelled": "[ Table mode cancelled ]",
        "status.table_created": "[ Table created ]",
        "status.cell_text_centered": "[ Cell Text Centered (^J) ]",
        "status.editing_config": "[ Editing %@ ]",
        "status.config_reloaded": "[ Config reloaded ]",
        "status.justify_disabled_in_canvas_mode": "[ Justify disabled in Canvas Mode ]",
        "status.inserted_diagram_snippet": "[ Inserted %@ Snippet ]",
        "status.line_numbers_state": "[ Line Numbers %@ ]",
        "status.wrap_column_set": "[ Wrap Column set to %d ]",
        "status.wrap_column_reset": "[ Wrap Column reset to dynamic ]",
        "status.deleted_selection": "[ Deleted selection ]",
        "status.cannot_shrink_width": "[ Cannot shrink column width ]",
        "status.cannot_shrink_height": "[ Cannot shrink row height ]",
        "status.cannot_expand_width_collision": "[ Cannot expand width (adjacent box collision) ]",
        "status.replaced_occurrences": "[ Replaced %d occurrence(s) ]",
        "status.no_document_link": "[ No document link at cursor ]",
        "status.document_link_same_file": "[ Link points to current file ]",
        "status.opened_document_link": "[ Opened %@ ]",
        "status.no_headings": "[ No headings ]",
        "status.heading_position": "[ Heading %d/%d: %@ ]",
        "status.heading_nav_disabled_directory": "[ Heading navigation disabled in Directory Mode ]",
        "status.heading_nav_disabled_canvas": "[ Heading navigation disabled in Canvas Mode ]",
        "status.heading_nav_disabled_table": "[ Heading navigation disabled in Table Mode ]",
        "status.heading_nav_unsupported_format": "[ Document outline not supported for this file type ]",
        "status.outline_cancelled": "[ Outline cancelled ]",
        "status.no_text_selection": "[ No text selected ]",
        "status.transformed_selection": "[ Transformed selection: %@ ]",
        "status.text_transform_failed": "[ Text transform failed: %@ ]",
        "status.word_count_selection": "[ Selection: %@ ]",
        "status.word_count_document": "[ Document: %@ ]",
        "menu.tools.eval_logo": "Eval LOGO Code\t^Q",
        "menu.edit.copy": "Copy\tM+W",

        // Help Viewer
        "helpview.title": "  zago - Full Help & Command Reference",
        "helpview.header": "  KEYBINDINGS & COMMANDS REFERENCE",
        "helpview.sec_nav": "  NAVIGATION & CURSOR MOVEMENT:",
        "helpview.nav_1": "    ^F / Right Arrow   Move forward one character",
        "helpview.nav_2": "    ^B / Left Arrow    Move backward one character",
        "helpview.nav_3": "    ^P / Up Arrow      Move to previous line",
        "helpview.nav_4": "    ^N / Down Arrow    Move to next line",
        "helpview.nav_5": "    ^A / Home          Move to beginning of current line",
        "helpview.nav_6": "    ^E / End           Move to end of current line",
        "helpview.nav_7": "    ^V / PgDn          Move forward one page of text",
        "helpview.nav_8": "    ^Y / PgUp          Move backward one page of text",

        "helpview.sec_edit": "  EDITING & SELECTION:",
        "helpview.edit_1": "    ^D / Delete        Delete character at cursor position",
        "helpview.edit_2": "    ⇧+Arrow/Home/End   Extend text/table selection",
        "helpview.edit_3": "    ^K / F9            Cut selected text, canvas block, or current line",
        "helpview.edit_4": "    ^U / F10           Uncut (paste) last cut text at cursor position",
        "helpview.edit_5": "    ^I / Tab           Insert tab (4 spaces) at cursor position",

        "helpview.sec_canvas": "  CANVAS MODE:",
        "helpview.canvas_1": "    F8 / M+V           Toggle Canvas Mode for fixed-position editing",
        "helpview.canvas_2": "    ⇧+Arrow            Draw box lines and move the canvas cursor",
        "helpview.canvas_3": "    ^⇧+Arrow.          Draw arrow lines with an arrowhead at the endpoint",
        "helpview.canvas_4": "    ^^ / M+B           Set / unset rectangular canvas block mark",

        "helpview.sec_search": "  SEARCH & PARAGRAPH FORMATTING:",
        "helpview.search_1": "    ^W / F6, M+N/P     Search; repeat next/previous match",
        "helpview.search_2": "    M+O                Open Markdown/Org/rst/AsciiDoc document link at cursor",
        "helpview.search_3": "    M+[ / M+] / M+\\    Previous/next heading; open outline",
        "helpview.search_4": "    ^L                 Refresh screen display",
        "helpview.search_5": "    ^C / F11           Display current cursor position info",
        "helpview.search_6": "    ^T / F12           Spell checker status",
        "helpview.search_7": "    ^J                 Justify (format) current paragraph (CJK/Latin reflow)",

        "outlineview.title": "  Document Outline",
        "outlineview.footer": "  Up/Down move  Enter jump  Esc/^G close",

        "helpview.sec_file": "  FILE & BUFFER OPERATIONS:",
        "helpview.file_1": "    ^S                 Save current file; ^O / F3 WriteOut (choose path)",
        "helpview.file_2": "    ^R / F5            Read file (insert external file into buffer)",
        "helpview.file_3": "    ^N                 New Buffer (open a new empty buffer)",
        "helpview.file_4": "    M+. / M+>          Next Buffer (switch to next open buffer)",
        "helpview.file_5": "    M+, / M+<          Previous Buffer (switch to previous buffer)",
        "helpview.file_6": "    ^X / F2            Close buffer / Exit editor",
        "helpview.file_7": "    F4                 Save & Exit (save buffer and close/exit)",
        "helpview.file_8": "    ^G                 Cancel active selection or canvas mark",
        "helpview.file_10": "    ^^ / M+B (Canvas)  Set / unset rectangular canvas block mark",
        "helpview.file_9": "    F1 / M+M / ^M      Toggle top Menu Bar",

        "helpview.sec_set": "  CONFIGURABLE SETTINGS VIA 'set / unset' COMMANDS:",
        "helpview.set_1": "    wrap <col|off>           Soft wrap column limit (e.g. set wrap 80/off)",
        "helpview.set_2": "    ruler <on|off>           Toggle column ruler bar",
        "helpview.set_3": "    linenumbers <on|off>     Toggle line numbers gutter",
        "helpview.set_4": "    sublinenumbers <on|off>  Toggle soft-wrapped line numbers",
        "helpview.set_5": "    canvas-mode <on|off>     Start editor in 2D Canvas Mode",
        "helpview.set_6": "    syntax <on|off>          Toggle syntax highlighting",
        "helpview.set_7": "    tab <size>               Tab stop column width (e.g. set tab 4)",
        "helpview.set_8": "    auto-reload <on|off>     Auto-reload files modified externally",
        "helpview.set_9": "    border <style>           Default border style (single/double/round/ascii)",
        "helpview.set_10": "    arrow <style>            Default arrow style (solid/stemmed/hollow/small)",
        "helpview.set_11": "    regex <on|off>           Enable/disable regex search mode",
        "helpview.set_12": "    lang <en|zh_TW>          Set UI language",
        "helpview.set_13": "    spell <lang>             Set spell checker language (e.g. en_US)",
        "helpview.set_14": "    trim-trailing-whitespace Trim trailing spaces on save",

        "helpview.sec_logo": "  EDITOR LOGO MACRO & TURTLE GRAPHICS REFERENCE:",
        "helpview.logo_1": "    Esc / M+:          Command prompt",
        "helpview.logo_2": "    TYPE / PRINT       Insert text into buffer at cursor",
        "helpview.logo_3": "    BOX / DRAWBOX / LINE / VLINE Draw box frames and separator lines",
        "helpview.logo_4": "    MAKE / VAR / :var  Declare variables and arithmetic expressions",
        "helpview.logo_5": "    REPEAT / TO / EXEC Loop execution and custom procedure calls",
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
        "menu.run": "Run",
        "menu.shapes": "Shapes",
        "menu.borders": "Borders",
        "menu.tools": "Tools",
        "menu.diagrams": "Diagrams",
        "menu.help": "Help",

        // Menu Bar Items
        "menu.file.new": "New Buffer\t^N",
        "menu.file.open": "Read File...\t^R",
        "menu.file.directory": "Directory Buffer\tDIR",
        "menu.file.save": "Save File\t^S",
        "menu.file.write_out": "Write Out...\t^O",
        "menu.file.save_exit": "Save & Exit\tF4",
        "menu.file.exit": "Exit Buffer / Editor\t^X",
        "menu.file.edit_config": "Edit Config",
        "menu.file.reload_config": "Reload Config",

        "menu.edit.undo": "Undo\t^Z",
        "menu.edit.mark": "Toggle Mark\t^^ / M+B",
        "menu.edit.cancel_selection": "Cancel Mark / Selection\t^G / M+U",
        "menu.edit.cut": "Cut Text\t^K",
        "menu.edit.paste": "UnCut (Paste)\t^U",
        "menu.edit.delete_line": "Delete Line\t^⌫",
        "menu.edit.search": "WhereIs (Search)...\t^W",
        "menu.edit.open_link": "Open Link\tM+O",
        "menu.edit.outline": "Outline\tM+\\",
        "menu.edit.next_heading": "Next Heading\tM+]",
        "menu.edit.previous_heading": "Previous Heading\tM+[",
        "menu.edit.spell": "Spell Checker...\t^T",
        "menu.edit.goto_line": "Goto Line...\t^/",
        "menu.edit.justify": "Justify Paragraph\t^J",
        "menu.edit.text_editing_mode": "Text Editing Mode",
        "menu.edit.canvas_mode": "Canvas Mode\tF8",
        "menu.edit.table_editing_mode": "Table Editing Mode\tF7",

        "menu.buffer.next": "Next Buffer\tM+.",
        "menu.buffer.prev": "Previous Buffer\tM+,",
        "menu.buffer.output": "LOGO Output\tM+L",

        "menu.run.script": "Run Script\tF5",
        "menu.run.eval": "Evaluate Line/Selection\t^Q",
        "menu.run.output": "LOGO Output\tM+L",
        "menu.run.canvas": "LOGO Canvas\tM+C",
        "menu.run.clear": "Clear Canvas & Output",

        "menu.shapes.box": "Box",
        "menu.shapes.draw_box": "Draw Box",
        "menu.shapes.line": "Line",
        "menu.shapes.vline": "Vertical Line",
        "menu.shapes.table": "Table",
        "menu.shapes.fill": "Fill Region/Cell",
        "menu.shapes.symbols": "Insert Symbol...",

        "dialog.symbol_picker.title": " Insert Symbol ",
        "dialog.symbol_picker.footer": " Enter: Insert   Tab/1-4: Switch Tab   a-z: Quick Select   Esc: Cancel ",
        "dialog.symbol_picker.selected": " Selected: ",

        "symbol_category.gfm": "1. Callouts",
        "symbol_category.steps": "2. Steps",
        "symbol_category.badges": "3. Badges",
        "symbol_category.math_keys": "4. Math/Keys",

        "symbol.callout.note": "Note callout block",
        "symbol.callout.tip": "Tip callout block",
        "symbol.callout.important": "Important callout block",
        "symbol.callout.warning": "Warning callout block",
        "symbol.callout.caution": "Caution callout block",

        "symbol.step.circled_1": "Circled number 1",
        "symbol.step.circled_2": "Circled number 2",
        "symbol.step.circled_3": "Circled number 3",
        "symbol.step.circled_4": "Circled number 4",
        "symbol.step.circled_5": "Circled number 5",
        "symbol.step.circled_6": "Circled number 6",
        "symbol.step.circled_7": "Circled number 7",
        "symbol.step.circled_8": "Circled number 8",
        "symbol.step.circled_9": "Circled number 9",
        "symbol.step.circled_10": "Circled number 10",

        "symbol.step.filled_circled_1": "Filled circled number 1",
        "symbol.step.filled_circled_2": "Filled circled number 2",
        "symbol.step.filled_circled_3": "Filled circled number 3",
        "symbol.step.filled_circled_4": "Filled circled number 4",
        "symbol.step.filled_circled_5": "Filled circled number 5",
        "symbol.step.filled_circled_6": "Filled circled number 6",
        "symbol.step.filled_circled_7": "Filled circled number 7",
        "symbol.step.filled_circled_8": "Filled circled number 8",
        "symbol.step.filled_circled_9": "Filled circled number 9",
        "symbol.step.filled_circled_10": "Filled circled number 10",

        "symbol.step.roman_1": "Roman numeral 1",
        "symbol.step.roman_2": "Roman numeral 2",
        "symbol.step.roman_3": "Roman numeral 3",
        "symbol.step.roman_4": "Roman numeral 4",
        "symbol.step.roman_5": "Roman numeral 5",
        "symbol.step.roman_6": "Roman numeral 6",
        "symbol.step.roman_7": "Roman numeral 7",
        "symbol.step.roman_8": "Roman numeral 8",
        "symbol.step.roman_9": "Roman numeral 9",
        "symbol.step.roman_10": "Roman numeral 10",

        "symbol.step.circled_a": "Circled letter a",
        "symbol.step.circled_b": "Circled letter b",
        "symbol.step.circled_c": "Circled letter c",
        "symbol.step.circled_d": "Circled letter d",
        "symbol.step.circled_e": "Circled letter e",

        "symbol.step.badge_step1": "Step 1 badge",
        "symbol.step.badge_progress1_5": "Progress badge 1/5",
        "symbol.step.right_pointer_small": "Small right pointer",
        "symbol.step.right_pointer_small_hollow": "Small right hollow pointer",
        "symbol.step.right_pointer_med": "Medium right triangle pointer",
        "symbol.step.right_pointer_med_hollow": "Medium right hollow triangle pointer",

        "symbol.badge.check": "Check mark",
        "symbol.badge.heavy_check": "Heavy check mark",
        "symbol.badge.check_button": "White heavy check mark / Done",
        "symbol.badge.cross": "Cross mark",
        "symbol.badge.heavy_cross": "Heavy cross mark",
        "symbol.badge.ballot_cross": "Ballot cross",

        "symbol.badge.black_star": "Black star",
        "symbol.badge.white_star": "White star",
        "symbol.badge.black_diamond": "Black diamond",
        "symbol.badge.white_diamond": "White diamond",
        "symbol.badge.black_square": "Black square bullet",
        "symbol.badge.white_square": "White square bullet",
        "symbol.badge.up_triangle": "Up triangle",
        "symbol.badge.down_triangle": "Down triangle",

        "symbol.badge.bulb": "Light bulb / Tip",
        "symbol.badge.warning": "Warning sign",
        "symbol.badge.pushpin": "Pushpin / Note",
        "symbol.badge.rocket": "Rocket / Release",
        "symbol.badge.package": "Package / Distribution",
        "symbol.badge.inbox": "Inbox / Download",
        "symbol.badge.open_book": "Open book / Readme",
        "symbol.badge.books": "Books / Docs",
        "symbol.badge.question": "Red question mark / FAQ",
        "symbol.badge.speech_balloon": "Speech balloon / Comment",
        "symbol.badge.document": "Page facing up / File",
        "symbol.badge.scale": "Balance scale / License",
        "symbol.badge.handshake": "Handshake / Contribute",
        "symbol.badge.team": "Busts in silhouette / Authors",
        "symbol.badge.lock": "Lock / Private",
        "symbol.badge.unlock": "Unlock / Public",
        "symbol.badge.lightning": "High voltage / Quick action",

        "symbol.math.plus_minus": "Plus-minus sign",
        "symbol.math.multiply": "Multiplication sign",
        "symbol.math.divide": "Division sign",
        "symbol.math.not_equal": "Not equal to",
        "symbol.math.approx_equal": "Almost equal to",
        "symbol.math.less_equal": "Less-than or equal to",
        "symbol.math.greater_equal": "Greater-than or equal to",
        "symbol.math.infinity": "Infinity",
        "symbol.math.summation": "N-ary summation",
        "symbol.math.product": "N-ary product",
        "symbol.math.square_root": "Square root",
        "symbol.math.integral": "Integral",
        "symbol.math.element_of": "Element of",
        "symbol.math.not_element_of": "Not an element of",
        "symbol.math.intersection": "Intersection",
        "symbol.math.union": "Union",

        "symbol.key.command": "Command key",
        "symbol.key.option": "Option / Alt key",
        "symbol.key.shift": "Shift key",
        "symbol.key.control": "Control key",
        "symbol.key.escape": "Escape key",
        "symbol.key.return": "Return key",
        "symbol.key.backspace": "Backspace key",

        "menu.borders.single": "Single",
        "menu.borders.double": "Double",
        "menu.borders.round": "Round",
        "menu.borders.double_round": "Double Round",
        "menu.borders.ascii": "ASCII",
        "menu.borders.ascii_round": "ASCII Rounded",
        "menu.borders.markdown": "Markdown",
        "menu.borders.next_style": "Next Style\tM+S",
        "menu.borders.arrow_solid": "Arrow: Solid ▲▼◀▶",
        "menu.borders.arrow_stemmed": "Arrow: Stemmed ↑↓←→",
        "menu.borders.arrow_hollow": "Arrow: Hollow △▽◁▷",
        "menu.borders.arrow_small": "Arrow: Small ▴▾◂▸",

        "menu.tools.logo": "Command Prompt...\tEsc",
        "menu.tools.word_count": "Word Count",
        "menu.tools.transform_tohant": "Transform: To Traditional Chinese",
        "menu.tools.transform_tohans": "Transform: To Simplified Chinese",
        "menu.tools.transform_tolatin": "Transform: To Latin",
        "menu.tools.transform_hiragana": "Transform: To Hiragana",
        "menu.tools.transform_katakana": "Transform: To Katakana",
        "menu.tools.transform_romaji": "Transform: To Romaji",
        "menu.tools.transform_cjk_spacing": "Transform: CJK Spacing",
        "menu.tools.line_numbers": "Toggle Line Numbers",
        "menu.tools.sub_line_numbers": "Toggle Sub Line Numbers",
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
        "menu.help.logo_reference": "Editor LOGO Reference",
        "menu.help.logo_workspace": "Editor LOGO Workspace",

        "transform.tohant": "Traditional Chinese",
        "transform.tohans": "Simplified Chinese",
        "transform.tolatin": "Latin",
        "transform.hiragana": "Hiragana",
        "transform.katakana": "Katakana",
        "transform.romaji": "Romaji",
        "transform.cjk_spacing": "CJK Spacing",
    ]
}
