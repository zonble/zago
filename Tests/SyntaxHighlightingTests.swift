import Foundation
import Testing

@testable import Editor

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
            line: "MAKE \"i\" 1 IFELSE :i > 5 [ FD 10 RT 90 ] [ BOX 5 3 ]", syntax: lang)
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
