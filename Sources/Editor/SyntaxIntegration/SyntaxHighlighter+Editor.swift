import Foundation
@_exported import Syntax

extension SyntaxHighlighter {
    /// Editor-facing compatibility wrapper around the pure Syntax target API.
    public func getSyntaxForLine(editor: Editor, bufferLineIndex: Int) -> LanguageSyntax? {
        getSyntaxForLine(
            filePath: editor.buffer.filePath,
            isDirectoryBuffer: editor.buffer.isDirectoryBuffer,
            lines: editor.buffer.lines,
            bufferLineIndex: bufferLineIndex,
            isEnabled: editor.displayConfig.enableSyntaxHighlight
        )
    }
}
