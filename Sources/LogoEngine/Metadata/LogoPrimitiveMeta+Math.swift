import Foundation

extension LogoPrimitive {
    var mathMeta: LogoPrimitiveMeta? {
        switch self {
        case .sum:
            LogoPrimitiveMeta(
                name: "SUM",
                description: "Calculates the arithmetic sum of numbers or lists.",
                localizedDescriptionKey: "logo.doc.sum",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
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
                    LogoPrimitiveParameter(name: "b", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
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
                    LogoPrimitiveParameter(name: "b", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
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
                    LogoPrimitiveParameter(name: "b", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
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
                    LogoPrimitiveParameter(name: "tz", required: false),
                    LogoPrimitiveParameter(name: "cal", required: false)
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
                    LogoPrimitiveParameter(name: "unit", required: false),
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
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true),
                    LogoPrimitiveParameter(name: "order", required: false, allowedValues: ["desc", "descending", "greaterp", "greater?"]),
                    LogoPrimitiveParameter(name: "template", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "SORT [3 1 4 1 5 9]", output: "[1 1 3 4 5 9]")]
            )

        case .fill:
            LogoPrimitiveMeta(
                name: "FILL",
                description: "Fills active canvas mark block or table cell with text pattern.",
                localizedDescriptionKey: "logo.doc.fill",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "width", required: false),
                    LogoPrimitiveParameter(name: "height", required: false),
                    LogoPrimitiveParameter(name: "text", required: true)
                ],
                examples: [
                    LogoPrimitiveExample(input: "FILL \".\""),
                    LogoPrimitiveExample(input: "FILL 20 3 \".#\"")
                ]
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
        default: nil
    }
}
}
