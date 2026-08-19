import Foundation

extension LogoPrimitive {
    var editMeta: LogoPrimitiveMeta? {
        return switch self {
        case .type:
            LogoPrimitiveMeta(
                name: "TYPE",
                description: "Inserts text at current editor cursor position without trailing newline.",
                localizedDescriptionKey: "logo.doc.type",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "The value to process. Used by TYPE.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "...", required: false, description: "The ... argument. Used by TYPE.", example: "..."),
                ],
                examples: [LogoPrimitiveExample(input: "TYPE \"Hello")]
            )

        case .delete:
            LogoPrimitiveMeta(
                name: "DELETE",
                description: "Deletes specified number of characters forward from cursor.",
                localizedDescriptionKey: "logo.doc.delete",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "count", required: false, description: "The count argument. Used by DELETE.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "DELETE 5")]
            )

        case .backspace:
            LogoPrimitiveMeta(
                name: "BACKSPACE",
                description: "Deletes specified number of characters backward from cursor.",
                localizedDescriptionKey: "logo.doc.backspace",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "count", required: false, description: "The count argument. Used by BACKSPACE.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "BACKSPACE 1")]
            )

        case .deleteLine:
            LogoPrimitiveMeta(
                name: "DELETELINE",
                description: "Deletes current line from text buffer.",
                localizedDescriptionKey: "logo.doc.deleteline",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "DELETELINE")]
            )

        case .top:
            LogoPrimitiveMeta(
                name: "TOP",
                description: "Moves cursor to top-left corner of current buffer.",
                localizedDescriptionKey: "logo.doc.top",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "TOP")]
            )

        case .bottom:
            LogoPrimitiveMeta(
                name: "BOTTOM",
                description: "Moves cursor to bottom of current buffer.",
                localizedDescriptionKey: "logo.doc.bottom",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "BOTTOM")]
            )

        case .lineStart:
            LogoPrimitiveMeta(
                name: "LINESTART",
                description: "Moves cursor to beginning of current line.",
                localizedDescriptionKey: "logo.doc.linestart",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "LINESTART")]
            )

        case .lineEnd:
            LogoPrimitiveMeta(
                name: "LINEEND",
                description: "Moves cursor to end of current line.",
                localizedDescriptionKey: "logo.doc.lineend",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "LINEEND")]
            )

        case .appendText:
            LogoPrimitiveMeta(
                name: "APPEND",
                description: "Appends text to the end of the current buffer.",
                localizedDescriptionKey: "logo.doc.appendtext",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text to insert. Used by APPEND.",
                        example: "text")
                ],
                examples: [LogoPrimitiveExample(input: "APPEND \"Footer")]
            )

        case .prependText:
            LogoPrimitiveMeta(
                name: "PREPEND",
                description: "Prepends text to the very beginning of the buffer.",
                localizedDescriptionKey: "logo.doc.prependtext",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The text to insert. Used by PREPEND.",
                        example: "text")
                ],
                examples: [LogoPrimitiveExample(input: "PREPEND \"Header")]
            )

        case .changeText:
            LogoPrimitiveMeta(
                name: "CHANGE",
                description: "Replaces text at current line or selection with new content.",
                localizedDescriptionKey: "logo.doc.changetext",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "text", required: true, description: "The replacement text. Used by CHANGE.",
                        example: "text")
                ],
                examples: [LogoPrimitiveExample(input: "CHANGE \"Replaced")]
            )

        case .joinLine:
            LogoPrimitiveMeta(
                name: "JOIN",
                description: "Joins current line with the next line.",
                localizedDescriptionKey: "logo.doc.joinline",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "JOIN")]
            )

        case .splitLine:
            LogoPrimitiveMeta(
                name: "SPLITLINE",
                description: "Splits current line at cursor into two lines.",
                localizedDescriptionKey: "logo.doc.splitline",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "SPLITLINE")]
            )

        case .indentLines:
            LogoPrimitiveMeta(
                name: "INDENT",
                description: "Indents current line or selection by tab width.",
                localizedDescriptionKey: "logo.doc.indentlines",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "spaces", required: false, description: "The spaces argument. Used by INDENT.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "INDENT 4")]
            )

        case .outdentLines:
            LogoPrimitiveMeta(
                name: "OUTDENT",
                description: "Outdents current line or selection by tab width.",
                localizedDescriptionKey: "logo.doc.outdentlines",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "spaces", required: false, description: "The spaces argument. Used by OUTDENT.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "OUTDENT 4")]
            )

        case .move:
            LogoPrimitiveMeta(
                name: "MOVE",
                description: "Moves cursor by relative (dx, dy) characters in buffer.",
                localizedDescriptionKey: "logo.doc.move",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "dx", required: true, description: "The horizontal offset. Used by MOVE.", example: "3"),
                    LogoPrimitiveParameter(
                        name: "dy", required: true, description: "The vertical offset. Used by MOVE.", example: "3"),
                ],
                examples: [LogoPrimitiveExample(input: "MOVE 5 -2")]
            )

        case .mark:
            LogoPrimitiveMeta(
                name: "MARK",
                description: "Toggles or sets text selection anchor point.",
                localizedDescriptionKey: "logo.doc.mark",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "MARK")]
            )

        case .cut:
            LogoPrimitiveMeta(
                name: "CUT",
                description: "Cuts selected text or current line to kill ring clipboard.",
                localizedDescriptionKey: "logo.doc.cut",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "CUT")]
            )

        case .uncut:
            LogoPrimitiveMeta(
                name: "UNCUT",
                description: "Pastes text from kill ring clipboard at cursor.",
                localizedDescriptionKey: "logo.doc.uncut",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "UNCUT")]
            )

        case .justify:
            LogoPrimitiveMeta(
                name: "JUSTIFY",
                description: "Re-wraps and justifies current paragraph.",
                localizedDescriptionKey: "logo.doc.justify",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "JUSTIFY")]
            )

        case .goto:
            LogoPrimitiveMeta(
                name: "GOTO",
                description: "Moves editor cursor to absolute line and column.",
                localizedDescriptionKey: "logo.doc.goto",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "line", required: true, description: "The line number. Used by GOTO.", example: "3"),
                    LogoPrimitiveParameter(
                        name: "col", required: true, description: "The visual column. Used by GOTO.", example: "3"),
                ],
                examples: [LogoPrimitiveExample(input: "GOTO 10 5")]
            )

        default:
            nil
        }
    }
}
