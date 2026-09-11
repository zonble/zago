import Foundation

/// Represents a reusable TMD score snippet template.
public struct TMDSnippet: Sendable {
    public let id: String
    public let titleKey: String
    public let hotkeyChar: Character
    public let templateText: String

    public init(id: String, titleKey: String, hotkeyChar: Character = " ", templateText: String) {
        self.id = id
        self.titleKey = titleKey
        self.hotkeyChar = hotkeyChar
        self.templateText = templateText
    }
}

/// Factory and provider for TMD snippets.
public enum TMDSnippets {
    public static let fullScoreTemplate = TMDSnippet(
        id: "tmd.score_template",
        titleKey: "menu.tmd.snippet.score_template",
        hotkeyChar: "t",
        templateText: """
::SCORE::
** Untitled Score **

!= 120
?= C
<4/4>

-> Intro
-> Verse
-> Chorus
-> #

Intro:Piano@|0|{
    <4*>
    [C] 1 3 5 1' | [G] 5, 7, 2 5 | [Am] 6, 1 3 6 | [F] 4, 6, 1 4 |
}

Verse:Piano@|0|{
    <4*>
    [C] 1 - 3 - | [G] 5 - 7 - | [Am] 6 - 1' - | [F] 4 - 6 - |
}

Chorus:Piano@|0|{
    <4*>
    [F] 4 6 1' - | [G] 5 7 2' - | [Em] 3 5 7 - | [Am] 6 1' 3' - |
    [Dm] 2 4 6 - | [G] 5 7 2' - | [C] 1' - - - |
}
"""
    )

    public static let paragraphTemplate = TMDSnippet(
        id: "tmd.paragraph",
        titleKey: "menu.tmd.snippet.paragraph",
        hotkeyChar: "p",
        templateText: """
Verse:Piano@|0|{
    <4*>
    [C] 1 3 5 1' | [G] 5, 7, 2 5 | [Am] 6, 1 3 6 | [F] 4, 6, 1 4 |
}
"""
    )

    public static let chordProgressionTemplate = TMDSnippet(
        id: "tmd.chords",
        titleKey: "menu.tmd.snippet.chords",
        hotkeyChar: "c",
        templateText: """
Chorus:Piano@|0|{
    <4*>
    [F] 4 - - - | [G] 5 - - - | [Em] 3 - - - | [Am] 6 - - - |
    [Dm7] 2 - - - | [G7] 5 - - - | [C] 1 - - - |
}
"""
    )

    public static let allSnippets: [TMDSnippet] = [
        fullScoreTemplate,
        paragraphTemplate,
        chordProgressionTemplate,
    ]

    /// Inserts a TMD snippet into the editor buffer.
    public static func insertSnippet(_ snippet: TMDSnippet, into editor: Editor) {
        editor.saveUndoSnapshot()

        let lines = snippet.templateText.components(separatedBy: .newlines)
        for (i, line) in lines.enumerated() {
            editor.buffer.insertString(line)
            if i < lines.count - 1 {
                editor.buffer.insertNewline()
            }
        }

        editor.buffer.isModified = true
        editor.reportOperationResult(.succeeded(message: editor.l10n["status.tmd_snippet_inserted"]))
    }
}
