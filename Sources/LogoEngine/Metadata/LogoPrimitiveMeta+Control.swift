import Foundation

extension LogoPrimitive {
    var controlMeta: LogoPrimitiveMeta? {
        return switch self {
        case .ifCondition:
            LogoPrimitiveMeta(
                name: "IF",
                description:
                    "Conditionally executes instructions if predicate is true, with optional else-branch (alias: IFELSE).",
                localizedDescriptionKey: "logo.doc.if",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "condition", required: true, description: "The condition to evaluate. Used by IF.",
                        example: "1"),
                    LogoPrimitiveParameter(
                        name: "thenBlock", required: true,
                        description: "The instructions to run if true. Used by IF.", example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "elseBlock", required: false,
                        description: "The optional instructions to run if false. Used by IF/IFELSE.", example: "[BK 1]"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "IF :x > 0 [ TYPE \"Positive NL ]"),
                    LogoPrimitiveExample(input: "IF :x > 0 [ TYPE \"Positive ] [ TYPE \"Non-Positive ]"),
                ]
            )

        case .output:
            LogoPrimitiveMeta(
                name: "OUTPUT",
                description: "Returns a value from a custom procedure and stops execution.",
                localizedDescriptionKey: "logo.doc.output",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "The value to return. Used by OUTPUT.", example: "1"
                    )
                ],
                examples: [LogoPrimitiveExample(input: "OUTPUT :count + 1")]
            )

        case .repeatLoop:
            LogoPrimitiveMeta(
                name: "REPEAT",
                description: "Executes an instruction list count times; REPCOUNT gives current 1-based index.",
                localizedDescriptionKey: "logo.doc.repeat",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "count", required: true, description: "The number of iterations. Used by REPEAT.",
                        example: "3"),
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by REPEAT.", example: "[FD 1]"),
                ],
                examples: [LogoPrimitiveExample(input: "REPEAT 4 [ FORWARD 10 RIGHT 90 ]")]
            )

        case .forLoop:
            LogoPrimitiveMeta(
                name: "FOR",
                description: "Iterates variable from start to stop with optional step value.",
                localizedDescriptionKey: "logo.doc.for",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "control", required: true, description: "The [var start stop step] spec. Used by FOR.",
                        example: "[i 1 10 1]"),
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by FOR.", example: "[FD 1]"),
                ],
                examples: [LogoPrimitiveExample(input: "FOR [i 1 5 1] [ TYPE :i NL ]")]
            )

        case .dotimesLoop:
            LogoPrimitiveMeta(
                name: "DOTIMES",
                description: "Iterates variable from 0 up to count - 1.",
                localizedDescriptionKey: "logo.doc.dotimes",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "spec", required: true, description: "The spec argument. Used by DOTIMES.",
                        example: "value"),
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by DOTIMES.", example: "[FD 1]"),
                ],
                examples: [LogoPrimitiveExample(input: "DOTIMES [i 5] [ TYPE :i NL ]")]
            )

        case .whileLoop:
            LogoPrimitiveMeta(
                name: "WHILE",
                description: "Repeats instruction block as long as condition remains true.",
                localizedDescriptionKey: "logo.doc.while",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "condition", required: true, description: "The condition to evaluate. Used by WHILE.",
                        example: "1"),
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by WHILE.", example: "[FD 1]"),
                ],
                examples: [LogoPrimitiveExample(input: "WHILE [:count > 0] [ MAKE \"count :count - 1 ]")]
            )

        case .doWhileLoop:
            LogoPrimitiveMeta(
                name: "DO.WHILE",
                description: "Executes instruction block once, then repeats while condition is true.",
                localizedDescriptionKey: "logo.doc.dowhile",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by DOWHILE.", example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "condition", required: true, description: "The condition to evaluate. Used by DOWHILE.",
                        example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "DO.WHILE [ MAKE \"x :x - 1 ] [:x > 0]")]
            )

        case .untilLoop:
            LogoPrimitiveMeta(
                name: "UNTIL",
                description: "Repeats instruction block until condition becomes true.",
                localizedDescriptionKey: "logo.doc.until",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "condition", required: true, description: "The condition to evaluate. Used by UNTIL.",
                        example: "1"),
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by UNTIL.", example: "[FD 1]"),
                ],
                examples: [LogoPrimitiveExample(input: "UNTIL [:x = 0] [ MAKE \"x :x - 1 ]")]
            )

        case .doUntilLoop:
            LogoPrimitiveMeta(
                name: "DO.UNTIL",
                description: "Executes instruction block once, then repeats until condition is true.",
                localizedDescriptionKey: "logo.doc.dountil",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by DOUNTIL.", example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "condition", required: true, description: "The condition to evaluate. Used by DOUNTIL.",
                        example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "DO.UNTIL [ MAKE \"x :x - 1 ] [:x = 0]")]
            )

        case .caseSwitch:
            LogoPrimitiveMeta(
                name: "CASE",
                description: "Matches value against multiple branch clauses with optional ELSE.",
                localizedDescriptionKey: "logo.doc.case",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "The value to process. Used by CASESWITCH.",
                        example: "1"),
                    LogoPrimitiveParameter(
                        name: "clauses", required: true, description: "The clauses argument. Used by CASESWITCH.",
                        example: "[FD 1]"),
                ],
                examples: [LogoPrimitiveExample(input: "CASE :mode [ [1 [SHOW \"One]] [ELSE [SHOW \"Other]] ]")]
            )

        case .condSwitch:
            LogoPrimitiveMeta(
                name: "COND",
                description: "Evaluates condition clauses sequentially until one is true.",
                localizedDescriptionKey: "logo.doc.cond",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "clauses", required: true, description: "The clauses argument. Used by CONDSWITCH.",
                        example: "[FD 1]")
                ],
                examples: [LogoPrimitiveExample(input: "COND [ [[:x > 0] [SHOW \"+]] [ELSE [SHOW \"-]] ]")]
            )

        case .testCondition:
            LogoPrimitiveMeta(
                name: "TEST",
                description: "Sets internal test flag for subsequent IFTRUE / IFFALSE statements.",
                localizedDescriptionKey: "logo.doc.test",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "condition", required: true,
                        description: "The condition to evaluate. Used by TESTCONDITION.", example: "1")
                ],
                examples: [LogoPrimitiveExample(input: "TEST :x > 10")]
            )

        case .assertCondition:
            LogoPrimitiveMeta(
                name: "ASSERT",
                description: "Asserts that condition is true, throwing error on failure.",
                localizedDescriptionKey: "logo.doc.assert",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "condition", required: true,
                        description: "The condition to evaluate. Used by ASSERTCONDITION.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "message", required: false, description: "The message text. Used by ASSERTCONDITION.",
                        example: "text"),
                ],
                examples: [LogoPrimitiveExample(input: "ASSERT :count > 0 \"Must be positive")]
            )

        case .local:
            LogoPrimitiveMeta(
                name: "LOCAL",
                description: "Declares local variable(s) scoped to active procedure.",
                localizedDescriptionKey: "logo.doc.local",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "varname", required: true, description: "The variable name. Used by LOCAL.",
                        example: "text")
                ],
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
                parameters: [
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by IFTRUE.", example: "[FD 1]")
                ],
                examples: [LogoPrimitiveExample(input: "IFTRUE [ SHOW \"Passed ]")]
            )

        case .ifFalse:
            LogoPrimitiveMeta(
                name: "IFFALSE",
                description: "Executes instructions if preceding TEST was false.",
                localizedDescriptionKey: "logo.doc.iffalse",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by IFFALSE.", example: "[FD 1]")
                ],
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
                    LogoPrimitiveParameter(
                        name: "tag", required: true, description: "The catch or throw tag. Used by CATCHTAG.",
                        example: "text"),
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by CATCHTAG.", example: "[FD 1]"),
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
                    LogoPrimitiveParameter(
                        name: "tag", required: true, description: "The catch or throw tag. Used by THROWTAG.",
                        example: "text"),
                    LogoPrimitiveParameter(
                        name: "value", required: false, description: "The value to process. Used by THROWTAG.",
                        example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "THROW \"exit 42")]
            )

        case .wait:
            LogoPrimitiveMeta(
                name: "WAIT",
                description: "Pauses execution for specified 1/60th second intervals.",
                localizedDescriptionKey: "logo.doc.wait",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "ticks", required: true, description: "The ticks argument. Used by WAIT.", example: "3")
                ],
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
                    LogoPrimitiveParameter(
                        name: "template", required: true, description: "The Logo template to apply. Used by APPLY.",
                        example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "argslist", required: true, description: "The argslist argument. Used by APPLY.",
                        example: "[A B C]"),
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
                    LogoPrimitiveParameter(
                        name: "template", required: true, description: "The Logo template to apply. Used by INVOKE.",
                        example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "arg1", required: true, description: "The arg1 argument. Used by INVOKE.",
                        example: "value"),
                    LogoPrimitiveParameter(
                        name: "...", required: false, description: "The ... argument. Used by INVOKE.", example: "..."),
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
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list to process. Used by FOREACH.",
                        example: "[A B C]"),
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by FOREACH.", example: "[FD 1]"),
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
                    LogoPrimitiveParameter(
                        name: "template", required: true, description: "The Logo template to apply. Used by MAP.",
                        example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list to process. Used by MAP.",
                        example: "[A B C]"),
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
                    LogoPrimitiveParameter(
                        name: "template", required: true, description: "The Logo template to apply. Used by MAPSE.",
                        example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list to process. Used by MAPSE.",
                        example: "[A B C]"),
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
                    LogoPrimitiveParameter(
                        name: "predicate", required: true, description: "The predicate argument. Used by FILTER.",
                        example: "1"),
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list to process. Used by FILTER.",
                        example: "[A B C]"),
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
                    LogoPrimitiveParameter(
                        name: "predicate", required: true, description: "The predicate argument. Used by FIND.",
                        example: "1"),
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list to process. Used by FIND.",
                        example: "[A B C]"),
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
                    LogoPrimitiveParameter(
                        name: "template", required: true, description: "The Logo template to apply. Used by REDUCE.",
                        example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "list", required: true, description: "The list to process. Used by REDUCE.",
                        example: "[A B C]"),
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
                    LogoPrimitiveParameter(
                        name: "template", required: true, description: "The Logo template to apply. Used by CROSSMAP.",
                        example: "[FD 1]"),
                    LogoPrimitiveParameter(
                        name: "lists", required: true, description: "The lists argument. Used by CROSSMAP.",
                        example: "[A B C]"),
                ],
                examples: [LogoPrimitiveExample(input: "CROSSMAP [WORD ?1 ?2] [[A B] [1 2]]", output: "[A1 A2 B1 B2]")]
            )

        case .run:
            LogoPrimitiveMeta(
                name: "RUN",
                description: "Executes a list of LOGO tokens or script string.",
                localizedDescriptionKey: "logo.doc.run",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "instructions", required: true,
                        description: "The Logo instructions to execute. Used by RUN.", example: "[FD 1]")
                ],
                examples: [LogoPrimitiveExample(input: "RUN [ TYPE \"Dynamic NL ]")]
            )

        case .runResult:
            LogoPrimitiveMeta(
                name: "RUNRESULT",
                description: "Runs expression and returns list with result or empty list.",
                localizedDescriptionKey: "logo.doc.runresult",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "expression", required: true, description: "The expression argument. Used by RUNRESULT.",
                        example: "1")
                ],
                examples: [LogoPrimitiveExample(input: "RUNRESULT [ 10 + 20 ]", output: "[30]")]
            )

        case .ignore:
            LogoPrimitiveMeta(
                name: "IGNORE",
                description: "Evaluates an expression and discards its return value.",
                localizedDescriptionKey: "logo.doc.ignore",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "The value to process. Used by IGNORE.",
                        example: "1")
                ],
                examples: [LogoPrimitiveExample(input: "IGNORE SUM 10 20")]
            )

        case .to:
            LogoPrimitiveMeta(
                name: "TO",
                description: "Defines a new custom LOGO procedure.",
                localizedDescriptionKey: "logo.doc.to",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "header", required: true, description: "The header argument. Used by TO.",
                        example: "value")
                ],
                examples: [LogoPrimitiveExample(input: "TO SQUARE :n OUTPUT :n * :n END")]
            )

        default:
            nil
        }
    }
}
