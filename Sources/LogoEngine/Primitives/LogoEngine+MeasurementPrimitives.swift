import Foundation

extension LogoEngine {
    /// Measurement Primitives Evaluator (`evaluateMeasurementPrimitives`)
    ///
    /// Evaluates `CONVERT.MEASURE`, `FORMAT.MEASURE`, `MEASURE.ADD`, `MEASURE.SUB`,
    /// `MEASURE.SCALE`, `MEASURE.EQUAL?`, `MEASURE.LESS?`, `MEASURE.GREATER?`,
    /// `MEASURE.MIN`, `MEASURE.MAX`.
    internal func evaluateMeasurementPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = parsePrimitive(tokens[index]) else { return nil }

        switch prim {
        case .convertMeasure:
            return evaluateMeasurementConvertPrimitive(prim, tokens: tokens, index: &index)

        case .formatMeasure:
            return evaluateMeasurementFormatPrimitive(prim, tokens: tokens, index: &index)

        case .measureAdd, .measureSub, .measureScale, .measureEqual, .measureLess, .measureGreater, .measureMin,
            .measureMax:
            return evaluateMeasureOperationPrimitive(prim, tokens: tokens, index: &index)

        default:
            return nil
        }
    }

    private func evaluateMeasurementConvertPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int)
        -> String
    {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        let firstArg = reader.nextExpression()

        var val: Double = 0
        var fromUnit: String = ""
        var toUnit: String = ""

        let parsedFirst = LogoValue.parse(firstArg)
        if case .measurement(let mVal, let mUnit, _) = parsedFirst {
            val = mVal
            fromUnit = mUnit
            toUnit = unquote(reader.nextExpression())
        } else {
            val = Double(unquote(firstArg)) ?? 0
            fromUnit = unquote(reader.nextExpression())
            toUnit = unquote(reader.nextExpression())
        }
        reader.commit(to: &index)

        guard let dimFrom = LogoMeasurementConverter.findDimension(for: fromUnit) else {
            let msg = "[LOGO Error: \(prim.meta.name) invalid or unknown source unit '\(fromUnit)']"
            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
            return ""
        }
        guard let dimTo = LogoMeasurementConverter.findDimension(for: toUnit) else {
            let msg = "[LOGO Error: \(prim.meta.name) invalid or unknown target unit '\(toUnit)']"
            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
            return ""
        }
        guard dimFrom == dimTo else {
            let msg =
                "[LOGO Error: \(prim.meta.name) cannot convert '\(fromUnit)' (\(dimFrom)) to '\(toUnit)' (\(dimTo))]"
            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
            return ""
        }

        if let converted = LogoMeasurementConverter.convert(value: val, from: fromUnit, to: toUnit, kind: dimFrom) {
            let res = LogoMeasurementConverter.formatResult(converted)
            setLastExpressionString(res)
            return res
        }
        return ""
    }

    private func evaluateMeasurementFormatPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> String
    {
        #if !canImport(Darwin)
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            _ = reader.nextOptionalExpression()
            _ = reader.nextOptionalExpression()
            reader.commit(to: &index)
            let name = prim.meta.name
            let message = "[LOGO Error: \(name) is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: name)
            return ""
        #else
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            guard let firstArg = reader.nextOptionalExpression() else { return "" }

            var val: Double = 0
            var cleanUnit: String = ""
            let kind: LogoMeasurementConverter.DimensionKind

            let parsedFirst = LogoValue.parse(firstArg)
            if case .measurement(let mVal, let mUnit, let mDim) = parsedFirst {
                val = mVal
                cleanUnit = mUnit
                kind = mDim
            } else {
                guard let unitStr = reader.nextOptionalExpression() else {
                    reader.commit(to: &index)
                    return ""
                }
                val = Double(unquote(firstArg)) ?? 0
                cleanUnit = unquote(unitStr)
                guard let inferredDim = LogoMeasurementConverter.findDimension(for: cleanUnit) else {
                    let msg = "[LOGO Error: \(prim.meta.name) invalid or unknown unit '\(cleanUnit)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    reader.commit(to: &index)
                    return ""
                }
                kind = inferredDim
            }

            var style: String? = nil
            var localeSpec: String? = nil
            var naturalScale = false
            var targetConversionUnit: String? = nil

            if reader.peekToken() == "[" {
                let rawList = reader.nextExpression()
                let parsed = LogoValue.parse(rawList)
                if case .list(let items) = parsed {
                    var isDict = false
                    var i = 0
                    while i < items.count {
                        let key = items[i].stringValue
                        if let field = parseFormatOptionField(key), i + 1 < items.count {
                            isDict = true
                            let v = items[i + 1].stringValue
                            switch field {
                            case .style, .format:
                                style = v
                            case .locale, .language:
                                localeSpec = v
                            case .naturalScale:
                                naturalScale = parseBoolean(v) ?? (v.lowercased() == "yes")
                            case .unit:
                                targetConversionUnit = v
                            default:
                                break
                            }
                            i += 2
                        } else {
                            i += 1
                        }
                    }
                    if !isDict {
                        let strings = items.map { $0.stringValue }
                        for s in strings {
                            let unq = unquote(s)
                            if let dim = LogoMeasurementConverter.findDimension(for: unq) {
                                if dim == kind {
                                    targetConversionUnit = unq
                                } else {
                                    let msg =
                                        "[LOGO Error: \(prim.meta.name) invalid unit '\(unq)' (expected \(kind) unit, got \(dim))]"
                                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                                    reader.commit(to: &index)
                                    return ""
                                }
                            }
                        }
                        LogoMeasurementConverter.disambiguateFormatOptions(
                            strings, style: &style, locale: &localeSpec, naturalScale: &naturalScale)
                    }
                }
            } else {
                var positional: [String] = []
                while positional.count < 3,
                    let arg = reader.nextOptionalExpression()
                {
                    let unq = unquote(arg)
                    if let dim = LogoMeasurementConverter.findDimension(for: unq) {
                        if dim == kind {
                            targetConversionUnit = unq
                        } else {
                            let msg =
                                "[LOGO Error: \(prim.meta.name) invalid unit '\(unq)' (expected \(kind) unit, got \(dim))]"
                            reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                            reader.commit(to: &index)
                            return ""
                        }
                    } else {
                        positional.append(unq)
                    }
                }
                LogoMeasurementConverter.disambiguateFormatOptions(
                    positional, style: &style, locale: &localeSpec, naturalScale: &naturalScale)
            }

            reader.commit(to: &index)

            if let targetUnit = targetConversionUnit,
                let convertedVal = LogoMeasurementConverter.convert(
                    value: val, from: cleanUnit, to: targetUnit, kind: kind)
            {
                val = convertedVal
                cleanUnit = targetUnit
            }

            if let formatted = LogoMeasurementConverter.format(
                value: val,
                unit: cleanUnit,
                kind: kind,
                style: style,
                locale: localeSpec,
                naturalScale: naturalScale
            ) {
                setLastExpressionString(formatted)
                return formatted
            }
            return ""
        #endif
    }

    private func evaluateMeasureOperationPrimitive(_ prim: LogoPrimitive, tokens: [String], index: inout Int) -> String
    {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard let arg1 = reader.nextOptionalExpression() else { return "" }
        let clean1 = unquote(arg1)
        let parsed1 = LogoValue.parse(arg1)

        switch prim {
        case .measureScale:
            let val: Double
            let unit: String
            let factor: Double

            if case .measurement(let mVal, let mUnit, _) = parsed1 {
                guard let factorStr = reader.nextOptionalExpression() else {
                    reader.commit(to: &index)
                    return ""
                }
                val = mVal
                unit = mUnit
                factor = Double(unquote(factorStr)) ?? 1
            } else {
                guard let unitStr = reader.nextOptionalExpression(),
                    let factorStr = reader.nextOptionalExpression()
                else {
                    reader.commit(to: &index)
                    return ""
                }
                val = Double(clean1) ?? 0
                unit = unquote(unitStr)
                factor = Double(unquote(factorStr)) ?? 1
            }
            reader.commit(to: &index)

            guard let res = LogoMeasurementConverter.scale(value: val, unit: unit, factor: factor) else {
                return ""
            }
            setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
            return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

        case .measureAdd, .measureSub, .measureEqual, .measureLess, .measureGreater, .measureMin, .measureMax:
            let val1: Double
            let unit1: String
            let val2: Double
            let unit2: String
            let targetUnit: String?

            if case .measurement(let mVal1, let mUnit1, _) = parsed1 {
                guard let arg2 = reader.nextOptionalExpression() else {
                    reader.commit(to: &index)
                    return ""
                }
                let parsed2 = LogoValue.parse(arg2)
                if case .measurement(let mVal2, let mUnit2, _) = parsed2 {
                    val1 = mVal1
                    unit1 = mUnit1
                    val2 = mVal2
                    unit2 = mUnit2
                } else {
                    guard let unit2Str = reader.nextOptionalExpression() else {
                        reader.commit(to: &index)
                        return ""
                    }
                    val1 = mVal1
                    unit1 = mUnit1
                    val2 = Double(unquote(arg2)) ?? 0
                    unit2 = unquote(unit2Str)
                }
            } else {
                guard let unit1Str = reader.nextOptionalExpression(),
                    let val2Str = reader.nextOptionalExpression(),
                    let unit2Str = reader.nextOptionalExpression()
                else {
                    reader.commit(to: &index)
                    return ""
                }
                val1 = Double(clean1) ?? 0
                unit1 = unquote(unit1Str)
                let parsedVal2 = LogoValue.parse(val2Str)
                if case .measurement(let mVal2, let mUnit2, _) = parsedVal2 {
                    val2 = mVal2
                    unit2 = mUnit2
                } else {
                    val2 = Double(unquote(val2Str)) ?? 0
                    unit2 = unquote(unit2Str)
                }
            }

            if let dim1 = LogoMeasurementConverter.findDimension(for: unit1),
                let peek = reader.peekToken(),
                !isArgumentBoundary(peek),
                let peekDim = LogoMeasurementConverter.findDimension(for: unquote(peek)),
                peekDim == dim1
            {
                targetUnit = reader.nextOptionalExpression().map(unquote)
            } else {
                targetUnit = nil
            }
            reader.commit(to: &index)

            switch prim {
            case .measureAdd:
                guard
                    let res = LogoMeasurementConverter.add(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            case .measureSub:
                guard
                    let res = LogoMeasurementConverter.subtract(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            case .measureEqual:
                guard
                    let (v1, v2) = LogoMeasurementConverter.compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return "false"
                }
                let tolerance = targetUnit.flatMap(Double.init) ?? 1e-6
                let res = abs(v1 - v2) <= tolerance
                setLastExpressionBoolean(res)
                return res.logoString

            case .measureLess:
                guard
                    let (v1, v2) = LogoMeasurementConverter.compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return "false"
                }
                let res = v1 < v2
                setLastExpressionBoolean(res)
                return res.logoString

            case .measureGreater:
                guard
                    let (v1, v2) = LogoMeasurementConverter.compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return "false"
                }
                let res = v1 > v2
                setLastExpressionBoolean(res)
                return res.logoString

            case .measureMin:
                guard
                    let res = LogoMeasurementConverter.min(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            case .measureMax:
                guard
                    let res = LogoMeasurementConverter.max(
                        val1: val1, unit1: unit1, val2: val2, unit2: unit2, targetUnit: targetUnit)
                else {
                    let msg = "[LOGO Error: Incompatible or invalid measurement units '\(unit1)' and '\(unit2)']"
                    reportError(LogoError(code: 1, message: msg), token: prim.meta.name)
                    return ""
                }
                setLastExpressionMeasurement(value: res.value, unit: res.unit, dimension: res.dimension)
                return "[\(LogoMeasurementConverter.formatResult(res.value)) \(res.unit)]"

            default:
                return ""
            }
        default:
            return ""
        }
    }
}
