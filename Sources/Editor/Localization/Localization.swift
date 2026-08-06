import Config
import Foundation

/// Localization manager indexing language translation tables.
public struct L10n: Sendable {
    public let language: Language

    public init(language: Language = .detectSystemLanguage()) {
        self.language = language
    }

    /// Translation tables mapped per language.
    private static let tables: [Language: [String: String]] = [
        .en: EnglishStrings.table,
        .zh_TW: TraditionalChineseStrings.table,
    ]

    /// Subscript lookup for localized string key in this L10n instance's language.
    public subscript(_ key: String) -> String {
        Self.string(key, language: language)
    }

    /// Pure stateless lookup for localized string key.
    public static func string(_ key: String, language: Language = .detectSystemLanguage()) -> String {
        tables[language]?[key] ?? tables[.en]?[key] ?? key
    }

    // MARK: - Strongly-Typed Help Bar Accessors
    public var helpGetHelp: String { self["help.get_help"] }
    public var helpMenu: String { self["help.menu"] }
    public var helpCancel: String { self["help.cancel"] }
    public var helpCanvasMode: String { self["help.canvas_mode"] }
    public var helpTableMode: String { self["help.table_mode"] }
    public var helpTextMode: String { self["help.text_mode"] }
    public var helpWriteOut: String { self["help.write_out"] }
    public var helpReadFile: String { self["help.read_file"] }
    public var helpPrevPg: String { self["help.prev_pg"] }
    public var helpCutText: String { self["help.cut_text"] }
    public var helpCurPos: String { self["help.cur_pos"] }
    public var helpExit: String { self["help.exit"] }
    public var helpJustify: String { self["help.justify"] }
    public var helpWhereIs: String { self["help.where_is"] }
    public var helpNextPg: String { self["help.next_pg"] }
    public var helpUnCutText: String { self["help.uncut_text"] }
    public var helpToSpell: String { self["help.to_spell"] }

    public var newBuffer: String { self["buffer.new_buffer"] }
    public var modified: String { self["buffer.modified"] }

    // MARK: - Directory Buffer Helpers
    public func dirBufHeaderDirectory(_ path: String, _ branch: String) -> String {
        String(format: self["dirbuf.header_directory"], "\(path)\(branch)")
    }
    public var dirBufHeaderInstructions: String { self["dirbuf.header_instructions"] }
    public var dirBufUpDir: String { self["dirbuf.up_dir"] }

    // MARK: - Format String Helpers
    public func readLines(_ count: Int) -> String {
        String(format: self["msg.read_lines"], count)
    }

    public func wroteToFile(_ filename: String) -> String {
        String(format: self["msg.wrote_to_file"], filename)
    }

    public var cancelled: String { self["msg.cancelled"] }

    public func configLoadedWithErrors(_ count: Int) -> String {
        String(format: self["msg.config_loaded_with_errors"], count)
    }

    public func cursorInfo(
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

    public func foundQueryAtLine(query: String, line: Int) -> String {
        String(format: self["msg.found_query_at_line"], query, line)
    }

    public func searchWrappedFound(query: String, line: Int) -> String {
        String(format: self["msg.search_wrapped_found"], query, line)
    }

    public func notFound(query: String) -> String {
        String(format: self["msg.not_found"], query)
    }

    public func insertedLines(_ count: Int) -> String {
        String(format: self["msg.inserted_lines"], count)
    }

    public func errorInsertingFile(error: String) -> String {
        String(format: self["msg.error_inserting_file"], error)
    }

    public func errorSavingFile(error: String) -> String {
        String(format: self["msg.error_saving_file"], error)
    }

    public func replacedWord(target: String, newWord: String) -> String {
        String(format: self["msg.replaced_word"], target, newWord)
    }

    public func defaultBorder(_ style: String) -> String {
        String(format: self["status.default_border"], style)
    }

    public func unknownBorderStyle(_ style: String) -> String {
        String(format: self["status.unknown_border_style"], style)
    }

    public func unknownTableBorder(_ style: String) -> String {
        String(format: self["status.unknown_table_border"], style)
    }

    public func disabledInTableMode(_ token: String) -> String {
        String(format: self["status.disabled_in_table_mode"], token)
    }

    public func editingConfig(_ path: String) -> String {
        String(format: self["status.editing_config"], path)
    }

    public func insertedDiagramSnippet(_ name: String) -> String {
        String(format: self["status.inserted_diagram_snippet"], name)
    }

    public func lineNumbersState(_ state: String) -> String {
        String(format: self["status.line_numbers_state"], state)
    }

    public func wrapColumnSet(_ col: Int) -> String {
        String(format: self["status.wrap_column_set"], col)
    }

    public func replacedOccurrences(_ count: Int) -> String {
        String(format: self["status.replaced_occurrences"], count)
    }

}
