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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by SUM.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by SUM.", example: "1"),
                    LogoPrimitiveParameter(name: "...", required: false, description: "The ... argument. Used by SUM.", example: "..."),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by MIN.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by MIN.", example: "1"),
                    LogoPrimitiveParameter(name: "...", required: false, description: "The ... argument. Used by MIN.", example: "..."),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by MAX.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by MAX.", example: "1"),
                    LogoPrimitiveParameter(name: "...", required: false, description: "The ... argument. Used by MAX.", example: "..."),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by DIFFERENCE.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by DIFFERENCE.", example: "1"),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by PRODUCT.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by PRODUCT.", example: "1"),
                    LogoPrimitiveParameter(name: "...", required: false, description: "The ... argument. Used by PRODUCT.", example: "..."),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by QUOTIENT.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by QUOTIENT.", example: "1"),
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
                    LogoPrimitiveParameter(name: "base", required: true, description: "The base argument. Used by POWER.", example: "value"),
                    LogoPrimitiveParameter(name: "exponent", required: true, description: "The exponent argument. Used by POWER.", example: "value"),
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
                    LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by REMAINDER.", example: "1"),
                    LogoPrimitiveParameter(name: "div", required: true, description: "The div argument. Used by REMAINDER.", example: "value"),
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
                    LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by MODULO.", example: "1"),
                    LogoPrimitiveParameter(name: "div", required: true, description: "The div argument. Used by MODULO.", example: "value"),
                ],
                examples: [LogoPrimitiveExample(input: "MODULO -1 10", output: "9")]
            )

        case .minus:
            LogoPrimitiveMeta(
                name: "MINUS",
                description: "Returns arithmetic negation of number (-num).",
                localizedDescriptionKey: "logo.doc.minus",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by MINUS.", example: "1")],
                examples: [LogoPrimitiveExample(input: "MINUS 42", output: "-42")]
            )

        case .abs:
            LogoPrimitiveMeta(
                name: "ABS",
                description: "Returns absolute value of number.",
                localizedDescriptionKey: "logo.doc.abs",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by ABS.", example: "1")],
                examples: [LogoPrimitiveExample(input: "ABS -5", output: "5")]
            )

        case .int:
            LogoPrimitiveMeta(
                name: "INT",
                description: "Truncates floating-point number to integer.",
                localizedDescriptionKey: "logo.doc.int",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by INT.", example: "1")],
                examples: [LogoPrimitiveExample(input: "INT 3.8", output: "3")]
            )

        case .round:
            LogoPrimitiveMeta(
                name: "ROUND",
                description: "Rounds number to nearest integer.",
                localizedDescriptionKey: "logo.doc.round",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by ROUND.", example: "1")],
                examples: [LogoPrimitiveExample(input: "ROUND 3.6", output: "4")]
            )

        case .sqrt:
            LogoPrimitiveMeta(
                name: "SQRT",
                description: "Calculates square root of non-negative number.",
                localizedDescriptionKey: "logo.doc.sqrt",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by SQRT.", example: "1")],
                examples: [LogoPrimitiveExample(input: "SQRT 144", output: "12")]
            )

        case .exp:
            LogoPrimitiveMeta(
                name: "EXP",
                description: "Calculates exponential function (e ^ num).",
                localizedDescriptionKey: "logo.doc.exp",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by EXP.", example: "1")],
                examples: [LogoPrimitiveExample(input: "EXP 1", output: "2.718281828459045")]
            )

        case .log10:
            LogoPrimitiveMeta(
                name: "LOG10",
                description: "Calculates base-10 logarithm of number.",
                localizedDescriptionKey: "logo.doc.log10",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by LOG10.", example: "1")],
                examples: [LogoPrimitiveExample(input: "LOG10 100", output: "2")]
            )

        case .ln:
            LogoPrimitiveMeta(
                name: "LN",
                description: "Calculates natural logarithm (base e) of number.",
                localizedDescriptionKey: "logo.doc.ln",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by LN.", example: "1")],
                examples: [LogoPrimitiveExample(input: "LN 2.718281828459045", output: "1")]
            )

        case .arctan:
            LogoPrimitiveMeta(
                name: "ARCTAN",
                description: "Calculates inverse tangent in degrees.",
                localizedDescriptionKey: "logo.doc.arctan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by ARCTAN.", example: "1")],
                examples: [LogoPrimitiveExample(input: "ARCTAN 1", output: "45")]
            )

        case .sin:
            LogoPrimitiveMeta(
                name: "SIN",
                description: "Calculates sine of angle in degrees.",
                localizedDescriptionKey: "logo.doc.sin",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "degrees", required: true, description: "The degrees argument. Used by SIN.", example: "value")],
                examples: [LogoPrimitiveExample(input: "SIN 90", output: "1")]
            )

        case .cos:
            LogoPrimitiveMeta(
                name: "COS",
                description: "Calculates cosine of angle in degrees.",
                localizedDescriptionKey: "logo.doc.cos",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "degrees", required: true, description: "The degrees argument. Used by COS.", example: "value")],
                examples: [LogoPrimitiveExample(input: "COS 0", output: "1")]
            )

        case .tan:
            LogoPrimitiveMeta(
                name: "TAN",
                description: "Calculates tangent of angle in degrees.",
                localizedDescriptionKey: "logo.doc.tan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "degrees", required: true, description: "The degrees argument. Used by TAN.", example: "value")],
                examples: [LogoPrimitiveExample(input: "TAN 45", output: "1")]
            )

        case .radArctan:
            LogoPrimitiveMeta(
                name: "RADARCTAN",
                description: "Calculates inverse tangent in radians.",
                localizedDescriptionKey: "logo.doc.radarctan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true, description: "The radians argument. Used by RADARCTAN.", example: "value")],
                examples: [LogoPrimitiveExample(input: "RADARCTAN 1", output: "0.7853981633974483")]
            )

        case .radSin:
            LogoPrimitiveMeta(
                name: "RADSIN",
                description: "Calculates sine of angle in radians.",
                localizedDescriptionKey: "logo.doc.radsin",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true, description: "The radians argument. Used by RADSIN.", example: "value")],
                examples: [LogoPrimitiveExample(input: "RADSIN 1.5707963267948966", output: "1")]
            )

        case .radCos:
            LogoPrimitiveMeta(
                name: "RADCOS",
                description: "Calculates cosine of angle in radians.",
                localizedDescriptionKey: "logo.doc.radcos",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true, description: "The radians argument. Used by RADCOS.", example: "value")],
                examples: [LogoPrimitiveExample(input: "RADCOS 0", output: "1")]
            )

        case .radTan:
            LogoPrimitiveMeta(
                name: "RADTAN",
                description: "Calculates tangent of angle in radians.",
                localizedDescriptionKey: "logo.doc.radtan",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "radians", required: true, description: "The radians argument. Used by RADTAN.", example: "value")],
                examples: [LogoPrimitiveExample(input: "RADTAN 0.7853981633974483", output: "1")]
            )

        case .iseq:
            LogoPrimitiveMeta(
                name: "ISEQ",
                description: "Generates integer sequence list from start to end.",
                localizedDescriptionKey: "logo.doc.iseq",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "start", required: true, description: "The start argument. Used by ISEQ.", example: "value"),
                    LogoPrimitiveParameter(name: "end", required: true, description: "The end argument. Used by ISEQ.", example: "value"),
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
                    LogoPrimitiveParameter(name: "start", required: true, description: "The start argument. Used by RSEQ.", example: "value"),
                    LogoPrimitiveParameter(name: "end", required: true, description: "The end argument. Used by RSEQ.", example: "value"),
                    LogoPrimitiveParameter(name: "count", required: true, description: "The number of items. Used by RSEQ.", example: "3"),
                ],
                examples: [LogoPrimitiveExample(input: "RSEQ 0 1 5", output: "[0 0.25 0.5 0.75 1]")]
            )

        case .random:
            LogoPrimitiveMeta(
                name: "RANDOM",
                description: "Generates pseudorandom integer from 0 to limit - 1.",
                localizedDescriptionKey: "logo.doc.random",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "limit", required: true, description: "The limit argument. Used by RANDOM.", example: "value")],
                examples: [LogoPrimitiveExample(input: "RANDOM 100")]
            )

        case .rerandom:
            LogoPrimitiveMeta(
                name: "RERANDOM",
                description: "Reseeds the random number generator.",
                localizedDescriptionKey: "logo.doc.rerandom",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "seed", required: false, description: "The seed argument. Used by RERANDOM.", example: "value")],
                examples: [LogoPrimitiveExample(input: "RERANDOM 42")]
            )

        case .form:
            LogoPrimitiveMeta(
                name: "FORM",
                description: "Formats floating point number into fixed width and precision string.",
                localizedDescriptionKey: "logo.doc.form",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by FORM.", example: "1"),
                    LogoPrimitiveParameter(name: "width", required: true, description: "The width. Used by FORM.", example: "3"),
                    LogoPrimitiveParameter(name: "precision", required: true, description: "The precision argument. Used by FORM.", example: "value"),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by BITAND.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by BITAND.", example: "1"),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by BITOR.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by BITOR.", example: "1"),
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
                    LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by BITXOR.", example: "1"),
                    LogoPrimitiveParameter(name: "b", required: true, description: "The b argument. Used by BITXOR.", example: "1"),
                ],
                examples: [LogoPrimitiveExample(input: "BIT.XOR 5 3", output: "6")]
            )

        case .bitNot:
            LogoPrimitiveMeta(
                name: "BIT.NOT",
                description: "Performs bitwise NOT operation on an integer.",
                localizedDescriptionKey: "logo.doc.bitnot",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "a", required: true, description: "The a argument. Used by BITNOT.", example: "1")],
                examples: [LogoPrimitiveExample(input: "BIT.NOT 0", output: "-1")]
            )

        case .ashift:
            LogoPrimitiveMeta(
                name: "ASHIFT",
                description: "Performs arithmetic bitwise shift.",
                localizedDescriptionKey: "logo.doc.ashift",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by ASHIFT.", example: "1"),
                    LogoPrimitiveParameter(name: "bits", required: true, description: "The bits argument. Used by ASHIFT.", example: "value"),
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
                    LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by LSHIFT.", example: "1"),
                    LogoPrimitiveParameter(name: "bits", required: true, description: "The bits argument. Used by LSHIFT.", example: "value"),
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
                    LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by RSHIFT.", example: "1"),
                    LogoPrimitiveParameter(name: "bits", required: true, description: "The bits argument. Used by RSHIFT.", example: "value"),
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
                    LogoPrimitiveParameter(name: "format", required: false, description: "The format argument. Used by DATE.", example: "single"),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale identifier. Used by DATE.", example: "en_US"),
                    LogoPrimitiveParameter(name: "tz", required: false, description: "The tz argument. Used by DATE.", example: "value"),
                    LogoPrimitiveParameter(name: "cal", required: false, description: "The cal argument. Used by DATE.", example: "value"),
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
                    LogoPrimitiveParameter(name: "format", required: false, description: "The format argument. Used by TIME.", example: "single"),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale identifier. Used by TIME.", example: "en_US"),
                    LogoPrimitiveParameter(name: "tz", required: false, description: "The tz argument. Used by TIME.", example: "value"),
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
                    LogoPrimitiveParameter(name: "format", required: false, description: "The format argument. Used by DATETIME.", example: "single"),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale identifier. Used by DATETIME.", example: "en_US"),
                    LogoPrimitiveParameter(name: "tz", required: false, description: "The tz argument. Used by DATETIME.", example: "value"),
                    LogoPrimitiveParameter(name: "cal", required: false, description: "The cal argument. Used by DATETIME.", example: "value"),
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
                    LogoPrimitiveParameter(name: "dateStr", required: true, description: "The dateStr argument. Used by DATEFORMAT.", example: "value"),
                    LogoPrimitiveParameter(name: "format", required: false, description: "The format argument. Used by DATEFORMAT.", example: "single"),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale identifier. Used by DATEFORMAT.", example: "en_US"),
                    LogoPrimitiveParameter(name: "tz", required: false, description: "The tz argument. Used by DATEFORMAT.", example: "value"),
                    LogoPrimitiveParameter(name: "cal", required: false, description: "The cal argument. Used by DATEFORMAT.", example: "value"),
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
                    LogoPrimitiveParameter(name: "dateStr", required: true, description: "The dateStr argument. Used by DATEADD.", example: "value"),
                    LogoPrimitiveParameter(name: "amount", required: true, description: "The amount argument. Used by DATEADD.", example: "value"),
                    LogoPrimitiveParameter(
                        name: "unit", required: false, description: "The unit used for the operation. Used by DATEADD.", example: "days",
                        allowedValues: ["days", "weeks", "months", "years", "hours", "minutes", "seconds"]),
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
                    LogoPrimitiveParameter(name: "date1", required: true, description: "The date1 argument. Used by DATEDIFF.", example: "value"),
                    LogoPrimitiveParameter(name: "date2", required: true, description: "The date2 argument. Used by DATEDIFF.", example: "value"),
                    LogoPrimitiveParameter(
                        name: "unit", required: false, description: "The unit used for the operation. Used by DATEDIFF.", example: "days",
                        allowedValues: ["days", "weeks", "months", "years", "hours", "minutes", "seconds"]),
                ],
                examples: [LogoPrimitiveExample(input: "DATE.DIFF \"2026-12-31 DATE \"days")]
            )

        case .formatNumber:
            LogoPrimitiveMeta(
                name: "FORMAT.NUMBER",
                description:
                    "Formats number using localized decimal, currency, percent, roman, or financial CJK uppercase.",
                localizedDescriptionKey: "logo.doc.formatnumber",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "num", required: true, description: "The num argument. Used by FORMATNUMBER.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "style", required: false, description: "The formatting or border style. Used by FORMATNUMBER.", example: "decimal",
                        allowedValues: ["decimal", "currency", "percent", "roman", "financial", "ordinal", "spellout"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale identifier. Used by FORMATNUMBER.", example: "en_US"),
                    LogoPrimitiveParameter(name: "currency", required: false, description: "The currency argument. Used by FORMATNUMBER.", example: "value"),
                    LogoPrimitiveParameter(name: "precision", required: false, description: "The precision argument. Used by FORMATNUMBER.", example: "value"),
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
                    LogoPrimitiveParameter(name: "list", required: true, description: "The list or array to format.", example: "[A B C]"),
                    LogoPrimitiveParameter(name: "type", required: false, description: "The list conjunction style.", example: "and", allowedValues: ["and", "or", "unit"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale used for formatting.", example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.LIST [A B C] \"and \"en_US", output: "A, B, and C")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatRelativeTime:
            LogoPrimitiveMeta(
                name: "FORMAT.RELATIVETIME",
                description: "Formats relative elapsed time description (e.g. '2 hours ago').",
                localizedDescriptionKey: "logo.doc.formatrelativetime",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "A numeric offset or target date.", example: "-2"),
                    LogoPrimitiveParameter(name: "unit", required: false, description: "The relative time unit.", example: "hour"),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale used for formatting.", example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.RELATIVETIME -2 \"hour \"en_US", output: "2 hours ago")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatBytes:
            LogoPrimitiveMeta(
                name: "FORMAT.BYTES",
                description: "Formats byte counts into human-readable memory or file sizes (KB, MB, GB).",
                localizedDescriptionKey: "logo.doc.formatbytes",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "bytes", required: true, description: "The bytes argument. Used by FORMATBYTES.", example: "value"),
                    LogoPrimitiveParameter(
                        name: "style", required: false, description: "The formatting or border style. Used by FORMATBYTES.", example: "file", allowedValues: ["file", "memory", "binary", "decimal", "bytes"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "The locale identifier. Used by FORMATBYTES.", example: "en_US"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.BYTES 1048576", output: "1 MB")]
            )

        case .detectURL:
            LogoPrimitiveMeta(
                name: "DETECT.URL",
                description: "Detects URLs in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detecturl",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true, description: "The text to scan for URLs.", example: "Visit https://example.com")],
                examples: [LogoPrimitiveExample(input: "DETECT.URL \"Visit https://example.com", output: "[https://example.com]")],
                notes: "Not supported on Linux or Windows."
            )

        case .detectEmail:
            LogoPrimitiveMeta(
                name: "DETECT.EMAIL",
                description: "Detects email addresses in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectemail",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true, description: "The text to scan for email addresses.", example: "Mail team@example.com")],
                examples: [LogoPrimitiveExample(input: "DETECT.EMAIL \"Mail team@example.com", output: "[team@example.com]")],
                notes: "Not supported on Linux or Windows."
            )

        case .detectPhone:
            LogoPrimitiveMeta(
                name: "DETECT.PHONE",
                description: "Detects phone numbers in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectphone",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true, description: "The text to scan for phone numbers.", example: "Call 555-123-4567")],
                examples: [LogoPrimitiveExample(input: "DETECT.PHONE \"Call 555-123-4567", output: "[555-123-4567]")],
                notes: "Not supported on Linux or Windows."
            )

        case .detectDate:
            LogoPrimitiveMeta(
                name: "DETECT.DATE",
                description: "Detects dates in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectdate",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true, description: "The text to scan for dates.", example: "Meeting on January 5, 2027")],
                examples: [LogoPrimitiveExample(input: "DETECT.DATE \"Meeting on January 5, 2027", output: "[January 5, 2027]")],
                notes: "Not supported on Linux or Windows."
            )

        case .detectAddress:
            LogoPrimitiveMeta(
                name: "DETECT.ADDRESS",
                description: "Detects postal addresses in text and returns the matching strings as a list.",
                localizedDescriptionKey: "logo.doc.detectaddress",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true, description: "The text to scan for postal addresses.", example: "1600 Pennsylvania Avenue NW")],
                examples: [LogoPrimitiveExample(input: "DETECT.ADDRESS \"1600 Pennsylvania Avenue NW", output: "[1600 Pennsylvania Avenue NW]")],
                notes: "Not supported on Linux or Windows."
            )

        case .search:
            LogoPrimitiveMeta(
                name: "SEARCH",
                description: "Searches text in editor buffer and highlights occurrences.",
                localizedDescriptionKey: "logo.doc.search",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "query", required: true, description: "The query argument. Used by SEARCH.", example: "value")],
                examples: [LogoPrimitiveExample(input: "SEARCH \"hello")]
            )

        case .sort:
            LogoPrimitiveMeta(
                name: "SORT",
                description: "Sorts elements in list alphabetically or numerically.",
                localizedDescriptionKey: "logo.doc.sort",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true, description: "The list to process. Used by SORT.", example: "[A B C]"),
                    LogoPrimitiveParameter(
                        name: "order", required: false, description: "The order argument. Used by SORT.", example: "desc", allowedValues: ["desc", "descending", "greaterp", "greater?"]),
                    LogoPrimitiveParameter(name: "template", required: false, description: "The Logo template to apply. Used by SORT.", example: "[FD 1]"),
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
                    LogoPrimitiveParameter(name: "width", required: false, description: "The width. Used by FILL.", example: "3"),
                    LogoPrimitiveParameter(name: "height", required: false, description: "The height. Used by FILL.", example: "3"),
                    LogoPrimitiveParameter(name: "text", required: true, description: "The text value. Used by FILL.", example: "text"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "FILL \".\""),
                    LogoPrimitiveExample(input: "FILL 20 3 \".#\""),
                ]
            )

        case .readWord:
            LogoPrimitiveMeta(
                name: "READWORD",
                description: "Prompts user to enter a line of text input.",
                localizedDescriptionKey: "logo.doc.readword",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "prompt", required: false, description: "The prompt argument. Used by READWORD.", example: "value")],
                examples: [LogoPrimitiveExample(input: "MAKE \"name READWORD \"Name: ")]
            )

        case .readChar:
            LogoPrimitiveMeta(
                name: "READCHAR",
                description: "Prompts user to press a single character key.",
                localizedDescriptionKey: "logo.doc.readchar",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "prompt", required: false, description: "The prompt argument. Used by READCHAR.", example: "value")],
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
                parameters: [LogoPrimitiveParameter(name: "procname", required: true, description: "The procname argument. Used by TEXT.", example: "text")],
                examples: [LogoPrimitiveExample(input: "TEXT \"square")]
            )

        case .define:
            LogoPrimitiveMeta(
                name: "DEFINE",
                description: "Defines procedure dynamically from parameter and instruction list.",
                localizedDescriptionKey: "logo.doc.define",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "procname", required: true, description: "The procname argument. Used by DEFINE.", example: "text"),
                    LogoPrimitiveParameter(name: "textList", required: true, description: "The textList argument. Used by DEFINE.", example: "[A B C]"),
                ],
                examples: [LogoPrimitiveExample(input: "DEFINE \"double [[n] [OUTPUT :n * 2]]")]
            )

        case .erase:
            LogoPrimitiveMeta(
                name: "ERASE",
                description: "Erases named custom procedure definition.",
                localizedDescriptionKey: "logo.doc.erase",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "procname", required: true, description: "The procname argument. Used by ERASE.", example: "text")],
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
                parameters: [LogoPrimitiveParameter(name: "procname", required: true, description: "The procname argument. Used by ARITY.", example: "text")],
                examples: [LogoPrimitiveExample(input: "ARITY \"sum", output: "2")]
            )

        case .doc:
            LogoPrimitiveMeta(
                name: "DOC",
                description: "Returns documentation docstring for procedure or built-in primitive.",
                localizedDescriptionKey: "logo.doc.doc",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "name", required: true, description: "The name. Used by DOC.", example: "text")],
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
