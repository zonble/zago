import Config
import Foundation

/// Localization manager indexing language translation tables.
struct L10n: Sendable {
    let language: Language

    init(language: Language = .detectSystemLanguage()) {
        self.language = language
    }

    /// Translation tables mapped per language.
    private static let tables: [Language: [String: String]] = [
        .en: EnglishStrings.table,
        .zh_TW: TraditionalChineseStrings.table,
    ]

    /// Subscript lookup for localized string key in this L10n instance's language.
    subscript(_ key: String) -> String {
        Self.string(key, language: language)
    }

    /// Pure stateless lookup for localized string key.
    static func string(_ key: String, language: Language = .detectSystemLanguage()) -> String {
        tables[language]?[key] ?? tables[.en]?[key] ?? key
    }

    // MARK: - Strongly-Typed Help Bar Accessors
    var helpGetHelp: String { self["help.get_help"] }
    var helpMenu: String { self["help.menu"] }
    var helpCancel: String { self["help.cancel"] }
    var helpCanvasMode: String { self["help.canvas_mode"] }
    var helpTableMode: String { self["help.table_mode"] }
    var helpTextMode: String { self["help.text_mode"] }
    var helpWriteOut: String { self["help.write_out"] }
    var helpReadFile: String { self["help.read_file"] }
    var helpPrevPg: String { self["help.prev_pg"] }
    var helpCutText: String { self["help.cut_text"] }
    var helpCurPos: String { self["help.cur_pos"] }
    var helpExit: String { self["help.exit"] }
    var helpJustify: String { self["help.justify"] }
    var helpWhereIs: String { self["help.where_is"] }
    var helpNextPg: String { self["help.next_pg"] }
    var helpUnCutText: String { self["help.uncut_text"] }
    var helpToSpell: String { self["help.to_spell"] }

    var newBuffer: String { self["buffer.new_buffer"] }
    var modified: String { self["buffer.modified"] }

    // MARK: - Directory Buffer Helpers
    func dirBufHeaderDirectory(_ path: String, _ branch: String) -> String {
        String(format: self["dirbuf.header_directory"], "\(path)\(branch)")
    }
    var dirBufHeaderInstructions: String { self["dirbuf.header_instructions"] }
    var dirBufUpDir: String { self["dirbuf.up_dir"] }

    // MARK: - Format String Helpers
    func readLines(_ count: Int) -> String {
        String(format: self["msg.read_lines"], count)
    }

    func wroteToFile(_ filename: String) -> String {
        String(format: self["msg.wrote_to_file"], filename)
    }

    var cancelled: String { self["msg.cancelled"] }

    func configLoadedWithErrors(_ count: Int) -> String {
        String(format: self["msg.config_loaded_with_errors"], count)
    }

    func cursorInfo(
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

    func foundQueryAtLine(query: String, line: Int) -> String {
        String(format: self["msg.found_query_at_line"], query, line)
    }

    func searchWrappedFound(query: String, line: Int) -> String {
        String(format: self["msg.search_wrapped_found"], query, line)
    }

    func notFound(query: String) -> String {
        String(format: self["msg.not_found"], query)
    }

    func insertedLines(_ count: Int) -> String {
        String(format: self["msg.inserted_lines"], count)
    }

    func errorInsertingFile(error: String) -> String {
        String(format: self["msg.error_inserting_file"], error)
    }

    func errorOpeningFile(error: String) -> String {
        String(format: self["msg.error_opening_file"], error)
    }

    func errorSavingFile(error: String) -> String {
        String(format: self["msg.error_saving_file"], error)
    }

    func replacedWord(target: String, newWord: String) -> String {
        String(format: self["msg.replaced_word"], target, newWord)
    }

    func defaultBorder(_ style: String) -> String {
        String(format: self["status.default_border"], style)
    }

    func unknownBorderStyle(_ style: String) -> String {
        String(format: self["status.unknown_border_style"], style)
    }

    func unknownTableBorder(_ style: String) -> String {
        String(format: self["status.unknown_table_border"], style)
    }

    func disabledInTableMode(_ token: String) -> String {
        String(format: self["status.disabled_in_table_mode"], token)
    }

    func editingConfig(_ path: String) -> String {
        String(format: self["status.editing_config"], path)
    }

    func insertedDiagramSnippet(_ name: String) -> String {
        String(format: self["status.inserted_diagram_snippet"], name)
    }

    func lineNumbersState(_ state: String) -> String {
        String(format: self["status.line_numbers_state"], state)
    }

    func wrapColumnSet(_ col: Int) -> String {
        String(format: self["status.wrap_column_set"], col)
    }

    func replacedOccurrences(_ count: Int) -> String {
        String(format: self["status.replaced_occurrences"], count)
    }
}
