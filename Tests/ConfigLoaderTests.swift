import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import Syntax

@Suite(.serialized)
struct ConfigLoaderTests {
    struct TestLocalConfigFileProvider: ConfigFileProvider {
        init() {}
        func homeDirectoryPath() -> String { FileManager.default.homeDirectoryForCurrentUser.path }
        func currentDirectoryPath() -> String { FileManager.default.currentDirectoryPath }
        func fileExists(atPath path: String) -> Bool { FileManager.default.fileExists(atPath: path) }
        func readString(atPath path: String) throws -> String { try String(contentsOfFile: path, encoding: .utf8) }
        func writeString(_ content: String, toPath path: String) throws {
            try content.write(toFile: path, atomically: false, encoding: .utf8)
        }
    }

    @Test func testInMemoryConfigFileProviderAndWasmAbstraction() throws {
        let mockProvider = InMemoryConfigFileProvider(
            homePath: "/home/wasm",
            currentPath: "/home/wasm",
            files: [
                "/home/wasm/.zagorc": """
                set wrap 100
                set tab 2
                set ruler on
                set syntax off
                set trim-trailing-whitespace on
                """
            ]
        )

        let loader = ConfigLoader(provider: mockProvider)
        let config = loader.loadConfig()

        #expect(config.wrapColumn == 100)
        #expect(config.tabSize == 2)
        #expect(config.showRuler == true)
        #expect(config.enableSyntaxHighlight == false)
        #expect(config.trimTrailingWhitespaceOnSave == true)
        #expect(config.loadedFilePath == "/home/wasm/.zagorc")
    }

    @Test func testConfigLoaderDirectivesAndLogoBlocks() throws {
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent(
            "test_zagorc_directives_\(UUID().uuidString)"
        ).path
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let configContent = """
            # Sample config file
            set wrap 80
            set ruler on
            set linenumbers off
            set sublinenumbers on
            set canvas-mode on
            set border double
            set spell-language en
            set trim-trailing-whitespace on
            set auto-reload on

            unset wrap
            unset ruler
            unset linenumbers
            unset canvas-mode

            bind Ctrl+A move-home
            unbind Ctrl+A

            logo-prelude
            MAKE "globalVar 123
            endlogo

            logo-script customMacro
            PRINT "MacroExecuted
            endlogo
            """

        try configContent.write(to: URL(fileURLWithPath: tmpFile), atomically: testAtomicallyOption, encoding: .utf8)

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        loader.parseConfigFile(at: tmpFile, into: &config)

        #expect(config.loadedFilePath == tmpFile)
        #expect(config.defaultBorderStyle == .double)
        #expect(config.spellLanguage == "en")
        #expect(config.trimTrailingWhitespaceOnSave == true)
        #expect(config.autoReload == true)
        #expect(config.logoPrelude.contains("MAKE \"globalVar 123"))
    }

    @Test func testGenerateDefaultConfigFile() throws {
        let provider = InMemoryConfigFileProvider(homePath: "/home/user", currentPath: "/home/user")
        let generatedPath = try ConfigLoader.generateDefaultConfigFile(
            targetPath: "/home/user/.zagorc", provider: provider)
        #expect(provider.fileExists(atPath: generatedPath) == true)

        let content = try provider.readString(atPath: generatedPath)
        #expect(content.contains("set wrap 80"))
        #expect(content.contains("set fill 72"))
        #expect(content.contains("set ruler on"))
        #expect(content.contains("set linenumbers on"))
        #expect(content.contains("set sublinenumbers off"))
        #expect(content.contains("set tab 4"))
        #expect(content.contains("set smarttab on"))
        #expect(content.contains("set list-indent-size 2"))
        #expect(content.contains("set list-wrap-indent on"))
        #expect(content.contains("set autoreload on"))
        #expect(content.contains("set trim-trailing-whitespace off"))
        #expect(content.contains("set nonewlines off"))
        #expect(content.contains("set git-diff on"))
        #expect(content.contains("set border single"))
        #expect(content.contains("set arrow solid"))
        #expect(content.contains("set keymap classic"))
        #expect(content.contains("# bind ^T search.find"))
        #expect(content.contains("# logo-prelude"))
        #expect(content.contains("# logo-script insert-title"))
        #expect(content.contains("# bind alt-t logo:insert-title"))

        var config = EditorConfig()
        ConfigLoader(provider: provider).parseConfigFile(at: generatedPath, into: &config)
        #expect(config.syntaxErrorCount == 0)
    }

    @Test func testConfigLoaderAndKeyParser() throws {
        let parsedCtrlF = KeyParser.parse("ctrl-f")
        #expect(parsedCtrlF == .ctrl("f"))

        let parsedAltDot = KeyParser.parse("alt-.")
        #expect(parsedAltDot == .alt("."))

        let parsedMetaComma = KeyParser.parse("m-,")
        #expect(parsedMetaComma == .alt(","))

        let parsedF1 = KeyParser.parse("f1")
        #expect(parsedF1 == .f1)

        let parsedUp = KeyParser.parse("up")
        #expect(parsedUp == .arrowUp)
        #expect(KeyParser.parse("shift-home") == .shiftHome)
        #expect(KeyParser.parse("shift-end") == .shiftEnd)
        #expect(KeyParser.parse("ctrl-shift-right") == .ctrlShiftArrowRight)
        #expect(KeyParser.parse("ctrl-shift-arrow-left") == .ctrlShiftArrowLeft)

        let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID().uuidString).serc")
            .path
        let sampleConfig = """
            # Sample serc configuration
            set wrap 80
            set ruler true
            set linenumbers off
            set sublinenumbers on
            set canvas-mode on
            set autoreload true
            set trim-trailing-whitespace on
            bind ctrl-f move.left
            bind alt-h "logo: MOVE HOME TYPE '# ' MOVE END"
            logo-prelude
              MAKE "boxWidth 30
              TO FILLBOX :text
                BOX :boxWidth 4
                MOVE LEFT (:boxWidth - 1) MOVE UP 2
                FILL :text
              END
            endlogo
            logo-script insert-title
              BOX 40 3 ROUND
              MOVE LEFT 38 MOVE UP 1
              FILL "-
            endlogo
            unbind f1
            invalid syntax line
            """
        try sampleConfig.write(to: URL(fileURLWithPath: tmpPath), atomically: testAtomicallyOption, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmpPath) }

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        loader.parseConfigFile(at: tmpPath, into: &config)

        #expect(config.wrapColumn == 80)
        #expect(config.showRuler == true)
        #expect(config.showLineNumbers == false)
        #expect(config.showSubLineNumbers == true)
        #expect(config.startInCanvasMode == true)
        #expect(config.autoReload == true)
        #expect(config.trimTrailingWhitespaceOnSave == true)
        #expect(config.customKeyBinds[.ctrl("f")] == "move.left")
        #expect(config.customKeyBinds[.alt("h")] == "logo: MOVE HOME TYPE '# ' MOVE END")
        #expect(config.unbindKeys.contains(.f1))
        #expect(config.logoPrelude.contains("MAKE \"boxWidth 30"))
        #expect(config.logoPrelude.contains("TO FILLBOX :text"))
        #expect(config.logoScripts["insert-title"]?.contains("BOX 40 3 ROUND") == true)
        #expect(config.syntaxErrorCount == 1)
    }

    @Test func testSettingCommandSuggestionsUseCanonicalNames() throws {
        #expect(SettingCommand.settingNames.contains("sublinenumbers"))
        #expect(SettingCommand.valueSuggestions(for: "sublinenumbers") == ["on", "off"])
        #expect(SettingCommand.settingNames.contains("canvas-mode"))
        #expect(SettingCommand.valueSuggestions(for: "canvas-mode") == ["on", "off"])
        #expect(SettingCommand.settingNames.contains("trim-trailing-whitespace"))
        #expect(SettingCommand.valueSuggestions(for: "trim-trailing-whitespace") == ["on", "off"])
        #expect(EditorSettingUpdateParser.parse(setting: "sublines", value: "on") == nil)

        let editor = Editor()
        #expect(editor.displayConfig.showSubLineNumbers == false)

        editor.apply(.subLineNumbers(true))
        #expect(editor.displayConfig.showSubLineNumbers == true)

        editor.apply(.subLineNumbers(false))
        #expect(editor.displayConfig.showSubLineNumbers == false)

        editor.apply(.canvasMode(true))
        #expect(editor.isCanvasModeActive == true)

        editor.apply(.canvasMode(false))
        #expect(editor.isCanvasModeActive == false)

        editor.apply(.trimTrailingWhitespace(true))
        #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == true)

        editor.apply(.trimTrailingWhitespace(false))
        #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == false)
    }

    @Test func testWrapColumnMinimumIsTen() throws {
        let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent(
            "test_min_wrap_\(UUID().uuidString).serc"
        ).path
        let sampleConfig = "set wrap 4\n"
        try sampleConfig.write(to: URL(fileURLWithPath: tmpPath), atomically: testAtomicallyOption, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmpPath) }

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        loader.parseConfigFile(at: tmpPath, into: &config)

        #expect(config.wrapColumn == 10)

        let engine = LayoutEngine(wrapColumn: 4)
        #expect(engine.wrapColumn == 10)
    }

    @Test func testNanoRCParser() throws {
        let rawPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_\(UUID().uuidString).nanorc").path
        let tmpNanoRC = TestLocalEditorFileIOStrategy().normalizePath(rawPath, isDirectory: false)
        let content = """
            # Sample nanorc file
            syntax "customlang" "\\.custom$"
            header "^#!custom"
            magic "custom file"
            linter custom-lint --check
            color cyan "\\b(foo|bar)\\b"
            color green "\"([^\"]*)\""
            """
        try content.write(to: URL(fileURLWithPath: tmpNanoRC), atomically: testAtomicallyOption, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmpNanoRC) }

        let highlighter = SyntaxHighlighter()
        highlighter.parseNanoRCFile(at: tmpNanoRC)

        let customLang = highlighter.detectLanguage(for: "file.custom")
        #expect(customLang != nil)
        #expect(customLang?.name == "customlang")
        #expect(customLang?.headerRules.count == 1)
        #expect(customLang?.magicRules.count == 1)
        #expect(customLang?.linterCommand == ["custom-lint", "--check"])
    }

    @Test func testZagorcIncludesNanoRCSyntaxDefinitions() throws {
        let provider = InMemoryConfigFileProvider(
            files: [
                "/home/user/.zagorc": "include \"~/.nano/custom.nanorc\"\n",
                "/home/user/.nano/custom.nanorc": """
                syntax "customlang" "\\.custom$"
                color cyan "\\b(foo|bar)\\b"
                """,
            ])
        let loader = ConfigLoader(provider: provider)
        var config = EditorConfig()
        loader.parseConfigFile(at: "/home/user/.zagorc", into: &config)

        #expect(config.syntaxErrorCount == 0)
        #expect(config.nanoRCContent.contains("syntax \"customlang\""))

        let highlighter = SyntaxHighlighter()
        highlighter.loadNanoRCContent(config.nanoRCContent)
        #expect(highlighter.detectLanguage(for: "file.custom")?.name == "customlang")
    }

    @Test func testDefaultBorderStyleConfig() throws {
        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        let configContent = """
            set border triple-dash
            """
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(
            "test_border_config_\(UUID().uuidString).zagorc"
        ).path
        try configContent.write(to: URL(fileURLWithPath: tempFile), atomically: testAtomicallyOption, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        loader.parseConfigFile(at: tempFile, into: &config)
        #expect(config.defaultBorderStyle == .tripleDash)

        let editor = Editor()
        editor.apply(.border(.double, rawValue: "double"))
        #expect(editor.defaultBorderStyle == .double)
    }

    @Test func testZagorcCommentSyntaxHighlighting() throws {
        let highlighter = SyntaxHighlighter()
        guard let syntax = highlighter.detectLanguage(for: ".zagorc") else {
            Issue.record("Should detect syntax for .zagorc")
            return
        }

        #expect(syntax.name == "Zagorc")

        let commentTokens = highlighter.tokenTypes(for: "# set wrap 80", syntax: syntax)
        #expect(commentTokens.allSatisfy { $0 == .comment })

        let commentedPreludeTokens = highlighter.tokenTypes(for: "#   MAKE \"boxWidth 30", syntax: syntax)
        #expect(commentedPreludeTokens.allSatisfy { $0 == .comment })

        let commentedVariableTokens = highlighter.tokenTypes(for: "#     FILL :text", syntax: syntax)
        #expect(commentedVariableTokens.allSatisfy { $0 == .comment })

        let codeTokens = highlighter.tokenTypes(for: "MAKE \"i\" 80", syntax: syntax)
        #expect(codeTokens.contains(.keyword))
        #expect(codeTokens.contains(.number))
    }

    @Test func testConfigLoaderParsesCanonicalSettingsAndUnset() throws {
        let testDir =
            FileManager.default.currentDirectoryPath + "/.test-artifacts/config-loader-aliases-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: testDir, withIntermediateDirectories: true, attributes: nil)
        let configPath = testDir + "/aliases.zagorc"
        defer { try? FileManager.default.removeItem(atPath: testDir) }

        let content = """
            # Canonical settings and unset directives
            set wrap 12
            set wrap off
            set wrap 9
            unset wrap
            set ruler on
            unset ruler
            set linenumbers on
            unset linenumbers
            set sublinenumbers on
            unset sublinenumbers
            set canvas-mode on
            unset canvas-mode
            set git-diff on
            unset git-diff
            set tab 8
            set syntax on
            set autoreload off
            set trim-trailing-whitespace on
            set lang zh_TW
            set spell-language en_GB
            set border heavy
            """
        try content.write(to: URL(fileURLWithPath: configPath), atomically: testAtomicallyOption, encoding: .utf8)

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        loader.parseConfigFile(at: configPath, into: &config)

        #expect(config.loadedFilePath == configPath)
        #expect(config.wrapColumn == nil)
        #expect(config.showRuler == false)
        #expect(config.showLineNumbers == false)
        #expect(config.showSubLineNumbers == false)
        #expect(config.startInCanvasMode == false)
        #expect(config.showGitDiff == false)
        #expect(config.tabSize == 8)
        #expect(config.enableSyntaxHighlight == true)
        #expect(config.autoReload == false)
        #expect(config.trimTrailingWhitespaceOnSave == true)
        #expect(config.language == .zh_TW)
        #expect(config.spellLanguage == "en_gb")
        #expect(config.defaultBorderStyle == .heavy)
        #expect(config.syntaxErrorCount == 0)
    }

    @Test func testConfigLoaderRejectsSettingAliasesAndBareSettings() {
        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()

        loader.parseConfigContent(
            """
            set showRuler on
            set language english
            ruler on
            """,
            into: &config
        )

        #expect(config.showRuler == false)
        #expect(config.language == nil)
        #expect(config.syntaxErrorCount == 3)
    }

    @Test func testConfigLoaderReportsMalformedAndUnknownDirectives() throws {
        let testDir =
            FileManager.default.currentDirectoryPath + "/.test-artifacts/config-loader-errors-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: testDir, withIntermediateDirectories: true, attributes: nil)
        let configPath = testDir + "/errors.zagorc"
        defer { try? FileManager.default.removeItem(atPath: testDir) }

        let content = """
            # Every non-comment directive below should count as a syntax error.
            set
            set wrap zero
            set ruler maybe
            set linenumbers maybe
            set sublinenumbers maybe
            set canvas-mode maybe
            set git-diff maybe
            set tab 0
            set unset nope
            set syntax maybe
            set autoreload maybe
            set trim-trailing-whitespace maybe
            set lang klingon
            set spell-language
            set border bubble
            set mystery on
            unset
            unset nope
            bind
            bind nope cmd.run
            unbind
            unbind nope
            logo-prelude extra
            logo-script
            border bubble
            endlogo
            unknown directive
            logo-script named
              PRINT "unterminated
            """
        try content.write(to: URL(fileURLWithPath: configPath), atomically: testAtomicallyOption, encoding: .utf8)

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        loader.parseConfigFile(at: configPath, into: &config)

        #expect(config.loadedFilePath == configPath)
        #expect(config.syntaxErrorCount == 28)
        #expect(config.wrapColumn == nil)
        #expect(config.tabSize == 4)
        #expect(config.spellLanguage == "en_US")
        #expect(config.defaultBorderStyle == .single)
        #expect(config.logoPrelude.isEmpty)
        #expect(config.logoScripts["named"] == nil)
        #expect(config.customKeyBinds.isEmpty)
        #expect(config.unbindKeys.isEmpty)
    }

    @Test func testConfigLoaderHandlesLogoBlocksCommentsWhitespaceAndQuotedBindings() throws {
        let testDir =
            FileManager.default.currentDirectoryPath + "/.test-artifacts/config-loader-logo-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: testDir, withIntermediateDirectories: true, attributes: nil)
        let configPath = testDir + "/logo.zagorc"
        defer { try? FileManager.default.removeItem(atPath: testDir) }

        let content = """
              
              # Leading comment with indentation
              bind ctrl-y 'logo: MOVE HOME TYPE "# " MOVE END'
              bind alt-k "macro.run"
              unbind shift-home

              logo-prelude
                # ignored inside prelude
                MAKE "boxWidth 30
                PRINT :boxWidth
              endlogo

              logo-script  insert-title
                # ignored inside script
                BOX 40 3 ROUND
                MOVE LEFT 38 MOVE UP 1
              endlogo

              logo-prelude
                PRINT "SECOND
              endlogo
            """
        try content.write(to: URL(fileURLWithPath: configPath), atomically: testAtomicallyOption, encoding: .utf8)

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        loader.parseConfigFile(at: configPath, into: &config)

        #expect(config.syntaxErrorCount == 0)
        #expect(config.customKeyBinds[.ctrl("y")] == "logo: MOVE HOME TYPE \"# \" MOVE END")
        #expect(config.customKeyBinds[.alt("k")] == "macro.run")
        #expect(config.unbindKeys.contains(.shiftHome))
        #expect(config.logoPrelude.contains("MAKE \"boxWidth 30"))
        #expect(config.logoPrelude.contains("PRINT :boxWidth"))
        #expect(config.logoPrelude.contains("PRINT \"SECOND"))
        #expect(!config.logoPrelude.contains("ignored inside prelude"))
        #expect(config.logoScripts["insert-title"]?.contains("BOX 40 3 ROUND") == true)
        #expect(config.logoScripts["insert-title"]?.contains("MOVE LEFT 38 MOVE UP 1") == true)
        #expect(config.logoScripts["insert-title"]?.contains("ignored inside script") == false)
    }

    @Test func testConfigLoaderSkipsWhitespaceCommentsAndEmptyFiles() throws {
        let testDir =
            FileManager.default.currentDirectoryPath + "/.test-artifacts/config-loader-empty-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: testDir, withIntermediateDirectories: true, attributes: nil)
        let configPath = testDir + "/empty.zagorc"
        defer { try? FileManager.default.removeItem(atPath: testDir) }

        let content = """

             
               # comment with leading spaces

            # plain comment

            """
        try content.write(to: URL(fileURLWithPath: configPath), atomically: testAtomicallyOption, encoding: .utf8)

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
        var config = EditorConfig()
        loader.parseConfigFile(at: configPath, into: &config)

        #expect(config.loadedFilePath == configPath)
        #expect(config.syntaxErrorCount == 0)
        #expect(config.wrapColumn == nil)
        #expect(config.showRuler == false)
        #expect(config.showLineNumbers == true)
        #expect(config.showSubLineNumbers == false)
        #expect(config.logoPrelude.isEmpty)
        #expect(config.logoScripts.isEmpty)
        #expect(config.customKeyBinds.isEmpty)
    }

    @Test func testConfigLoaderLoadConfigPrefersLocalZagorcThenLegacySerc() throws {
        let repoRoot = FileManager.default.currentDirectoryPath
        let localZagorc = repoRoot + "/.zagorc"
        let localSerc = repoRoot + "/.serc"
        let backupDir = repoRoot + "/.test-artifacts/config-loader-load-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: backupDir, withIntermediateDirectories: true, attributes: nil)

        let backupZagorc = backupDir + "/.zagorc.backup"
        let backupSerc = backupDir + "/.serc.backup"
        let hadLocalZagorc = FileManager.default.fileExists(atPath: localZagorc)
        let hadLocalSerc = FileManager.default.fileExists(atPath: localSerc)

        if hadLocalZagorc {
            try FileManager.default.moveItem(atPath: localZagorc, toPath: backupZagorc)
        }
        if hadLocalSerc {
            try FileManager.default.moveItem(atPath: localSerc, toPath: backupSerc)
        }

        defer {
            try? FileManager.default.removeItem(atPath: localZagorc)
            try? FileManager.default.removeItem(atPath: localSerc)
            if hadLocalZagorc {
                try? FileManager.default.moveItem(atPath: backupZagorc, toPath: localZagorc)
            }
            if hadLocalSerc {
                try? FileManager.default.moveItem(atPath: backupSerc, toPath: localSerc)
            }
            try? FileManager.default.removeItem(atPath: backupDir)
        }

        try """
        set wrap 71
        set border double
        """.write(to: URL(fileURLWithPath: localZagorc), atomically: testAtomicallyOption, encoding: .utf8)
        try """
        set wrap 55
        set border heavy
        """.write(to: URL(fileURLWithPath: localSerc), atomically: testAtomicallyOption, encoding: .utf8)

        let loader = ConfigLoader(provider: TestLocalConfigFileProvider())

        let zagorcConfig = loader.loadConfig()
        #expect(zagorcConfig.loadedFilePath == localZagorc)
        #expect(zagorcConfig.wrapColumn == 71)
        #expect(zagorcConfig.defaultBorderStyle == .double)

        try FileManager.default.removeItem(atPath: localZagorc)

        let sercConfig = loader.loadConfig()
        #expect(sercConfig.loadedFilePath == localSerc)
        #expect(sercConfig.wrapColumn == 55)
        #expect(sercConfig.defaultBorderStyle == .heavy)
    }

    @Test func testConfigLoaderDoesNotParseSameHomeAndCurrentZagorcTwice() {
        let provider = InMemoryConfigFileProvider(
            homePath: "/home/user",
            currentPath: "/home/user",
            files: [
                "/home/user/.zagorc": """
                set wrap 72
                set invalid-setting on
                """
            ]
        )

        let config = ConfigLoader(provider: provider).loadConfig()
        #expect(config.wrapColumn == 72)
        #expect(config.syntaxErrorCount == 1)
    }
}
