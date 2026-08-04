import Foundation
import Testing

@testable import Editor
@testable import Syntax

@Test func testSyntaxHighlighter() throws {
    let highlighter = SyntaxHighlighter()

    let swiftLang = highlighter.detectLanguage(for: "main.swift")
    #expect(swiftLang != nil)
    #expect(swiftLang?.name == "Swift")

    let pythonLang = highlighter.detectLanguage(for: "script.py")
    #expect(pythonLang != nil)
    #expect(pythonLang?.name == "Python")

    let jsonLang = highlighter.detectLanguage(for: "package.json")
    #expect(jsonLang != nil)
    #expect(jsonLang?.name == "JSON")

    let yamlLang = highlighter.detectLanguage(for: "workflow.yml")
    #expect(yamlLang != nil)
    #expect(yamlLang?.name == "YAML")

    let tomlLang = highlighter.detectLanguage(for: "pyproject.toml")
    #expect(tomlLang != nil)
    #expect(tomlLang?.name == "TOML")

    let iniLang = highlighter.detectLanguage(for: "settings.ini")
    #expect(iniLang != nil)
    #expect(iniLang?.name == "INI")

    let rstLang = highlighter.detectLanguage(for: "docs.rst")
    #expect(rstLang != nil)
    #expect(rstLang?.name == "reStructuredText")

    let markdownLang = highlighter.detectLanguage(for: "notes.mkd")
    #expect(markdownLang != nil)
    #expect(markdownLang?.name == "Markdown")

    let orgLang = highlighter.detectLanguage(for: "todo.org")
    #expect(orgLang != nil)
    #expect(orgLang?.name == "Org-mode")

    let adocLang = highlighter.detectLanguage(for: "doc.adoc")
    #expect(adocLang != nil)
    #expect(adocLang?.name == "AsciiDoc")

    let wikiLang = highlighter.detectLanguage(for: "page.wiki")
    #expect(wikiLang != nil)
    #expect(wikiLang?.name == "Wiki")

    let logoLang = highlighter.detectLanguage(for: "script.logo")
    #expect(logoLang != nil)
    #expect(logoLang?.name == "LOGO")

    let vhsLang = highlighter.detectLanguage(for: "demo.tape")
    #expect(vhsLang != nil)
    #expect(vhsLang?.name == "VHS")

    let zagorcLang = highlighter.detectLanguage(for: ".zagorc")
    #expect(zagorcLang != nil)
    #expect(zagorcLang?.name == "LOGO")

    if let lang = logoLang {
        let highlighted = highlighter.highlight(
            line: "MAKE \"i\" 1 IFELSE :i > 5 [ FD 10 RT ] [ BOX 5 3 ]", syntax: lang)
        #expect(highlighted.contains("\u{1B}[1;36m"))
        #expect(highlighted.contains("\u{1B}[94m"))

        let loopCounterHighlighted = highlighter.highlight(line: "REPEAT 3 [ TYPE :# ]", syntax: lang)
        #expect(loopCounterHighlighted.contains("\u{1B}[94m:#"))

        let aliasHighlighted = highlighter.highlight(line: "CLEARBUFFER MAP.SE MODIFIED?", syntax: lang)
        #expect(aliasHighlighted.contains("\u{1B}[1;36mCLEARBUFFER"))
        #expect(aliasHighlighted.contains("\u{1B}[1;36mMODIFIED?"))

        let lowercaseHighlighted = highlighter.highlight(
            line: "make \"i\" 1 ifelse :i > 5 [ fd 10 rt 90 ]", syntax: lang)
        #expect(lowercaseHighlighted.contains("\u{1B}[1;36mmake"))
        #expect(lowercaseHighlighted.contains("\u{1B}[1;36mifelse"))
        #expect(lowercaseHighlighted.contains("\u{1B}[1;36mfd"))

        let mixedCaseHighlighted = highlighter.highlight(line: "DrawBox 10 table 2 3 ascii", syntax: lang)
        #expect(mixedCaseHighlighted.contains("\u{1B}[1;36mDrawBox"))
        #expect(mixedCaseHighlighted.contains("\u{1B}[1;36mtable"))
        #expect(mixedCaseHighlighted.contains("\u{1B}[1;36mascii"))

        let arrowHighlighted = highlighter.highlight(line: "LINE ARROW TYPE :#", syntax: lang)
        #expect(arrowHighlighted.contains("\u{1B}[1;36mARROW"))
        #expect(!arrowHighlighted.contains("\u{1B}[90m#"))
        #expect(arrowHighlighted.contains("\u{1B}[94m:#"))

        let quotedWordsHighlighted = highlighter.highlight(line: "show \"1 \"2 \"3", syntax: lang)
        #expect(quotedWordsHighlighted.contains("\u{1B}[32m\"1"))
        #expect(quotedWordsHighlighted.contains("\u{1B}[32m\"2"))
        #expect(quotedWordsHighlighted.contains("\u{1B}[32m\"3"))
        #expect(!quotedWordsHighlighted.contains("\u{1B}[32m\"1 \""))

        let commentHighlighted = highlighter.highlight(line: "TYPE \"ok ; SHOW :x 123", syntax: lang)
        #expect(commentHighlighted.contains("\u{1B}[90m; SHOW :x 123"))
        #expect(!commentHighlighted.contains("\u{1B}[1;36mSHOW"))
        #expect(!commentHighlighted.contains("\u{1B}[94m:x"))

        let semicolonStringHighlighted = highlighter.highlight(line: "TYPE \"a;b\" ; SHOW :x", syntax: lang)
        #expect(semicolonStringHighlighted.contains("\u{1B}[32m\"a;b\""))
        #expect(semicolonStringHighlighted.contains("\u{1B}[90m ; SHOW :x"))
        #expect(!semicolonStringHighlighted.contains("\u{1B}[90m;b\""))
    }

    if let lang = vhsLang {
        let setHighlighted = highlighter.highlight(line: "Set FontSize 20", syntax: lang)
        #expect(setHighlighted.contains("\u{1B}[1;36mSet"))
        #expect(setHighlighted.contains("\u{1B}[94mFontSize"))
        #expect(setHighlighted.contains("\u{1B}[33m20"))

        let typeHighlighted = highlighter.highlight(line: "Type `echo # not comment`", syntax: lang)
        #expect(typeHighlighted.contains("\u{1B}[1;36mType"))
        #expect(typeHighlighted.contains("\u{1B}[32m`echo # not comment`"))
        #expect(!typeHighlighted.contains("\u{1B}[90m# not comment"))

        let waitHighlighted = highlighter.highlight(line: "Wait+Screen /ready\\/[0-9]+/", syntax: lang)
        #expect(waitHighlighted.contains("\u{1B}[1;36mWait"))
        #expect(waitHighlighted.contains("\u{1B}[94m+"))
        #expect(waitHighlighted.contains("\u{1B}[32m/ready\\/[0-9]+/"))

        let envHighlighted = highlighter.highlight(line: "Env API_URL \"https://example.test\"", syntax: lang)
        #expect(envHighlighted.contains("\u{1B}[1;36mEnv"))
        #expect(envHighlighted.contains("\u{1B}[32m\"https://example.test\""))
    }

    if let lang = yamlLang {
        let keyHighlighted = highlighter.highlight(line: "name: \"CI\"", syntax: lang)
        #expect(keyHighlighted.contains("\u{1B}[1;36mname"))
        #expect(keyHighlighted.contains("\u{1B}[32m\"CI\""))

        let listHighlighted = highlighter.highlight(line: "  - run: swift test # verify", syntax: lang)
        #expect(listHighlighted.contains("\u{1B}[33m  - "))
        #expect(listHighlighted.contains("\u{1B}[1;36mrun"))
        #expect(listHighlighted.contains("\u{1B}[90m# verify"))
    }

    if let lang = tomlLang {
        let sectionHighlighted = highlighter.highlight(line: "[tool.swift]", syntax: lang)
        #expect(sectionHighlighted.contains("\u{1B}[1;36m[tool.swift]"))

        let keyHighlighted = highlighter.highlight(line: "enabled = true", syntax: lang)
        #expect(keyHighlighted.contains("\u{1B}[1;36menabled"))
        #expect(keyHighlighted.contains("\u{1B}[94mtrue"))
    }

    if let lang = iniLang {
        let sectionHighlighted = highlighter.highlight(line: "[server]", syntax: lang)
        #expect(sectionHighlighted.contains("\u{1B}[1;36m[server]"))

        let keyHighlighted = highlighter.highlight(line: "port = 1976", syntax: lang)
        #expect(keyHighlighted.contains("\u{1B}[1;36mport"))
        #expect(keyHighlighted.contains("\u{1B}[33m1976"))

        let commentHighlighted = highlighter.highlight(line: "; disabled", syntax: lang)
        #expect(commentHighlighted.contains("\u{1B}[90m; disabled"))
    }

    if let swiftLang = highlighter.detectLanguage(for: "Package.swift") {
        let packageLine = ".package(url: \"https://github.com/apple/swift-argument-parser.git\", from: \"1.3.0\"),"
        let tokens = highlighter.tokenTypes(for: packageLine, syntax: swiftLang)
        let githubRange = (packageLine as NSString).range(of: "github")
        #expect(githubRange.location != NSNotFound)
        #expect(tokens[githubRange.location] == .string)
    }

    let adocLines = [
        "= Title",
        "[source,swift]",
        "----",
        "let x = 1",
        "----",
    ]
    let adocEmbedded = highlighter.detectEmbeddedLanguage(in: adocLines, bufferLineIndex: 3, fileExtension: "adoc")
    #expect(adocEmbedded?.name == "Swift")

    let wikiLines = [
        "== Section ==",
        "<syntaxhighlight lang=\"python\">",
        "print('hello')",
        "</syntaxhighlight>",
    ]
    let wikiEmbedded = highlighter.detectEmbeddedLanguage(in: wikiLines, bufferLineIndex: 2, fileExtension: "wiki")
    #expect(wikiEmbedded?.name == "Python")

    if let lang = markdownLang {
        let fenceHighlighted = highlighter.highlight(line: "```logo", syntax: lang)
        #expect(fenceHighlighted.contains("\u{1B}[94m```logo"))

        let taskHighlighted = highlighter.highlight(line: "- [x] finish Markdown rules", syntax: lang)
        #expect(taskHighlighted.contains("\u{1B}[94m- [x] "))

        let tableHighlighted = highlighter.highlight(line: "| Name | Value |", syntax: lang)
        #expect(tableHighlighted.contains("\u{1B}[94m| Name | Value |"))

        let compactTableHighlighted = highlighter.highlight(line: "Name | Value | Notes", syntax: lang)
        #expect(compactTableHighlighted.contains("\u{1B}[94mName | Value | Notes"))

        let pipeListHighlighted = highlighter.highlight(
            line: "- LINE [SINGLE|DOUBLE|ASCII] [ARROW|BACKARROW|",
            syntax: lang
        )
        #expect(pipeListHighlighted.contains("\u{1B}[33m- "))
        #expect(!pipeListHighlighted.contains("\u{1B}[94mLINE [SINGLE|DOUBLE|ASCII]"))

        let separatorHighlighted = highlighter.highlight(line: "| --- | :---: |", syntax: lang)
        #expect(separatorHighlighted.contains("\u{1B}[1;36m| --- | :---: |"))

        let referenceHighlighted = highlighter.highlight(line: "[docs]: https://example.com", syntax: lang)
        #expect(referenceHighlighted.contains("\u{1B}[94m[docs]: https://example.com"))

        let emphasisHighlighted = highlighter.highlight(line: " **good** and _cool_", syntax: lang)
        #expect(emphasisHighlighted.contains("\u{1B}[32m**good**"))
        #expect(emphasisHighlighted.contains("\u{1B}[0m and "))
        #expect(emphasisHighlighted.contains("\u{1B}[32m_cool_"))
        #expect(!emphasisHighlighted.contains("\u{1B}[32m**good** and _"))
    }
}

@Test func testFindLanguageByNameAndAliases() throws {
    let highlighter = SyntaxHighlighter()

    // Test exact language names and alias extensions
    #expect(highlighter.findLanguage(named: "Python")?.name == "Python")
    #expect(highlighter.findLanguage(named: "py")?.name == "Python")
    #expect(highlighter.findLanguage(named: "python")?.name == "Python")

    #expect(highlighter.findLanguage(named: "Swift")?.name == "Swift")
    #expect(highlighter.findLanguage(named: "swift")?.name == "Swift")

    #expect(highlighter.findLanguage(named: "C/C++")?.name == "C/C++")
    #expect(highlighter.findLanguage(named: "c")?.name == "C/C++")
    #expect(highlighter.findLanguage(named: "cpp")?.name == "C/C++")
    #expect(highlighter.findLanguage(named: "c++")?.name == "C/C++")

    #expect(highlighter.findLanguage(named: "Shell")?.name == "Shell")
    #expect(highlighter.findLanguage(named: "sh")?.name == "Shell")
    #expect(highlighter.findLanguage(named: "bash")?.name == "Shell")
    #expect(highlighter.findLanguage(named: "zsh")?.name == "Shell")
    #expect(highlighter.findLanguage(named: "shell")?.name == "Shell")

    #expect(highlighter.findLanguage(named: "Markdown")?.name == "Markdown")
    #expect(highlighter.findLanguage(named: "md")?.name == "Markdown")
    #expect(highlighter.findLanguage(named: "markdown")?.name == "Markdown")

    #expect(highlighter.findLanguage(named: "PlantUML")?.name == "PlantUML")
    #expect(highlighter.findLanguage(named: "puml")?.name == "PlantUML")
    #expect(highlighter.findLanguage(named: "plantuml")?.name == "PlantUML")

    #expect(highlighter.findLanguage(named: "AsciiDoc")?.name == "AsciiDoc")
    #expect(highlighter.findLanguage(named: "adoc")?.name == "AsciiDoc")
    #expect(highlighter.findLanguage(named: "asciidoc")?.name == "AsciiDoc")

    #expect(highlighter.findLanguage(named: "Wiki")?.name == "Wiki")
    #expect(highlighter.findLanguage(named: "mediawiki")?.name == "Wiki")

    #expect(highlighter.findLanguage(named: "VHS")?.name == "VHS")
    #expect(highlighter.findLanguage(named: "tape")?.name == "VHS")

    #expect(highlighter.findLanguage(named: "NonExistentLanguage") == nil)
}

@Test func testEmbeddedLanguageDetectionForAllMarkupSyntaxes() throws {
    let highlighter = SyntaxHighlighter()

    // 1. Markdown (```python and ~~~swift)
    let mdLines = ["# Title", "```python", "print('hello')", "```"]
    let mdSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.md", isDirectoryBuffer: false, lines: mdLines, bufferLineIndex: 2, isEnabled: true
    )
    #expect(mdSyntax?.name == "Python")

    // 2. Org-mode (#+BEGIN_SRC logo ... #+END_SRC)
    let orgLines = ["* Header", "#+BEGIN_SRC logo", "FD 10", "#+END_SRC"]
    let orgSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.org", isDirectoryBuffer: false, lines: orgLines, bufferLineIndex: 2, isEnabled: true
    )
    #expect(orgSyntax?.name == "LOGO")

    // 3. reStructuredText (.. code-block:: c)
    let rstLines = ["Title", "=====", ".. code-block:: c", "    int x = 0;"]
    let rstSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.rst", isDirectoryBuffer: false, lines: rstLines, bufferLineIndex: 3, isEnabled: true
    )
    #expect(rstSyntax?.name == "C/C++")

    // 4. AsciiDoc ([source,swift] and ----)
    let adocLines = ["= Title", "[source,swift]", "----", "let a = 1", "----"]
    let adocSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.adoc", isDirectoryBuffer: false, lines: adocLines, bufferLineIndex: 3, isEnabled: true
    )
    #expect(adocSyntax?.name == "Swift")

    // 5. Wiki (<syntaxhighlight lang="shell">)
    let wikiLines = ["== Section ==", "<syntaxhighlight lang=\"shell\">", "echo hello", "</syntaxhighlight>"]
    let wikiSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.wiki", isDirectoryBuffer: false, lines: wikiLines, bufferLineIndex: 2, isEnabled: true
    )
    #expect(wikiSyntax?.name == "Shell")

    // Direct invocation on each SyntaxDefinition struct
    #expect(MarkdownSyntaxDefinition().detectEmbeddedLanguageName(in: mdLines, bufferLineIndex: 2) == "python")
    #expect(OrgModeSyntaxDefinition().detectEmbeddedLanguageName(in: orgLines, bufferLineIndex: 2) == "logo")
    #expect(ReSTSyntaxDefinition().detectEmbeddedLanguageName(in: rstLines, bufferLineIndex: 3) == "c")
    #expect(AsciiDocSyntaxDefinition().detectEmbeddedLanguageName(in: adocLines, bufferLineIndex: 3) == "swift")
    #expect(WikiSyntaxDefinition().detectEmbeddedLanguageName(in: wikiLines, bufferLineIndex: 2) == "shell")

    // Plain code file returns nil for embedded detection
    #expect(PythonSyntaxDefinition().detectEmbeddedLanguageName(in: ["x = 1"], bufferLineIndex: 0) == nil)
}

@Test func testMarkdownAndOrgTableFormattingAndNavigation() throws {
    let mdSyntax = MarkdownSyntaxDefinition().buildLanguageSyntax()
    #expect(mdSyntax.tableFormatter != nil)
    #expect(mdSyntax.tableNavigator != nil)

    let unalignedMd = [
        "| Name | Role |",
        "| --- | --- |",
        "| Alice | Senior Software Engineer |",
        "| Bob | Designer |",
    ]

    if let formatResult = mdSyntax.tableFormatter?(unalignedMd, 0, 2) {
        #expect(formatResult.updatedLines[0] == "| Name  | Role                     |")
        #expect(formatResult.updatedLines[2] == "| Alice | Senior Software Engineer |")
        #expect(formatResult.updatedLines[3] == "| Bob   | Designer                 |")
    }

    // Cell navigation forwarding from last cell automatically appends a new empty row
    if let navResult = mdSyntax.tableNavigator?(unalignedMd, 3, 10, true) {
        #expect(navResult.updatedLines != nil)
        #expect(navResult.newBufferLineIndex == 4)
    }

    let orgSyntax = OrgModeSyntaxDefinition().buildLanguageSyntax()
    #expect(orgSyntax.tableFormatter != nil)
    #expect(orgSyntax.tableNavigator != nil)
}

@Test func testOrgModeTableSyntaxHighlighting() throws {
    let highlighter = SyntaxHighlighter()
    let orgLines = [
        "* Headline",
        "| Header 1 | Header 2 |",
        "|----------+----------|",
        "| Data 1   | Data 2   |",
    ]

    let separatorHighlight = highlighter.tokenTypes(
        for: orgLines[2],
        syntax: OrgModeSyntaxDefinition().buildLanguageSyntax()
    )
    #expect(!separatorHighlight.isEmpty)
    #expect(separatorHighlight[0] == .keyword)

    let tableRowHighlight = highlighter.tokenTypes(
        for: orgLines[1],
        syntax: OrgModeSyntaxDefinition().buildLanguageSyntax()
    )
    #expect(!tableRowHighlight.isEmpty)
    #expect(tableRowHighlight[0] == .typeOrAttribute)
}

@Test func testPlainTextCodeBlockSyntaxHighlighting() throws {
    let highlighter = SyntaxHighlighter()

    // 1. Markdown plain text code block (``` without language)
    let mdLines = ["# Title", "```", "# Not a header inside code block", "```"]
    let mdSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.md", isDirectoryBuffer: false, lines: mdLines, bufferLineIndex: 2, isEnabled: true
    )
    #expect(mdSyntax?.name == "CodeBlockPlainText")
    let mdHighlighted = highlighter.highlight(line: mdLines[2], syntax: mdSyntax!)
    #expect(mdHighlighted.contains("\u{1B}[94m# Not a header inside code block"))

    // 2. Markdown code block with explicit 'text' language
    let mdTextLines = ["# Title", "```text", "plain text line", "```"]
    let mdTextSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.md", isDirectoryBuffer: false, lines: mdTextLines, bufferLineIndex: 2, isEnabled: true
    )
    #expect(mdTextSyntax?.name == "CodeBlockPlainText")

    // 3. Org-mode plain text code block (#+BEGIN_SRC or #+BEGIN_EXAMPLE)
    let orgLines = ["* Header", "#+BEGIN_SRC", "* Not an org heading", "#+END_SRC"]
    let orgSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.org", isDirectoryBuffer: false, lines: orgLines, bufferLineIndex: 2, isEnabled: true
    )
    #expect(orgSyntax?.name == "CodeBlockPlainText")
    let orgHighlighted = highlighter.highlight(line: orgLines[2], syntax: orgSyntax!)
    #expect(orgHighlighted.contains("\u{1B}[94m* Not an org heading"))

    // 4. AsciiDoc plain text code block (----)
    let adocLines = ["= Title", "----", "= Not an adoc title", "----"]
    let adocSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.adoc", isDirectoryBuffer: false, lines: adocLines, bufferLineIndex: 2, isEnabled: true
    )
    #expect(adocSyntax?.name == "CodeBlockPlainText")
    let adocHighlighted = highlighter.highlight(line: adocLines[2], syntax: adocSyntax!)
    #expect(adocHighlighted.contains("\u{1B}[94m= Not an adoc title"))

    // 5. reStructuredText plain text code block (.. code-block::)
    let rstLines = ["Title", "=====", ".. code-block::", "    Title underline"]
    let rstSyntax = highlighter.getSyntaxForLine(
        filePath: "doc.rst", isDirectoryBuffer: false, lines: rstLines, bufferLineIndex: 3, isEnabled: true
    )
    #expect(rstSyntax?.name == "CodeBlockPlainText")
    let rstHighlighted = highlighter.highlight(line: rstLines[3], syntax: rstSyntax!)
    #expect(rstHighlighted.contains("\u{1B}[94m    Title underline"))
}

@Test func testMarkdownTableWithInlineCodeHighlighting() throws {
    let highlighter = SyntaxHighlighter()
    let lang = try #require(highlighter.detectLanguage(for: "test.md"))
    let line = "| `server_legacy._norm_punct(t)` | `assistant_server.chat.response` |"
    let tokenMap = highlighter.tokenTypes(for: line, syntax: lang)

    let chars = Array(line)
    for (i, ch) in chars.enumerated() {
        print("[\(i)] '\(ch)' -> \(tokenMap[i])")
    }
}




