import ArgumentParser
import Config
import Editor
import Foundation
import Git

@main
struct Zago: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "zago",
        abstract:
            "zago v\(ZagoVersion.current) - zonble's nano + Editor LOGO: A lightweight terminal text editor with powerful plain-text diagramming.",
        version: ZagoVersion.current
    )

    @Argument(help: "The file(s) to edit.")
    var files: [String] = []

    @Option(
        name: [.customShort("w"), .long],
        help: "Specify softwrap column width (e.g. 80). If omitted, softwrap adapts to terminal width.")
    var wrap: Int?

    @Flag(
        name: [.customShort("r"), .long],
        help:
            "Display a classic WordStar-style ruler bar (----!----1----!----2) above the text viewport.")
    var ruler: Bool = false

    @Option(
        name: [.customLong("linenumbers"), .customLong("line-numbers"), .customShort("l")],
        help: "Enable or disable line numbers (true/false).")
    var lineNumbers: String?

    @Option(
        name: [.customLong("sublinenumbers"), .customLong("sub-line-numbers")],
        help: "Enable or disable sub-line numbers for soft-wrapped lines (true/false).")
    var subLineNumbers: String?

    @Option(
        name: [.customLong("syntax")], help: "Enable or disable syntax highlighting (true/false).")
    var syntax: String?

    @Option(
        name: [.customLong("lang"), .customLong("language")], help: "Set interface language (en/zh_TW)."
    )
    var lang: String?

    @Option(
        name: [.customLong("spell-lang"), .customLong("spell-language")],
        help: "Set spell checker language (e.g. en_US, de_DE, fr_FR)."
    )
    var spellLang: String?

    @Flag(
        name: [.customShort("R"), .long],
        help: "Open file(s) in read-only mode.")
    var readonly: Bool = false

    @Flag(
        name: [.customLong("init"), .customLong("init-config"), .customLong("generate-config")],
        help: "Generate a default ~/.zagorc configuration file.")
    var initConfig: Bool = false

    @Option(
        name: [.customShort("e"), .customLong("eval")],
        help: "Execute inline LOGO code string in headless mode and print output to stdout.")
    var eval: String?

    @Option(
        name: [.customShort("s"), .customLong("run"), .customLong("script")],
        help: "Execute a LOGO script file in headless mode and print output to stdout.")
    var script: String?

    func run() throws {
        let fileIOStrategy = LocalEditorFileIOStrategy.shared
        let terminal = LocalTerminal()
        let gitService = GitService()
        let dependencies = EditorDependencies(
            fileIOStrategy: fileIOStrategy,
            terminal: terminal,
            gitService: gitService
        )
        let configProvider = { ConfigLoader(provider: LocalConfigFileProvider()).loadConfig() }
        let configSource = EditorConfigSource(initial: configProvider(), reload: configProvider)

        var rawFiles = files
        let (initialLine, initialColumn) = Self.parseInitialLineAndColumn(from: &rawFiles)

        if initConfig {
            let targetPath = rawFiles.first
            let generatedPath = try ConfigLoader.generateDefaultConfigFile(
                targetPath: targetPath, provider: LocalConfigFileProvider())
            terminal.write("Successfully generated default configuration file at: \(generatedPath)\n")
            return
        }
        let enableSyntax = Self.parseBoolOption(syntax)
        let enableLineNumbers = Self.parseBoolOption(lineNumbers)
        let enableSubLineNumbers = Self.parseBoolOption(subLineNumbers)
        let selectedLang = Self.parseLanguageOption(lang)

        var pipedInputData: String? = nil
        var targetFiles = rawFiles
        let isStdinPiped: Bool
        #if os(Windows)
        isStdinPiped = false
        #else
        if targetFiles == ["-"] {
            isStdinPiped = true
        } else if isatty(STDIN_FILENO) == 0 {
            var pfd = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
            isStdinPiped = poll(&pfd, 1, 0) > 0 && (pfd.revents & Int16(POLLIN)) != 0
        } else {
            isStdinPiped = false
        }
        #endif

        if isStdinPiped {
            if targetFiles == ["-"] { targetFiles = [] }
            let handle = FileHandle.standardInput
            let data = handle.readDataToEndOfFile()
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                pipedInputData = str
            }
        }

        let baseOptions = EditorOptions(
            filePaths: targetFiles,
            wrapColumn: wrap,
            showLineNumbers: enableLineNumbers,
            showSubLineNumbers: enableSubLineNumbers,
            language: selectedLang,
            spellLanguage: spellLang,
            initialLine: initialLine,
            initialColumn: initialColumn,
            readOnly: readonly,
            pipedInput: pipedInputData
        )
        var headlessOptions = baseOptions
        headlessOptions.showRuler = false
        headlessOptions.enableSyntax = false

        if let code = eval {
            let editor = Editor(
                options: headlessOptions,
                configSource: configSource,
                dependencies: dependencies
            )

            editor.runLogoScript(code)
            let output = editor.buffer.lines.joined(separator: "\n")
            terminal.write(output + "\n")
            return
        }

        if let scriptPath = script {
            let fileURL = URL(fileURLWithPath: scriptPath)
            do {
                let code = try String(contentsOf: fileURL, encoding: .utf8)
                let editor = Editor(
                    options: headlessOptions,
                    configSource: configSource,
                    dependencies: dependencies
                )
                editor.runLogoScript(code)
                let output = editor.buffer.lines.joined(separator: "\n")
                terminal.write(output + "\n")
                return
            } catch {
                if let data = "Error reading script file '\(scriptPath)': \(error.localizedDescription)\n".data(
                    using: .utf8)
                {
                    FileHandle.standardError.write(data)
                }
                throw ExitCode.failure
            }
        }

        if isStdinPiped {
            #if os(macOS) || os(Linux)
            if let ttyHandle = FileHandle(forReadingAtPath: "/dev/tty") {
                dup2(ttyHandle.fileDescriptor, STDIN_FILENO)
            }
            #endif
        }

        var interactiveOptions = baseOptions
        interactiveOptions.showRuler = ruler
        interactiveOptions.enableSyntax = enableSyntax

        for file in targetFiles {
            let normalized = fileIOStrategy.normalizePath(file, isDirectory: false)
            let info = fileIOStrategy.fileInfo(at: normalized)
            if info.exists && !info.isDirectory && info.isBinary {
                let name = (file as NSString).lastPathComponent
                if let data = "Error: '\(name)' is a binary file and cannot be opened.\n".data(using: .utf8) {
                    FileHandle.standardError.write(data)
                }
                throw ExitCode.failure
            }
        }

        let editor = Editor(
            options: interactiveOptions,
            configSource: configSource,
            dependencies: dependencies
        )
        editor.run()
    }

    private static func parseInitialLineAndColumn(from files: inout [String]) -> (line: Int?, column: Int?) {
        var targetLine: Int? = nil
        var targetCol: Int? = nil
        var remaining: [String] = []

        for arg in files {
            if arg.hasPrefix("+") && arg.count > 1 {
                let spec = arg.dropFirst()
                let parts = spec.components(separatedBy: ":")
                if let lineVal = Int(parts[0]), lineVal > 0 {
                    targetLine = lineVal
                    if parts.count >= 2, let colVal = Int(parts[1]), colVal > 0 {
                        targetCol = colVal
                    }
                    continue
                }
            }
            remaining.append(arg)
        }
        files = remaining
        return (targetLine, targetCol)
    }

    private static func parseBoolOption(_ value: String?) -> Bool? {
        guard let value else { return nil }
        let normalized = value.lowercased()
        return normalized == "true" || normalized == "1" || normalized == "on" || normalized == "yes"
    }

    private static func parseLanguageOption(_ value: String?) -> Language? {
        guard let value else { return nil }
        switch value.lowercased() {
        case "zh_tw", "zh-hant", "zh", "tw":
            return .zh_TW
        case "en", "english":
            return .en
        default:
            return nil
        }
    }
}
