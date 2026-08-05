import Config
import Foundation

/// Centralized localization manager indexing language translation tables.
public enum L10n {
    public static nonisolated(unsafe) var currentLanguage: Language = Language.detectSystemLanguage()

    /// Translation tables mapped per language.
    private static let tables: [Language: [String: String]] = [
        .en: EnglishStrings.table,
        .zh_TW: TraditionalChineseStrings.table,
    ]

    /// Subscript lookup for localized string key.
    public static subscript(_ key: String) -> String {
        tables[currentLanguage]?[key] ?? tables[.en]?[key] ?? key
    }

    public static func string(_ key: String, language: Language) -> String {
        tables[language]?[key] ?? tables[.en]?[key] ?? key
    }

    // MARK: - Strongly-Typed Help Bar Accessors
    public static var helpGetHelp: String { self["help.get_help"] }
    public static var helpMenu: String { self["help.menu"] }
    public static var helpCancel: String { self["help.cancel"] }
    public static var helpCanvasMode: String { self["help.canvas_mode"] }
    public static var helpTableMode: String { self["help.table_mode"] }
    public static var helpTextMode: String { self["help.text_mode"] }
    public static var helpWriteOut: String { self["help.write_out"] }
    public static var helpReadFile: String { self["help.read_file"] }
    public static var helpPrevPg: String { self["help.prev_pg"] }
    public static var helpCutText: String { self["help.cut_text"] }
    public static var helpCurPos: String { self["help.cur_pos"] }
    public static var helpExit: String { self["help.exit"] }
    public static var helpJustify: String { self["help.justify"] }
    public static var helpWhereIs: String { self["help.where_is"] }
    public static var helpNextPg: String { self["help.next_pg"] }
    public static var helpUnCutText: String { self["help.uncut_text"] }
    public static var helpToSpell: String { self["help.to_spell"] }

    public static var newBuffer: String { self["buffer.new_buffer"] }
    public static var modified: String { self["buffer.modified"] }

    // MARK: - Format String Helpers
    public static func readLines(_ count: Int) -> String {
        String(format: self["msg.read_lines"], count)
    }

    public static func wroteToFile(_ filename: String) -> String {
        String(format: self["msg.wrote_to_file"], filename)
    }

    public static var cancelled: String { self["msg.cancelled"] }

    public static func configLoadedWithErrors(_ count: Int) -> String {
        String(format: self["msg.config_loaded_with_errors"], count)
    }

    public static func cursorInfo(
        currentLine: Int,
        totalLines: Int,
        percent: Int,
        currentCol: Int,
        totalCol: Int,
        visualCol: Int,
        totalVisualCol: Int
    ) -> String {
        String(
            format: self["msg.cursor_info"], currentLine, totalLines, percent, currentCol, totalCol, visualCol,
            totalVisualCol)
    }

    public static func foundQueryAtLine(query: String, line: Int) -> String {
        String(format: self["msg.found_query_at_line"], query, line)
    }

    public static func searchWrappedFound(query: String, line: Int) -> String {
        String(format: self["msg.search_wrapped_found"], query, line)
    }

    public static func notFound(query: String) -> String {
        String(format: self["msg.not_found"], query)
    }

    public static func insertedLines(_ count: Int) -> String {
        String(format: self["msg.inserted_lines"], count)
    }

    public static func errorInsertingFile(error: String) -> String {
        String(format: self["msg.error_inserting_file"], error)
    }

    public static func errorSavingFile(error: String) -> String {
        String(format: self["msg.error_saving_file"], error)
    }

    public static func replacedWord(target: String, newWord: String) -> String {
        String(format: self["msg.replaced_word"], target, newWord)
    }

    public static func defaultBorder(_ style: String) -> String {
        String(format: self["status.default_border"], style)
    }

    public static func unknownBorderStyle(_ style: String) -> String {
        String(format: self["status.unknown_border_style"], style)
    }

    public static func unknownTableBorder(_ style: String) -> String {
        String(format: self["status.unknown_table_border"], style)
    }

    public static func disabledInTableMode(_ token: String) -> String {
        String(format: self["status.disabled_in_table_mode"], token)
    }

    public static func editingConfig(_ path: String) -> String {
        String(format: self["status.editing_config"], path)
    }

    public static func insertedDiagramSnippet(_ name: String) -> String {
        String(format: self["status.inserted_diagram_snippet"], name)
    }

    public static func lineNumbersState(_ state: String) -> String {
        String(format: self["status.line_numbers_state"], state)
    }

    public static func wrapColumnSet(_ col: Int) -> String {
        String(format: self["status.wrap_column_set"], col)
    }

    public static func replacedOccurrences(_ count: Int) -> String {
        String(format: self["status.replaced_occurrences"], count)
    }
}
