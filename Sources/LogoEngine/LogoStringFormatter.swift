import Foundation

/// Pure implementation of LOGO's FORMAT reporter.
///
/// Argument evaluation and list expansion stay in `LogoEngine`; this type only
/// parses the format pattern and renders already-evaluated string arguments.
internal enum LogoStringFormatter {
    static func argumentCount(for pattern: String) -> Int {
        var count = 0
        var maxPositional = 0
        let chars = Array(pattern)
        var i = 0

        while i < chars.count {
            guard chars[i] == "%", i + 1 < chars.count else {
                i += 1
                continue
            }

            i += 1
            if chars[i] == "%" {
                i += 1
                continue
            }

            var digits = ""
            let digitStart = i
            while i < chars.count && chars[i].isNumber {
                digits.append(chars[i])
                i += 1
            }
            if !digits.isEmpty, let pos = Int(digits), pos > 0,
                i == chars.count || !("sSdfxX".contains(chars[i]))
            {
                maxPositional = max(maxPositional, pos)
                continue
            }
            i = digitStart

            while i < chars.count {
                let ch = chars[i]
                i += 1
                if "sSdfxX".contains(ch) {
                    count += 1
                    break
                }
            }
        }

        return max(count, maxPositional)
    }

    static func format(pattern: String, args: [String]) -> String {
        var result = ""
        var argIndex = 0
        let chars = Array(pattern)
        var i = 0

        while i < chars.count {
            if chars[i] == "%" && i + 1 < chars.count {
                i += 1
                if chars[i] == "%" {
                    result.append("%")
                    i += 1
                    continue
                }

                var posDigits = ""
                let posStart = i
                while i < chars.count && chars[i].isNumber {
                    posDigits.append(chars[i])
                    i += 1
                }
                if !posDigits.isEmpty, let posIdx = Int(posDigits), posIdx > 0,
                    i == chars.count || !("sSdfxX".contains(chars[i]))
                {
                    let targetVal = posIdx <= args.count ? args[posIdx - 1] : ""
                    result.append(targetVal)
                    continue
                } else {
                    i = posStart
                }

                var specifier = "%"
                while i < chars.count {
                    let ch = chars[i]
                    specifier.append(ch)
                    i += 1
                    if "sSdfxX".contains(ch) {
                        break
                    }
                }

                let currentArg = argIndex < args.count ? args[argIndex] : ""
                argIndex += 1
                let lastChar = specifier.last ?? "s"
                let trimmedArg = currentArg.trimmingCharacters(in: .whitespacesAndNewlines)

                if lastChar == "d" || lastChar == "D" || lastChar == "x" || lastChar == "X" {
                    let intVal = Int(trimmedArg) ?? Int(Double(trimmedArg) ?? 0.0)
                    result.append(String(format: specifier, CInt(intVal)))
                } else if lastChar == "f" {
                    let dblVal = Double(trimmedArg) ?? 0.0
                    result.append(String(format: specifier, dblVal))
                } else if specifier.contains("-") || specifier.contains("0") || specifier.count > 2 {
                    let widthStr = specifier.dropFirst().dropLast()
                    let alignLeft = widthStr.hasPrefix("-")
                    let cleanWidth = Int(widthStr.replacingOccurrences(of: "-", with: "")) ?? 0
                    let displayWidth = currentArg.reduce(0) { $0 + $1.displayWidth }
                    if displayWidth < cleanWidth {
                        let pad = String(repeating: " ", count: cleanWidth - displayWidth)
                        result.append(alignLeft ? currentArg + pad : pad + currentArg)
                    } else {
                        result.append(currentArg)
                    }
                } else {
                    result.append(currentArg)
                }
            } else {
                result.append(chars[i])
                i += 1
            }
        }

        return result
    }
}
