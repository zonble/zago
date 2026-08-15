import Foundation

extension LogoPrimitive {
    var bufferMeta: LogoPrimitiveMeta? {
        switch self {
        case .buffers:
            LogoPrimitiveMeta(
                name: "BUFFERS",
                description: "Returns list of open buffer names in editor.",
                localizedDescriptionKey: "logo.doc.buffers",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "MAKE \"list BUFFERS")]
            )

        case .buffer:
            LogoPrimitiveMeta(
                name: "BUFFER",
                description: "Returns 1-based index of currently active buffer.",
                localizedDescriptionKey: "logo.doc.buffer",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "SHOW BUFFER")]
            )

        case .clearBuffer:
            LogoPrimitiveMeta(
                name: "CLEARBUFFER",
                description: "Clears all text content in active buffer.",
                localizedDescriptionKey: "logo.doc.clearbuffer",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "CLEARBUFFER")]
            )

        case .getline:
            LogoPrimitiveMeta(
                name: "GETLINE",
                description: "Returns text content of specified line (or current line).",
                localizedDescriptionKey: "logo.doc.getline",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "row", required: false)],
                examples: [LogoPrimitiveExample(input: "GETLINE 1")]
            )

        case .setline:
            LogoPrimitiveMeta(
                name: "SETLINE",
                description: "Replaces text of specified line with new content.",
                localizedDescriptionKey: "logo.doc.setline",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "row", required: false),
                    LogoPrimitiveParameter(name: "text", required: true),
                ],
                examples: [LogoPrimitiveExample(input: "SETLINE 1 \"Title")]
            )

        case .gotoline:
            LogoPrimitiveMeta(
                name: "GOTOLINE",
                description: "Jumps cursor directly to specified 1-based row.",
                localizedDescriptionKey: "logo.doc.gotoline",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "row", required: true)],
                examples: [LogoPrimitiveExample(input: "GOTOLINE 10")]
            )

        case .gotocol:
            LogoPrimitiveMeta(
                name: "GOTOCOL",
                description: "Jumps cursor directly to specified 1-based visual column.",
                localizedDescriptionKey: "logo.doc.gotocol",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "col", required: true)],
                examples: [LogoPrimitiveExample(input: "GOTOCOL 5")]
            )

        case .row:
            LogoPrimitiveMeta(
                name: "ROW",
                description: "Returns current 1-based line row number.",
                localizedDescriptionKey: "logo.doc.row",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "SHOW ROW")]
            )

        case .col:
            LogoPrimitiveMeta(
                name: "COL",
                description: "Returns current 1-based visual column number.",
                localizedDescriptionKey: "logo.doc.col",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "SHOW COL")]
            )

        case .lineCount:
            LogoPrimitiveMeta(
                name: "LINECOUNT",
                description: "Returns total number of lines in active buffer.",
                localizedDescriptionKey: "logo.doc.linecount",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "SHOW LINECOUNT")]
            )

        case .bufferText:
            LogoPrimitiveMeta(
                name: "BUFFERTEXT",
                description: "Returns full text content of active buffer as single string.",
                localizedDescriptionKey: "logo.doc.buffertext",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "MAKE \"txt BUFFERTEXT")]
            )

        case .selection:
            LogoPrimitiveMeta(
                name: "SELECTION",
                description: "Returns currently selected text string in buffer.",
                localizedDescriptionKey: "logo.doc.selection",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "MAKE \"sel SELECTION")]
            )

        case .isModified:
            LogoPrimitiveMeta(
                name: "MODIFIED?",
                description: "Returns true if buffer has unsaved edits, false otherwise.",
                localizedDescriptionKey: "logo.doc.ismodified",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "IF MODIFIED? [ SHOW \"Unsaved ]")]
            )

        case .fileName:
            LogoPrimitiveMeta(
                name: "FILENAME",
                description: "Returns file path or title of active buffer.",
                localizedDescriptionKey: "logo.doc.filename",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "SHOW FILENAME")]
            )

        default: nil
        }
    }
}
