import Foundation

/// English translation table for zago text editor.
struct EnglishStrings {
    static let table: [String: String] = [
        // Help Bar Labels
        "help.get_help": "Get Help",
        "help.menu": "Menu",
        "help.cancel": "Cancel",
        "help.write_out": "WriteOut",
        "help.save": "Save",
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
        "help.redo": "Redo",
        "help.replace": "Replace",
        "help.select_all": "Select All",
        "help.open_link": "Open Link",
        "help.table_exit": "Exit Table",
        "help.next_cell": "Next Cell",
        "help.prev_cell": "Prev Cell",
        "help.cell_width": "Cell Width -/+",
        "help.cell_height": "Cell Height -/+",
        "help.center_text": "Center",
        "help.clear_cell": "Clear Cell",
        "help.select_text": "Select Text",
        "help.complete": "Complete",
        "help.confirm": "Confirm",
        "help.go_back": "Go Back",
        "help.yes": "Yes",
        "help.no": "No",
        "help.clear": "Clear",
        "help.move": "Move",
        "help.jump": "Jump",
        "help.command": "Command",
        "help.commands": "Cmds",
        "help.undo": "Undo",
        "help.copy_text": "Copy Text",
        "help.clear_mark": "Clear Mark",
        "help.border_style": "Border Style",
        "help.mark_block": "Mark Block",
        "help.cut_block": "Cut Block",
        "help.copy_block": "Copy Block",
        "help.uncut_block": "UnCut Block",
        "help.line": "Line",
        "help.arrow": "Arrow",
        "help.ai_accept": "Accept AI",
        "help.ai_reject": "Reject AI",
        "help.ai_next_proposal": "Next Prop",
        "help.ai_previous_proposal": "Prev Prop",
        "help.run_logo": "Run Logo",
        "help.all": "All",
        "help.goto_line": "Goto Line",
        "chrome.end_of_file": "End of File",

        // Prompts
        "prompt.write_name": "File Name to Write: ",
        "prompt.confirm_exit_save": "Save modified buffer? (Answering \"N\" will discard changes) : ",
        "prompt.confirm_reload": "File changed on disk. Reload? (Answering \"N\" will keep local buffer): ",
        "prompt.encoding_fallback": "Encoding \"%@\" cannot represent new text. Convert and save as UTF-8? (y/n) ",
        "prompt.backup_failed_continue": "Could not create backup file (%@). Continue saving anyway? (y/n) ",
        "prompt.save_failed_retry_path": "Save failed (%@). Save to another path: ",
        "prompt.search": "Search",
        "prompt.replace_search": "Search (to replace)",
        "prompt.replace_with": "Replace with: ",
        "prompt.confirm_replace": "Replace this instance? [Y]es / [N]o / [A]ll / [^C]ancel: ",
        "prompt.insert_file": "File to insert: ",
        "prompt.edit_spelled_word": "Edit misspelled word \"%@\": ",
        "prompt.logo": "❯ ",
        "prompt.fill_text": "Fill with: ",
        "prompt.table_dimensions": "Table rows cols width: ",
        "prompt.logo_input": "Input: ",
        "prompt.logo_read_key": "Input [Key]: ",
        "prompt.describe_key": "Press any key: ",
        "status.read_only": "The buffer is read-only",
        "status.directory_buffer_readonly": "The buffer is read-only",
        "status.describe_char": "'%@': Insert character '%@'",
        "status.describe_unbound": "%@: Unbound key",
        "mode.canvas_mode": "Canvas Mode",
        "mode.table_mode": "Table Mode",
        "dirbuf.header_directory": "\" Directory: %@",
        "dirbuf.header_instructions": "\" Press Enter on a file to open, or on a folder to navigate",
        "dirbuf.up_dir": ".. (up a dir)",
        "status.cannot_open_binary_file": "Cannot open binary file",
        "prompt.goto_line": "Enter line number, column number: ",
        "textview.footer": "  Up/Down/PgUp/PgDn/Home/End: Scroll | Any other key: Close",
        "logoview.reference_title": "  zago - Editor LOGO Reference",
        "logoview.workspace_title": "  zago - Editor LOGO Workspace",
        "styledsl.reference_title": "  zago - Style DSL Reference",
        "styledsl.content": """

          Style DSL Reference (Plain-Text Diagram Shorthand)
          ================================================================

          Style DSL provides concise, ASCII-art-like shorthand syntax for boxes,
          tables, lines, and directional arrows in drawing commands.

          1. Border Style Tokens
          ----------------------------------------------------------------
            -       Single line (─ │ ┌ ┐ └ ┘)
            +       Heavy bold line (━ ┃ ┏ ┓ ┗ ┛)
            =       Double line (═ ║ ╔ ╗ ╚ ╝)
            a       ASCII text (+ - |)
            --      Double dash (╌ ╎ ┌ ┐ └ ┘)
            ++      Heavy double dash (╍ ╏ ┏ ┓ ┗ ┛)
            ---     Triple dash (┄ ┆ ┌ ┐ └ ┘)
            +++     Heavy triple dash (┅ ┇ ┏ ┓ ┗ ┛)
            ----    Quadruple dash (┈ ┊ ┌ ┐ └ ┘)
            ++++    Heavy quadruple dash (┉ ┋ ┏ ┓ ┗ ┛)

          2. Rounded Corner Modifier
          ----------------------------------------------------------------
            Append ")" to any border token or name to make corners rounded:
            -)      Single rounded box (╭ ╮ ╰ ╯)
            +)      Heavy rounded box (╭ ╮ ╰ ┛)
            =)      Double rounded box (╭ ╮ ╰ ╯)
            a)      ASCII rounded box (/ \\ \\ /)
            ---)    Triple-dash rounded box
            ++++)   Heavy quadruple-dash rounded box

          3. Arrow Shapes (for LINE and VLINE)
          ----------------------------------------------------------------
            <   >   Standard / ASCII arrow (← / → / ↑ / ↓)
            <<  >>  Solid filled arrow (◀ / ▶ / ▲ / ▼)
            <|  |>  Hollow triangular arrow (◁ / ▷ / △ / ▽)
            <~  ~>  Stemmed arrow (◄ / ► / ↑ / ↓)
            <.  .>  Small triangular arrow (◂ / ▸ / ▴ / ▾)

          4. Command Usage Examples
          ----------------------------------------------------------------
            • BOX & DRAWBOX:
                BOX 10 5 -)            Draw 10x5 single rounded box
                BOX 14 4 =             Draw 14x4 double border box
                BOX 12 4 +)            Draw 12x4 heavy rounded box
                BOX 16 5 ---)          Draw 16x5 triple-dash rounded box
                BOX "Hello" -)         Draw centered text in a single rounded box
                BOX "Alert!" +         Draw centered text in a heavy box
                DRAWBOX 10 5 -)        Draw overlay rounded box at cursor/mark

            • TABLE:
                TABLE 3 3 8 -)         Create 3x3 table with 8-col cells and rounded corners
                TABLE 2 4 10 =         Create 2x4 double-bordered table
                TABLE 3 3 6 +)         Create 3x3 heavy-line rounded table

            • LINE & VLINE:
                LINE 15 "->"           15-char horizontal single line with right standard arrow
                LINE 12 "<=>"          12-char double line with bidirectional standard arrows
                LINE 20 "<<=>>"        20-char double line with bidirectional solid arrows
                LINE 10 "<~+"          10-char heavy line with left stemmed arrow
                LINE 16 "-->>"         16-char double-dash line with right solid arrow
                LINE 18 "<|+++|>"      18-char heavy triple-dash with bidirectional hollow arrows
                VLINE 6 "++|>"         6-line vertical heavy double-dash with downward hollow arrow
                VLINE 8 "<.---.>"      8-line vertical triple-dash with bidirectional small arrows
        """,
        "logoref.content": """

          Editor LOGO is a plain-text diagram language. Start with shapes, lines,
          tables, and text layout; use DESCRIBE for full primitive parameters,
          aliases, examples, and platform notes.

          1. Shapes, lines & tables
            BOX [text|width height [style]]      Insert a framed box (centered text)
            DRAWBOX [text|width height [style]]  Draw overlay box
            INSET [text|width height text]       Insert centered text inside box/region
            LINE [len] [style] [arrow]           Draw/connect a horizontal line
            VLINE [height] [style]               Draw/connect a vertical line
            FILL text                            Fill selection region, table cell,
                                                 or box interior
            TABLE [rows cols width]              Insert ASCII table

            • Bounds:  BOX/DRAWBOX clamp to width 3...200, height 2...100;
                       LINE/VLINE clamp to length 1...200.
            • Borders: single, heavy, double, round, double-round, ascii, ascii-round
                       triple-dash, heavy-triple-dash, quadruple-dash,
                       heavy-quadruple-dash, double-dash, heavy-double-dash
            • Arrows:  solid (▲▼◀▶), stemmed (↑↓←→), hollow (△▽◁▷), small (▴▾◂▸)

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
            NL / NEWLINE                         Insert a new line at current position
            JOINLINE / SPLITLINE                 Join next line / split current line
            MARK                                 Mark selection 
            CUT / UNCUT                          Cut / paste clipboard

          4. String operations
            WORD a b ...                         Concatenate values into a single word
            SUBSTRING s start len / SUBSTR       Extract substring (1-based)
            INDEXOF s "sub"                      First index of substring (1-based)
            LASTINDEXOF s "sub"                  Last index of substring
            STARTSWITH? s "prefix"               Check if string starts with prefix
            ENDSWITH? s "suffix"                 Check if string ends with suffix
            CONTAINS? s "sub"                    Check if string contains substring
            UPPERCASE s / LOWERCASE s            Convert to uppercase / lowercase
            TRIM s                               Trim whitespace from both ends
            REPLACE s "old" "new"                Replace all occurrences
            REPEATSTR s count                    Repeat string n times
            SPLIT s "delim"                      Split string into list by delimiter
            JOIN list "delim"                    Join list items with delimiter
            PADLEFT s len [char]                 Pad string on left to target length
            PADRIGHT s len [char]                Pad string on right to target length
            FORMAT "fmt" val ...                 Format string using C-style specifier
            COUNT item                           Count length of string or list
            ASCII char / CHAR code               ASCII code / character by ASCII code

          5. Lists, Arrays & Plist
            LIST a b ...                         Build a list, preserving each item
            SENTENCE a b / SE                    Merge words/lists into a flat list
            FIRST data / LAST data               First or last item from word/list
            BUTFIRST data / BUTLAST data         Remove first or last item
            ITEM n data                          1-based item from word/list/array
            FPUT item list / LPUT item list      Add item to front / end of list
            FIRSTS list / BUTFIRSTS list         First / remaining items
            COMBINE a b / REVERSE list           Combine or reverse list
            PICK list|array                      Random item from list or array
            REMOVE item list                     Remove items matching target
            REMDUP list                          Remove duplicates from list
            SORT list [template]                 Sort list items
            SORT.LOCALIZED list [template]       Natural localized sort
            ARRAY size / MDARRAY dims            Create 1D or multi-dimensional arrays
            MDITEM dims arr / MDSETITEM dims v   Get/set multi-dimensional element
            LISTTOARRAY list / ARRAYTOLIST arr   Convert list to array / array to list
            PPROP "plist "prop val               Set property value on property list
            GPROP "plist "prop                   Get property value from property list
            REMPROP "plist "prop                 Remove property from property list
            PLIST "plist / PLISTS                Get full property list / all plists

            • List: Enclosed in square brackets [ ... ], with elements separated 
              by spaces.
              • Example: [apple banana orange] or [1 2 3]
              • Dynamic List: Resizable length; ideal for prepending, appending, 
                and list concatenation.
              • Commonly used creation & manipulation primitives: LIST, SENTENCE 
                (or SE), FPUT (prepend), LPUT (append), FIRST / BUTFIRST.
           • Array: Enclosed in curly braces { ... }, with elements separated 
             by spaces.
              • Example: {1 2 3} or {"apple" "banana"}
              • Fixed-size / Matrix Space: Typically initialized with a specific size
                or dimensions; ideal for indexed random access or multi-dimensional 
                calculations.
              • Commonly used creation primitives:
                • ARRAY size (Creates a 1D array of specified size, e.g., 
                  ARRAY 3 produces {"" "" ""})
                • MDARRAY dims (Creates a multi-dimensional array of specified 
                  dimensions,  e.g., MDARRAY [3 3] produces a 3 × 3 matrix)

          6. Date, Time & Formatters
            DATE [format] [locale] [tz] [cal]    Get current date (styles, timezones, 
                                                 calendars)
            TIME [format] [locale] [tz] [cal]    Get current time (default: "HH:mm:ss")
            DATETIME [fmt] [loc] [tz] [cal]      Get combined date & time string
            DATE.ADD date amount [unit]          Add/subtract time units (days, hours, etc.)
            DATE.DIFF date1 date2 [unit]         Difference between dates in specified units
            CONVERT.CALENDAR d target [src] [fmt] Convert date between calendar systems (ROC, etc.)
            FORMAT.DATE date [fmt] [loc] [tz]    Format custom date/timestamp/list
            FORMAT.NUMBER num [style] [loc]      Format number (words, caps, roman, 
                                                 money, pct)
            FORMAT.LIST list [type] [locale]     Format human list ("and" -> A, B, and C)
            FORMAT.RELATIVETIME val [unit] [loc] Relative time ("yesterday", "3 days ago")
            FORMAT.BYTES bytes [style] [locale]  Format byte sizes ("1 MB", "1.07 GB")
            DETECT.URL text                      Detect URLs; returns a list
            DETECT.EMAIL text                    Detect email addresses; returns a list
            DETECT.PHONE text                    Detect phone numbers; returns a list
            DETECT.DATE text                     Detect dates; returns a list
            DETECT.ADDRESS text                  Detect postal addresses; returns a list
            UUID [flavor]                        Generate UUID (v4, v7, nil, short, nano)
            UUID? string                         Test if string is a valid UUID
            UUID.TIME uuid_v7                    Extract ISO8601 timestamp from UUID v7
            BASE64.ENCODE s / BASE64.DECODE s    Encode / decode Base64 string (or BASE64?)
            URL.ENCODE s / URL.DECODE s          Percent-encode / decode URL string
            HEX.ENCODE v / HEX.DECODE hex        Encode integer (0xX) or text to hex, or decode
            HASH.SHA256 s / HASH.MD5 s / SHA1    Compute cryptographic hash digest

          7. Measurements & Unit Conversions
            CONVERT.MEASURE val from to / m to   Convert measurements 
                                                 (e.g. 1000 "m "km, 100 "c "f)
            FORMAT.MEASURE val unit [style] [locale] [natural]
                                                 Format measurement
                                                 (e.g. FORMAT.MEASURE 1500 "m "long)
            MEASURE.ADD v1 u1 v2 u2 [targetUnit] Add measurements 
                                                 (e.g. 5 "km 300 "m "m -> 5300)
            MEASURE.SUB v1 u1 v2 u2 [targetUnit] Subtract measurements
                                                 (e.g. 1 "hr 15 "min "min -> 45)
            MEASURE.SCALE val unit factor        Scale measurement (e.g. 2.5 "km 3 -> 7.5)
            MEASURE.EQUAL? v1 u1 v2 u2 [tol]     Test measurement equality under conversion
            MEASURE.LESS? v1 u1 v2 u2            Test if measurement 1 < measurement 2
            MEASURE.GREATER? v1 u1 v2 u2         Test if measurement 1 > measurement 2
            MEASURE.MIN v1 u1 v2 u2 [targetUnit] Minimum of two measurements
            MEASURE.MAX v1 u1 v2 u2 [targetUnit] Maximum of two measurements

          8. CJK text transforms & metrics
            TRANSFORM.TOHANS s / TOHANS          Convert Trad. Chinese to Simp.
            TRANSFORM.TOHANT s / TOHANT          Convert Simp. Chinese to Trad.
            TRANSFORM.TOHIRAGANA s               Convert to Hiragana
            TRANSFORM.TOKATAKANA s               Convert to Katakana
            TRANSFORM.TOROMAJI s                 Convert to Romaji
            SPACING.CJK s                        Add space between CJK and Latin/digits
            CHARCOUNT.CJK s                      Count CJK characters
            CHARCOUNT.EMOJI s                    Count Emoji symbols
            CHARCOUNT.WORDS s                    Count words
            CHARCOUNT.LINES s                    Count total lines

          9. Turtle drawing
            PD / PU                              Pen down / pen up
            FD len / BK len                      Move forward / back
            RT / LT                              Turn right / left
            SETHEADING dir                       Set heading (UP, DOWN, LEFT, RIGHT)
            HEADING                              Return current heading

          10. RegEx operations
            REGEX.MATCH s "pattern"              Full string regex match
            REGEX.REPLACE s "pat" "repl"         Global regex find and replace
            REGEX.FIND s "pattern"               Find all regex matches as a list

          11. Control flow
            REPEAT n [ commands ]                Repeat block n times (repcount or #)
            FOR [ var start end step ] [ ]       Numeric loop control
            DOTIMES [ var n ] [ commands ]       Repeat n times (var 0 to n-1)
            WHILE [ test ] [ commands ]          Execute loop while true
            DO.WHILE [ commands ] [ test ]       Execute once, repeat while true
            UNTIL [ test ] [ commands ]          Execute loop until condition is true
            DO.UNTIL [ commands ] [ test ]       Execute once, repeat true
            IF test [ commands ]                 Single-branch conditional execution
            IFELSE test [ yes ] [ no ]           Two-branch conditional execution
            CASE val [ [ match [cmds] ] ]        Multi-case pattern matching
            OUTPUT expr / OP / RETURN            Return value (reporter)

          12. Interactive input (RC/RW)
            READWORD [prompt] / RW               Read line input from user or stdin
            READCHAR [prompt] / RC               Read single keypress from user or stdin

          13. Math & Bitwise operations
            ABS / INT / ROUND / SQRT             Absolute / floor / round / square root
            MIN a b ... / MAX a b ...            Minimum / maximum value
            SIN / COS / TAN degrees              Trigonometric functions (degrees)
            RANDOM n / RERANDOM [seed]           Random int 0...n-1 / seed generator
            ISEQ start end                       Generate list of sequential integers
            BIT.AND a b                          Bitwise logic AND
            BIT.OR a b                           Bitwise logic OR
            BIT.XOR a b                          Bitwise logic XOR
            BIT.NOT a                            Bitwise logic NOT
            BIT.SHL a bits / LSHIFT              Bitwise logical shift left
            BIT.SHR a bits / RSHIFT              Bitwise logical shift right

          14. Program & workspace management
            TO name :arg ... END                 Define custom procedure 
                                                 (single-expression procedures support
                                                 implicit return!)
            DEFINE "name [[args] [body]]         Define procedure from list
            TEXT "name                           Get procedure text representation
            ARITY "name                          Get procedure argument count (arity)
            PROCEDURES / PROCS                   List all user-defined procedure names
            PRIMITIVES / PRIMS                   List all built-in primitive names
            NAMES                                List all global variable names
            CONTENTS                             List workspace contents 
                                                 (procedures, vars, plists)
            ERASE "name / ER                     Erase procedure or variable
            ERPS / ERNS / ERALL                  Erase all user procedures / variables

          15. Higher-order functions
            MAP template list                    Map list items using template
                                                 (? is current item)
            MAPSE template list                  Map list items and flatten results
            FILTER template list                 Filter items matching template condition
            REDUCE template list                 Reduce items using template (?1, ?2)
            CROSSMAP template lists              Cartesian product map over lists
            APPLY "proc args                     Dynamically apply procedure with arg list
            INVOKE "proc arg1 arg2               Dynamically invoke procedure with arguments

          16. Exception handling & Assertions
            CATCH "tag [ commands ]              Catch exception tag 
                                                 ("ERROR catches runtime errors)
            THROW "tag                           Throw exception tag
            ASSERT cond [msg]                    Assert condition (halts execution 
                                                 on false)
            ERROR                                Query last caught error info object

          17. Predicates
            WORD? LIST? ARRAY? NUMBER?           Check data type of value
            EMPTY? val                           Check if string or list is empty
            EQUAL? a b / NOTEQUAL? a b           Check equality / inequality
            LESS? a b / GREATER? a b             Compare values (less / greater)
            PROCEDURE? name                      Check if procedure exists
            PRIMITIVE? name                      Check if built-in primitive exists
            DEFINED? name                        Check if user-defined procedure exists
            NAME? name                           Check if variable exists

          18. Buffer & multi-document operations
            BUFFERS / BUFFERLIST                 List all open buffer names
            BUFFER "name / BUFFER index          Switch to buffer by name or index
            CLEARBUFFER                          Clear all text in current buffer
            GETLINE [row]                        Get logical line text
            SETLINE row "text"                   Set logical line text at row
            LINECOUNT                            Return line count of active buffer
            BUFFERTEXT                           Return text of active buffer
            SELECTION                            Return currently selected text
            FILENAME                             Return active buffer file path
        """,
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
        "status.buffer_readonly_bracketed": "[ Buffer is read-only ]",
        "status.justified_paragraph": "Justified paragraph",
        "status.formatted_table": "[ Formatted Table ]",
        "status.already_oldest": "Already at oldest change",
        "status.already_newest": "Already at newest change",
        "status.undo_performed": "Undo performed",
        "status.redo_performed": "Redo performed",
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
        "status.large_file_mode": "[ Large file mode active (%@): Syntax highlighting and git diff disabled ]",
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
        "status.markdown_table_text_mode": "[ Markdown/Org tables are edited in Text Mode (Tab / ^J) ]",
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
        "status.jumped_to_anchor": "[ Jumped to anchor #%@ ]",
        "status.anchor_not_found": "[ Anchor not found: #%@ ]",
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
        "status.logo_debug_paused": "[LOGO Debug] Paused. Use :logo continue",
        "status.logo_execution_error": "Error in LOGO execution. Press M+L or type :output to view.",
        "status.logo_output_cleared": "Cleared *LOGO Output* buffer.",
        "status.logo_canvas_cleared": "Cleared *LOGO Canvas* buffer.",
        "status.logo_output_canvas_cleared": "Cleared LOGO Output & Canvas buffers.",
        "status.logo_debug_completed": "[LOGO Debug] Execution completed",
        "status.logo_debug_aborted": "[LOGO Debug] Execution aborted",
        "status.logo_debug_not_paused": "[LOGO Debug] Execution is not paused",
        "status.logo_debug_breakpoint_set": "[LOGO Debug] Breakpoint set at line %d",
        "status.logo_debug_breakpoint_cleared": "[LOGO Debug] Breakpoint cleared at line %d",
        "status.logo_debug_usage":
            "[LOGO Debug] Usage: :logo break | breaks | eval [expression] | debug | continue | step | abort",
        "status.logo_debug_result": "[LOGO Debug] %@",
        "debug.logo_title": "LOGO Debugger",
        "debug.paused_at": "Paused at %@",
        "debug.source": "Source: %@:%d",
        "debug.token": "Token: %@",
        "debug.call_stack": "Call stack:",
        "debug.locals": "Locals:",
        "debug.evaluation": "Evaluation: %@",
        "debug.state": "State: %@",
        "debug.breakpoints": "Breakpoints — %@",
        "debug.none": "  (none)",
        "debug.line": "  ● line %d",
        "debug.commands": "Commands: :logo continue | :logo step | :logo abort | :logo eval",
        "buffer.untitled": "Untitled",
        // Key & Shortcut Labels
        "key.arrow_right": "Right Arrow",
        "key.arrow_left": "Left Arrow",
        "key.arrow_up": "Up Arrow",
        "key.arrow_down": "Down Arrow",
        "key.shift_arrow": "⇧+Arrow",
        "key.ctrl_shift_arrow": "^⇧+Arrow / ^+Arrow",
        "key.page_up": "PgUp",
        "key.page_down": "PgDn",
        "key.home": "Home",
        "key.end": "End",
        "key.delete": "Delete",
        "key.tab": "Tab",
        "key.enter": "Enter",
        "key.esc": "Esc",

        // Command Descriptions
        "command.select.extend.description": "Extend text/table selection",
        "command.move.right.description": "Move forward one character",
        "command.move.left.description": "Move backward one character",
        "command.move.up.description": "Move to previous line",
        "command.move.down.description": "Move to next line",
        "command.move.home.description": "Move to beginning of current line",
        "command.move.end.description": "Move to end of current line",
        "command.move.pgdn.description": "Move forward one page of text",
        "command.move.pgup.description": "Move backward one page of text",
        "command.move.word_forward.description": "Move forward one word",
        "command.move.word_backward.description": "Move backward one word",

        "command.edit.delete.description": "Delete character at cursor position",
        "command.edit.delete_line.description": "Delete current line",
        "command.edit.cut.description": "Cut selected text, canvas block, or current line",
        "command.edit.copy.description": "Copy selected text or canvas block",
        "command.edit.uncut.description": "Uncut (paste) last cut text at cursor position",
        "command.edit.tab.description": "Insert tab (4 spaces) at cursor position",
        "command.edit.backtab.description": "Outdent line or selection",
        "command.edit.join_line.description": "Join next line with current line",
        "command.edit.split_line.description": "Split current line at cursor position",
        "command.edit.toggle_comment.description": "Comment or uncomment current line or selection",
        "command.edit.justify.description": "Justify (format) current paragraph (CJK/Latin reflow)",
        "command.edit.spell.description": "Spell checker status",
        "command.edit.eval_logo.description": "Evaluate Editor LOGO code at current line or selection",
        "command.edit.mark.description": "Set / unset rectangular canvas block mark",
        "command.edit.cancel_selection.description": "Cancel active selection or canvas mark",

        "command.canvas.toggle.description": "Toggle Canvas Mode for fixed-position editing",
        "command.mode.canvas.toggle.description": "Toggle Canvas Mode for fixed-position editing",
        "command.canvas.draw_line.description": "Draw box lines and move the canvas cursor",
        "command.canvas.draw_arrow.description": "Draw arrow lines with an arrowhead at the endpoint",
        "command.canvas.block_mark.description": "Set / unset rectangular canvas block mark",

        "command.table.next_cell.description": "Move to next table cell",
        "command.table.prev_cell.description": "Move to previous table cell",
        "command.table.adjust_width_inc.description": "Increase current table column width",
        "command.table.adjust_width_dec.description": "Decrease current table column width",
        "command.table.adjust_height_inc.description": "Increase current table row height",
        "command.table.adjust_height_dec.description": "Decrease current table row height",
        "command.table.center_text.description": "Center text in current table cell",
        "command.table.clear_cell.description": "Clear text inside current table cell",

        "command.search.whereis.description": "Search; repeat next/previous match",
        "command.search.replace.description": "Search and replace text",
        "command.search.next.description": "Repeat search next match",
        "command.search.previous.description": "Repeat search previous match",
        "command.search.substitute.description": "Vim-style regex substitute s/search/replace/g",
        "command.document.open_link.description": "Open Markdown/Org/rst/AsciiDoc document link at cursor",
        "command.document.heading_next.description": "Previous/next heading; open outline",
        "command.document.heading_previous.description": "Previous/next heading; open outline",
        "command.document.outline.description": "Previous/next heading; open outline",
        "command.screen.refresh.description": "Refresh screen display",
        "command.cursor.pos.description": "Display current cursor position info",
        "command.cursor.goto_line.description": "Jump to line and column number",

        "command.file.save.description": "Save current file; ^O / F3 WriteOut (choose path)",
        "command.file.write_out.description": "Write buffer to file (choose path)",
        "command.file.insert.description": "Read file (insert external file into buffer)",
        "command.file.save_exit.description": "Save & Exit (save buffer and close/exit)",
        "command.file.exit.description": "Close buffer / Exit editor",
        "command.file.edit_config.description": "Open user configuration file",
        "command.file.reload_config.description": "Reload user configuration file",
        "command.file.directory.description": "Open directory buffer",
        "command.file.run_logo.description": "Run full LOGO script in active buffer",

        "command.buffer.new.description": "New Buffer (open a new empty buffer)",
        "command.buffer.next.description": "Next Buffer (switch to next open buffer)",
        "command.buffer.prev.description": "Previous Buffer (switch to previous buffer)",
        "command.menu.show.description": "Toggle top Menu Bar",
        "command.menu.toggle.description": "Toggle top Menu Bar",
        "command.help.describe_key.description": "Describe keybinding and mode functions",

        "command.select.all.description": "Select all buffer text",
        "command.edit.undo.description": "Undo last edit operation",
        "command.edit.redo.description": "Redo last undone operation",

        // Help Viewer
        "helpview.title": "  zago - Full Help & Command Reference",
        "helpview.header": "  KEYBINDINGS & COMMANDS REFERENCE",
        "helpview.sec_nav": "  NAVIGATION & CURSOR MOVEMENT:",
        "helpview.sec_edit": "  EDITING & SELECTION:",
        "helpview.sec_canvas": "  CANVAS MODE:",
        "helpview.sec_search": "  SEARCH & PARAGRAPH FORMATTING:",
        "helpview.sec_file": "  FILE & BUFFER OPERATIONS:",

        "outlineview.title": "  Document Outline",
        "outlineview.footer": "  Up/Down: Scroll | Enter: Jump | Esc/^G: Close",

        "helpview.sec_set": "  CONFIGURABLE SETTINGS VIA 'set / unset' COMMANDS:",
        "helpview.set_1": "    wrap <col|off>           Soft wrap column limit (e.g. set wrap 80/off)",
        "helpview.set_2": "    fill <col>               Paragraph justify target column width (e.g. set fill 72)",
        "helpview.set_3": "    ruler <on|off>           Toggle column ruler bar",
        "helpview.set_4": "    linenumbers <on|off>     Toggle line numbers gutter",
        "helpview.set_5": "    sublinenumbers <on|off>  Toggle soft-wrapped line numbers",
        "helpview.set_6": "    canvas-mode <on|off>     Start editor in 2D Canvas Mode",
        "helpview.set_7": "    syntax <on|off>          Toggle syntax highlighting",
        "helpview.set_8": "    tab <size>               Tab stop column width (e.g. set tab 4)",
        "helpview.set_9": "    smarttab <on|off>        Toggle smart indentation and list nesting",
        "helpview.set_10": "    list-indent-size <size>  Indent size for bullet and numbered lists",
        "helpview.set_11": "    list-wrap-indent <on|off> Align wrapped lines with list content",
        "helpview.set_12": "    autoreload <on|off>      Auto-reload files modified externally",
        "helpview.set_13": "    trim-trailing-whitespace Trim trailing spaces on save",
        "helpview.set_14": "    nonewlines <on|off>      Disable automatic trailing newline on save",
        "helpview.set_15": "    git-diff <on|off>        Show Git modified/added line indicators",
        "helpview.set_16": "    border <style>           Default border style (single/double/round/ascii)",
        "helpview.set_17": "    arrow <style>            Default arrow style (solid/stemmed/hollow/small)",
        "helpview.set_18": "    keymap <classic|modern>  Switch keybinding preset",
        "helpview.set_19": "    regex <on|off>           Enable/disable regex search mode",
        "helpview.set_20": "    ipc <on|off>             Enable/disable IPC socket server",
        "helpview.set_21": "    lang <en|zh_TW>          Set UI language",
        "helpview.set_22": "    spell-language <lang>    Set spell checker language (e.g. en_US)",
        "helpview.set_23": "    debug <on|off>           Toggle debug overlay logging",

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

        "helpview.sec_substitute": "  COMMAND BAR ACTIONS & SUBSTITUTION (/, s/, goto, eof):",
        "helpview.substitute_1": "    /<query>                 Search text or regex pattern in buffer",
        "helpview.substitute_2": "    s/<find>/<rep>/[flags]   Substitute in current line or selection",
        "helpview.substitute_3": "    %s/<find>/<rep>/[flags]  Substitute in entire buffer (all lines)",
        "helpview.substitute_4": "    Flags: g (global), i (ignore case), r (regex) | Delim: / or ,",
        "helpview.substitute_5": "    s/z(.*?)e/ddddd/r        Regex substitution ($1, $2 capture groups)",
        "helpview.substitute_6": "    <line>[:col] / goto      Jump to line/column (e.g. 42, :42, 42:10)",
        "helpview.substitute_7": "    eof / end-of-file        Move cursor to the end of buffer",

        "helpview.footer": "  Up/Dn/PgUp/PgDn: Scroll | Press any key to return",

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
        "msg.error_opening_file": "Error opening file: %@",
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
        "menu.selection": "Selection",

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
        "menu.edit.redo": "Redo\t^⇧Z",
        "menu.edit.mark": "Toggle Mark\t^^ / M+B",
        "menu.edit.cancel_selection": "Cancel Mark / Selection\t^G / M+U",
        "menu.edit.copy": "Copy\tM+W",
        "menu.edit.cut": "Cut Text\t^K",
        "menu.edit.paste": "UnCut (Paste)\t^U",
        "menu.edit.delete_line": "Delete Line\t^⌫",
        "menu.edit.search": "WhereIs (Search)...\t^W",
        "menu.edit.open_link": "Open Link\tM+O",
        "menu.edit.outline": "Outline\tM+\\",
        "menu.edit.next_heading": "Next Heading\tM+]",
        "menu.edit.previous_heading": "Previous Heading\tM+[",
        "menu.edit.spell": "Spell Checker...\t^T",
        "menu.edit.goto_line": "Goto Line...\tM+/",
        "menu.edit.toggle_comment": "Toggle Comment...\t^/",
        "menu.edit.justify": "Justify Paragraph\t^J",
        "menu.edit.text_editing_mode": "Text Editing Mode",
        "menu.edit.canvas_mode": "Canvas Mode\tF8",
        "menu.edit.table_editing_mode": "Table Editing Mode\tF7",

        "menu.buffer.next": "Next Buffer\tM+.",
        "menu.buffer.prev": "Previous Buffer\tM+,",
        "menu.buffer.output": "LOGO Output\tM+L",
        "menu.buffer.logo_debugger": "LOGO Debugger",
        "menu.buffer.clear_output": "Clear LOGO Output",

        "menu.run.script": "Run Script\tF5",
        "menu.run.output": "LOGO Output\tM+L",
        "menu.run.canvas": "LOGO Canvas\tM+C",
        "menu.run.clear": "Clear Canvas & Output",

        "menu.shapes.box": "Box (Insert)",
        "menu.shapes.draw_box": "Box (Replace)",
        "menu.shapes.line": "Horizontal Line",
        "menu.shapes.vline": "Vertical Line",
        "menu.shapes.table": "Table",
        "menu.shapes.fill": "Fill Region/Cell",
        "menu.shapes.symbols": "Insert Symbol...",

        "dialog.symbol_picker.title": " Insert Symbol ",
        "dialog.symbol_picker.footer": " Enter: Insert | Tab/1-4: Switch Tab | a-z: Quick Select | Esc: Cancel ",
        "dialog.symbol_picker.selected": " Selected: ",

        "dialog.describe_key.title": " Describe Key ",
        "dialog.describe_key.prompt": "Press any key to inspect its command and mode behaviors...",
        "dialog.describe_key.footer_close": " Press any key to close ",
        "dialog.describe_key.key_label": " Key: %@ ",
        "dialog.describe_key.section_text": "Text Mode (Default Editing):",
        "dialog.describe_key.section_canvas": "Canvas Mode (Fixed-Position / Drawing):",
        "dialog.describe_key.section_table": "Table Mode (Cell Navigation & Resize):",
        "dialog.describe_key.section_logo": "Custom LOGO Script / Macro:",
        "dialog.describe_key.same_as_text": "Same as Text Mode",
        "dialog.describe_key.insert_char": "Insert character '%@'",
        "dialog.describe_key.unbound": "Unbound key",

        "symbol_category.steps": "1. Steps",
        "symbol_category.badges": "2. Badges",
        "symbol_category.math_keys": "3. Math/Keys",
        "symbol_category.gfm": "4. Callouts",

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

        "menu.borders.single": "Single         ┌──┐",
        "menu.borders.heavy": "Heavy          ┏━━┓",
        "menu.borders.double": "Double         ╔══╗",
        "menu.borders.round": "Rounded Corners",
        "menu.borders.double_round": "Double Round   ╭══╮",
        "menu.borders.ascii": "ASCII          +--+",
        "menu.borders.ascii_round": "ASCII Round    /--\\",
        "menu.borders.triple_dash": "Triple Dash    ┌┄┄┐",
        "menu.borders.heavy_triple": "Heavy Triple   ┏┅┅┓",
        "menu.borders.quad_dash": "Quad Dash      ┌┈┈┐",
        "menu.borders.heavy_quad": "Heavy Quad     ┏┉┉┓",
        "menu.borders.double_dash": "Double Dash    ┌╌╌┐",
        "menu.borders.heavy_double": "Heavy Double   ┏╍╍┓",
        "menu.borders.next_style": "Next Style\tM+S",
        "menu.borders.arrow_solid": "Arrow: Solid   ▲▼◀▶",
        "menu.borders.arrow_stemmed": "Arrow: Stemmed ↑↓←→",
        "menu.borders.arrow_hollow": "Arrow: Hollow  △▽◁▷",
        "menu.borders.arrow_small": "Arrow: Small   ▴▾◂▸",

        "menu.tools.logo": "Command Prompt...\tEsc",
        "menu.tools.eval_logo": "Eval LOGO Code\t^Q",
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
        "menu.tools.clear_logo_output": "Clear LOGO Output",

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
        "menu.help.style_dsl": "Style DSL Reference",
        "menu.help.describe_key": "Describe Key",
        "menu.help.describe_command": "Describe Command & Procedure",
        "menu.help.logo_workspace": "Editor LOGO Workspace",

        "transform.tohant": "Traditional Chinese",
        "transform.tohans": "Simplified Chinese",
        "transform.tolatin": "Latin",
        "transform.hiragana": "Hiragana",
        "transform.katakana": "Katakana",
        "transform.romaji": "Romaji",
        "transform.cjk_spacing": "CJK Spacing",

        // AI Proposal UI & Status Strings
        "ai.proposal.action_hint": "[M+A Accept | M+R Reject]",
        "ai.proposal.readonly_cannot_modify": "[AI Proposal] Cannot modify read-only buffer",
        "ai.proposal.readonly_cannot_generate": "[AI Proposal] Cannot generate proposal in read-only buffer",
        "ai.proposal.no_pending_accept": "[AI Proposal] No pending proposal to accept",
        "ai.proposal.no_pending_reject": "[AI Proposal] No pending proposal to reject",
        "ai.proposal.accepted": "[AI Proposal] Accepted changes from %@ (^Z to Undo)",
        "ai.proposal.accepted_table_exited":
            "[AI Proposal] Accepted changes (Table Mode exited due to table grid structure changes)",
        "ai.proposal.rejected": "[AI Proposal] Rejected proposal from %@",
        "ai.proposal.queue_empty": "[AI Proposal] Queue is empty",
        "ai.proposal.preview_item": "[AI Proposal] (%d/%d) '%@'",
        "ai.proposal.mock_generated":
            "🤖 [Mock AI Proposal] \"%@\" (Press M+A to Accept, M+R to Reject, M+P to Preview)",
        "ai.proposal.received": "🤖 [AI Proposal from %@] \"%@\" (Press M+A to Accept, M+R to Reject, M+P to Preview)",
        "ai.proposal.queue_indicator": "[AI Queue %d/%d]",

        // Describe Command & Procedure Dialog Strings
        "describe_command.title_input": "Describe Command & Procedure",
        "describe_command.title_help": "Help: %@",
        "describe_command.prompt_input": "Enter command, procedure or primitive name:",
        "describe_command.footer_input": "[ Tab: Complete  |  Enter: Search  |  Esc: Close ]",
        "describe_command.footer_scroll": "[ ↑/↓/PgUp/PgDn: Scroll  |  q/Esc/Enter: Close ]",
        "describe_command.footer_close": "[ Press q / Esc / Enter to close ]",
        "describe_command.found_matches": "Found %d matches:",
        "describe_command.user_procedure": "User-Defined Procedure",
        "describe_command.syntax": "Syntax: ",
        "describe_command.no_parameters": "(none)",
        "describe_command.docstring": "Docstring",
        "describe_command.no_docstring": "(No docstring provided)",
        "describe_command.definition": "Definition",
        "describe_command.editor_command": "Editor Command",
        "describe_command.name": "Name: ",
        "describe_command.description": "Description:",
        "describe_command.notes": "Notes:",
        "describe_command.aliases": "Aliases:",
        "describe_command.builtin_primitive": "Built-in LOGO Primitive (%@)",
        "describe_command.source_ucb_logo": "UCB Logo Standard",
        "describe_command.source_zago": "Zago Extension",
        "describe_command.parameters": "Parameters:",
        "describe_command.parameter_description": "Description: ",
        "describe_command.parameter_example": "Example: ",
        "describe_command.param_required": "(required)",
        "describe_command.param_optional": "(optional)",
        "describe_command.allowed_values": " (allowed: ",
        "describe_command.examples": "Examples:",
        "describe_command.not_found": "Not Found",
        "describe_command.not_found_desc": "No command, procedure or primitive found matching '%@'.",
    ]
}
