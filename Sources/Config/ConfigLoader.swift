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
        var loadedPaths: Set<String> = []
        let homeDir = provider.homeDirectoryPath()
        let globalZagorc = (homeDir as NSString).appendingPathComponent(".zagorc")
        let globalSerc = (homeDir as NSString).appendingPathComponent(".serc")
        if provider.fileExists(atPath: globalZagorc) {
            parseConfigFile(at: globalZagorc, into: &config, loadedPaths: &loadedPaths)
        } else if provider.fileExists(atPath: globalSerc) {
            parseConfigFile(at: globalSerc, into: &config, loadedPaths: &loadedPaths)
        }

        let currentDir = provider.currentDirectoryPath()
        let localZagorc = (currentDir as NSString).appendingPathComponent(".zagorc")
        let localSerc = (currentDir as NSString).appendingPathComponent(".serc")
        if provider.fileExists(atPath: localZagorc) {
            parseConfigFile(at: localZagorc, into: &config, loadedPaths: &loadedPaths)
        } else if provider.fileExists(atPath: localSerc) {
            parseConfigFile(at: localSerc, into: &config, loadedPaths: &loadedPaths)
        }
        return config
    }

    public func parseConfigFile(at path: String, into config: inout EditorConfig) {
        do {
            let content = try provider.readString(atPath: path)
            config.loadedFilePath = path
            parseConfigContent(content, from: path, into: &config, visitedIncludes: [path])
        } catch {
            // An unreadable optional config file is ignored.
        }
    }

    private func parseConfigFile(at path: String, into config: inout EditorConfig, loadedPaths: inout Set<String>) {
        let standardizedPath = (path as NSString).standardizingPath
        guard loadedPaths.insert(standardizedPath).inserted else { return }
        parseConfigFile(at: path, into: &config)
    }

    public func parseConfigContent(_ content: String, into config: inout EditorConfig) {
        parseConfigContent(content, from: nil, into: &config, visitedIncludes: [])
    }

    private func parseConfigContent(
        _ content: String,
        from sourcePath: String?,
        into config: inout EditorConfig,
        visitedIncludes: Set<String>
    ) {
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

            if Self.isNanoRCDirective(line) {
                appendNanoRCDirective(
                    line, from: sourcePath, into: &config, visitedIncludes: visitedIncludes)
                continue
            }

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
                    let rest = tokens[2].trimmingCharacters(in: .whitespaces)
                    let validModes: Set<String> = ["text", "canvas", "table", "prompt", "menu"]
                    let parts = rest.split(whereSeparator: \.isWhitespace).map(String.init)
                    if parts.count >= 2, let lastPart = parts.last?.lowercased(), validModes.contains(lastPart) {
                        let targetPart = rest.dropLast(lastPart.count).trimmingCharacters(in: .whitespaces)
                        let target = Self.unquote(targetPart)
                        var map = config.customModeKeyBinds[lastPart, default: [:]]
                        map[key] = target
                        config.customModeKeyBinds[lastPart] = map
                    } else {
                        config.customKeyBinds[key] = Self.unquote(rest)
                    }
                    config.unbindKeys.remove(key)
                case .unbind:
                    let rawTokens = line.split(whereSeparator: \.isWhitespace).map(String.init)
                    guard rawTokens.count >= 2, let key = KeyParser.parse(rawTokens[1]) else {
                        recordSyntaxError(in: &config)
                        continue
                    }
                    if rawTokens.count >= 3 {
                        let mode = rawTokens[2].lowercased()
                        config.customModeKeyBinds[mode]?.removeValue(forKey: key)
                    } else {
                        config.unbindKeys.insert(key)
                        config.customKeyBinds.removeValue(forKey: key)
                        for m in config.customModeKeyBinds.keys {
                            config.customModeKeyBinds[m]?.removeValue(forKey: key)
                        }
                    }
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

    private static func isNanoRCDirective(_ line: String) -> Bool {
        ["include ", "syntax ", "color ", "icolor ", "comment ", "header ", "magic ", "linter "].contains {
            line.lowercased().hasPrefix($0)
        }
    }

    private func appendNanoRCDirective(
        _ line: String,
        from sourcePath: String?,
        into config: inout EditorConfig,
        visitedIncludes: Set<String>
    ) {
        guard line.lowercased().hasPrefix("include ") else {
            config.nanoRCContent += line + "\n"
            return
        }

        let rawPath = line.dropFirst("include ".count)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\" '"))
        let includePath = provider.resolvePath(String(rawPath), relativeTo: sourcePath)

        guard !visitedIncludes.contains(includePath),
            let included = try? provider.readString(atPath: includePath)
        else {
            // Preserve wildcard or platform-specific includes for NanoRCParser.
            config.nanoRCContent += line + "\n"
            return
        }

        var nextVisited = visitedIncludes
        nextVisited.insert(includePath)
        parseConfigContent(included, from: includePath, into: &config, visitedIncludes: nextVisited)
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
        case .keymap:
            if ["classic", "nano", "default"].contains(value) {
                config.keymapPreset = "classic"
            } else if ["modern", "vscode", "cua"].contains(value) {
                config.keymapPreset = "modern"
            } else {
                recordSyntaxError(in: &config)
            }
        case .modernbindings:
            if SettingBoolean.parse(value, emptyValue: true) == true {
                config.keymapPreset = "modern"
            } else if SettingBoolean.parse(value, emptyValue: true) == false {
                config.keymapPreset = "classic"
            } else {
                recordSyntaxError(in: &config)
            }
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
            set autoreload on
            set trim-trailing-whitespace off
            set border single
            set arrow solid

            # Interface Language
            # set lang en

            # Spell Checker Language
            # set spell-language en_US

            # Custom Key Bindings
            # bind <key> <command_id_or_macro>
            # bind ^T search.find
            # bind alt-t table.toggle
            # bind alt-h logo:MOVE HOME TYPE "# " MOVE END
            # unbind ^K

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

            # On macOS, you can install `nanorc` and include its syntax definitions 
            # for additional highlighting.

            # include "/opt/homebrew/share/nanorc/apacheconf.nanorc"
            # include "/opt/homebrew/share/nanorc/arduino.nanorc"
            # include "/opt/homebrew/share/nanorc/asciidoc.nanorc"
            # include "/opt/homebrew/share/nanorc/asm.nanorc"
            # include "/opt/homebrew/share/nanorc/awk.nanorc"
            # include "/opt/homebrew/share/nanorc/batch.nanorc"
            # include "/opt/homebrew/share/nanorc/c.nanorc"
            # include "/opt/homebrew/share/nanorc/clojure.nanorc"
            # include "/opt/homebrew/share/nanorc/cmake.nanorc"
            # include "/opt/homebrew/share/nanorc/coffeescript.nanorc"
            # include "/opt/homebrew/share/nanorc/colortest.nanorc"
            # include "/opt/homebrew/share/nanorc/conf.nanorc"
            # include "/opt/homebrew/share/nanorc/conky.nanorc"
            # include "/opt/homebrew/share/nanorc/creole.nanorc"
            # include "/opt/homebrew/share/nanorc/csh.nanorc"
            # include "/opt/homebrew/share/nanorc/csharp.nanorc"
            # include "/opt/homebrew/share/nanorc/css.nanorc"
            # include "/opt/homebrew/share/nanorc/csv.nanorc"
            # include "/opt/homebrew/share/nanorc/cython.nanorc"
            # include "/opt/homebrew/share/nanorc/Dockerfile.nanorc"
            # include "/opt/homebrew/share/nanorc/dot.nanorc"
            # include "/opt/homebrew/share/nanorc/dotenv.nanorc"
            # include "/opt/homebrew/share/nanorc/elixir.nanorc"
            # include "/opt/homebrew/share/nanorc/email.nanorc"
            # include "/opt/homebrew/share/nanorc/erb.nanorc"
            # include "/opt/homebrew/share/nanorc/etc-hosts.nanorc"
            # include "/opt/homebrew/share/nanorc/fish.nanorc"
            # include "/opt/homebrew/share/nanorc/fortran.nanorc"
            # include "/opt/homebrew/share/nanorc/fsharp.nanorc"
            # include "/opt/homebrew/share/nanorc/gemini.nanorc"
            # include "/opt/homebrew/share/nanorc/genie.nanorc"
            # include "/opt/homebrew/share/nanorc/gentoo.nanorc"
            # include "/opt/homebrew/share/nanorc/git.nanorc"
            # include "/opt/homebrew/share/nanorc/gitcommit.nanorc"
            # include "/opt/homebrew/share/nanorc/glsl.nanorc"
            # include "/opt/homebrew/share/nanorc/go.nanorc"
            # include "/opt/homebrew/share/nanorc/gophermap.nanorc"
            # include "/opt/homebrew/share/nanorc/gradle.nanorc"
            # include "/opt/homebrew/share/nanorc/groff.nanorc"
            # include "/opt/homebrew/share/nanorc/haml.nanorc"
            # include "/opt/homebrew/share/nanorc/haskell.nanorc"
            # include "/opt/homebrew/share/nanorc/hcl.nanorc"
            # include "/opt/homebrew/share/nanorc/html.j2.nanorc"
            # include "/opt/homebrew/share/nanorc/html.nanorc"
            # include "/opt/homebrew/share/nanorc/i3.nanorc"
            # include "/opt/homebrew/share/nanorc/ical.nanorc"
            # include "/opt/homebrew/share/nanorc/ini.nanorc"
            # include "/opt/homebrew/share/nanorc/inputrc.nanorc"
            # include "/opt/homebrew/share/nanorc/jade.nanorc"
            # include "/opt/homebrew/share/nanorc/java.nanorc"
            # include "/opt/homebrew/share/nanorc/javascript.nanorc"
            # include "/opt/homebrew/share/nanorc/js.nanorc"
            # include "/opt/homebrew/share/nanorc/json.nanorc"
            # include "/opt/homebrew/share/nanorc/keymap.nanorc"
            # include "/opt/homebrew/share/nanorc/kickstart.nanorc"
            # include "/opt/homebrew/share/nanorc/kotlin.nanorc"
            # include "/opt/homebrew/share/nanorc/ledger.nanorc"
            # include "/opt/homebrew/share/nanorc/lisp.nanorc"
            # include "/opt/homebrew/share/nanorc/lua.nanorc"
            # include "/opt/homebrew/share/nanorc/m3u.nanorc"
            # include "/opt/homebrew/share/nanorc/makefile.nanorc"
            # include "/opt/homebrew/share/nanorc/man.nanorc"
            # include "/opt/homebrew/share/nanorc/markdown.nanorc"
            # include "/opt/homebrew/share/nanorc/moonscript.nanorc"
            # include "/opt/homebrew/share/nanorc/mpdconf.nanorc"
            # include "/opt/homebrew/share/nanorc/mutt.nanorc"
            # include "/opt/homebrew/share/nanorc/nanorc.nanorc"
            # include "/opt/homebrew/share/nanorc/nginx.nanorc"
            # include "/opt/homebrew/share/nanorc/nmap.nanorc"
            # include "/opt/homebrew/share/nanorc/ocaml.nanorc"
            # include "/opt/homebrew/share/nanorc/octave.nanorc"
            # include "/opt/homebrew/share/nanorc/patch.nanorc"
            # include "/opt/homebrew/share/nanorc/peg.nanorc"
            # include "/opt/homebrew/share/nanorc/perl.nanorc"
            # include "/opt/homebrew/share/nanorc/perl6.nanorc"
            # include "/opt/homebrew/share/nanorc/php.nanorc"
            # include "/opt/homebrew/share/nanorc/pkg-config.nanorc"
            # include "/opt/homebrew/share/nanorc/pkgbuild.nanorc"
            # include "/opt/homebrew/share/nanorc/po.nanorc"
            # include "/opt/homebrew/share/nanorc/pov.nanorc"
            # include "/opt/homebrew/share/nanorc/powershell.nanorc"
            # include "/opt/homebrew/share/nanorc/privoxy.nanorc"
            # include "/opt/homebrew/share/nanorc/prolog.nanorc"
            # include "/opt/homebrew/share/nanorc/properties.nanorc"
            # include "/opt/homebrew/share/nanorc/pug.nanorc"
            # include "/opt/homebrew/share/nanorc/puppet.nanorc"
            # include "/opt/homebrew/share/nanorc/python.nanorc"
            # include "/opt/homebrew/share/nanorc/reST.nanorc"
            # include "/opt/homebrew/share/nanorc/Rnw.nanorc"
            # include "/opt/homebrew/share/nanorc/rpmspec.nanorc"
            # include "/opt/homebrew/share/nanorc/ruby.nanorc"
            # include "/opt/homebrew/share/nanorc/rust.nanorc"
            # include "/opt/homebrew/share/nanorc/scala.nanorc"
            # include "/opt/homebrew/share/nanorc/sed.nanorc"
            # include "/opt/homebrew/share/nanorc/sh.nanorc"
            # include "/opt/homebrew/share/nanorc/sieve.nanorc"
            # include "/opt/homebrew/share/nanorc/sls.nanorc"
            # include "/opt/homebrew/share/nanorc/sparql.nanorc"
            # include "/opt/homebrew/share/nanorc/sql.nanorc"
            # include "/opt/homebrew/share/nanorc/svn.nanorc"
            # include "/opt/homebrew/share/nanorc/swift.nanorc"
            # include "/opt/homebrew/share/nanorc/systemd.nanorc"
            # include "/opt/homebrew/share/nanorc/tcl.nanorc"
            # include "/opt/homebrew/share/nanorc/tex.nanorc"
            # include "/opt/homebrew/share/nanorc/toml.nanorc"
            # include "/opt/homebrew/share/nanorc/ts.nanorc"
            # include "/opt/homebrew/share/nanorc/twig.nanorc"
            # include "/opt/homebrew/share/nanorc/vala.nanorc"
            # include "/opt/homebrew/share/nanorc/verilog.nanorc"
            # include "/opt/homebrew/share/nanorc/vi.nanorc"
            # include "/opt/homebrew/share/nanorc/x11basic.nanorc"
            # include "/opt/homebrew/share/nanorc/xml.nanorc"
            # include "/opt/homebrew/share/nanorc/xresources.nanorc"
            # include "/opt/homebrew/share/nanorc/yaml.nanorc"
            # include "/opt/homebrew/share/nanorc/yum.nanorc"
            # include "/opt/homebrew/share/nanorc/zig.nanorc"
            # include "/opt/homebrew/share/nanorc/zsh.nanorc"
            # include "/opt/homebrew/share/nanorc/zshrc.nanorc"
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
