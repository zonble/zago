import Foundation
import LogoEngine

/// Parsed configuration settings loaded from ~/.serc or ./.serc files.
public struct EditorConfig {
    public var wrapColumn: Int? = nil
    public var showRuler: Bool = false
    public var showLineNumbers: Bool = true
    public var showSubLineNumbers: Bool = false
    public var tabSize: Int = 4
    public var enableSyntaxHighlight: Bool = true
    public var autoReload: Bool = true
    public var language: Language? = nil
    public var defaultBorderStyle: BorderStyle = .single
    public var customKeyBinds: [Key: String] = [:]
    public var unbindKeys: Set<Key> = []
    public var logoPrelude: String = ""
    public var logoScripts: [String: String] = [:]
    public var syntaxErrorCount: Int = 0
    public var loadedFilePath: String? = nil

    public init() {}
}

/// Helper utility parsing key strings (e.g. "ctrl-f", "f1", "up") into Key enum.
public enum KeyParser {
    public static func parse(_ keyStr: String) -> Key? {
        let normalized = keyStr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return nil }

        switch normalized {
        case "ctrl-shift-left", "ctrl-shift-arrow-left", "c-s-left", "c-s-arrow-left": return .ctrlShiftArrowLeft
        case "ctrl-shift-right", "ctrl-shift-arrow-right", "c-s-right", "c-s-arrow-right": return .ctrlShiftArrowRight
        case "ctrl-shift-up", "ctrl-shift-arrow-up", "c-s-up", "c-s-arrow-up": return .ctrlShiftArrowUp
        case "ctrl-shift-down", "ctrl-shift-arrow-down", "c-s-down", "c-s-arrow-down": return .ctrlShiftArrowDown
        default:
            break
        }

        if normalized.hasPrefix("ctrl-") || normalized.hasPrefix("^") {
            let charStr =
                normalized.hasPrefix("ctrl-") ? String(normalized.dropFirst(5)) : String(normalized.dropFirst(1))
            if let first = charStr.first {
                return .ctrl(Character(first.lowercased()))
            }
        }

        if normalized.hasPrefix("alt-") || normalized.hasPrefix("meta-") || normalized.hasPrefix("m-") {
            let prefixLen: Int
            if normalized.hasPrefix("alt-") {
                prefixLen = 4
            } else if normalized.hasPrefix("meta-") {
                prefixLen = 5
            } else {
                prefixLen = 2
            }

            let charStr = String(normalized.dropFirst(prefixLen))
            if let first = charStr.first {
                return .alt(first)
            }
        }

        switch normalized {
        case "up", "arrow-up", "arrowup": return .arrowUp
        case "down", "arrow-down", "arrowdown": return .arrowDown
        case "left", "arrow-left", "arrowleft": return .arrowLeft
        case "right", "arrow-right", "arrowright": return .arrowRight
        case "home": return .home
        case "end": return .end
        case "pageup", "page-up", "pgup": return .pageUp
        case "pagedown", "page-down", "pgdn": return .pageDown
        case "backspace", "bs": return .backspace
        case "ctrl-backspace", "ctrl-bs", "c-backspace", "c-bs": return .ctrlBackspace
        case "delete", "del": return .delete
        case "enter", "return": return .enter
        case "tab": return .tab
        case "mark": return .mark
        case "esc", "escape": return .esc
        case "shift-left", "shift-arrow-left": return .shiftArrowLeft
        case "shift-right", "shift-arrow-right": return .shiftArrowRight
        case "shift-up", "shift-arrow-up": return .shiftArrowUp
        case "shift-down", "shift-arrow-down": return .shiftArrowDown
        case "shift-home", "s-home": return .shiftHome
        case "shift-end", "s-end": return .shiftEnd
        case "f1": return .f1
        case "f2": return .f2
        case "f3": return .f3
        case "f4": return .f4
        case "f5": return .f5
        case "f6": return .f6
        case "f7": return .f7
        case "f8": return .f8
        case "f9": return .f9
        case "f10": return .f10
        case "f11": return .f11
        case "f12": return .f12
        default:
            if normalized.count == 1, let ch = normalized.first {
                return .char(ch)
            }
            return nil
        }
    }
}

/// Loads and parses Nano/Vim-style directives from ~/.serc and ./.serc configuration files.
public final class ConfigLoader {
    private enum LogoBlock {
        case prelude(lines: [String])
        case script(name: String, lines: [String])
    }

    public init() {}

    /// Loads configuration with cascading priority (~/.zagorc -> ./.zagorc -> ~/.serc -> ./.serc).
    public func loadConfig() -> EditorConfig {
        var config = EditorConfig()

        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        // 1. Global ~/.zagorc (or legacy ~/.serc)
        let globalZagorc = (homeDir as NSString).appendingPathComponent(".zagorc")
        let globalSerc = (homeDir as NSString).appendingPathComponent(".serc")
        if FileManager.default.fileExists(atPath: globalZagorc) {
            parseConfigFile(at: globalZagorc, into: &config)
        } else if FileManager.default.fileExists(atPath: globalSerc) {
            parseConfigFile(at: globalSerc, into: &config)
        }

        // 2. Local ./.zagorc (or legacy ./.serc) (overrides global)
        let localZagorc = FileManager.default.currentDirectoryPath + "/.zagorc"
        let localSerc = FileManager.default.currentDirectoryPath + "/.serc"
        if FileManager.default.fileExists(atPath: localZagorc) {
            parseConfigFile(at: localZagorc, into: &config)
        } else if FileManager.default.fileExists(atPath: localSerc) {
            parseConfigFile(at: localSerc, into: &config)
        }

        return config
    }

    /// Parses a configuration file at specified path into EditorConfig struct.
    public func parseConfigFile(at path: String, into config: inout EditorConfig) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        config.loadedFilePath = path

        let lines = content.components(separatedBy: .newlines)
        var logoBlock: LogoBlock? = nil

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

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
                            config.wrapColumn = LayoutEngine.normalizedWrapColumn(w)
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

                    case "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers", "line_number":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.showLineNumbers = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.showLineNumbers = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "sublinenumbers", "sublinenumber", "subline-numbers", "subline-number", "subline_numbers",
                        "subline_number", "sublines":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.showSubLineNumbers = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.showSubLineNumbers = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "tabsize":
                        if let ts = Int(value), ts > 0 {
                            config.tabSize = ts
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "unset":
                        if value == "wrap" {
                            config.wrapColumn = nil
                        } else if value == "ruler" {
                            config.showRuler = false
                        } else if value == "linenumbers" || value == "linenumber" || value == "line-numbers"
                            || value == "line-number" || value == "line_numbers" || value == "line_number"
                        {
                            config.showLineNumbers = false
                        } else if value == "sublinenumbers" || value == "sublinenumber" || value == "subline-numbers"
                            || value == "subline-number" || value == "subline_numbers" || value == "subline_number"
                            || value == "sublines"
                        {
                            config.showSubLineNumbers = false
                        } else if value == "syntax" {
                            config.enableSyntaxHighlight = false
                        } else if value == "autoreload" {
                            config.autoReload = false
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

                    case "autoreload", "auto-reload", "auto_reload":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.autoReload = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.autoReload = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "lang", "language":
                        if value == "zh_tw" || value == "zh-hant" || value == "zh" || value == "tw" {
                            config.language = .zh_TW
                        } else if value == "en" || value == "english" {
                            config.language = .en
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "border", "borderstyle", "border-style", "border_style", "defaultborder", "defaultborderstyle",
                        "default-border-style", "default_border_style":
                        if let style = BorderStyle(value) {
                            config.defaultBorderStyle = style
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    default:
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "unset":
                if tokens.count >= 2 {
                    let option = tokens[1].lowercased()
                    switch option {
                    case "wrap":
                        config.wrapColumn = nil
                    case "ruler", "showruler":
                        config.showRuler = false
                    case "linenumbers", "linenumber", "line-numbers", "line-number", "line_numbers", "line_number":
                        config.showLineNumbers = false
                    case "sublinenumbers", "sublinenumber", "subline-numbers", "subline-number", "subline_numbers",
                        "subline_number", "sublines":
                        config.showSubLineNumbers = false
                    case "syntax", "enablesyntax", "syntaxhighlight", "syntaxhighlighting":
                        config.enableSyntaxHighlight = false
                    case "autoreload", "auto-reload", "auto_reload":
                        config.autoReload = false
                    default:
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "bind":
                if tokens.count >= 3 {
                    let keyStr = tokens[1]
                    let cmdId = Self.unquote(tokens[2])
                    if let key = KeyParser.parse(keyStr) {
                        config.customKeyBinds[key] = cmdId
                    } else {
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "unbind":
                if tokens.count >= 2 {
                    let keyStr = tokens[1]
                    if let key = KeyParser.parse(keyStr) {
                        config.unbindKeys.insert(key)
                    } else {
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "logo-prelude":
                if tokens.count == 1 {
                    logoBlock = .prelude(lines: [])
                } else {
                    config.syntaxErrorCount += 1
                }

            case "logo-script":
                if tokens.count == 2 {
                    let name = tokens[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if name.isEmpty {
                        config.syntaxErrorCount += 1
                    } else {
                        logoBlock = .script(name: name, lines: [])
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "border", "borderstyle", "border-style", "border_style", "defaultborder", "defaultborderstyle",
                "default-border-style", "default_border_style":
                if tokens.count >= 2 {
                    let value = tokens[1].lowercased()
                    if let style = BorderStyle(value) {
                        config.defaultBorderStyle = style
                    } else {
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            default:
                config.syntaxErrorCount += 1
            }
        }

        if logoBlock != nil {
            config.syntaxErrorCount += 1
        }
    }

    private static func append(rawLine: String, to block: LogoBlock) -> LogoBlock {
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") {
            return block
        }

        switch block {
        case .prelude(var lines):
            lines.append(rawLine)
            return .prelude(lines: lines)
        case .script(let name, let lines):
            var updatedLines = lines
            updatedLines.append(rawLine)
            return .script(name: name, lines: updatedLines)
        }
    }

    private func commitLogoBlock(_ block: LogoBlock, into config: inout EditorConfig) {
        switch block {
        case .prelude(let lines):
            appendLogoPrelude(lines.joined(separator: "\n"), into: &config)
        case .script(let name, let lines):
            config.logoScripts[name] = lines.joined(separator: "\n")
        }
    }

    private func appendLogoPrelude(_ script: String, into config: inout EditorConfig) {
        let trimmedScript = script.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedScript.isEmpty else { return }

        if config.logoPrelude.isEmpty {
            config.logoPrelude = trimmedScript
        } else {
            config.logoPrelude += "\n" + trimmedScript
        }
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2 else { return value }

        let first = value.first
        let last = value.last
        if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }

    /// Generates a clean default .zagorc configuration file with detailed comments and sample keybindings.
    public static func generateDefaultConfigFile(targetPath: String? = nil) throws -> String {
        let path: String
        if let targetPath = targetPath {
            path = (targetPath as NSString).expandingTildeInPath
        } else {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            path = (homeDir as NSString).appendingPathComponent(".zagorc")
        }

        let content = defaultConfigTemplate
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    /// Complete default .zagorc configuration file template content.
    public static let defaultConfigTemplate = """
# ==============================================================================
#  zago Text Editor Configuration File (~/.zagorc)
# ==============================================================================

# Softwrap Column Width (uncomment to fix width, e.g. 80; omit for dynamic width)
# set wrapColumn 80

# Show WordStar-style ruler bar (on / off)
set showRuler off

# Show line number gutter (on / off)
set lineNumbers on

# Show right-side sub line numbers for wrapped prose paragraphs (on / off)
set subLineNumbers off

# Tab Stop Width (default: 4)
set tabSize 4

# Enable Syntax Highlighting (on / off)
set enableSyntax on

# Auto Reload modified files from disk (on / off)
set autoReload on

# Interface Language (en / zh_TW)
# set language zh_TW

# Default Table & Canvas Border Style (single / double / round / double-round / ascii / markdown)
# set border single

# ------------------------------------------------------------------------------
# Custom Keybindings & Unbinds
# Syntax: bind <key> <command_id>
# Example: bind ctrl-f search.find
# Example: bind alt-t table.toggle
# Example: bind alt-h logo: MOVE HOME TYPE "# " MOVE END
# Example: unbind ctrl-k
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# LOGO Prelude & Named Scripts
# Prelude code runs once on the editor's persistent LOGO engine.
# Named scripts can be triggered with bind <key> logo:<script-name>.
#
# logo-prelude
#   MAKE "boxWidth 30
#   TO FILLBOX :text
#     BOX :boxWidth 4
#     MOVE LEFT (:boxWidth - 1) MOVE UP 2
#     FILL :text
#   END
# endlogo
#
# logo-script insert-title
#   BOX 40 3 ROUND
#   MOVE LEFT 38 MOVE UP 1
#   FILL "-
# endlogo
#
# bind alt-b logo:FILLBOX "hi
# bind alt-t logo:insert-title
# ------------------------------------------------------------------------------
"""
}
