import Drawing
import Foundation

/// Loads and parses Nano/Vim-style directives from ~/.zagorc and ./.zagorc configuration files.
public final class ConfigLoader {
    private enum LogoBlock {
        case prelude(lines: [String])
        case script(name: String, lines: [String])
    }

    private enum ConfigCommand: String {
        case set
        case unset
        case bind
        case unbind
        case logo
        case logoPrelude = "logo-prelude"
        case logoScript = "logo-script"
    }

    public let provider: any ConfigFileProvider

    public init(provider: any ConfigFileProvider) {
        self.provider = provider
    }

    /// Loads configuration with cascading priority (~/.zagorc -> ./.zagorc -> ~/.serc -> ./.serc).
    public func loadConfig() -> EditorConfig {
        var config = EditorConfig()
        let homeDir = provider.homeDirectoryPath()
        let globalZagorc = (homeDir as NSString).appendingPathComponent(".zagorc")
        let globalSerc = (homeDir as NSString).appendingPathComponent(".serc")
        if provider.fileExists(atPath: globalZagorc) {
            parseConfigFile(at: globalZagorc, into: &config)
        } else if provider.fileExists(atPath: globalSerc) {
            parseConfigFile(at: globalSerc, into: &config)
        }

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

    public func parseConfigFile(at path: String, into config: inout EditorConfig) {
        do {
            let content = try provider.readString(atPath: path)
            config.loadedFilePath = path
            parseConfigContent(content, into: &config)
        } catch {
            // An unreadable optional config file is ignored.
        }
    }

    public func parseConfigContent(_ content: String, into config: inout EditorConfig) {
        var logoBlock: LogoBlock?

        for rawLine in content.components(separatedBy: .newlines) {
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

            let tokens = line.split(separator: " ", maxSplits: 2).map(String.init)
            guard let commandText = tokens.first else { continue }

            if let command = ConfigCommand(rawValue: commandText.lowercased()) {
                switch command {
                case .set:
                    guard tokens.count >= 2 else {
                        recordSyntaxError(in: &config)
                        continue
                    }
                    let value = tokens.count >= 3 ? tokens[2] : ""
                    applyOption(named: tokens[1], value: value, into: &config)
                case .unset:
                    guard tokens.count >= 2 else {
                        recordSyntaxError(in: &config)
                        continue
                    }
                    applyUnset(tokens[1], into: &config)
                case .bind:
                    guard tokens.count >= 3, let key = KeyParser.parse(tokens[1]) else {
                        recordSyntaxError(in: &config)
                        continue
                    }
                    config.customKeyBinds[key] = Self.unquote(tokens[2])
                    config.unbindKeys.remove(key)
                case .unbind:
                    guard tokens.count >= 2, let key = KeyParser.parse(tokens[1]) else {
                        recordSyntaxError(in: &config)
                        continue
                    }
                    config.unbindKeys.insert(key)
                    config.customKeyBinds.removeValue(forKey: key)
                case .logoScript:
                    guard tokens.count >= 2 else {
                        recordSyntaxError(in: &config)
                        continue
                    }
                    logoBlock = .script(name: tokens[1], lines: [])
                case .logo:
                    logoBlock = tokens.count >= 2 ? .script(name: tokens[1], lines: []) : .prelude(lines: [])
                case .logoPrelude:
                    guard tokens.count == 1 else {
                        recordSyntaxError(in: &config)
                        continue
                    }
                    logoBlock = .prelude(lines: [])
                }
            } else {
                recordSyntaxError(in: &config)
            }
        }

        if logoBlock != nil { recordSyntaxError(in: &config) }
    }

    private func applyOption(named name: String, value: String, into config: inout EditorConfig) {
        guard let option = EditorSettingKey(rawValue: name.lowercased()) else {
            recordSyntaxError(in: &config)
            return
        }
        apply(option, value: value, into: &config)
    }

    private func apply(_ option: EditorSettingKey, value rawValue: String, into config: inout EditorConfig) {
        let value = rawValue.lowercased()
        switch option {
        case .wrap:
            if let width = Int(value), width > 0 {
                config.wrapColumn = EditorConfig.normalizedWrapColumn(width)
            } else if ["false", "off", "none"].contains(value) {
                config.wrapColumn = nil
            } else {
                recordSyntaxError(in: &config)
            }
        case .ruler, .lineNumbers, .subLineNumbers, .canvasMode, .syntax, .smartTab,
            .listWrapIndent, .autoReload, .ipc, .trimTrailingWhitespace, .gitDiff, .debug:
            guard let boolean = SettingBoolean.parse(value, emptyValue: true) else {
                recordSyntaxError(in: &config)
                return
            }
            switch option {
            case .ruler: config.showRuler = boolean
            case .lineNumbers: config.showLineNumbers = boolean
            case .subLineNumbers: config.showSubLineNumbers = boolean
            case .canvasMode: config.startInCanvasMode = boolean
            case .syntax: config.enableSyntaxHighlight = boolean
            case .smartTab: config.smartTab = boolean
            case .listWrapIndent: config.listWrapIndent = boolean
            case .autoReload: config.autoReload = boolean
            case .ipc: config.ipcEnabled = boolean
            case .trimTrailingWhitespace: config.trimTrailingWhitespaceOnSave = boolean
            case .gitDiff: config.showGitDiff = boolean
            case .debug: config.debugMode = boolean
            default: break
            }
        case .listIndentSize:
            guard let size = Int(value), size > 0 else {
                recordSyntaxError(in: &config)
                return
            }
            config.listIndentSize = size
        case .tab:
            guard let size = Int(value), size > 0 else {
                recordSyntaxError(in: &config)
                return
            }
            config.tabSize = size
        case .language:
            guard let language = Language(settingValue: rawValue) else {
                recordSyntaxError(in: &config)
                return
            }
            config.language = language
        case .spellLanguage:
            guard !value.isEmpty else {
                recordSyntaxError(in: &config)
                return
            }
            config.spellLanguage = value
        case .border:
            guard let style = BorderStyle(value) else {
                recordSyntaxError(in: &config)
                return
            }
            config.defaultBorderStyle = style
        case .arrow:
            guard let style = ArrowStyle(value) else {
                recordSyntaxError(in: &config)
                return
            }
            config.defaultArrowStyle = style
        case .regex:
            recordSyntaxError(in: &config)
        }
    }

    private func applyUnset(_ name: String, into config: inout EditorConfig) {
        guard let option = EditorSettingKey(rawValue: name.lowercased()), option.supportsConfigUnset else {
            recordSyntaxError(in: &config)
            return
        }
        if option == .wrap {
            config.wrapColumn = nil
        } else {
            apply(option, value: "off", into: &config)
        }
    }

    private func recordSyntaxError(in config: inout EditorConfig) {
        config.syntaxErrorCount += 1
    }

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

    private static func append(rawLine: String, to block: LogoBlock) -> LogoBlock {
        if rawLine.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#") { return block }
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
        case .prelude(let lines): appendLogoPrelude(lines.joined(separator: "\n"), into: &config)
        case .script(let name, let lines):
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return }
            config.logoScripts[trimmedName] = lines.joined(separator: "\n")
        }
    }

    private func appendLogoPrelude(_ script: String, into config: inout EditorConfig) {
        let trimmed = script.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        config.logoPrelude = config.logoPrelude.isEmpty ? trimmed : config.logoPrelude + "\n" + trimmed
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
