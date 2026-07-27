import Foundation

/// English translation table for se text editor.
public struct EnglishStrings {
    public static let table: [String: String] = [
        // Help Bar Labels
        "help.get_help":   "Get Help",
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

        // Prompts
        "prompt.write_name": "File Name to Write: ",
        "prompt.confirm_exit_save": "Save modified buffer? (Answering \"N\" will discard changes) [Y/N]: ",
        "prompt.search": "Search",
        "prompt.insert_file": "File to insert: ",
        "prompt.edit_spelled_word": "Edit misspelled word \"%@\": ",

        // Status Messages
        "status.mark_set": "Mark Set",
        "status.mark_unset": "Mark Unset",
        "status.cut_text": "Cut text",
        "status.cut_one_line": "Cut 1 line",
        "status.uncut_text": "Uncut text",
        "status.clipboard_empty": "Clipboard is empty",
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

        // Help Viewer (HelpView.swift)
        "helpview.title": "  se - Full Help & Command Reference",
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
        "helpview.edit_2": "    ^^ (Ctrl+^)        Set / Unset selection mark (starts text selection)",
        "helpview.edit_3": "    ^K / F9            Cut selected text (or current line if no mark set)",
        "helpview.edit_4": "    ^U / F10           Uncut (paste) last cut text at cursor position",
        "helpview.edit_5": "    ^I / Tab           Insert tab (4 spaces) at cursor position",

        "helpview.sec_search": "  SEARCH & PARAGRAPH FORMATTING:",
        "helpview.search_1": "    ^W / F6            Where Is (case-insensitive text search)",
        "helpview.search_2": "    ^J / F4            Justify (format) current paragraph (CJK/Latin reflow)",
        "helpview.search_3": "    ^L                 Refresh screen display",
        "helpview.search_4": "    ^C / F11           Display current cursor position info",
        "helpview.search_5": "    ^T / F12           Spell checker status",

        "helpview.sec_file": "  FILE OPERATIONS & EXIT:",
        "helpview.file_1": "    ^O / ^S / F3       WriteOut (save buffer to file)",
        "helpview.file_2": "    ^R / F5            Read file (insert external file into buffer)",
        "helpview.file_3": "    ^X / F2            Exit editor (prompts to save modified buffer)",
        "helpview.file_4": "    ^G / F1            Display this full-screen help page",

        "helpview.footer": "  [ Press any key to return to editor ]",

        // Common Messages
        "msg.cancelled": "[ Cancelled ]",
        "buffer.new_buffer": "New Buffer",
        "buffer.modified": "Modified",

        // Format Messages
        "msg.read_lines": "[ Read %d line(s) ]",
        "msg.wrote_to_file": "[ Wrote to %@ ]",
        "msg.config_loaded_with_errors": "[ Config loaded with %d syntax error(s) ]",
        "msg.cursor_info": "line %d/%d (%d%%), col %d/%d",
        "msg.found_query_at_line": "Found \"%1$@\" at line %2$d",
        "msg.search_wrapped_found": "Search wrapped, found \"%1$@\" at line %2$d",
        "msg.not_found": "\"%@\" not found",
        "msg.inserted_lines": "[ Inserted %d lines ]",
        "msg.error_inserting_file": "Error inserting file: %@",
        "msg.error_saving_file": "Error saving file: %@",
        "msg.replaced_word": "Replaced '%@' with '%@'"
    ]
}
