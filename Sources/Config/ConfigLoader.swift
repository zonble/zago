import Drawing
import Foundation

/// Loads and parses Nano/Vim-style directives from ~/.zagorc and ./.zagorc configuration files.
public final class ConfigLoader {
    private enum LogoBlock {
        case prelude(lines: [String])
        case script(name: String, lines: [String])
    }

    public let provider: any ConfigFileProvider

    public init(provider: any ConfigFileProvider) {
        self.provider = provider
    }

    /// Loads configuration with cascading priority (~/.zagorc -> ./.zagorc -> ~/.serc -> ./.serc).
    public func loadConfig() -> EditorConfig {
        var config = EditorConfig()

        let homeDir = provider.homeDirectoryPath()

        // 1. Global ~/.zagorc (or legacy ~/.serc)
        let globalZagorc = (homeDir as NSString).appendingPathComponent(".zagorc")
        let globalSerc = (homeDir as NSString).appendingPathComponent(".serc")
        if provider.fileExists(atPath: globalZagorc) {
            parseConfigFile(at: globalZagorc, into: &config)
        } else if provider.fileExists(atPath: globalSerc) {
            parseConfigFile(at: globalSerc, into: &config)
        }

        // 2. Local ./.zagorc (or legacy ./.serc) (overrides global)
        let currentDir = provider.currentDirectoryPath()
        let localZagorc = (currentDir as NSString).appendingPathComponent(".zagorc")
        let localSerc = (currentDir as NSString).appendingPathComponent(".serc")
        if provider.fileExists(atPath: localZagorc) {
            parseConfigFile(at: localZagorc, into: &config)
        } else if provider.fileExists(atPath: localSerc) {
            parseConfigFile(at: localSerc, into: &config)
        }

        return config
    }

    /// Parses a configuration file at specified path into EditorConfig struct.
    public func parseConfigFile(at path: String, into config: inout EditorConfig) {
        do {
            let content = try provider.readString(atPath: path)
            config.loadedFilePath = path
            parseConfigContent(content, into: &config)
        } catch {
            // Couldn't read file at path
        }
    }

    /// Pure parser method reading string content into EditorConfig struct.
    public func parseConfigContent(_ content: String, into config: inout EditorConfig) {
        let lines = content.components(separatedBy: .newlines)
        var logoBlock: LogoBlock? = nil

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if let activeBlock = logoBlock {
                if line.lowercased() == "endlogo" {
                    commitLogoBlock(activeBlock, into: &config)
                    logoBlock = nil
                } else {
                    logoBlock = Self.append(rawLine: rawLine, to: activeBlock)
                }
                continue
            }

            if line.isEmpty || line.hasPrefix("#") { continue }

            let tokens = line.split(separator: " ", maxSplits: 2).map { String($0) }
            guard !tokens.isEmpty else { continue }

            let command = tokens[0].lowercased()

            switch command {
            case "set":
                if tokens.count >= 2 {
                    let option = tokens[1].lowercased()
                    let value = tokens.count >= 3 ? tokens[2].lowercased() : ""

                    switch option {
                    case "wrap":
                        if let w = Int(value), w > 0 {
                            config.wrapColumn = EditorConfig.normalizedWrapColumn(w)
                        } else if value == "false" || value == "off" || value == "none" {
                            config.wrapColumn = nil
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "nowrap":
                        config.wrapColumn = nil

                    case "ruler", "showruler":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.showRuler = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.showRuler = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers",
                        "line_number":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.showLineNumbers = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.showLineNumbers = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "sublinenumbers", "sublinenumber", "subline-numbers", "subline-number",
                        "subline_numbers", "subline_number", "sublines":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.showSubLineNumbers = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.showSubLineNumbers = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "canvas-mode", "canvasmode", "canvas_mode":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.startInCanvasMode = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.startInCanvasMode = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "syntax", "enablesyntax", "syntaxhighlight", "syntaxhighlighting":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.enableSyntaxHighlight = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.enableSyntaxHighlight = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "smarttab", "smart-tab", "smart_tab":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.smartTab = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.smartTab = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "listindentsize", "list-indent-size", "list_indent_size", "list_indent", "listindent":
                        if let s = Int(value), s > 0 {
                            config.listIndentSize = s
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "autoreload", "auto-reload", "auto_reload":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.autoReload = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.autoReload = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "trim-trailing-whitespace", "trimtrailingwhitespace",
                        "trim_trailing_whitespace", "trim-trailing-spaces", "trimtrailingspaces",
                        "trim_trailing_spaces":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.trimTrailingWhitespaceOnSave = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.trimTrailingWhitespaceOnSave = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "tab", "tabsize":
                        if let size = Int(value), size > 0 {
                            config.tabSize = size
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "language", "lang":
                        if value == "zh_tw" || value == "zh-tw" || value == "zh_hant" || value == "zh-hant" || value == "zh" || value == "chinese" || value == "traditionalchinese" {
                            config.language = .zh_TW
                        } else if value == "en" || value == "english" {
                            config.language = .en
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "spell", "spell-lang", "spell_lang", "spelllang", "spelllanguage", "spell_language", "spell-language":
                        if !value.isEmpty {
                            config.spellLanguage = value
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "border", "borderstyle", "border-style", "border_style", "defaultborder",
                        "defaultborderstyle", "default-border-style", "default_border_style":
                        if let style = BorderStyle(value) {
                            config.defaultBorderStyle = style
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "arrow", "arrowstyle", "arrow-style", "arrow_style", "defaultarrow",
                        "defaultarrowstyle", "default-arrow-style", "default_arrow_style":
                        if let style = ArrowStyle(value) {
                            config.defaultArrowStyle = style
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "unset":
                        if tokens.count >= 3 {
                            let subOption = tokens[2].lowercased()
                            Self.applyUnsetOption(subOption, into: &config)
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "git-diff", "git_diff", "gitdiff", "showgitdiff", "show-git-diff", "show_git_diff":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.showGitDiff = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.showGitDiff = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "nogit-diff", "nogit_diff", "nogitdiff":
                        config.showGitDiff = false

                    default:
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "unset":
                if tokens.count >= 2 {
                    let option = tokens[1].lowercased()
                    Self.applyUnsetOption(option, into: &config)
                } else {
                    config.syntaxErrorCount += 1
                }

            case "bind":
                if tokens.count >= 3 {
                    let rawKey = tokens[1]
                    let rawCmd = Self.unquote(tokens[2])

                    if let key = KeyParser.parse(rawKey) {
                        config.customKeyBinds[key] = rawCmd
                        config.unbindKeys.remove(key)
                    } else {
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "unbind":
                if tokens.count >= 2 {
                    let rawKey = tokens[1]
                    if let key = KeyParser.parse(rawKey) {
                        config.unbindKeys.insert(key)
                        config.customKeyBinds.removeValue(forKey: key)
                    } else {
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "logo", "logo-prelude", "logo-script":
                if command == "logo-script" {
                    if tokens.count >= 2 {
                        let scriptName = tokens[1]
                        logoBlock = .script(name: scriptName, lines: [])
                    } else {
                        config.syntaxErrorCount += 1
                    }
                } else if command == "logo" && tokens.count >= 2 {
                    let scriptName = tokens[1]
                    logoBlock = .script(name: scriptName, lines: [])
                } else if command == "logo-prelude" && tokens.count > 1 {
                    config.syntaxErrorCount += 1
                } else {
                    logoBlock = .prelude(lines: [])
                }

            default:
                let option = command
                let value = tokens.count >= 2 ? tokens[1].lowercased() : ""

                switch option {
                case "wrap", "wrapcolumn":
                    if let w = Int(value), w > 0 {
                        config.wrapColumn = EditorConfig.normalizedWrapColumn(w)
                    } else if value == "false" || value == "off" || value == "none" {
                        config.wrapColumn = nil
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "nowrap":
                    config.wrapColumn = nil

                case "ruler", "showruler":
                    if value == "true" || value == "on" || value == "1" || value.isEmpty {
                        config.showRuler = true
                    } else if value == "false" || value == "off" || value == "0" {
                        config.showRuler = false
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "noruler":
                    config.showRuler = false

                case "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers",
                    "line_number":
                    if value == "true" || value == "on" || value == "1" || value.isEmpty {
                        config.showLineNumbers = true
                    } else if value == "false" || value == "off" || value == "0" {
                        config.showLineNumbers = false
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "nolinenumbers", "nolinenumber", "noline-numbers", "noline-number",
                    "noline_numbers", "noline_number":
                    config.showLineNumbers = false

                case "sublinenumbers", "sublinenumber", "subline-numbers", "subline-number",
                    "subline_numbers", "subline_number", "sublines":
                    if value == "true" || value == "on" || value == "1" || value.isEmpty {
                        config.showSubLineNumbers = true
                    } else if value == "false" || value == "off" || value == "0" {
                        config.showSubLineNumbers = false
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "nosublinenumbers", "nosublinenumber", "nosubline-numbers", "nosubline-number",
                    "nosubline_numbers", "nosubline_number", "nosublines":
                    config.showSubLineNumbers = false

                case "canvas-mode", "canvasmode", "canvas_mode":
                    if value == "true" || value == "on" || value == "1" || value.isEmpty {
                        config.startInCanvasMode = true
                    } else if value == "false" || value == "off" || value == "0" {
                        config.startInCanvasMode = false
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "nocanvas-mode", "nocanvasmode", "nocanvas_mode":
                    config.startInCanvasMode = false

                case "syntax", "enablesyntax", "syntaxhighlight", "syntaxhighlighting":
                    if value == "true" || value == "on" || value == "1" || value.isEmpty {
                        config.enableSyntaxHighlight = true
                    } else if value == "false" || value == "off" || value == "0" {
                        config.enableSyntaxHighlight = false
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "nosyntax", "noenablesyntax", "nosyntaxhighlight", "nosyntaxhighlighting":
                    config.enableSyntaxHighlight = false

                case "autoreload", "auto-reload", "auto_reload":
                    if value == "true" || value == "on" || value == "1" || value.isEmpty {
                        config.autoReload = true
                    } else if value == "false" || value == "off" || value == "0" {
                        config.autoReload = false
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "noautoreload", "noauto-reload", "noauto_reload":
                    config.autoReload = false

                case "trim-trailing-whitespace", "trimtrailingwhitespace",
                    "trim_trailing_whitespace", "trim-trailing-spaces", "trimtrailingspaces",
                    "trim_trailing_spaces":
                    if value == "true" || value == "on" || value == "1" || value.isEmpty {
                        config.trimTrailingWhitespaceOnSave = true
                    } else if value == "false" || value == "off" || value == "0" {
                        config.trimTrailingWhitespaceOnSave = false
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "notrim-trailing-whitespace", "notrimtrailingwhitespace",
                    "notrim_trailing_whitespace", "notrim-trailing-spaces", "notrimtrailingspaces",
                    "notrim_trailing_spaces":
                    config.trimTrailingWhitespaceOnSave = false

                case "tab", "tabsize":
                    if let size = Int(value), size > 0 {
                        config.tabSize = size
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "language", "lang":
                    if value == "zh_tw" || value == "zh-tw" || value == "zh_hant" || value == "zh-hant" || value == "zh" || value == "chinese" || value == "traditionalchinese" {
                        config.language = .zh_TW
                    } else if value == "en" || value == "english" {
                        config.language = .en
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "spell", "spell-lang", "spell_lang", "spelllang", "spelllanguage", "spell_language", "spell-language":
                    if !value.isEmpty {
                        config.spellLanguage = value
                    } else {
                        config.syntaxErrorCount += 1
                    }

                case "border", "borderstyle", "border-style", "border_style", "defaultborder",
                    "defaultborderstyle", "default-border-style", "default_border_style":
                    if let style = BorderStyle(value) {
                        config.defaultBorderStyle = style
                    } else {
                        config.syntaxErrorCount += 1
                    }

                default:
                    print("DEBUG_SYNTAX_ERROR: line=[\(line)], command=[\(command)]")
                    config.syntaxErrorCount += 1
                }
            }
        }

        if logoBlock != nil {
            config.syntaxErrorCount += 1
        }
    }

    /// Helper to generate a default `.zagorc` template at the given file path (or default ~/.zagorc if nil).
    public static func generateDefaultConfigFile(
        targetPath: String? = nil, provider: any ConfigFileProvider
    ) throws -> String {
        let path = targetPath ?? (provider.homeDirectoryPath() as NSString).appendingPathComponent(".zagorc")
        let content = """
            # zago Configuration File (.zagorc)
            # Lines starting with '#' are comments.

            # View & Layout Options
            set wrap 80
            set ruler on
            set linenumbers on
            set sublinenumbers off
            set syntax on
            set tab 4
            set auto-reload on
            set trim-trailing-whitespace off
            set border single
            set arrow solid

            # Custom Key Bindings
            # bind <key> <command_or_macro>
            # bind ^T logo:fd 10
            """
        if !provider.fileExists(atPath: path) {
            try provider.writeString(content, toPath: path)
        }
        return path
    }

    private static func applyUnsetOption(_ option: String, into config: inout EditorConfig) {
        switch option {
        case "wrap":
            config.wrapColumn = nil
        case "ruler", "showruler":
            config.showRuler = false
        case "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers", "line_number":
            config.showLineNumbers = false
        case "sublinenumbers", "sublinenumber", "subline-numbers", "subline-number", "subline_numbers", "subline_number", "sublines":
            config.showSubLineNumbers = false
        case "canvas-mode", "canvasmode", "canvas_mode":
            config.startInCanvasMode = false
        case "syntax", "enablesyntax", "syntaxhighlight", "syntaxhighlighting":
            config.enableSyntaxHighlight = false
        case "autoreload", "auto-reload", "auto_reload":
            config.autoReload = false
        case "trim-trailing-whitespace", "trimtrailingwhitespace", "trim_trailing_whitespace", "trim-trailing-spaces", "trimtrailingspaces", "trim_trailing_spaces":
            config.trimTrailingWhitespaceOnSave = false
        case "git-diff", "git_diff", "gitdiff":
            config.showGitDiff = false
        default:
            config.syntaxErrorCount += 1
        }
    }

    private static func append(rawLine: String, to block: LogoBlock) -> LogoBlock {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") {
            return block
        }
        switch block {
        case .prelude(var lines):
            lines.append(rawLine)
            return .prelude(lines: lines)
        case .script(let name, var lines):
            lines.append(rawLine)
            return .script(name: name, lines: lines)
        }
    }

    private func commitLogoBlock(_ block: LogoBlock, into config: inout EditorConfig) {
        switch block {
        case .prelude(let lines):
            appendLogoPrelude(lines.joined(separator: "\n"), into: &config)
        case .script(let name, let lines):
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return }
            let scriptBody = lines.joined(separator: "\n")
            config.logoScripts[trimmedName] = scriptBody
        }
    }

    private func appendLogoPrelude(_ script: String, into config: inout EditorConfig) {
        let trimmed = script.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if config.logoPrelude.isEmpty {
            config.logoPrelude = trimmed
        } else {
            config.logoPrelude += "\n" + trimmed
        }
    }

    private static func unquote(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return trimmed }

        let first = trimmed.first
        let last = trimmed.last
        if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
            return String(trimmed.dropFirst().dropLast())
        }
        return trimmed
    }
}
