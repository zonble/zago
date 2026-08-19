import Foundation
import LogoEngine

/// Traditional Chinese (`zh-TW` / `zh-Hant`) Dialect Plugin for LogoEngine.
public struct LogoTraditionalChinesePlugin: LogoParserPlugin {
    public let id: String = "zh-TW"
    public let displayName: String = "Traditional Chinese (繁體中文)"
    public let aliases: [String] = ["zh-Hant", "zh", "traditional-chinese"]

    public init() {}

    private static let primitiveMap: [String: LogoPrimitive] = [
        // Drawing & Shapes
        "畫框": .drawBox,
        "矩形": .box,
        "框": .drawBox,
        "打字": .type,
        "輸入": .type,
        "寫字": .type,
        "畫線": .line,
        "橫線": .line,
        "垂直線": .vline,
        "直線": .vline,
        "表格": .table,
        "填滿": .fill,
        "清空": .clearBuffer,
        "清畫布": .clearBuffer,
        "跳至": .goto,
        "前往": .goto,
        "定位": .goto,
        "到行": .gotoline,
        "到欄": .gotocol,
        "到列": .gotoline,
        "頂端": .top,
        "底端": .bottom,
        "行首": .lineStart,
        "行尾": .lineEnd,

        // Turtle Graphics
        "前進": .forward,
        "前": .forward,
        "後退": .back,
        "後": .back,
        "右轉": .turnRight,
        "右": .turnRight,
        "左轉": .turnLeft,
        "左": .turnLeft,
        "落筆": .penDown,
        "提筆": .penUp,
        "朝向": .setHeading,
        "方向": .headingPrimitive,

        // Control & Execution
        "重複": .repeatLoop,
        "如果": .ifCondition,
        "若": .ifCondition,
        "否則": .ifElseCondition,
        "迴圈": .forLoop,
        "當": .whileLoop,
        "直到": .untilLoop,
        "次數": .dotimesLoop,
        "條件分支": .caseSwitch,
        "分支": .condSwitch,
        "定義": .define,
        "設定": .make,
        "設為": .make,
        "變數": .name,
        "區域變數": .local,
        "顯示": .show,
        "印出": .show,
        "輸出": .output,
        "回傳": .output,
        "停止": .stop,
        "結束": .end,
        "等待": .wait,
        "離開": .bye,
        "執行": .run,
        "呼叫": .exec,
        "測試": .testCondition,
        "斷言": .assertCondition,
        "捕獲": .catchTag,
        "拋出": .throwTag,
        "忽略": .ignore,
        "遍歷": .foreach,
        "搜尋": .search,

        // Math & Logic
        "總和": .sum,
        "加": .sum,
        "差": .difference,
        "減": .difference,
        "積": .product,
        "乘": .product,
        "商": .quotient,
        "除": .quotient,
        "餘數": .remainder,
        "模": .modulo,
        "次方": .power,
        "負數": .minus,
        "絕對值": .abs,
        "整數": .int,
        "四捨五入": .round,
        "平方根": .sqrt,
        "開根號": .sqrt,
        "隨機": .random,
        "最小值": .min,
        "最大值": .max,

        // Logic
        "且": .andLogic,
        "並且": .andLogic,
        "或": .orLogic,
        "或者": .orLogic,
        "非": .notLogic,
        "反": .notLogic,
        "異或": .xorLogic,

        // Data Structures & Collections
        "接字": .word,
        "單字": .word,
        "字": .word,
        "清單": .list,
        "列表": .list,
        "句子": .sentence,
        "接句": .sentence,
        "成句": .sentence,
        "第一個": .first,
        "首": .first,
        "頭": .first,
        "最後": .last,
        "尾": .last,
        "除了第一個": .butFirst,
        "去頭": .butFirst,
        "除了最後": .butLast,
        "去尾": .butLast,
        "項目": .item,
        "計數": .count,
        "長度": .count,
        "反轉": .reverse,
        "排序": .sort,
        "清單?": .isList,
        "單字?": .isWord,
        "空?": .isEmpty,
        "等於?": .isEqual,
        "相同?": .isEqual,
        "包含?": .isMember,

        // Formatting & Date
        "日期": .date,
        "時間": .time,
        "現在": .datetime,
        "格式化日期": .dateformat,
        "格式化數字": .formatNumber,
        "格式化清單": .formatList,
        "格式化時間": .formatRelativeTime,
        "格式化位元組": .formatBytes,
        "格式化姓名": .formatName,
        "轉換曆法": .convertCalendar,
        "轉換度量": .convertMeasure,
        "格式化度量": .formatMeasure,

        // Codecs & Detectors
        "編碼64": .base64Encode,
        "解碼64": .base64Decode,
        "偵測網址": .detectURL,
        "偵測郵件": .detectEmail,
        "偵測電話": .detectPhone,
        "偵測日期": .detectDate,
        "偵測地址": .detectAddress,
        "唯一碼": .uuid,
    ]

    private static let operatorMap: [String: LogoOperator] = [
        "等於": .equal,
        "是": .equal,
        "不等於": .notEqual,
        "不是": .notEqual,
        "小於": .lessThan,
        "大於": .greaterThan,
        "小於等於": .lessOrEqual,
        "大於等於": .greaterOrEqual,
    ]

    private static let headingMap: [String: LogoHeading] = [
        "北": .up,
        "上": .up,
        "東": .right,
        "右": .right,
        "南": .down,
        "下": .down,
        "西": .left,
        "左": .left,
    ]

    private static let booleanMap: [String: Bool] = [
        "真": true,
        "是": true,
        "假": false,
        "否": false,
        "對": true,
        "錯": false,
    ]

    public func parsePrimitive(_ token: String) -> LogoPrimitive? {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; "))
        return Self.primitiveMap[clean.uppercased()] ?? Self.primitiveMap[clean]
    }

    public func parseOperator(_ token: String) -> LogoOperator? {
        Self.operatorMap[token]
    }

    public func parseHeading(_ token: String) -> LogoHeading? {
        Self.headingMap[token]
    }

    public func parseBoolean(_ token: String) -> Bool? {
        Self.booleanMap[token]
    }

    public func parseExitPosition(_ token: String) -> BoxExitPosition? {
        switch token.lowercased() {
        case "右上", "東北": return .ne
        case "右下", "東南": return .se
        case "左上", "西北": return .nw
        case "左下", "西南": return .sw
        case "下方", "下方出口", "向下", "南": return .down
        default: return nil
        }
    }

    public func parseNumberStyle(_ token: String) -> LogoNumberStyle? {
        switch token.lowercased() {
        case "貨幣", "金額", "錢": return .currency
        case "百分比", "比例": return .percent
        case "中文數字", "大寫", "大寫數字", "讀音", "念法": return .spellout
        case "金融", "大寫金融": return .financial
        case "羅馬數字", "羅馬": return .roman
        case "序數", "第幾": return .ordinal
        case "十進位", "小數", "一般數字": return .decimal
        default: return nil
        }
    }

    public func parseListType(_ token: String) -> LogoListType? {
        switch token.lowercased() {
        case "且", "以及", "和", "與", "並": return .and
        case "或", "或者", "或是": return .or
        case "標準", "單位": return .unit
        default: return nil
        }
    }

    public func parseByteCountStyle(_ token: String) -> LogoByteCountStyle? {
        switch token.lowercased() {
        case "檔案", "檔案大小": return .file
        case "記憶體", "記憶體大小": return .memory
        case "十進位": return .decimal
        case "二進位": return .binary
        case "位元組", "純位元組": return .bytes
        default: return nil
        }
    }

    public func parsePersonNameStyle(_ token: String) -> LogoPersonNameStyle? {
        switch token.lowercased() {
        case "預設": return .default
        case "簡短", "簡稱": return .short
        case "詳細", "完整": return .long
        case "縮寫": return .abbreviated
        default: return nil
        }
    }

    public func resolveKeyword(_ token: String, domain: LogoKeywordDomain) -> String? {
        switch domain {
        case .borderStyle:
            switch token.lowercased() {
            case "單線", "單": return "single"
            case "雙線", "雙": return "double"
            case "圓角", "圓": return "round"
            case "雙圓角": return "double-round"
            case "純字元", "字元": return "ascii"
            case "字元圓角": return "ascii-round"
            case "粗線", "粗": return "thick"
            case "虛線": return "dashed"
            case "點線": return "dotted"
            default: return nil
            }
        case .calendar:
            switch token.lowercased() {
            case "西曆", "公曆", "陽曆": return "gregorian"
            case "民國曆", "民國": return "roc"
            case "日本曆", "和曆": return "japanese"
            case "農曆", "陰曆", "中曆": return "chinese"
            default: return nil
            }
        default:
            return nil
        }
    }

    public var keywordAliases: [String] {
        Array(Self.primitiveMap.keys)
            + Array(Self.operatorMap.keys)
            + Array(Self.headingMap.keys)
            + Array(Self.booleanMap.keys)
    }
}
