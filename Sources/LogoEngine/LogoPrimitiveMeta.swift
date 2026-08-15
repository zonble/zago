import Foundation

public enum LogoPrimitiveMetaSource: Sendable, Equatable {
    case ucbLogo
    case zago
}

public struct LogoPrimitiveParameter: Sendable, Equatable {
    public let name: String
    public let required: Bool
    public let allowedValues: [String]

    public init(name: String, required: Bool, allowedValues: [String] = []) {
        self.name = name
        self.required = required
        self.allowedValues = allowedValues
    }
}

public struct LogoPrimitiveExample: Sendable, Equatable {
    public let input: String
    public let output: String

    public init(input: String, output: String = "") {
        self.input = input
        self.output = output
    }
}

public struct LogoPrimitiveMeta: Sendable, Equatable {
    public let name: String
    public let description: String
    public let localizedDescriptionKey: String
    public let source: LogoPrimitiveMetaSource
    public let parameters: [LogoPrimitiveParameter]?
    public let examples: [LogoPrimitiveExample]?

    public init(
        name: String,
        description: String,
        localizedDescriptionKey: String,
        source: LogoPrimitiveMetaSource,
        parameters: [LogoPrimitiveParameter]? = nil,
        examples: [LogoPrimitiveExample]? = nil
    ) {
        self.name = name
        self.description = description
        self.localizedDescriptionKey = localizedDescriptionKey
        self.source = source
        self.parameters = parameters
        self.examples = examples
    }
}

extension LogoPrimitive {
    public var meta: LogoPrimitiveMeta {
        switch self {
        // MARK: - Statement / Control Primitives
        case .make:
            LogoPrimitiveMeta(
                name: "MAKE",
                description: "Assigns a value to a named variable in current scope.",
                localizedDescriptionKey: "logo.doc.make",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "varname", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MAKE \"count 10")]
            )

        case .name:
            LogoPrimitiveMeta(
                name: "NAME",
                description: "Assigns a value to a named variable (reverse argument order of MAKE).",
                localizedDescriptionKey: "logo.doc.name",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true),
                    LogoPrimitiveParameter(name: "varname", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "NAME 42 \"answer")]
            )

        case .type:
            LogoPrimitiveMeta(
                name: "TYPE",
                description: "Inserts text at current editor cursor position without trailing newline.",
                localizedDescriptionKey: "logo.doc.type",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "TYPE \"Hello")]
            )

        case .show:
            LogoPrimitiveMeta(
                name: "SHOW",
                description: "Displays a status message or formatted output to the user.",
                localizedDescriptionKey: "logo.doc.show",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "SHOW [Done]")]
            )

        case .delete:
            LogoPrimitiveMeta(
                name: "DEL",
                description: "Deletes character(s) forward at current cursor position.",
                localizedDescriptionKey: "logo.doc.del",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "count", required: false)],
                examples: [LogoPrimitiveExample(input: "DEL 3")]
            )

        case .backspace:
            LogoPrimitiveMeta(
                name: "BS",
                description: "Deletes character(s) backward before current cursor position.",
                localizedDescriptionKey: "logo.doc.bs",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "count", required: false)],
                examples: [LogoPrimitiveExample(input: "BS 2")]
            )

        case .deleteLine:
            LogoPrimitiveMeta(
                name: "DELETELINE",
                description: "Deletes one or more whole lines at current line position.",
                localizedDescriptionKey: "logo.doc.deleteline",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "count", required: false)],
                examples: [LogoPrimitiveExample(input: "DELETELINE")]
            )

        case .top:
            LogoPrimitiveMeta(
                name: "TOP",
                description: "Moves editor cursor to top (line 1, column 0) of active buffer.",
                localizedDescriptionKey: "logo.doc.top",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "TOP")]
            )

        case .bottom:
            LogoPrimitiveMeta(
                name: "BOTTOM",
                description: "Moves editor cursor to bottom of active buffer.",
                localizedDescriptionKey: "logo.doc.bottom",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "BOTTOM")]
            )

        case .lineStart:
            LogoPrimitiveMeta(
                name: "LINESTART",
                description: "Moves cursor to the start of current line.",
                localizedDescriptionKey: "logo.doc.linestart",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "LINESTART")]
            )

        case .lineEnd:
            LogoPrimitiveMeta(
                name: "LINEEND",
                description: "Moves cursor to the end of current line.",
                localizedDescriptionKey: "logo.doc.lineend",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "LINEEND")]
            )

        case .appendText:
            LogoPrimitiveMeta(
                name: "APPEND",
                description: "Appends text to the end of current line.",
                localizedDescriptionKey: "logo.doc.append",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true)],
                examples: [LogoPrimitiveExample(input: "APPEND \" (done)")]
            )

        case .prependText:
            LogoPrimitiveMeta(
                name: "PREPEND",
                description: "Prepends text to the start of current line.",
                localizedDescriptionKey: "logo.doc.prepend",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true)],
                examples: [LogoPrimitiveExample(input: "PREPEND \"# ")]
            )

        case .changeText:
            LogoPrimitiveMeta(
                name: "CHANGE",
                description: "Replaces text on current line or active selection.",
                localizedDescriptionKey: "logo.doc.change",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "old", required: true),
                    LogoPrimitiveParameter(name: "new", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "CHANGE \"old \"new")]
            )

        case .joinLine:
            LogoPrimitiveMeta(
                name: "JOIN",
                description: "Joins current line with next line using optional separator.",
                localizedDescriptionKey: "logo.doc.join",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "separator", required: false)],
                examples: [LogoPrimitiveExample(input: "JOIN \" ")]
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
                description: "Indents current line or selection by standard tab stops.",
                localizedDescriptionKey: "logo.doc.indent",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "levels", required: false)],
                examples: [LogoPrimitiveExample(input: "INDENT 1")]
            )

        case .outdentLines:
            LogoPrimitiveMeta(
                name: "OUTDENT",
                description: "Outdents current line or selection by standard tab stops.",
                localizedDescriptionKey: "logo.doc.outdent",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "levels", required: false)],
                examples: [LogoPrimitiveExample(input: "OUTDENT 1")]
            )

        case .move:
            LogoPrimitiveMeta(
                name: "MOVE",
                description: "Moves editor cursor in visual direction (UP, DOWN, LEFT, RIGHT).",
                localizedDescriptionKey: "logo.doc.move",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "direction", required: true, allowedValues: ["UP", "DOWN", "LEFT", "RIGHT"]),
                    LogoPrimitiveParameter(name: "count", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "MOVE \"RIGHT 5")]
            )

        case .mark:
            LogoPrimitiveMeta(
                name: "MARK",
                description: "Sets selection anchor mark at current cursor location.",
                localizedDescriptionKey: "logo.doc.mark",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "MARK")]
            )

        case .cut:
            LogoPrimitiveMeta(
                name: "CUT",
                description: "Cuts selected text into clipboard.",
                localizedDescriptionKey: "logo.doc.cut",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "CUT")]
            )

        case .uncut:
            LogoPrimitiveMeta(
                name: "UNCUT",
                description: "Pastes text from clipboard at cursor position.",
                localizedDescriptionKey: "logo.doc.uncut",
                source: .zago,
                examples: [LogoPrimitiveExample(input: "UNCUT")]
            )

        case .justify:
            LogoPrimitiveMeta(
                name: "JUSTIFY",
                description: "Reflows and justifies paragraph text to wrap margin.",
                localizedDescriptionKey: "logo.doc.justify",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "width", required: false)],
                examples: [LogoPrimitiveExample(input: "JUSTIFY 72")]
            )

        case .goto:
            LogoPrimitiveMeta(
                name: "GOTO",
                description: "Moves cursor to 1-based row and optional visual column.",
                localizedDescriptionKey: "logo.doc.goto",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "row", required: true),
                    LogoPrimitiveParameter(name: "col", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "GOTO 10 5")]
            )

        case .box:
            LogoPrimitiveMeta(
                name: "BOX",
                description: "Draws an ASCII/Unicode box around current position or selection.",
                localizedDescriptionKey: "logo.doc.box",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: false),
                    LogoPrimitiveParameter(name: "height", required: false),
                    LogoPrimitiveParameter(name: "text", required: false),
                    LogoPrimitiveParameter(name: "align", required: false, allowedValues: ["left", "center", "right"]),
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["single", "heavy", "double", "round", "double-round", "ascii", "ascii-round"]),
                    LogoPrimitiveParameter(name: "exit", required: false, allowedValues: ["ne", "se", "nw", "sw", "down"])
                ],
                examples: [LogoPrimitiveExample(input: "BOX 30 5 \"Window \"center \"double")]
            )

        case .drawBox:
            LogoPrimitiveMeta(
                name: "DRAWBOX",
                description: "Overlays an ASCII/Unicode box at current position or selection.",
                localizedDescriptionKey: "logo.doc.drawbox",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: false),
                    LogoPrimitiveParameter(name: "height", required: false),
                    LogoPrimitiveParameter(name: "text", required: false),
                    LogoPrimitiveParameter(name: "align", required: false, allowedValues: ["left", "center", "right"]),
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["single", "heavy", "double", "round", "double-round", "ascii", "ascii-round"]),
                    LogoPrimitiveParameter(name: "exit", required: false, allowedValues: ["ne", "se", "nw", "sw", "down"])
                ],
                examples: [LogoPrimitiveExample(input: "DRAWBOX 20 4 \"Server \"center")]
            )

        case .inset:
            LogoPrimitiveMeta(
                name: "INSET",
                description: "Centers and insets text inside a box or rectangular region.",
                localizedDescriptionKey: "logo.doc.inset",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: false),
                    LogoPrimitiveParameter(name: "height", required: false),
                    LogoPrimitiveParameter(name: "text", required: true)
                ],
                examples: [
                    LogoPrimitiveExample(input: "INSET \"Hello"),
                    LogoPrimitiveExample(input: "INSET 20 5 \"Title")
                ]
            )

        case .line:
            LogoPrimitiveMeta(
                name: "LINE",
                description: "Draws horizontal rule with smart junction blending.",
                localizedDescriptionKey: "logo.doc.line",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "length", required: false),
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["single", "heavy", "double", "ascii"])
                ],
                examples: [LogoPrimitiveExample(input: "LINE 40 \"single")]
            )

        case .vline:
            LogoPrimitiveMeta(
                name: "VLINE",
                description: "Draws a vertical line with smart junction blending.",
                localizedDescriptionKey: "logo.doc.vline",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "height", required: false),
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["single", "double", "ascii"])
                ],
                examples: [LogoPrimitiveExample(input: "VLINE 8 \"single")]
            )

        case .table:
            LogoPrimitiveMeta(
                name: "TABLE",
                description: "Creates a Unicode/ASCII table grid or changes table border style.",
                localizedDescriptionKey: "logo.doc.table",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "rows", required: false),
                    LogoPrimitiveParameter(name: "cols", required: false),
                    LogoPrimitiveParameter(name: "cellwidth", required: false)
                ],
                examples: [
                    LogoPrimitiveExample(input: "TABLE"),
                    LogoPrimitiveExample(input: "TABLE 3 4 12"),
                    LogoPrimitiveExample(input: "TABLE BORDER \"double"),
                    LogoPrimitiveExample(input: "TABLE NEXTSTYLE")
                ]
            )

        case .newline:
            LogoPrimitiveMeta(
                name: "NEWLINE",
                description: "Inserts one or more newlines at current cursor position.",
                localizedDescriptionKey: "logo.doc.newline",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "count", required: false)],
                examples: [LogoPrimitiveExample(input: "NL 2")]
            )

        case .penDown:
            LogoPrimitiveMeta(
                name: "PENDOWN",
                description: "Lowers the turtle pen to enable line drawing during motion.",
                localizedDescriptionKey: "logo.doc.pendown",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PD")]
            )

        case .penUp:
            LogoPrimitiveMeta(
                name: "PENUP",
                description: "Lifts the turtle pen to move without drawing.",
                localizedDescriptionKey: "logo.doc.penup",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PU")]
            )

        case .forward:
            LogoPrimitiveMeta(
                name: "FORWARD",
                description: "Moves turtle forward along current heading.",
                localizedDescriptionKey: "logo.doc.forward",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "steps", required: false)],
                examples: [LogoPrimitiveExample(input: "FD 10")]
            )

        case .back:
            LogoPrimitiveMeta(
                name: "BACK",
                description: "Moves turtle backward along opposite heading.",
                localizedDescriptionKey: "logo.doc.back",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "steps", required: false)],
                examples: [LogoPrimitiveExample(input: "BK 5")]
            )

        case .turnRight:
            LogoPrimitiveMeta(
                name: "RIGHT",
                description: "Turns turtle heading 90 degrees clockwise.",
                localizedDescriptionKey: "logo.doc.right",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "RT")]
            )

        case .turnLeft:
            LogoPrimitiveMeta(
                name: "LEFT",
                description: "Turns turtle heading 90 degrees counter-clockwise.",
                localizedDescriptionKey: "logo.doc.left",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "LT")]
            )

        case .setHeading:
            LogoPrimitiveMeta(
                name: "SETHEADING",
                description: "Sets turtle heading to UP, RIGHT, DOWN, or LEFT.",
                localizedDescriptionKey: "logo.doc.setheading",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "direction", required: true, allowedValues: ["UP", "RIGHT", "DOWN", "LEFT"])],
                examples: [LogoPrimitiveExample(input: "SETH \"DOWN")]
            )

        case .headingPrimitive:
            LogoPrimitiveMeta(
                name: "HEADING",
                description: "Returns current turtle heading direction string.",
                localizedDescriptionKey: "logo.doc.heading",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "SHOW HEADING", output: "RIGHT")]
            )

        case .ifCondition:
            LogoPrimitiveMeta(
                name: "IF",
                description: "Executes instructions if condition evaluates to true.",
                localizedDescriptionKey: "logo.doc.if",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "condition", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "IF :count > 0 [ TYPE \"Positive ]")]
            )

        case .ifElseCondition:
            LogoPrimitiveMeta(
                name: "IFELSE",
                description: "Executes true branch or false branch based on condition.",
                localizedDescriptionKey: "logo.doc.ifelse",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "condition", required: true),
                    LogoPrimitiveParameter(name: "trueBranch", required: true),
                    LogoPrimitiveParameter(name: "falseBranch", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "IFELSE :x > 0 [ SHOW \"Yes ] [ SHOW \"No ]")]
            )

        case .output:
            LogoPrimitiveMeta(
                name: "OUTPUT",
                description: "Returns a value from a custom procedure to caller.",
                localizedDescriptionKey: "logo.doc.output",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "OUTPUT :a + :b")]
            )

        case .repeatLoop:
            LogoPrimitiveMeta(
                name: "REPEAT",
                description: "Repeats block of instructions; :# holds 1-based loop counter.",
                localizedDescriptionKey: "logo.doc.repeat",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "count", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REPEAT 4 [ FD 5 RT ]")]
            )

        case .forLoop:
            LogoPrimitiveMeta(
                name: "FOR",
                description: "Iterates variable from start to stop with optional step.",
                localizedDescriptionKey: "logo.doc.for",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "spec", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "FOR [ i 1 10 2 ] [ TYPE :i NL ]")]
            )

        case .dotimesLoop:
            LogoPrimitiveMeta(
                name: "DOTIMES",
                description: "Iterates variable from 0 to limit - 1.",
                localizedDescriptionKey: "logo.doc.dotimes",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "spec", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "DOTIMES [ i 5 ] [ SHOW :i ]")]
            )

        case .whileLoop:
            LogoPrimitiveMeta(
                name: "WHILE",
                description: "Repeats instructions while condition evaluates to true.",
                localizedDescriptionKey: "logo.doc.while",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "condition", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "WHILE [ :x > 0 ] [ MAKE \"x :x - 1 ]")]
            )

        case .doWhileLoop:
            LogoPrimitiveMeta(
                name: "DO.WHILE",
                description: "Executes instructions at least once, repeating while condition is true.",
                localizedDescriptionKey: "logo.doc.dowhile",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "instructions", required: true),
                    LogoPrimitiveParameter(name: "condition", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "DO.WHILE [ MAKE \"x :x + 1 ] [ :x < 5 ]")]
            )

        case .untilLoop:
            LogoPrimitiveMeta(
                name: "UNTIL",
                description: "Repeats instructions until condition evaluates to true.",
                localizedDescriptionKey: "logo.doc.until",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "condition", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "UNTIL [ :done ] [ STEP ]")]
            )

        case .doUntilLoop:
            LogoPrimitiveMeta(
                name: "DO.UNTIL",
                description: "Executes instructions at least once, repeating until condition is true.",
                localizedDescriptionKey: "logo.doc.dountil",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "instructions", required: true),
                    LogoPrimitiveParameter(name: "condition", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "DO.UNTIL [ STEP ] [ :ready ]")]
            )

        case .caseSwitch:
            LogoPrimitiveMeta(
                name: "CASE",
                description: "Matches value against multiple branch clauses with optional ELSE.",
                localizedDescriptionKey: "logo.doc.case",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true),
                    LogoPrimitiveParameter(name: "clauses", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "CASE :mode [ [1 [SHOW \"One]] [ELSE [SHOW \"Other]] ]")]
            )

        case .condSwitch:
            LogoPrimitiveMeta(
                name: "COND",
                description: "Evaluates condition clauses sequentially until one is true.",
                localizedDescriptionKey: "logo.doc.cond",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "clauses", required: true)],
                examples: [LogoPrimitiveExample(input: "COND [ [[:x > 0] [SHOW \"+]] [ELSE [SHOW \"-]] ]")]
            )

        case .testCondition:
            LogoPrimitiveMeta(
                name: "TEST",
                description: "Sets internal test flag for subsequent IFTRUE / IFFALSE statements.",
                localizedDescriptionKey: "logo.doc.test",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "condition", required: true)],
                examples: [LogoPrimitiveExample(input: "TEST :x > 10")]
            )

        case .assertCondition:
            LogoPrimitiveMeta(
                name: "ASSERT",
                description: "Asserts that condition is true, throwing error on failure.",
                localizedDescriptionKey: "logo.doc.assert",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "condition", required: true),
                    LogoPrimitiveParameter(name: "message", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "ASSERT :count > 0 \"Must be positive")]
            )

        case .local:
            LogoPrimitiveMeta(
                name: "LOCAL",
                description: "Declares local variable(s) scoped to active procedure.",
                localizedDescriptionKey: "logo.doc.local",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "varname", required: true)],
                examples: [LogoPrimitiveExample(input: "LOCAL \"temp")]
            )

        case .pons:
            LogoPrimitiveMeta(
                name: "PONS",
                description: "Prints names and values of all defined variables in environment.",
                localizedDescriptionKey: "logo.doc.pons",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PONS")]
            )

        case .pops:
            LogoPrimitiveMeta(
                name: "POPS",
                description: "Prints definitions of all user procedures.",
                localizedDescriptionKey: "logo.doc.pops",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "POPS")]
            )

        case .povas:
            LogoPrimitiveMeta(
                name: "POVAS",
                description: "Prints definitions of all procedures and variables.",
                localizedDescriptionKey: "logo.doc.povas",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "POVAS")]
            )

        case .ifTrue:
            LogoPrimitiveMeta(
                name: "IFTRUE",
                description: "Executes instructions if preceding TEST was true.",
                localizedDescriptionKey: "logo.doc.iftrue",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "instructions", required: true)],
                examples: [LogoPrimitiveExample(input: "IFTRUE [ SHOW \"Passed ]")]
            )

        case .ifFalse:
            LogoPrimitiveMeta(
                name: "IFFALSE",
                description: "Executes instructions if preceding TEST was false.",
                localizedDescriptionKey: "logo.doc.iffalse",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "instructions", required: true)],
                examples: [LogoPrimitiveExample(input: "IFFALSE [ SHOW \"Failed ]")]
            )

        case .stop:
            LogoPrimitiveMeta(
                name: "STOP",
                description: "Terminates execution of current procedure immediately.",
                localizedDescriptionKey: "logo.doc.stop",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "STOP")]
            )

        case .catchTag:
            LogoPrimitiveMeta(
                name: "CATCH",
                description: "Catches a named THROW exception inside instruction block.",
                localizedDescriptionKey: "logo.doc.catch",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "tag", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "CATCH \"exit [ LOOP ]")]
            )

        case .throwTag:
            LogoPrimitiveMeta(
                name: "THROW",
                description: "Throws named exception to matching CATCH block.",
                localizedDescriptionKey: "logo.doc.throw",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "tag", required: true),
                    LogoPrimitiveParameter(name: "value", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "THROW \"exit 42")]
            )

        case .wait:
            LogoPrimitiveMeta(
                name: "WAIT",
                description: "Pauses execution for specified 1/60th second intervals.",
                localizedDescriptionKey: "logo.doc.wait",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "ticks", required: true)],
                examples: [LogoPrimitiveExample(input: "WAIT 60")]
            )

        case .bye:
            LogoPrimitiveMeta(
                name: "BYE",
                description: "Exits script execution immediately.",
                localizedDescriptionKey: "logo.doc.bye",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "BYE")]
            )

        case .apply:
            LogoPrimitiveMeta(
                name: "APPLY",
                description: "Applies a template or procedure to an argument list.",
                localizedDescriptionKey: "logo.doc.apply",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "template", required: true),
                    LogoPrimitiveParameter(name: "argslist", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "APPLY \"SUM [10 20]", output: "30")]
            )

        case .invoke:
            LogoPrimitiveMeta(
                name: "INVOKE",
                description: "Invokes a template with individual arguments.",
                localizedDescriptionKey: "logo.doc.invoke",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "template", required: true),
                    LogoPrimitiveParameter(name: "arg1", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "INVOKE [?1 + ?2] 10 20", output: "30")]
            )

        case .foreach:
            LogoPrimitiveMeta(
                name: "FOREACH",
                description: "Iterates through items in list; ? contains current item.",
                localizedDescriptionKey: "logo.doc.foreach",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true),
                    LogoPrimitiveParameter(name: "instructions", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "FOREACH [A B C] [ TYPE ? NL ]")]
            )

        case .map:
            LogoPrimitiveMeta(
                name: "MAP",
                description: "Transforms each list item with template function.",
                localizedDescriptionKey: "logo.doc.map",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "template", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MAP [? * 2] [1 2 3]", output: "[2 4 6]")]
            )

        case .mapSe:
            LogoPrimitiveMeta(
                name: "MAP.SE",
                description: "Maps template over list and flattens sentences.",
                localizedDescriptionKey: "logo.doc.mapse",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "template", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MAP.SE [LIST ? ?] [A B]", output: "[A A B B]")]
            )

        case .filter:
            LogoPrimitiveMeta(
                name: "FILTER",
                description: "Filters list items satisfying predicate condition.",
                localizedDescriptionKey: "logo.doc.filter",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "predicate", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "FILTER [? > 0] [-2 0 5 8]", output: "[5 8]")]
            )

        case .find:
            LogoPrimitiveMeta(
                name: "FIND",
                description: "Finds first item in list satisfying predicate.",
                localizedDescriptionKey: "logo.doc.find",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "predicate", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "FIND [? > 10] [5 12 8]", output: "12")]
            )

        case .reduce:
            LogoPrimitiveMeta(
                name: "REDUCE",
                description: "Combines list elements using two-argument reducer.",
                localizedDescriptionKey: "logo.doc.reduce",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "template", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REDUCE \"SUM [1 2 3 4]", output: "10")]
            )

        case .crossmap:
            LogoPrimitiveMeta(
                name: "CROSSMAP",
                description: "Computes Cartesian product mapping across multiple lists.",
                localizedDescriptionKey: "logo.doc.crossmap",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "template", required: true),
                    LogoPrimitiveParameter(name: "lists", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "CROSSMAP [WORD ?1 ?2] [[A B] [1 2]]", output: "[A1 A2 B1 B2]")]
            )

        case .run:
            LogoPrimitiveMeta(
                name: "RUN",
                description: "Executes a list of LOGO tokens or script string.",
                localizedDescriptionKey: "logo.doc.run",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "instructions", required: true)],
                examples: [LogoPrimitiveExample(input: "RUN [ TYPE \"Dynamic NL ]")]
            )

        case .runResult:
            LogoPrimitiveMeta(
                name: "RUNRESULT",
                description: "Runs expression and returns list with result or empty list.",
                localizedDescriptionKey: "logo.doc.runresult",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "expression", required: true)],
                examples: [LogoPrimitiveExample(input: "RUNRESULT [ 10 + 20 ]", output: "[30]")]
            )

        case .ignore:
            LogoPrimitiveMeta(
                name: "IGNORE",
                description: "Evaluates an expression and discards its return value.",
                localizedDescriptionKey: "logo.doc.ignore",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "IGNORE SUM 10 20")]
            )

        case .to:
            LogoPrimitiveMeta(
                name: "TO",
                description: "Defines a new custom LOGO procedure.",
                localizedDescriptionKey: "logo.doc.to",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "header", required: true)],
                examples: [LogoPrimitiveExample(input: "TO SQUARE :n OUTPUT :n * :n END")]
            )

        case .exec:
            LogoPrimitiveMeta(
                name: "EXEC",
                description: "Loads and executes external LOGO script file.",
                localizedDescriptionKey: "logo.doc.exec",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "filepath", required: true)],
                examples: [LogoPrimitiveExample(input: "EXEC \"setup.logo")]
            )

        // MARK: - Multi-Buffer & Buffer Primitives
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
                    LogoPrimitiveParameter(name: "text", required: true)
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

        // MARK: - Expression & Data Primitives
        case .thing:
            LogoPrimitiveMeta(
                name: "THING",
                description: "Returns value of named variable (same as :var).",
                localizedDescriptionKey: "logo.doc.thing",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "varname", required: true)],
                examples: [LogoPrimitiveExample(input: "THING \"count")]
            )

        case .word:
            LogoPrimitiveMeta(
                name: "WORD",
                description: "Concatenates words into a single word string.",
                localizedDescriptionKey: "logo.doc.word",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "word1", required: true),
                    LogoPrimitiveParameter(name: "word2", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "WORD \"Hello \"World", output: "HelloWorld")]
            )

        case .list:
            LogoPrimitiveMeta(
                name: "LIST",
                description: "Creates a new list from supplied items.",
                localizedDescriptionKey: "logo.doc.list",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item1", required: true),
                    LogoPrimitiveParameter(name: "item2", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LIST 1 2", output: "[1 2]")]
            )

        case .sentence:
            LogoPrimitiveMeta(
                name: "SENTENCE",
                description: "Combines items or list elements into a single flattened list.",
                localizedDescriptionKey: "logo.doc.sentence",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item1", required: true),
                    LogoPrimitiveParameter(name: "item2", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SE [Hello] [World]", output: "[Hello World]")]
            )

        case .fput:
            LogoPrimitiveMeta(
                name: "FPUT",
                description: "Prepends item to the front of list or string.",
                localizedDescriptionKey: "logo.doc.fput",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "FPUT 0 [1 2 3]", output: "[0 1 2 3]")]
            )

        case .lput:
            LogoPrimitiveMeta(
                name: "LPUT",
                description: "Appends item to the end of list or string.",
                localizedDescriptionKey: "logo.doc.lput",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LPUT 4 [1 2 3]", output: "[1 2 3 4]")]
            )

        case .array:
            LogoPrimitiveMeta(
                name: "ARRAY",
                description: "Creates fixed-size indexed array.",
                localizedDescriptionKey: "logo.doc.array",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "size", required: true),
                    LogoPrimitiveParameter(name: "origin", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "ARRAY 10")]
            )

        case .mdarray:
            LogoPrimitiveMeta(
                name: "MDARRAY",
                description: "Creates multi-dimensional nested array.",
                localizedDescriptionKey: "logo.doc.mdarray",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "dimensions", required: true)],
                examples: [LogoPrimitiveExample(input: "MDARRAY [3 3]")]
            )

        case .mditem:
            LogoPrimitiveMeta(
                name: "MDITEM",
                description: "Accesses item in multi-dimensional array at indices.",
                localizedDescriptionKey: "logo.doc.mditem",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "indices", required: true),
                    LogoPrimitiveParameter(name: "array", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MDITEM [1 2] :grid")]
            )

        case .mdsetItem:
            LogoPrimitiveMeta(
                name: "MDSETITEM",
                description: "Sets value in multi-dimensional array at indices.",
                localizedDescriptionKey: "logo.doc.mdsetitem",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "indices", required: true),
                    LogoPrimitiveParameter(name: "array", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MDSETITEM [1 2] :grid 99")]
            )

        case .listToArray:
            LogoPrimitiveMeta(
                name: "LISTTOARRAY",
                description: "Converts list to fixed-size array.",
                localizedDescriptionKey: "logo.doc.listtoarray",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "list", required: true)],
                examples: [LogoPrimitiveExample(input: "LISTTOARRAY [A B C]")]
            )

        case .arrayToList:
            LogoPrimitiveMeta(
                name: "ARRAYTOLIST",
                description: "Converts array to list.",
                localizedDescriptionKey: "logo.doc.arraytolist",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "array", required: true)],
                examples: [LogoPrimitiveExample(input: "ARRAYTOLIST :myArr")]
            )

        case .combine:
            LogoPrimitiveMeta(
                name: "COMBINE",
                description: "Combines item with data (prepends or appends based on type).",
                localizedDescriptionKey: "logo.doc.combine",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "COMBINE \"A [B C]", output: "[A B C]")]
            )

        case .reverse:
            LogoPrimitiveMeta(
                name: "REVERSE",
                description: "Reverses items in list, array, or characters in word.",
                localizedDescriptionKey: "logo.doc.reverse",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "REVERSE [1 2 3]", output: "[3 2 1]")]
            )

        case .gensym:
            LogoPrimitiveMeta(
                name: "GENSYM",
                description: "Generates unique symbol name (e.g. G1, G2).",
                localizedDescriptionKey: "logo.doc.gensym",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "MAKE \"sym GENSYM")]
            )

        case .first:
            LogoPrimitiveMeta(
                name: "FIRST",
                description: "Returns first element of list or first character of word.",
                localizedDescriptionKey: "logo.doc.first",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "FIRST [Apple Banana]", output: "Apple")]
            )

        case .last:
            LogoPrimitiveMeta(
                name: "LAST",
                description: "Returns last element of list or last character of word.",
                localizedDescriptionKey: "logo.doc.last",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "LAST [Apple Banana]", output: "Banana")]
            )

        case .firsts:
            LogoPrimitiveMeta(
                name: "FIRSTS",
                description: "Returns list containing first element of each sublist.",
                localizedDescriptionKey: "logo.doc.firsts",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "listOfLists", required: true)],
                examples: [LogoPrimitiveExample(input: "FIRSTS [[A 1] [B 2]]", output: "[A B]")]
            )

        case .butFirst:
            LogoPrimitiveMeta(
                name: "BUTFIRST",
                description: "Returns list or word without its first element.",
                localizedDescriptionKey: "logo.doc.butfirst",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "BF [A B C]", output: "[B C]")]
            )

        case .butLast:
            LogoPrimitiveMeta(
                name: "BUTLAST",
                description: "Returns list or word without its last element.",
                localizedDescriptionKey: "logo.doc.butlast",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "BL [A B C]", output: "[A B]")]
            )

        case .butFirsts:
            LogoPrimitiveMeta(
                name: "BUTFIRSTS",
                description: "Returns list of sublists without their first elements.",
                localizedDescriptionKey: "logo.doc.butfirsts",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "listOfLists", required: true)],
                examples: [LogoPrimitiveExample(input: "BFS [[A 1] [B 2]]", output: "[[1] [2]]")]
            )

        case .item:
            LogoPrimitiveMeta(
                name: "ITEM",
                description: "Returns 1-based nth element of list, array, or word.",
                localizedDescriptionKey: "logo.doc.item",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "index", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "ITEM 2 [Apple Banana Orange]", output: "Banana")]
            )

        case .pick:
            LogoPrimitiveMeta(
                name: "PICK",
                description: "Randomly selects an element from list, array, or word.",
                localizedDescriptionKey: "logo.doc.pick",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "PICK [Heads Tails]")]
            )

        case .remove:
            LogoPrimitiveMeta(
                name: "REMOVE",
                description: "Removes all occurrences of item from list or word.",
                localizedDescriptionKey: "logo.doc.remove",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REMOVE 2 [1 2 3 2 4]", output: "[1 3 4]")]
            )

        case .remdup:
            LogoPrimitiveMeta(
                name: "REMDUP",
                description: "Removes duplicate elements from list or word preserving first order.",
                localizedDescriptionKey: "logo.doc.remdup",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "REMDUP [1 2 2 3 1]", output: "[1 2 3]")]
            )

        case .quoted:
            LogoPrimitiveMeta(
                name: "QUOTED",
                description: "Wraps word with leading double-quote literal.",
                localizedDescriptionKey: "logo.doc.quoted",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "QUOTED \"test", output: "\"test")]
            )

        case .split:
            LogoPrimitiveMeta(
                name: "SPLIT",
                description: "Splits string by delimiter into list of tokens.",
                localizedDescriptionKey: "logo.doc.split",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "separator", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SPLIT \"a,b,c \",", output: "[a b c]")]
            )

        case .setItem:
            LogoPrimitiveMeta(
                name: "SETITEM",
                description: "Mutates element at index in array.",
                localizedDescriptionKey: "logo.doc.setitem",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "index", required: true),
                    LogoPrimitiveParameter(name: "array", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SETITEM 1 :arr \"New")]
            )

        case .setFirst:
            LogoPrimitiveMeta(
                name: "SETFIRST",
                description: "Mutates first element of list in-place.",
                localizedDescriptionKey: "logo.doc.setfirst",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SETFIRST :myList 99")]
            )

        case .setBFL:
            LogoPrimitiveMeta(
                name: "SETBUTFIRST",
                description: "Mutates butfirst rest of list in-place.",
                localizedDescriptionKey: "logo.doc.setbutfirst",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true),
                    LogoPrimitiveParameter(name: "newRest", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SETBUTFIRST :myList [X Y]")]
            )

        case .push:
            LogoPrimitiveMeta(
                name: "PUSH",
                description: "Pushes item onto variable stack list.",
                localizedDescriptionKey: "logo.doc.push",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "stackVar", required: true),
                    LogoPrimitiveParameter(name: "item", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "PUSH \"stack 42")]
            )

        case .pop:
            LogoPrimitiveMeta(
                name: "POP",
                description: "Pops and returns top item from variable stack list.",
                localizedDescriptionKey: "logo.doc.pop",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "stackVar", required: true)],
                examples: [LogoPrimitiveExample(input: "MAKE \"top POP \"stack")]
            )

        case .dequeue:
            LogoPrimitiveMeta(
                name: "DEQUEUE",
                description: "Dequeues and returns front item from variable queue list.",
                localizedDescriptionKey: "logo.doc.dequeue",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "queueVar", required: true)],
                examples: [LogoPrimitiveExample(input: "MAKE \"item DEQUEUE \"q")]
            )

        case .pprop:
            LogoPrimitiveMeta(
                name: "PPROP",
                description: "Puts property key-value pair into property list.",
                localizedDescriptionKey: "logo.doc.pprop",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "plistName", required: true),
                    LogoPrimitiveParameter(name: "propName", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "PPROP \"person \"age 30")]
            )

        case .gprop:
            LogoPrimitiveMeta(
                name: "GPROP",
                description: "Gets property value from property list.",
                localizedDescriptionKey: "logo.doc.gprop",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "plistName", required: true),
                    LogoPrimitiveParameter(name: "propName", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "GPROP \"person \"age", output: "30")]
            )

        case .remprop:
            LogoPrimitiveMeta(
                name: "REMPROP",
                description: "Removes property from property list.",
                localizedDescriptionKey: "logo.doc.remprop",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "plistName", required: true),
                    LogoPrimitiveParameter(name: "propName", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REMPROP \"person \"age")]
            )

        case .plist:
            LogoPrimitiveMeta(
                name: "PLIST",
                description: "Returns alternating key-value list for named property list.",
                localizedDescriptionKey: "logo.doc.plist",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "plistName", required: true)],
                examples: [LogoPrimitiveExample(input: "PLIST \"person")]
            )

        case .plists:
            LogoPrimitiveMeta(
                name: "PLISTS",
                description: "Returns list of all active property list names.",
                localizedDescriptionKey: "logo.doc.plists",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PLISTS")]
            )

        case .error:
            LogoPrimitiveMeta(
                name: "ERROR",
                description: "Returns list describing last uncaught error [code message proc].",
                localizedDescriptionKey: "logo.doc.error",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERROR")]
            )

        case .isWord:
            LogoPrimitiveMeta(
                name: "WORD?",
                description: "Tests whether value is a word/string.",
                localizedDescriptionKey: "logo.doc.isword",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "WORD? \"hello", output: "true")]
            )

        case .isList:
            LogoPrimitiveMeta(
                name: "LIST?",
                description: "Tests whether value is a list.",
                localizedDescriptionKey: "logo.doc.islist",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "LIST? [1 2]", output: "true")]
            )

        case .isArray:
            LogoPrimitiveMeta(
                name: "ARRAY?",
                description: "Tests whether value is an array.",
                localizedDescriptionKey: "logo.doc.isarray",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "ARRAY? :arr")]
            )

        case .isNumber:
            LogoPrimitiveMeta(
                name: "NUMBER?",
                description: "Tests whether value is a valid numeric value.",
                localizedDescriptionKey: "logo.doc.isnumber",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "NUMBER? 42", output: "true")]
            )

        case .isEmpty:
            LogoPrimitiveMeta(
                name: "EMPTY?",
                description: "Tests whether word, list, or array is empty.",
                localizedDescriptionKey: "logo.doc.isempty",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "EMPTY? []", output: "true")]
            )

        case .isEqual:
            LogoPrimitiveMeta(
                name: "EQUAL?",
                description: "Tests whether two values are equal.",
                localizedDescriptionKey: "logo.doc.isequal",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "EQUAL? 10 10", output: "true")]
            )

        case .isNotEqual:
            LogoPrimitiveMeta(
                name: "NOTEQUAL?",
                description: "Tests whether two values are not equal.",
                localizedDescriptionKey: "logo.doc.isnotequal",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "NOTEQUAL? 1 2", output: "true")]
            )

        case .isIdentityEqual:
            LogoPrimitiveMeta(
                name: ".EQ",
                description: "Tests reference identity equality between arrays or lists.",
                localizedDescriptionKey: "logo.doc.isidentity",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: ".EQ :a :b")]
            )

        case .isBefore:
            LogoPrimitiveMeta(
                name: "BEFORE?",
                description: "Tests alphabetical ordering of two strings.",
                localizedDescriptionKey: "logo.doc.isbefore",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "BEFORE? \"apple \"banana", output: "true")]
            )

        case .isMember:
            LogoPrimitiveMeta(
                name: "MEMBER?",
                description: "Tests whether item is contained in list or word.",
                localizedDescriptionKey: "logo.doc.ismember",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MEMBER? 2 [1 2 3]", output: "true")]
            )

        case .isSubstring:
            LogoPrimitiveMeta(
                name: "SUBSTRING?",
                description: "Tests whether sub is a substring of string.",
                localizedDescriptionKey: "logo.doc.issubstring",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "sub", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SUBSTRING? \"log \"logo", output: "true")]
            )

        case .isProcedure:
            LogoPrimitiveMeta(
                name: "PROCEDURE?",
                description: "Tests whether name is a defined custom procedure.",
                localizedDescriptionKey: "logo.doc.isprocedure",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "name", required: true)],
                examples: [LogoPrimitiveExample(input: "PROCEDURE? \"square")]
            )

        case .isPrimitive:
            LogoPrimitiveMeta(
                name: "PRIMITIVE?",
                description: "Tests whether name is a built-in primitive.",
                localizedDescriptionKey: "logo.doc.isprimitive",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "name", required: true)],
                examples: [LogoPrimitiveExample(input: "PRIMITIVE? \"sum", output: "true")]
            )

        case .isDefined:
            LogoPrimitiveMeta(
                name: "DEFINED?",
                description: "Tests whether name is a defined procedure or primitive.",
                localizedDescriptionKey: "logo.doc.isdefined",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "name", required: true)],
                examples: [LogoPrimitiveExample(input: "DEFINED? \"box", output: "true")]
            )

        case .isName:
            LogoPrimitiveMeta(
                name: "NAME?",
                description: "Tests whether variable name exists in environment.",
                localizedDescriptionKey: "logo.doc.isname",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "varname", required: true)],
                examples: [LogoPrimitiveExample(input: "NAME? \"count")]
            )

        case .count:
            LogoPrimitiveMeta(
                name: "COUNT",
                description: "Returns item count of list, array, or character count of word.",
                localizedDescriptionKey: "logo.doc.count",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "COUNT [1 2 3 4]", output: "4")]
            )

        case .ascii:
            LogoPrimitiveMeta(
                name: "ASCII",
                description: "Returns integer Unicode code point of character.",
                localizedDescriptionKey: "logo.doc.ascii",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "char", required: true)],
                examples: [LogoPrimitiveExample(input: "ASCII \"A", output: "65")]
            )

        case .char:
            LogoPrimitiveMeta(
                name: "CHAR",
                description: "Returns character string corresponding to integer Unicode code point.",
                localizedDescriptionKey: "logo.doc.char",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "codepoint", required: true)],
                examples: [LogoPrimitiveExample(input: "CHAR 65", output: "A")]
            )

        case .member:
            LogoPrimitiveMeta(
                name: "MEMBER",
                description: "Returns sublist or subword starting from first occurrence of item.",
                localizedDescriptionKey: "logo.doc.member",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MEMBER 3 [1 2 3 4 5]", output: "[3 4 5]")]
            )

        case .uppercase:
            LogoPrimitiveMeta(
                name: "UPPERCASE",
                description: "Converts word to uppercase characters.",
                localizedDescriptionKey: "logo.doc.uppercase",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "UPPERCASE \"hello", output: "HELLO")]
            )

        case .lowercase:
            LogoPrimitiveMeta(
                name: "LOWERCASE",
                description: "Converts word to lowercase characters.",
                localizedDescriptionKey: "logo.doc.lowercase",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "LOWERCASE \"HELLO", output: "hello")]
            )

        case .standout:
            LogoPrimitiveMeta(
                name: "STANDOUT",
                description: "Wraps text with ANSI reverse standout escape codes.",
                localizedDescriptionKey: "logo.doc.standout",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true)],
                examples: [LogoPrimitiveExample(input: "STANDOUT \"Alert")]
            )

        case .translit:
            LogoPrimitiveMeta(
                name: "TRANSLIT",
                description: "Applies ICU transliteration transform to string.",
                localizedDescriptionKey: "logo.doc.translit",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "transform", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "TRANSLIT \"Traditional-Simplified \"繁體", output: "繁体")]
            )

        case .transformToHans:
            LogoPrimitiveMeta(
                name: "TOHANS",
                description: "Converts Traditional Chinese text to Simplified Chinese.",
                localizedDescriptionKey: "logo.doc.tohans",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOHANS \"繁體中文", output: "繁体中文")]
            )

        case .transformToHant:
            LogoPrimitiveMeta(
                name: "TOHANT",
                description: "Converts Simplified Chinese text to Traditional Chinese.",
                localizedDescriptionKey: "logo.doc.tohant",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOHANT \"简体中文", output: "簡體中文")]
            )

        case .transformToLatin:
            LogoPrimitiveMeta(
                name: "TOLATIN",
                description: "Transliterates text to Latin romanized script.",
                localizedDescriptionKey: "logo.doc.tolatin",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOLATIN \"中文", output: "zhōng wén")]
            )

        case .transformToHiragana:
            LogoPrimitiveMeta(
                name: "TOHIRAGANA",
                description: "Converts any text to Hiragana.",
                localizedDescriptionKey: "logo.doc.tohiragana",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOHIRAGANA \"カタカナ", output: "かたかな")]
            )

        case .transformToKatakana:
            LogoPrimitiveMeta(
                name: "TOKATAKANA",
                description: "Converts any text to Katakana.",
                localizedDescriptionKey: "logo.doc.tokatakana",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOKATAKANA \"ひらがな", output: "ヒラガナ")]
            )

        case .transformToRomaji:
            LogoPrimitiveMeta(
                name: "TOROMAJI",
                description: "Transliterates Japanese Kana to Romaji.",
                localizedDescriptionKey: "logo.doc.toromaji",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOROMAJI \"とうきょう", output: "tōkyō")]
            )

        case .spacingCJK:
            LogoPrimitiveMeta(
                name: "SPACING.CJK",
                description: "Formats typography spacing between CJK and Western alphanumeric characters.",
                localizedDescriptionKey: "logo.doc.spacingcjk",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "SPACING.CJK \"使用Zago編輯器\"", output: "使用 Zago 編輯器")]
            )

        case .charCount:
            LogoPrimitiveMeta(
                name: "CHARCOUNT",
                description: "Counts total Unicode grapheme clusters in string.",
                localizedDescriptionKey: "logo.doc.countchars",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT \"Hello 世界", output: "8")]
            )

        case .charCountCJK:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.CJK",
                description: "Counts CJK ideograph characters in string.",
                localizedDescriptionKey: "logo.doc.countcjk",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.CJK \"Hello 世界", output: "2")]
            )

        case .charCountWords:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.WORDS",
                description: "Counts words in natural language string.",
                localizedDescriptionKey: "logo.doc.countwords",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.WORDS \"Quick brown fox", output: "3")]
            )

        case .charCountEmoji:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.EMOJI",
                description: "Counts emoji glyphs in string.",
                localizedDescriptionKey: "logo.doc.countemoji",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.EMOJI \"🚀✨🎉", output: "3")]
            )

        case .charCountLines:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.LINES",
                description: "Counts lines in multiline string.",
                localizedDescriptionKey: "logo.doc.countlines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.LINES :multilineStr")]
            )

        case .parse:
            LogoPrimitiveMeta(
                name: "PARSE",
                description: "Parses string into a LOGO token list.",
                localizedDescriptionKey: "logo.doc.parse",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "PARSE \"[FD 10 RT]", output: "[FD 10 RT]")]
            )

        case .runparse:
            LogoPrimitiveMeta(
                name: "RUNPARSE",
                description: "Parses word string into tokenized list.",
                localizedDescriptionKey: "logo.doc.runparse",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "RUNPARSE \"FD 10", output: "[FD 10]")]
            )

        // MARK: - String & Regex Primitives
        case .indexof:
            LogoPrimitiveMeta(
                name: "INDEXOF",
                description: "Returns 1-based index of first substring occurrence.",
                localizedDescriptionKey: "logo.doc.indexof",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "start", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "INDEXOF \"world \"hello world", output: "7")]
            )

        case .lastindexof:
            LogoPrimitiveMeta(
                name: "LASTINDEXOF",
                description: "Returns 1-based index of last substring occurrence.",
                localizedDescriptionKey: "logo.doc.lastindexof",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LASTINDEXOF \"o \"hello world", output: "8")]
            )

        case .indexesof:
            LogoPrimitiveMeta(
                name: "INDEXESOF",
                description: "Returns list of all 1-based match positions of substring.",
                localizedDescriptionKey: "logo.doc.indexesof",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "INDEXESOF \"l \"hello world", output: "[3 4 10]")]
            )

        case .contains:
            LogoPrimitiveMeta(
                name: "CONTAINS?",
                description: "Tests whether string contains substring.",
                localizedDescriptionKey: "logo.doc.contains",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "substring", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "CONTAINS? \"zago \"ag", output: "true")]
            )

        case .startswith:
            LogoPrimitiveMeta(
                name: "STARTSWITH?",
                description: "Tests whether string starts with specified prefix.",
                localizedDescriptionKey: "logo.doc.startswith",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "prefix", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "STARTSWITH? \"index.html \"index", output: "true")]
            )

        case .endswith:
            LogoPrimitiveMeta(
                name: "ENDSWITH?",
                description: "Tests whether string ends with specified suffix.",
                localizedDescriptionKey: "logo.doc.endswith",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "suffix", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "ENDSWITH? \"main.swift \".swift", output: "true")]
            )

        case .substring:
            LogoPrimitiveMeta(
                name: "SUBSTRING",
                description: "Extracts substring from 1-based start index with optional length.",
                localizedDescriptionKey: "logo.doc.substring",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "start", required: true),
                    LogoPrimitiveParameter(name: "length", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "SUBSTRING \"abcdef 2 3", output: "bcd")]
            )

        case .replace:
            LogoPrimitiveMeta(
                name: "REPLACE",
                description: "Replaces occurrences of substring with replacement string.",
                localizedDescriptionKey: "logo.doc.replace",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "old", required: true),
                    LogoPrimitiveParameter(name: "new", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REPLACE \"hello world \"world \"there", output: "hello there")]
            )

        case .trim:
            LogoPrimitiveMeta(
                name: "TRIM",
                description: "Trims whitespace from both ends of string.",
                localizedDescriptionKey: "logo.doc.trim",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TRIM \"  hello  ", output: "hello")]
            )

        case .repeatstr:
            LogoPrimitiveMeta(
                name: "REPEATSTR",
                description: "Repeats string specified number of times.",
                localizedDescriptionKey: "logo.doc.repeatstr",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "count", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REPEATSTR 5 \"=", output: "=====")]
            )

        case .join:
            LogoPrimitiveMeta(
                name: "JOINSTR",
                description: "Joins list elements into single string using separator.",
                localizedDescriptionKey: "logo.doc.joinstr",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "separator", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "JOINSTR \", \" [A B C]", output: "A, B, C")]
            )

        case .lines:
            LogoPrimitiveMeta(
                name: "LINES",
                description: "Splits multiline string into list of individual lines.",
                localizedDescriptionKey: "logo.doc.lines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "multilineString", required: true)],
                examples: [LogoPrimitiveExample(input: "LINES :buffer")]
            )

        case .unlines:
            LogoPrimitiveMeta(
                name: "UNLINES",
                description: "Joins list of lines into single multiline string with newlines.",
                localizedDescriptionKey: "logo.doc.unlines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "listOfLines", required: true)],
                examples: [LogoPrimitiveExample(input: "UNLINES [Line1 Line2]")]
            )

        case .format:
            LogoPrimitiveMeta(
                name: "FORMAT",
                description: "Formats string with printf-style specifiers (%d, %s, %f).",
                localizedDescriptionKey: "logo.doc.format",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "formatString", required: true),
                    LogoPrimitiveParameter(name: "args", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT \"Hello, %s! \"Zago", output: "Hello, Zago!")]
            )

        case .padleft:
            LogoPrimitiveMeta(
                name: "PADLEFT",
                description: "Pads string on left to target width.",
                localizedDescriptionKey: "logo.doc.padleft",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: true),
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "padChar", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "PADLEFT 8 \"42 \"0", output: "00000042")]
            )

        case .padright:
            LogoPrimitiveMeta(
                name: "PADRIGHT",
                description: "Pads string on right to target width.",
                localizedDescriptionKey: "logo.doc.padright",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: true),
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "padChar", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "PADRIGHT 10 \"Title \".", output: "Title.....")]
            )

        case .regexMatch:
            LogoPrimitiveMeta(
                name: "REGEX.MATCH",
                description: "Tests whether string matches regular expression pattern.",
                localizedDescriptionKey: "logo.doc.regexmatch",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "pattern", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.MATCH \"abc-123 \"[a-z]+-[0-9]+", output: "true")]
            )

        case .regexReplace:
            LogoPrimitiveMeta(
                name: "REGEX.REPLACE",
                description: "Replaces regular expression matches in string with replacement template.",
                localizedDescriptionKey: "logo.doc.regexreplace",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "pattern", required: true),
                    LogoPrimitiveParameter(name: "template", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.REPLACE \"hello 2026 \"[0-9]+ \"world", output: "hello world")]
            )

        case .regexFind:
            LogoPrimitiveMeta(
                name: "REGEX.FIND",
                description: "Returns list of regex capture groups or matching substrings.",
                localizedDescriptionKey: "logo.doc.regexfind",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "pattern", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REGEX.FIND \"abc-123 \"[0-9]+", output: "[123]")]
            )

        // MARK: - Comparison Primitives
        case .less:
            LogoPrimitiveMeta(
                name: "LESS?",
                description: "Tests whether a is strictly less than b (same as <).",
                localizedDescriptionKey: "logo.doc.less",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LESS? 3 5", output: "true")]
            )

        case .greater:
            LogoPrimitiveMeta(
                name: "GREATER?",
                description: "Tests whether a is strictly greater than b (same as >).",
                localizedDescriptionKey: "logo.doc.greater",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "GREATER? 10 5", output: "true")]
            )

        case .lessOrEqual:
            LogoPrimitiveMeta(
                name: "LESSEQUAL?",
                description: "Tests whether a is less than or equal to b (same as <=).",
                localizedDescriptionKey: "logo.doc.lessequal",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LESSEQUAL? 5 5", output: "true")]
            )

        case .greaterOrEqual:
            LogoPrimitiveMeta(
                name: "GREATEREQUAL?",
                description: "Tests whether a is greater than or equal to b (same as >=).",
                localizedDescriptionKey: "logo.doc.greaterequal",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "GREATEREQUAL? 10 5", output: "true")]
            )

        // MARK: - Logical Primitives
        case .trueVal:
            LogoPrimitiveMeta(
                name: "TRUE",
                description: "Boolean literal true (evaluates to \"true\").",
                localizedDescriptionKey: "logo.doc.true",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "TRUE", output: "true")]
            )

        case .falseVal:
            LogoPrimitiveMeta(
                name: "FALSE",
                description: "Boolean literal false (evaluates to \"false\").",
                localizedDescriptionKey: "logo.doc.false",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "FALSE", output: "false")]
            )

        case .andLogic:
            LogoPrimitiveMeta(
                name: "AND",
                description: "Logical AND operation across multiple conditions.",
                localizedDescriptionKey: "logo.doc.and",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "cond1", required: true),
                    LogoPrimitiveParameter(name: "cond2", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "AND (:x > 0) (:y > 0)")]
            )

        case .orLogic:
            LogoPrimitiveMeta(
                name: "OR",
                description: "Logical OR operation across multiple conditions.",
                localizedDescriptionKey: "logo.doc.or",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "cond1", required: true),
                    LogoPrimitiveParameter(name: "cond2", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "OR (:a = 1) (:b = 1)")]
            )

        case .xorLogic:
            LogoPrimitiveMeta(
                name: "XOR",
                description: "Logical exclusive-OR operation on two boolean conditions.",
                localizedDescriptionKey: "logo.doc.xor",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "XOR TRUE FALSE", output: "true")]
            )

        case .notLogic:
            LogoPrimitiveMeta(
                name: "NOT",
                description: "Logical negation of condition.",
                localizedDescriptionKey: "logo.doc.not",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "condition", required: true)],
                examples: [LogoPrimitiveExample(input: "NOT :ready")]
            )

        // MARK: - Math & Bitwise Primitives
        case .sum:
            LogoPrimitiveMeta(
                name: "SUM",
                description: "Calculates the arithmetic sum of numbers or lists.",
                localizedDescriptionKey: "logo.doc.sum",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SUM 10 20", output: "30")]
            )

        case .min:
            LogoPrimitiveMeta(
                name: "MIN",
                description: "Returns minimum numeric value from inputs.",
                localizedDescriptionKey: "logo.doc.min",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MIN 5 2 9", output: "2")]
            )

        case .max:
            LogoPrimitiveMeta(
                name: "MAX",
                description: "Returns maximum numeric value from inputs.",
                localizedDescriptionKey: "logo.doc.max",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MAX 5 2 9", output: "9")]
            )

        case .difference:
            LogoPrimitiveMeta(
                name: "DIFFERENCE",
                description: "Calculates difference between two numbers (a - b).",
                localizedDescriptionKey: "logo.doc.difference",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "DIFFERENCE 10 3", output: "7")]
            )

        case .product:
            LogoPrimitiveMeta(
                name: "PRODUCT",
                description: "Calculates arithmetic product of numbers.",
                localizedDescriptionKey: "logo.doc.product",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "PRODUCT 5 6", output: "30")]
            )

        case .quotient:
            LogoPrimitiveMeta(
                name: "QUOTIENT",
                description: "Calculates quotient of division (a / b).",
                localizedDescriptionKey: "logo.doc.quotient",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "QUOTIENT 10 2", output: "5")]
            )

        case .power:
            LogoPrimitiveMeta(
                name: "POWER",
                description: "Raises base to specified exponent power (base ^ exp).",
                localizedDescriptionKey: "logo.doc.power",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "base", required: true),
                    LogoPrimitiveParameter(name: "exponent", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "POWER 2 8", output: "256")]
            )

        case .remainder:
            LogoPrimitiveMeta(
                name: "REMAINDER",
                description: "Returns remainder of division.",
                localizedDescriptionKey: "logo.doc.remainder",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true),
                    LogoPrimitiveParameter(name: "div", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REMAINDER 10 3", output: "1")]
            )

        case .modulo:
            LogoPrimitiveMeta(
                name: "MODULO",
                description: "Returns positive modulo of division.",
                localizedDescriptionKey: "logo.doc.modulo",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true),
                    LogoPrimitiveParameter(name: "div", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MODULO -1 10", output: "9")]
            )

        case .minus:
            LogoPrimitiveMeta(
                name: "MINUS",
                description: "Returns arithmetic negation of number (-num).",
                localizedDescriptionKey: "logo.doc.minus",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "MINUS 42", output: "-42")]
            )

        case .abs:
            LogoPrimitiveMeta(
                name: "ABS",
                description: "Returns absolute value of number.",
                localizedDescriptionKey: "logo.doc.abs",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "ABS -5", output: "5")]
            )

        case .int:
            LogoPrimitiveMeta(
                name: "INT",
                description: "Truncates floating-point number to integer.",
                localizedDescriptionKey: "logo.doc.int",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "INT 3.8", output: "3")]
            )

        case .round:
            LogoPrimitiveMeta(
                name: "ROUND",
                description: "Rounds number to nearest integer.",
                localizedDescriptionKey: "logo.doc.round",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "ROUND 3.6", output: "4")]
            )

        case .sqrt:
            LogoPrimitiveMeta(
                name: "SQRT",
                description: "Calculates square root of non-negative number.",
                localizedDescriptionKey: "logo.doc.sqrt",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "SQRT 144", output: "12")]
            )

        case .exp:
            LogoPrimitiveMeta(
                name: "EXP",
                description: "Calculates exponential function (e ^ num).",
                localizedDescriptionKey: "logo.doc.exp",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "EXP 1", output: "2.718281828459045")]
            )

        case .log10:
            LogoPrimitiveMeta(
                name: "LOG10",
                description: "Calculates base-10 logarithm of number.",
                localizedDescriptionKey: "logo.doc.log10",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "LOG10 100", output: "2")]
            )

        case .ln:
            LogoPrimitiveMeta(
                name: "LN",
                description: "Calculates natural logarithm (base e) of number.",
                localizedDescriptionKey: "logo.doc.ln",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "LN 2.718281828459045", output: "1")]
            )

        case .arctan:
            LogoPrimitiveMeta(
                name: "ARCTAN",
                description: "Calculates inverse tangent in degrees.",
                localizedDescriptionKey: "logo.doc.arctan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true)],
                examples: [LogoPrimitiveExample(input: "ARCTAN 1", output: "45")]
            )

        case .sin:
            LogoPrimitiveMeta(
                name: "SIN",
                description: "Calculates sine of angle in degrees.",
                localizedDescriptionKey: "logo.doc.sin",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "degrees", required: true)],
                examples: [LogoPrimitiveExample(input: "SIN 90", output: "1")]
            )

        case .cos:
            LogoPrimitiveMeta(
                name: "COS",
                description: "Calculates cosine of angle in degrees.",
                localizedDescriptionKey: "logo.doc.cos",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "degrees", required: true)],
                examples: [LogoPrimitiveExample(input: "COS 0", output: "1")]
            )

        case .tan:
            LogoPrimitiveMeta(
                name: "TAN",
                description: "Calculates tangent of angle in degrees.",
                localizedDescriptionKey: "logo.doc.tan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "degrees", required: true)],
                examples: [LogoPrimitiveExample(input: "TAN 45", output: "1")]
            )

        case .radArctan:
            LogoPrimitiveMeta(
                name: "RADARCTAN",
                description: "Calculates inverse tangent in radians.",
                localizedDescriptionKey: "logo.doc.radarctan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true)],
                examples: [LogoPrimitiveExample(input: "RADARCTAN 1", output: "0.7853981633974483")]
            )

        case .radSin:
            LogoPrimitiveMeta(
                name: "RADSIN",
                description: "Calculates sine of angle in radians.",
                localizedDescriptionKey: "logo.doc.radsin",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true)],
                examples: [LogoPrimitiveExample(input: "RADSIN 1.5707963267948966", output: "1")]
            )

        case .radCos:
            LogoPrimitiveMeta(
                name: "RADCOS",
                description: "Calculates cosine of angle in radians.",
                localizedDescriptionKey: "logo.doc.radcos",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true)],
                examples: [LogoPrimitiveExample(input: "RADCOS 0", output: "1")]
            )

        case .radTan:
            LogoPrimitiveMeta(
                name: "RADTAN",
                description: "Calculates tangent of angle in radians.",
                localizedDescriptionKey: "logo.doc.radtan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true)],
                examples: [LogoPrimitiveExample(input: "RADTAN 0.7853981633974483", output: "1")]
            )

        case .iseq:
            LogoPrimitiveMeta(
                name: "ISEQ",
                description: "Generates integer sequence list from start to end.",
                localizedDescriptionKey: "logo.doc.iseq",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "start", required: true),
                    LogoPrimitiveParameter(name: "end", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "ISEQ 1 5", output: "[1 2 3 4 5]")]
            )

        case .rseq:
            LogoPrimitiveMeta(
                name: "RSEQ",
                description: "Generates evenly spaced real number sequence.",
                localizedDescriptionKey: "logo.doc.rseq",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "start", required: true),
                    LogoPrimitiveParameter(name: "end", required: true),
                    LogoPrimitiveParameter(name: "count", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "RSEQ 0 1 5", output: "[0 0.25 0.5 0.75 1]")]
            )

        case .random:
            LogoPrimitiveMeta(
                name: "RANDOM",
                description: "Generates pseudorandom integer from 0 to limit - 1.",
                localizedDescriptionKey: "logo.doc.random",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "limit", required: true)],
                examples: [LogoPrimitiveExample(input: "RANDOM 100")]
            )

        case .rerandom:
            LogoPrimitiveMeta(
                name: "RERANDOM",
                description: "Reseeds the random number generator.",
                localizedDescriptionKey: "logo.doc.rerandom",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "seed", required: false)],
                examples: [LogoPrimitiveExample(input: "RERANDOM 42")]
            )

        case .form:
            LogoPrimitiveMeta(
                name: "FORM",
                description: "Formats floating point number into fixed width and precision string.",
                localizedDescriptionKey: "logo.doc.form",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true),
                    LogoPrimitiveParameter(name: "width", required: true),
                    LogoPrimitiveParameter(name: "precision", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "FORM 3.14159 8 2", output: "    3.14")]
            )

        case .bitAnd:
            LogoPrimitiveMeta(
                name: "BIT.AND",
                description: "Performs bitwise AND operation on two integers.",
                localizedDescriptionKey: "logo.doc.bitand",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "BIT.AND 6 3", output: "2")]
            )

        case .bitOr:
            LogoPrimitiveMeta(
                name: "BIT.OR",
                description: "Performs bitwise OR operation on two integers.",
                localizedDescriptionKey: "logo.doc.bitor",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "BIT.OR 4 2", output: "6")]
            )

        case .bitXor:
            LogoPrimitiveMeta(
                name: "BIT.XOR",
                description: "Performs bitwise XOR operation on two integers.",
                localizedDescriptionKey: "logo.doc.bitxor",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "BIT.XOR 5 3", output: "6")]
            )

        case .bitNot:
            LogoPrimitiveMeta(
                name: "BIT.NOT",
                description: "Performs bitwise NOT operation on an integer.",
                localizedDescriptionKey: "logo.doc.bitnot",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "a", required: true)],
                examples: [LogoPrimitiveExample(input: "BIT.NOT 0", output: "-1")]
            )

        case .ashift:
            LogoPrimitiveMeta(
                name: "ASHIFT",
                description: "Performs arithmetic bitwise shift.",
                localizedDescriptionKey: "logo.doc.ashift",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true),
                    LogoPrimitiveParameter(name: "bits", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "ASHIFT 4 2", output: "16")]
            )

        case .lshift:
            LogoPrimitiveMeta(
                name: "LSHIFT",
                description: "Performs bitwise logical left shift.",
                localizedDescriptionKey: "logo.doc.lshift",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true),
                    LogoPrimitiveParameter(name: "bits", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LSHIFT 1 3", output: "8")]
            )

        case .rshift:
            LogoPrimitiveMeta(
                name: "RSHIFT",
                description: "Performs bitwise logical right shift.",
                localizedDescriptionKey: "logo.doc.rshift",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true),
                    LogoPrimitiveParameter(name: "bits", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "RSHIFT 16 2", output: "4")]
            )

        case .date:
            LogoPrimitiveMeta(
                name: "DATE",
                description: "Returns formatted current date string.",
                localizedDescriptionKey: "logo.doc.date",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "format", required: false),
                    LogoPrimitiveParameter(name: "locale", required: false),
                    LogoPrimitiveParameter(name: "tz", required: false),
                    LogoPrimitiveParameter(name: "cal", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "DATE \"iso")]
            )

        case .time:
            LogoPrimitiveMeta(
                name: "TIME",
                description: "Returns formatted current time string.",
                localizedDescriptionKey: "logo.doc.time",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "format", required: false),
                    LogoPrimitiveParameter(name: "locale", required: false),
                    LogoPrimitiveParameter(name: "tz", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "TIME")]
            )

        case .datetime:
            LogoPrimitiveMeta(
                name: "DATETIME",
                description: "Returns formatted current date and time string.",
                localizedDescriptionKey: "logo.doc.datetime",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "format", required: false),
                    LogoPrimitiveParameter(name: "locale", required: false),
                    LogoPrimitiveParameter(name: "tz", required: false),
                    LogoPrimitiveParameter(name: "cal", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "DATETIME \"full")]
            )

        case .dateformat:
            LogoPrimitiveMeta(
                name: "FORMAT.DATE",
                description: "Formats given date string into specified format and locale.",
                localizedDescriptionKey: "logo.doc.formatdate",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "dateStr", required: true),
                    LogoPrimitiveParameter(name: "format", required: false),
                    LogoPrimitiveParameter(name: "locale", required: false),
                    LogoPrimitiveParameter(name: "tz", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.DATE \"2026-12-31 \"long")]
            )

        case .dateadd:
            LogoPrimitiveMeta(
                name: "DATE.ADD",
                description: "Adds or subtracts time units (days, months, years, hours) to date.",
                localizedDescriptionKey: "logo.doc.dateadd",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "dateStr", required: true),
                    LogoPrimitiveParameter(name: "amount", required: true),
                    LogoPrimitiveParameter(name: "unit", required: false, allowedValues: ["days", "weeks", "months", "years", "hours", "minutes", "seconds"])
                ],
                examples: [LogoPrimitiveExample(input: "DATE.ADD DATE 7 \"days")]
            )

        case .datediff:
            LogoPrimitiveMeta(
                name: "DATE.DIFF",
                description: "Calculates time difference between two dates in specified units.",
                localizedDescriptionKey: "logo.doc.datediff",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "date1", required: true),
                    LogoPrimitiveParameter(name: "date2", required: true),
                    LogoPrimitiveParameter(name: "unit", required: false, allowedValues: ["days", "weeks", "months", "years", "hours", "minutes", "seconds"])
                ],
                examples: [LogoPrimitiveExample(input: "DATE.DIFF \"2026-12-31 DATE \"days")]
            )

        case .formatNumber:
            LogoPrimitiveMeta(
                name: "FORMAT.NUMBER",
                description: "Formats number using localized decimal, currency, percent, roman, or financial CJK uppercase.",
                localizedDescriptionKey: "logo.doc.formatnumber",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true),
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["decimal", "currency", "percent", "roman", "financial", "ordinal", "spellout"]),
                    LogoPrimitiveParameter(name: "locale", required: false),
                    LogoPrimitiveParameter(name: "currency", required: false),
                    LogoPrimitiveParameter(name: "precision", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.NUMBER 10050208 \"financial", output: "壹仟零伍萬零貳佰零捌")]
            )

        case .formatList:
            LogoPrimitiveMeta(
                name: "FORMAT.LIST",
                description: "Formats list into localized natural language string (and, or, unit).",
                localizedDescriptionKey: "logo.doc.formatlist",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true),
                    LogoPrimitiveParameter(name: "type", required: false, allowedValues: ["and", "or", "unit"]),
                    LogoPrimitiveParameter(name: "locale", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.LIST [A B C] \"and \"en_US", output: "A, B, and C")]
            )

        case .formatRelativeTime:
            LogoPrimitiveMeta(
                name: "FORMAT.RELATIVETIME",
                description: "Formats relative elapsed time description (e.g. '2 hours ago').",
                localizedDescriptionKey: "logo.doc.formatrelativetime",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true),
                    LogoPrimitiveParameter(name: "unit", required: true),
                    LogoPrimitiveParameter(name: "locale", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.RELATIVETIME -2 \"hour \"en_US", output: "2 hours ago")]
            )

        case .formatBytes:
            LogoPrimitiveMeta(
                name: "FORMAT.BYTES",
                description: "Formats byte counts into human-readable memory or file sizes (KB, MB, GB).",
                localizedDescriptionKey: "logo.doc.formatbytes",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "bytes", required: true),
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["file", "memory", "binary", "decimal", "bytes"]),
                    LogoPrimitiveParameter(name: "locale", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.BYTES 1048576", output: "1 MB")]
            )

        case .search:
            LogoPrimitiveMeta(
                name: "SEARCH",
                description: "Searches text in editor buffer and highlights occurrences.",
                localizedDescriptionKey: "logo.doc.search",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "query", required: true)],
                examples: [LogoPrimitiveExample(input: "SEARCH \"hello")]
            )

        case .sort:
            LogoPrimitiveMeta(
                name: "SORT",
                description: "Sorts elements in list alphabetically or numerically.",
                localizedDescriptionKey: "logo.doc.sort",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "list", required: true)],
                examples: [LogoPrimitiveExample(input: "SORT [3 1 4 1 5 9]", output: "[1 1 3 4 5 9]")]
            )

        case .fill:
            LogoPrimitiveMeta(
                name: "FILL",
                description: "Fills active canvas mark block or table cell with text pattern.",
                localizedDescriptionKey: "logo.doc.fill",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true)],
                examples: [LogoPrimitiveExample(input: "FILL \".\"")]
            )

        case .readWord:
            LogoPrimitiveMeta(
                name: "READWORD",
                description: "Prompts user to enter a line of text input.",
                localizedDescriptionKey: "logo.doc.readword",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "prompt", required: false)],
                examples: [LogoPrimitiveExample(input: "MAKE \"name READWORD \"Name: ")]
            )

        case .readChar:
            LogoPrimitiveMeta(
                name: "READCHAR",
                description: "Prompts user to press a single character key.",
                localizedDescriptionKey: "logo.doc.readchar",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "prompt", required: false)],
                examples: [LogoPrimitiveExample(input: "MAKE \"k READCHAR")]
            )

        case .names:
            LogoPrimitiveMeta(
                name: "NAMES",
                description: "Returns list of all variable names in current environment.",
                localizedDescriptionKey: "logo.doc.names",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "NAMES")]
            )

        case .procedures:
            LogoPrimitiveMeta(
                name: "PROCEDURES",
                description: "Returns list of all defined procedure names.",
                localizedDescriptionKey: "logo.doc.procedures",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PROCEDURES")]
            )

        case .primitives:
            LogoPrimitiveMeta(
                name: "PRIMITIVES",
                description: "Returns list of all built-in LOGO primitive names.",
                localizedDescriptionKey: "logo.doc.primitives",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PRIMITIVES")]
            )

        case .contents:
            LogoPrimitiveMeta(
                name: "CONTENTS",
                description: "Returns list of procedures, variables, and property lists [procs vars plists].",
                localizedDescriptionKey: "logo.doc.contents",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "CONTENTS")]
            )

        case .text:
            LogoPrimitiveMeta(
                name: "TEXT",
                description: "Returns definition token list of named procedure.",
                localizedDescriptionKey: "logo.doc.text",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "procname", required: true)],
                examples: [LogoPrimitiveExample(input: "TEXT \"square")]
            )

        case .define:
            LogoPrimitiveMeta(
                name: "DEFINE",
                description: "Defines procedure dynamically from parameter and instruction list.",
                localizedDescriptionKey: "logo.doc.define",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "procname", required: true),
                    LogoPrimitiveParameter(name: "textList", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "DEFINE \"double [[n] [OUTPUT :n * 2]]")]
            )

        case .erase:
            LogoPrimitiveMeta(
                name: "ERASE",
                description: "Erases named custom procedure definition.",
                localizedDescriptionKey: "logo.doc.erase",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "procname", required: true)],
                examples: [LogoPrimitiveExample(input: "ERASE \"oldProc")]
            )

        case .erps:
            LogoPrimitiveMeta(
                name: "ERPS",
                description: "Erases all user procedure definitions.",
                localizedDescriptionKey: "logo.doc.erps",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERPS")]
            )

        case .erns:
            LogoPrimitiveMeta(
                name: "ERNS",
                description: "Erases all variable bindings in environment.",
                localizedDescriptionKey: "logo.doc.erns",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERNS")]
            )

        case .erall:
            LogoPrimitiveMeta(
                name: "ERALL",
                description: "Erases all procedures, variables, and property lists.",
                localizedDescriptionKey: "logo.doc.erall",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERALL")]
            )

        case .arity:
            LogoPrimitiveMeta(
                name: "ARITY",
                description: "Returns expected argument count of procedure or primitive.",
                localizedDescriptionKey: "logo.doc.arity",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "procname", required: true)],
                examples: [LogoPrimitiveExample(input: "ARITY \"sum", output: "2")]
            )

        case .doc:
            LogoPrimitiveMeta(
                name: "DOC",
                description: "Returns documentation docstring for procedure or built-in primitive.",
                localizedDescriptionKey: "logo.doc.doc",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "name", required: true)],
                examples: [LogoPrimitiveExample(input: "DOC \"BOX")]
            )

        case .end:
            LogoPrimitiveMeta(
                name: "END",
                description: "Marks the end of a procedure definition block.",
                localizedDescriptionKey: "logo.doc.end",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "END")]
            )
        }
    }
}
