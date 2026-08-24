import Drawing
import Foundation
import LogoEngine

/// A compact, language-neutral LOGO dialect written with emoji.
///
/// Emoji presentation selectors are ignored while parsing, so both `▶` and
/// `▶️` spellings work even when an input method chooses a different display
/// presentation.
public struct LogoEmojiPlugin: LogoParserPlugin {
    public let id = "emoji"
    public let displayName = "Emoji (😀)"
    public let aliases = ["emoji-logo", "emojilogo", "😀"]

    public init() {}

    private static let primitiveMap: [String: LogoPrimitive] = [
        // Drawing and editor output
        "🖼": .box,
        "🔲": .drawBox,
        "✍️": .type,
        "🎪": .show,
        "↩": .newline,
        "↔": .line,
        "↕": .vline,
        "▦": .table,
        "🪣": .fill,
        "📍": .goto,
        "🧹": .clearBuffer,

        // Turtle graphics
        "▶": .forward,
        "◀": .back,
        "↪": .turnRight,
        "↶": .turnLeft,
        "🖊": .penDown,
        "🪽": .penUp,
        "🧭": .setHeading,
        "🧭❓": .headingPrimitive,

        // Control and procedures
        "🔁": .repeatLoop,
        "❓": .ifCondition,
        "⏳": .whileLoop,
        "🔢": .forLoop,
        "📣": .output,
        "🛑": .stop,
        "🧩": .to,
        "🏁": .end,
        "🚀": .run,

        // Variables, data, and arithmetic
        "📦": .make,
        "🏷": .name,
        "➕": .sum,
        "➗": .quotient,
        "✖": .product,
        "➰": .remainder,
        "🧮": .modulo,
        "📏": .count,
        "🥇": .first,
        "🥉": .last,
        "🔤": .word,
        "📋": .list,

        // Editing
        "⌦": .delete,
        "⌫": .backspace,
        "🗑️📄": .deleteLine,
        "⤒": .top,
        "⤓": .bottom,
        "⏮": .lineStart,
        "⏭": .lineEnd,
        "🔄🔤": .changeText,
        "🔗📄": .joinLine,
        "✂️📄": .splitLine,
        "➡️📐": .indentLines,
        "⬅️📐": .outdentLines,
        "🚚": .move,
        "🔖": .mark,
        "✂": .cut,
        "📋⬇": .uncut,
        "📐": .justify,
        "📥": .inset,

        // Control flow and higher-order operations
        "🔂": .dotimesLoop,
        "🔁❓": .doWhileLoop,
        "⏳❓": .untilLoop,
        "❓⏳": .doUntilLoop,
        "🔀": .caseSwitch,
        "🚦": .condSwitch,
        "🧪": .testCondition,
        "‼": .assertCondition,
        "🏠": .local,
        "🗄️📥": .pons,
        "🗄️📤": .pops,
        "🗄️👀": .povas,
        "✅❓": .ifTrue,
        "❌❓": .ifFalse,
        "🥅": .catchTag,
        "🏈": .throwTag,
        "💤": .wait,
        "👋": .bye,
        "🧰": .apply,
        "📞": .invoke,
        "🔄": .foreach,
        "🗺": .map,
        "🗺🔗": .mapSe,
        "🧺": .filter,
        "🔎": .find,
        "🗜": .reduce,
        "✖️🗺": .crossmap,
        "🚀📦": .runResult,
        "🙈": .ignore,

        // Buffers and editor queries
        "📚": .buffers,
        "📄": .buffer,
        "📖": .getline,
        "📝": .setline,
        "📍↕": .gotoline,
        "📍↔": .gotocol,
        "#️⃣↕": .row,
        "#️⃣↔": .col,
        "🔢📄": .lineCount,
        "📄🔤": .bufferText,
        "🔖🔤": .selection,
        "📝❓": .isModified,
        "📛": .fileName,

        // Lists, arrays, words, and property lists
        "📦❓": .thing,
        "🔢➡️🔣": .char,
        "🔣➡️🔢": .ascii,
        "🗣": .sentence,
        "⬅📋": .fput,
        "📋➡": .lput,
        "🧱": .array,
        "🧊": .mdarray,
        "🧊🔎": .mditem,
        "🧊📝": .mdsetItem,
        "📋➡️🧱": .listToArray,
        "🧱➡️📋": .arrayToList,
        "🧬": .combine,
        "🔃": .reverse,
        "🆕🏷": .gensym,
        "🥇🥇": .firsts,
        "🚫🥇": .butFirst,
        "🚫🥉": .butLast,
        "🚫🥇🥇": .butFirsts,
        "☝": .item,
        "🎲☝": .pick,
        "➖📋": .remove,
        "👯🚫": .remdup,
        "💭": .quoted,
        "🪓": .split,
        "☝📝": .setItem,
        "🥇📝": .setFirst,
        "🚫🥇📝": .setBFL,
        "📚⬆": .push,
        "📚⬇": .pop,
        "🚶📚": .dequeue,
        "🗃➕": .pprop,
        "🗃🔎": .gprop,
        "🗃➖": .remprop,
        "🗃📋": .plist,
        "🗃📚": .plists,
        "💥": .error,

        // Predicates and logic
        "🔤❓": .isWord,
        "📋❓": .isList,
        "🧱❓": .isArray,
        "🔢❓": .isNumber,
        "🫙❓": .isEmpty,
        "🟰❓": .isEqual,
        "≠❓": .isNotEqual,
        "🪪❓": .isIdentityEqual,
        "⏪❓": .isBefore,
        "👥❓": .isMember,
        "👥🔎": .member,
        "🔡❓": .isSubstring,
        "🧩❓": .isProcedure,
        "⚙️❓": .isPrimitive,
        "📌❓": .isDefined,
        "🏷❓": .isName,
        "✅✅": .andLogic,
        "✅❌": .orLogic,
        "🔀✅": .xorLogic,
        "🚫": .notLogic,
        "✅‼": .trueVal,
        "❌‼": .falseVal,
        "◁❓": .less,
        "▷❓": .greater,
        "◁🟰❓": .lessOrEqual,
        "▷🟰❓": .greaterOrEqual,

        // Text and strings
        "🔠": .uppercase,
        "🔡": .lowercase,
        "🌟": .standout,
        "🔤🔄": .translit,
        "🇨🇳": .transformToHans,
        "🇹🇼": .transformToHant,
        "🔤🌐": .transformToLatin,
        "🇯🇵ひ": .transformToHiragana,
        "🇯🇵カ": .transformToKatakana,
        "🇯🇵🔤": .transformToRomaji,
        "↔️🀄": .spacingCJK,
        "🔢🔤": .charCount,
        "🔢🀄": .charCountCJK,
        "🔢🗣": .charCountWords,
        "🔢😀": .charCountEmoji,
        "🔢↩": .charCountLines,
        "🧠": .parse,
        "🧠🚀": .runparse,
        "🔎#️⃣": .indexof,
        "🔎#️⃣⏪": .lastindexof,
        "🔎#️⃣📋": .indexesof,
        "📦🔎": .contains,
        "🔤⏮": .startswith,
        "🔤⏭": .endswith,
        "🔡✂": .substring,
        "🔁🔡": .replace,
        "✂️↔": .trim,
        "🔁🔤": .repeatstr,
        "🔗": .join,
        "🔤➡️📄": .lines,
        "📄➡️🔤": .unlines,
        "🎨🔤": .format,
        "⬅️🧽": .padleft,
        "🧽➡️": .padright,
        "🕸❓": .regexMatch,
        "🕸🔁": .regexReplace,
        "🕸🔎": .regexFind,

        // Math and bitwise operations
        "🔽": .min,
        "🔼": .max,
        "➖➖": .difference,
        "⏫": .power,
        "➖1️⃣": .minus,
        "📏➕": .abs,
        "🔢⬇": .int,
        "🎯": .round,
        "√": .sqrt,
        "📈": .exp,
        "🔟🪵": .log10,
        "🪵": .ln,
        "📐↩": .arctan,
        "〰️": .sin,
        "🌊": .cos,
        "📐📈": .tan,
        "⭕📐↩": .radArctan,
        "⭕〰️": .radSin,
        "⭕🌊": .radCos,
        "⭕📐📈": .radTan,
        "🔢➡️🔢": .iseq,
        "🔣➡️🔣": .rseq,
        "🎲": .random,
        "🎲🔄": .rerandom,
        "🔢🖌": .form,
        "0️⃣1️⃣": .bitAnd,
        "0️⃣➕1️⃣": .bitOr,
        "0️⃣🔀1️⃣": .bitXor,
        "0️⃣🚫": .bitNot,
        "⬅️0️⃣": .lshift,
        "0️⃣➡️": .rshift,
        "↔️0️⃣": .ashift,

        // Dates, formatting, codecs, and workspace
        "📅": .date,
        "🕐": .time,
        "📅🕐": .datetime,
        "📅🎨": .dateformat,
        "📅➕": .dateadd,
        "📅➖": .datediff,
        "🔢🎨": .formatNumber,
        "📋🎨": .formatList,
        "⏱🎨": .formatRelativeTime,
        "💾🎨": .formatBytes,
        "👤🎨": .formatName,
        "📅🔄": .convertCalendar,
        "📏🔄": .convertMeasure,
        "📏🎨": .formatMeasure,
        "📏➕📏": .measureAdd,
        "📏➖📏": .measureSub,
        "📏✖️🔢": .measureScale,
        "📏🟰📏": .measureEqual,
        "📏◁📏": .measureLess,
        "📏▷📏": .measureGreater,
        "📏🔽": .measureMin,
        "📏🔼": .measureMax,
        "🔗🌐": .detectURL,
        "📧🔎": .detectEmail,
        "📞🔎": .detectPhone,
        "📅🔎": .detectDate,
        "🏠🔎": .detectAddress,
        "🆔": .uuid,
        "🆔❓": .isUUID,
        "🆔🕐": .uuidTime,
        "6️⃣4️⃣⬆": .base64Encode,
        "6️⃣4️⃣⬇": .base64Decode,
        "6️⃣4️⃣❓": .isBase64,
        "🔗⬆": .urlEncode,
        "🔗⬇": .urlDecode,
        "1️⃣6️⃣⬆": .hexEncode,
        "1️⃣6️⃣⬇": .hexDecode,
        "#️⃣2️⃣5️⃣6️⃣": .hashSha256,
        "#️⃣1️⃣": .hashSha1,
        "#️⃣5️⃣": .hashMd5,
        "🔤⬆⬇": .sort,
        "🌐⬆⬇": .sortLocalized,
        "🎤🔤": .readWord,
        "🎤1️⃣": .readChar,
        "🏷📚": .names,
        "🧩📚": .procedures,
        "⚙️📚": .primitives,
        "🧰📋": .contents,
        "🧩📜": .text,
        "🧩📝": .define,
        "🧽": .erase,
        "🧽🧩": .erps,
        "🧽🏷": .erns,
        "🧽🌎": .erall,
        "#️⃣❓": .arity,
        "📖❓": .doc,
    ]

    private static let operatorMap: [String: LogoOperator] = [
        "🟰": .equal,
        "≠": .notEqual,
        "◁": .lessThan,
        "▷": .greaterThan,
        "◀=": .lessOrEqual,
        "▶=": .greaterOrEqual,
    ]

    private static let headingMap: [String: LogoHeading] = [
        "⬆": .up,
        "➡": .right,
        "⬇": .down,
        "⬅": .left,
    ]

    private static let booleanMap: [String: Bool] = [
        "✅": true,
        "👍": true,
        "❌": false,
        "👎": false,
    ]

    private static func normalized(_ token: String) -> String {
        token
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .unicodeScalars
            .filter { $0.value != 0xFE0E && $0.value != 0xFE0F }
            .map(String.init)
            .joined()
    }

    private static func lookup<Value>(_ token: String, in map: [String: Value]) -> Value? {
        let clean = normalized(token)
        return map.first { normalized($0.key) == clean }?.value
    }

    public func parsePrimitive(_ token: String) -> LogoPrimitive? {
        let clean = Self.normalized(token)
        guard !clean.hasPrefix("\"") && !clean.hasPrefix("'") && !clean.hasPrefix(":") else { return nil }
        return Self.lookup(clean, in: Self.primitiveMap)
    }

    public func parseOperator(_ token: String) -> LogoOperator? {
        Self.lookup(token, in: Self.operatorMap)
    }

    public func parseHeading(_ token: String) -> LogoHeading? {
        Self.lookup(token, in: Self.headingMap)
    }

    public func parseBoolean(_ token: String) -> Bool? {
        Self.lookup(token, in: Self.booleanMap)
    }

    public func parseExitPosition(_ token: String) -> BoxExitPosition? {
        switch Self.normalized(token) {
        case "↗": return .ne
        case "↘": return .se
        case "↖": return .nw
        case "↙": return .sw
        case "⏬": return .down
        default: return nil
        }
    }

    public func parseBorderStyle(_ token: String) -> BorderStyle? {
        switch Self.normalized(token).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) {
        case "➖": return .single
        case "➰": return .heavy
        case "🟰": return .double
        case "🔤": return .ascii
        default: return nil
        }
    }

    public var fillerTokens: Set<String> { ["👉"] }

    public var keywordAliases: [String] {
        Array(Self.primitiveMap.keys)
            + Array(Self.operatorMap.keys)
            + Array(Self.headingMap.keys)
            + Array(Self.booleanMap.keys)
            + ["↗", "↘", "↖", "↙", "⏬"]
    }

    public func aliases(for primitive: LogoPrimitive) -> [String] {
        Self.primitiveMap.compactMap { $0.value == primitive ? $0.key : nil }.sorted()
    }
}
