import Foundation

/// Supported language options for se editor.
public enum Language: String, CaseIterable, Sendable {
    case en = "en"
    case zh_TW = "zh_TW"

    /// Detects current system language from LC_ALL, LC_MESSAGES, LANG, LANGUAGE, or Locale.
    public static func detectSystemLanguage() -> Language {
        let envs = [
            ProcessInfo.processInfo.environment["LC_ALL"],
            ProcessInfo.processInfo.environment["LC_MESSAGES"],
            ProcessInfo.processInfo.environment["LANG"],
            ProcessInfo.processInfo.environment["LANGUAGE"]
        ].compactMap { $0 }

        for env in envs {
            let lower = env.lowercased()
            if lower.contains("zh") || lower.contains("tw") || lower.contains("hant") || lower.contains("hk") {
                return .zh_TW
            }
        }

        let localeID = Locale.current.identifier.lowercased()
        if localeID.contains("zh") || localeID.contains("tw") || localeID.contains("hant") {
            return .zh_TW
        }

        return .en
    }
}

/// Centralized localization manager indexing language translation tables.
public enum L10n {
    public static nonisolated(unsafe) var currentLanguage: Language = Language.detectSystemLanguage()

    /// Translation tables mapped per language.
    private static let tables: [Language: [String: String]] = [
        .en: EnglishStrings.table,
        .zh_TW: TraditionalChineseStrings.table
    ]

    /// Subscript lookup for localized string key.
    public static subscript(_ key: String) -> String {
        tables[currentLanguage]?[key] ?? tables[.en]?[key] ?? key
    }

    // MARK: - Strongly-Typed Help Bar Accessors
    public static var helpGetHelp: String { self["help.get_help"] }
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
        currentLanguage == .zh_TW ? "[ 已讀取 \(count) 行 ]" : "[ Read \(count) line(s) ]"
    }

    public static func wroteToFile(_ filename: String) -> String {
        currentLanguage == .zh_TW ? "[ 已儲存至 \(filename) ]" : "[ Wrote to \(filename) ]"
    }

    public static var cancelled: String { self["msg.cancelled"] }

    public static func configLoadedWithErrors(_ count: Int) -> String {
        currentLanguage == .zh_TW ? "[ 已載入設定檔（含有 \(count) 個語法錯誤）]" : "[ Config loaded with \(count) syntax error(s) ]"
    }

    public static func cursorInfo(currentLine: Int, totalLines: Int, percent: Int, currentCol: Int, totalCol: Int) -> String {
        currentLanguage == .zh_TW
            ? "第 \(currentLine)/\(totalLines) 行 (\(percent)%), 第 \(currentCol)/\(totalCol) 欄"
            : "line \(currentLine)/\(totalLines) (\(percent)%), col \(currentCol)/\(totalCol)"
    }

    public static func foundQueryAtLine(query: String, line: Int) -> String {
        currentLanguage == .zh_TW
            ? "於第 \(line) 行找到 \"\(query)\""
            : "Found \"\(query)\" at line \(line)"
    }

    public static func searchWrappedFound(query: String, line: Int) -> String {
        currentLanguage == .zh_TW
            ? "搜尋回到開頭，於第 \(line) 行找到 \"\(query)\""
            : "Search wrapped, found \"\(query)\" at line \(line)"
    }

    public static func notFound(query: String) -> String {
        currentLanguage == .zh_TW ? "找不到 \"\(query)\"" : "\"\(query)\" not found"
    }

    public static func insertedLines(count: Int) -> String {
        currentLanguage == .zh_TW ? "[ 已插入 \(count) 行內容 ]" : "[ Inserted \(count) lines ]"
    }

    public static func errorInsertingFile(error: String) -> String {
        currentLanguage == .zh_TW ? "插入檔案錯誤：\(error)" : "Error inserting file: \(error)"
    }

    public static func errorSavingFile(error: String) -> String {
        currentLanguage == .zh_TW ? "儲存檔案錯誤：\(error)" : "Error saving file: \(error)"
    }

    public static func replacedWord(target: String, newWord: String) -> String {
        currentLanguage == .zh_TW
            ? "已將 '\(target)' 替換為 '\(newWord)'"
            : "Replaced '\(target)' with '\(newWord)'"
    }
}
