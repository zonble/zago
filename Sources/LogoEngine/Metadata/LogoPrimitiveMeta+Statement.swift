import Foundation

extension LogoPrimitive {
    var statementMeta: LogoPrimitiveMeta? {
        switch self {
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
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "TYPE \"Hello")]
            )

        case .show:
            LogoPrimitiveMeta(
                name: "SHOW",
                description: "Displays a status message or formatted output to the user.",
                localizedDescriptionKey: "logo.doc.show",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
                ],
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
                parameters: [
                    LogoPrimitiveParameter(name: "text", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "APPEND \" (done)")]
            )

        case .prependText:
            LogoPrimitiveMeta(
                name: "PREPEND",
                description: "Prepends text to the start of current line.",
                localizedDescriptionKey: "logo.doc.prepend",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "text", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
                ],
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
                    LogoPrimitiveParameter(name: "direction", required: true, allowedValues: ["UP", "DOWN", "LEFT", "RIGHT", "HOME", "END"]),
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
                examples: [LogoPrimitiveExample(input: "JUSTIFY")]
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
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["single", "heavy", "double", "round", "double-round", "ascii", "ascii-round"]),
                    LogoPrimitiveParameter(name: "arrow", required: false, allowedValues: ["arrow", "backarrow", "botharrow", "rightarrow", "leftarrow", "downarrow", "uparrow", "both", "bidir"]),
                    LogoPrimitiveParameter(name: "arrowStyle", required: false, allowedValues: ["solid", "stemmed", "hollow", "small"])
                ],
                examples: [
                    LogoPrimitiveExample(input: "LINE 40 \"single"),
                    LogoPrimitiveExample(input: "LINE 10 \"arrow \"hollow")
                ]
            )

        case .vline:
            LogoPrimitiveMeta(
                name: "VLINE",
                description: "Draws a vertical line with smart junction blending.",
                localizedDescriptionKey: "logo.doc.vline",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "height", required: false),
                    LogoPrimitiveParameter(name: "style", required: false, allowedValues: ["single", "heavy", "double", "round", "double-round", "ascii", "ascii-round"]),
                    LogoPrimitiveParameter(name: "arrow", required: false, allowedValues: ["arrow", "backarrow", "botharrow", "rightarrow", "leftarrow", "downarrow", "uparrow", "both", "bidir"]),
                    LogoPrimitiveParameter(name: "arrowStyle", required: false, allowedValues: ["solid", "stemmed", "hollow", "small"])
                ],
                examples: [
                    LogoPrimitiveExample(input: "VLINE 8 \"single"),
                    LogoPrimitiveExample(input: "VLINE 5 \"arrow \"stemmed")
                ]
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
                    LogoPrimitiveParameter(name: "cellwidth", required: false),
                    LogoPrimitiveParameter(name: "mode", required: false, allowedValues: ["BORDER", "NEXTSTYLE"]),
                    LogoPrimitiveParameter(name: "borderStyle", required: false, allowedValues: ["single", "heavy", "double", "round", "double-round", "ascii", "ascii-round"])
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
                parameters: [LogoPrimitiveParameter(name: "direction", required: true, allowedValues: ["UP", "RIGHT", "DOWN", "LEFT", "TOP", "BOTTOM"])],
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
                    LogoPrimitiveParameter(name: "arg1", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
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

        default: nil
    }
}
}
