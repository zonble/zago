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

        default:
            nil
        }
    }
}
