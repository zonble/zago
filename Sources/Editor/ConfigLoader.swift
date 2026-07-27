import Foundation

/// Parsed configuration settings loaded from ~/.serc or ./.serc files.
public struct EditorConfig {
    public var wrapColumn: Int? = nil
    public var showRuler: Bool = false
    public var tabSize: Int = 4
    public var enableSyntaxHighlight: Bool = true
    public var autoReload: Bool = true
    public var language: Language? = nil
    public var customKeyBinds: [Key: String] = [:]
    public var unbindKeys: Set<Key> = []
    public var syntaxErrorCount: Int = 0
    public var loadedFilePath: String? = nil

    public init() {}
}

/// Helper utility parsing key strings (e.g. "ctrl-f", "f1", "up") into Key enum.
public enum KeyParser {
    public static func parse(_ keyStr: String) -> Key? {
        let normalized = keyStr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return nil }

        if normalized.hasPrefix("ctrl-") || normalized.hasPrefix("^") {
            let charStr = normalized.hasPrefix("ctrl-") ? String(normalized.dropFirst(5)) : String(normalized.dropFirst(1))
            if let first = charStr.first {
                return .ctrl(Character(first.lowercased()))
            }
        }

        if normalized.hasPrefix("alt-") || normalized.hasPrefix("meta-") || normalized.hasPrefix("m-") {
            let prefixLen: Int
            if normalized.hasPrefix("alt-") { prefixLen = 4 }
            else if normalized.hasPrefix("meta-") { prefixLen = 5 }
            else { prefixLen = 2 }

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
    public init() {}

    /// Loads configuration with cascading priority (~/.serc -> ./.serc).
    public func loadConfig() -> EditorConfig {
        var config = EditorConfig()

        // 1. Try global ~/.serc
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let globalPath = (homeDir as NSString).appendingPathComponent(".serc")
        if FileManager.default.fileExists(atPath: globalPath) {
            parseConfigFile(at: globalPath, into: &config)
        }

        // 2. Try local ./.serc (overrides global)
        let localPath = FileManager.default.currentDirectoryPath + "/.serc"
        if FileManager.default.fileExists(atPath: localPath) {
            parseConfigFile(at: localPath, into: &config)
        }

        return config
    }

    /// Parses a configuration file at specified path into EditorConfig struct.
    public func parseConfigFile(at path: String, into config: inout EditorConfig) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        config.loadedFilePath = path

        let lines = content.components(separatedBy: .newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
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
                            config.wrapColumn = w
                        } else if value == "false" || value == "off" || value == "none" {
                            config.wrapColumn = nil
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "nowrap":
                        config.wrapColumn = nil

                    case "ruler":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.showRuler = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.showRuler = false
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
                        } else if value == "syntax" {
                            config.enableSyntaxHighlight = false
                        } else if value == "autoreload" {
                            config.autoReload = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "syntax":
                        if value == "true" || value == "on" || value == "1" || value.isEmpty {
                            config.enableSyntaxHighlight = true
                        } else if value == "false" || value == "off" || value == "0" {
                            config.enableSyntaxHighlight = false
                        } else {
                            config.syntaxErrorCount += 1
                        }

                    case "autoreload":
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

                    default:
                        config.syntaxErrorCount += 1
                    }
                } else {
                    config.syntaxErrorCount += 1
                }

            case "bind":
                if tokens.count >= 3 {
                    let keyStr = tokens[1]
                    let cmdId = tokens[2]
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

            default:
                config.syntaxErrorCount += 1
            }
        }
    }
}
