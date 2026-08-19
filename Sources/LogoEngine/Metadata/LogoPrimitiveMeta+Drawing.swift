import Foundation
import Drawing

private let borderStyleAllowedValues = BorderStyle.allCases.map(\.rawValue)
private let arrowStyleAllowedValues = ArrowStyle.allCases.map(\.rawValue)
private let arrowDirectionAllowedValues = LineArrowMode.allKeywords.map { $0.lowercased() }

private func boxParameters(for commandName: String) -> [LogoPrimitiveParameter] {
    [
        LogoPrimitiveParameter(
            name: "width", required: false, description: "The width. Used by \(commandName).", example: "3"),
        LogoPrimitiveParameter(
            name: "height", required: false, description: "The height. Used by \(commandName).", example: "3"),
        LogoPrimitiveParameter(
            name: "text", required: false, description: "The text value. Used by \(commandName).", example: "text"),
        LogoPrimitiveParameter(
            name: "align", required: false, description: "The align argument. Used by \(commandName).",
            example: "left", allowedValues: ["left", "center", "right"]),
        LogoPrimitiveParameter(
            name: "style", required: false, description: "The formatting or border style. Used by \(commandName).",
            example: "single",
            allowedValues: borderStyleAllowedValues),
        LogoPrimitiveParameter(
            name: "exit", required: false, description: "The exit argument. Used by \(commandName).",
            example: "ne", allowedValues: ["ne", "se", "nw", "sw", "down"]),
    ]
}

private func lineParameters(for commandName: String, lengthOrHeight: String) -> [LogoPrimitiveParameter] {
    [
        LogoPrimitiveParameter(
            name: lengthOrHeight, required: false,
            description: "The \(lengthOrHeight)\(lengthOrHeight == "length" ? " argument" : ""). Used by \(commandName).",
            example: "3"
        ),
        LogoPrimitiveParameter(
            name: "style", required: false, description: "The formatting or border style. Used by \(commandName).",
            example: "single",
            allowedValues: borderStyleAllowedValues),
        LogoPrimitiveParameter(
            name: "arrow", required: false, description: "The arrow argument. Used by \(commandName).", example: "3",
            allowedValues: arrowDirectionAllowedValues),
        LogoPrimitiveParameter(
            name: "arrowStyle", required: false, description: "The arrowStyle argument. Used by \(commandName).",
            example: "solid", allowedValues: arrowStyleAllowedValues),
    ]
}

extension LogoPrimitive {
    var drawingMeta: LogoPrimitiveMeta? {
        return switch self {
        case .box:
            LogoPrimitiveMeta(
                name: "BOX",
                description: "Overlays an ASCII/Unicode box with text in rectangular region.",
                localizedDescriptionKey: "logo.doc.box",
                source: .zago,
                parameters: boxParameters(for: "BOX"),
                examples: [LogoPrimitiveExample(input: "BOX 30 5 \"Window \"center \"double")]
            )

        case .drawBox:
            LogoPrimitiveMeta(
                name: "DRAWBOX",
                description: "Overlays an ASCII/Unicode box at current position or selection.",
                localizedDescriptionKey: "logo.doc.drawbox",
                source: .zago,
                parameters: boxParameters(for: "DRAWBOX"),
                examples: [LogoPrimitiveExample(input: "DRAWBOX 20 6 \"Popup \"center \"round")]
            )

        case .inset:
            LogoPrimitiveMeta(
                name: "INSET",
                description: "Adjusts box drawing margin/padding inset.",
                localizedDescriptionKey: "logo.doc.inset",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "top", required: false, description: "The top argument. Used by INSET.", example: "3"),
                    LogoPrimitiveParameter(
                        name: "right", required: false, description: "The right argument. Used by INSET.",
                        example: "3"),
                    LogoPrimitiveParameter(
                        name: "bottom", required: false, description: "The bottom argument. Used by INSET.",
                        example: "3"),
                    LogoPrimitiveParameter(
                        name: "left", required: false, description: "The left argument. Used by INSET.", example: "3"),
                ],
                examples: [LogoPrimitiveExample(input: "INSET 1 2 1 2")]
            )

        case .line:
            LogoPrimitiveMeta(
                name: "LINE",
                description: "Draws horizontal rule with smart junction blending.",
                localizedDescriptionKey: "logo.doc.line",
                source: .zago,
                parameters: lineParameters(for: "LINE", lengthOrHeight: "length"),
                examples: [
                    LogoPrimitiveExample(input: "LINE 40 \"single"),
                    LogoPrimitiveExample(input: "LINE 10 \"arrow \"hollow"),
                ]
            )

        case .vline:
            LogoPrimitiveMeta(
                name: "VLINE",
                description: "Draws a vertical line with smart junction blending.",
                localizedDescriptionKey: "logo.doc.vline",
                source: .zago,
                parameters: lineParameters(for: "VLINE", lengthOrHeight: "height"),
                examples: [
                    LogoPrimitiveExample(input: "VLINE 8 \"single"),
                    LogoPrimitiveExample(input: "VLINE 5 \"arrow \"stemmed"),
                ]
            )

        case .table:
            LogoPrimitiveMeta(
                name: "TABLE",
                description: "Creates a Unicode/ASCII table grid at current cursor position.",
                localizedDescriptionKey: "logo.doc.table",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "rows", required: false, description: "The number of rows. Used by TABLE.", example: "3"),
                    LogoPrimitiveParameter(
                        name: "cols", required: false, description: "The number of columns. Used by TABLE.",
                        example: "3"),
                    LogoPrimitiveParameter(
                        name: "cellwidth", required: false, description: "The cellwidth argument. Used by TABLE.",
                        example: "3"),
                    LogoPrimitiveParameter(
                        name: "style", required: false, description: "The formatting or border style. Used by TABLE.",
                        example: "single",
                        allowedValues: borderStyleAllowedValues),
                    LogoPrimitiveParameter(
                        name: "rounded", required: false,
                        description: "Whether table corners are rounded. Used by TABLE.",
                        example: "true",
                        allowedValues: ["true", "false"]),
                ],
                examples: [
                    LogoPrimitiveExample(input: "TABLE"),
                    LogoPrimitiveExample(input: "TABLE 3 4 12"),
                    LogoPrimitiveExample(input: "TABLE 3 3 10 \"double"),
                ]
            )

        case .newline:
            LogoPrimitiveMeta(
                name: "NEWLINE",
                description: "Advances editor cursor to the start of the next line.",
                localizedDescriptionKey: "logo.doc.newline",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "count", required: false, description: "The count argument. Used by NEWLINE.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "NEWLINE 2")]
            )

        case .penDown:
            LogoPrimitiveMeta(
                name: "PENDOWN",
                description: "Lowers drawing pen to enable canvas line drawing.",
                localizedDescriptionKey: "logo.doc.pendown",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PENDOWN")]
            )

        case .penUp:
            LogoPrimitiveMeta(
                name: "PENUP",
                description: "Lifts drawing pen to allow moving without drawing.",
                localizedDescriptionKey: "logo.doc.penup",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PENUP")]
            )

        case .forward:
            LogoPrimitiveMeta(
                name: "FORWARD",
                description: "Moves turtle forward by distance units, drawing if pen down.",
                localizedDescriptionKey: "logo.doc.forward",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "distance", required: true, description: "The distance. Used by FORWARD.", example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "FORWARD 10")]
            )

        case .back:
            LogoPrimitiveMeta(
                name: "BACK",
                description: "Moves turtle backward by distance units.",
                localizedDescriptionKey: "logo.doc.back",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "distance", required: true, description: "The distance. Used by BACK.", example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "BACK 5")]
            )

        case .turnRight:
            LogoPrimitiveMeta(
                name: "RIGHT",
                description: "Rotates turtle clockwise by degrees.",
                localizedDescriptionKey: "logo.doc.right",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "degrees", required: true, description: "The degrees angle. Used by TURNRIGHT.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "RIGHT 90")]
            )

        case .turnLeft:
            LogoPrimitiveMeta(
                name: "LEFT",
                description: "Rotates turtle counter-clockwise by degrees.",
                localizedDescriptionKey: "logo.doc.left",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "degrees", required: true, description: "The degrees angle. Used by TURNLEFT.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "LEFT 90")]
            )

        case .setHeading:
            LogoPrimitiveMeta(
                name: "SETHEADING",
                description: "Sets absolute heading angle (0=Up, 90=Right, 180=Down, 270=Left).",
                localizedDescriptionKey: "logo.doc.setheading",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "degrees", required: true, description: "The degrees angle. Used by SETHEADING.",
                        example: "3")
                ],
                examples: [LogoPrimitiveExample(input: "SETHEADING 180")]
            )

        case .headingPrimitive:
            LogoPrimitiveMeta(
                name: "HEADING",
                description: "Returns turtle's current heading in degrees.",
                localizedDescriptionKey: "logo.doc.heading",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "HEADING", output: "0")]
            )

        default:
            nil
        }
    }
}
