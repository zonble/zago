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
        "換行": .newline,
        "新行": .newline,
        "畫框": .drawBox,
        "插入框": .box,
        "加框": .box,
        "放": .inset,
        "放入": .inset,
        "打": .type,
        "打字": .type,
        "輸入": .type,
        "寫": .type,
        "畫線": .line,
        "畫橫線": .line,
        "橫線": .line,
        "畫直線": .vline,
        "直線": .vline,
        "表格": .table,
        "製表": .table,
        "製作表格": .table,
        "建立表格": .table,
        "填": .fill,
        "填滿": .fill,
        "填入": .fill,
        "填充": .fill,
        "清空文件": .clearBuffer,
        "清畫布": .clearBuffer,
        "清畫面": .clearBuffer,
        "跳至": .goto,
        "前往": .goto,
        "去": .goto,
        "去這行": .gotoline,
        "去指定行": .gotoline,
        "跳至行": .gotoline,
        "前往行": .gotoline,
        "去這欄": .gotocol,
        "去指定欄": .gotocol,
        "跳至欄": .gotocol,
        "前往欄": .gotocol,
        "去最上面": .top,
        "去最前面": .top,
        "去檔頭": .top,
        "去最下面": .bottom,
        "去最後面": .bottom,
        "去檔尾": .bottom,
        "去行首": .lineStart,
        "去開頭": .lineStart,
        "去行尾": .lineEnd,
        "去結尾": .lineEnd,

        // Editor Text Manipulation
        "刪除": .delete,
        "退格": .backspace,
        "往後刪": .delete,
        "往前刪": .backspace,
        "刪除行": .deleteLine,
        "刪除整行": .deleteLine,
        "刪整行": .deleteLine,
        "刪行": .deleteLine,
        "變更文字": .changeText,
        "接行": .joinLine,
        "合併行": .joinLine,
        "斷行": .splitLine,
        "縮排": .indentLines,
        "增加縮排": .indentLines,
        "凸排": .outdentLines,
        "減少縮排": .outdentLines,
        "移動": .move,
        "標記": .mark,
        "選取": .mark,
        "剪下": .cut,
        "貼上": .uncut,
        "對齊": .justify,

        // Buffer State Queries
        "所有緩衝區": .buffers,
        "緩衝區列表": .buffers,
        "緩衝區": .buffer,
        "所有文件": .buffers,
        "文件列表": .buffers,
        "文件": .buffer,
        "所在行內文": .getline,
        "讀取所在行內文": .getline,
        "取得所在行內文": .getline,
        "設定所在行內文": .setline,
        "寫入所在行內文": .setline,
        "目前所在行號": .row,
        "目前行號": .row,
        "行號": .row,
        "目前所在欄號": .col,
        "目前欄號": .col,
        "欄號": .col,
        "總行數": .lineCount,
        "行數": .lineCount,
        "緩衝區文字": .bufferText,
        "緩衝區內容": .bufferText,
        "文件內容": .bufferText,
        "文件內文": .bufferText,
        "全文": .bufferText,
        "選取內容": .selection,
        "選取文字": .selection,
        "選取範圍": .selection,
        "選擇內容": .selection,
        "選擇文字": .selection,
        "選擇範圍": .selection,
        "已修改?": .isModified,
        "有修改?": .isModified,
        "檔案名稱": .fileName,
        "檔名": .fileName,

        // Turtle Graphics
        "前進": .forward,
        "往前": .forward,
        "後退": .back,
        "往後": .back,
        "右轉": .turnRight,
        "往右": .turnRight,
        "左轉": .turnLeft,
        "往左": .turnLeft,
        "落筆": .penDown,
        "下筆": .penDown,
        "提筆": .penUp,
        "起筆": .penUp,
        "烏龜朝向": .setHeading,
        "烏龜指向": .setHeading,
        "朝向": .setHeading,
        "設定方向": .setHeading,
        "烏龜方向": .headingPrimitive,
        "目前方向": .headingPrimitive,

        // Control & Execution
        "重複": .repeatLoop,
        "連做": .repeatLoop,
        "連續": .repeatLoop,
        "要是": .ifCondition,
        "如果": .ifCondition,
        "若": .ifCondition,
        "計數迴圈": .forLoop,   
        "當": .whileLoop,
        "只要": .whileLoop,
        "凡是": .whileLoop,
        "先做.直到": .doWhileLoop,
        "做了再說.直到": .doWhileLoop,
        "直到": .untilLoop,
        "次數": .dotimesLoop,
        "依": .caseSwitch,
        "按照": .caseSwitch,
        "依照": .caseSwitch,
        "依據": .caseSwitch,
        "遇": .condSwitch,
        "遇狀況": .condSwitch,
        "狀況處置": .condSwitch,
        "應變措施": .condSwitch,
        "若為真": .ifTrue,
        "如果為真": .ifTrue,
        "若為假": .ifFalse,
        "如果為假": .ifFalse,
        "定義": .define,
        "宣告": .to,
        "自訂": .to,
        "函式": .to,
        "辦法": .to,
        "措施": .to,
        "變數": .make,
        "定": .make,
        "稱": .name,
        "以": .name,
        "區域變數": .local,
        "顯示": .show,
        "輸出": .output,
        "回報": .output,
        "停止": .stop,
        "結束": .end,
        "完畢": .end,
        "以上": .end,
        "等待": .wait,
        "離開": .bye,
        "委交": .apply,
        "委辦": .invoke,
        "責成": .invoke,
        "執行": .run,
        "執行結果": .runResult,
        "測試": .testCondition,
        "斷言": .assertCondition,
        "捕獲": .catchTag,
        "捕捉": .catchTag,
        "拋出": .throwTag,
        "忽略": .ignore,
        "遍歷": .foreach,
        "走訪": .foreach,
        "循": .foreach,
        "映射": .map,
        "映射連接": .mapSe,
        "過濾": .filter,
        "篩選": .filter,
        "尋找": .find,
        "折疊": .reduce,
        "累計": .reduce,
        "交叉映射": .crossmap,

        // Math & Arithmetic
        "總和": .sum,
        "相加": .sum,
        "相差": .difference,
        "相減": .difference,
        "相積": .product,
        "相乘": .product,
        "相商": .quotient,
        "相除": .quotient,
        "餘數": .remainder,
        "餘": .remainder,
        "取餘": .remainder,
        "模": .modulo,
        "取模": .modulo,
        "次方": .power,
        "冪": .power,
        "負數": .minus,
        "負": .minus,
        "絕對值": .abs,
        "整數": .int,
        "四捨五入": .round,
        "取整": .round,
        "平方根": .sqrt,
        "開根號": .sqrt,
        "根號": .sqrt,
        "自然指數": .exp,
        "常用對數": .log10,
        "自然對數": .ln,
        "反正切": .arctan,
        "正弦": .sin,
        "餘弦": .cos,
        "正切": .tan,
        "弧度反正切": .radArctan,
        "弧度正弦": .radSin,
        "弧度餘弦": .radCos,
        "弧度正切": .radTan,
        "整數數列": .iseq,
        "實數數列": .rseq,
        "隨機": .random,
        "重置隨機": .rerandom,
        "格式化數值": .form,
        "最小值": .min,
        "最大值": .max,

        // Bitwise Operations
        "位元且": .bitAnd,
        "位元或": .bitOr,
        "位元異或": .bitXor,
        "位元非": .bitNot,
        "算術位移": .ashift,
        "邏輯左移": .lshift,
        "邏輯右移": .rshift,
        "左移": .lshift,
        "右移": .rshift,


        // Logic & Comparisons
        "真": .trueVal,
        "假": .falseVal,
        "都成立": .andLogic,
        "任一成立": .orLogic,
        "不成立": .notLogic,
        "僅一成立": .xorLogic,
        "互斥成立": .xorLogic,
        "非此即彼": .xorLogic,
        "小於": .less,
        "少於": .less,
        "遜於": .less,
        "大於": .greater,
        "多過": .greater,
        "超過": .greater,
        "小於等於": .lessOrEqual,
        "大於等於": .greaterOrEqual,
        "前者較小": .less,
        "前者較大": .greater,
        "前者少於": .less,
        "前者多於": .greater,
        "前者遜於": .less,
        "前者超過": .greater,
        "前者小於等於": .lessOrEqual,
        "前者大於等於": .greaterOrEqual,

        // Data Structures & Collections
        "取值": .thing,
        "接字": .word,
        "單字": .word,
        "字": .word,
        "列表": .list,
        "句子": .sentence,
        "接句": .sentence,
        "前方加入": .fput,
        "後方加入": .lput,
        "前加": .fput,
        "後加": .lput,
        "首加": .fput,
        "尾加": .lput,
        "陣列": .array,
        "多維陣列": .mdarray,
        "設定多維項目": .mdsetItem,
        "列表轉陣列": .listToArray,
        "陣列轉列表": .arrayToList,
        "結合": .combine,
        "組合": .combine,
        "反轉": .reverse,
        "產生符號": .gensym,
        "取開頭": .first,
        "取第一個": .first,
        "結尾": .last,
        "取結尾": .last,
        "取最後": .last,
        "取最後一個": .last,
        "取所有開頭": .firsts,
        "取所有第一": .firsts,
        "除了第一個": .butFirst,
        "第一個外": .butFirst,
        "第一個之外": .butFirst,
        "去頭": .butFirst,
        "除了最後": .butLast,
        "最後一個外": .butLast,
        "最後一個之外": .butLast,
        "去尾": .butLast,
        "所有去頭": .butFirsts,
        "取項目": .item,
        "取任一項": .pick,
        "隨機選取": .pick,
        "隨機抽取": .pick,
        "摸彩": .pick,
        "移除": .remove,
        "去重": .remdup,
        "移除重複": .remdup,
        "加引號": .quoted,
        "分割": .split,
        "拆分": .split,
        "切割": .split,
        "設定項目": .setItem,
        "設定首項": .setFirst,
        "設定開頭": .setFirst,
        "設定去頭": .setBFL,
        "推入": .push,
        "壓入": .push,
        "彈出": .pop,
        "出列": .dequeue,
        "設定屬性": .pprop,
        "取得屬性": .gprop,
        "移除屬性": .remprop,
        "屬性列表": .plist,
        "所有屬性列表": .plists,
        "錯誤": .error,

        // Predicates / Type Queries
        "是文字?": .isWord,
        "是文字嗎?": .isWord,
        "文字?": .isWord,
        "是列表?": .isList,
        "是列表嗎?": .isList,
        "列表?": .isList,
        "是陣列?": .isArray,
        "是陣列嗎?": .isArray,
        "陣列?": .isArray,
        "是數字?": .isNumber,
        "是數字嗎?": .isNumber,
        "數字?": .isNumber,
        "是空?": .isEmpty,
        "空?": .isEmpty,
        "是空的?": .isEmpty,
        "是空的嗎?": .isEmpty,
        "空的?": .isEmpty,
        "相等?": .isEqual,
        "相等嗎?": .isEqual,
        "等於?": .isEqual,
        "相同?": .isEqual,
        "不相等?": .isNotEqual,
        "不等於?": .isNotEqual,
        "不相等嗎?": .isNotEqual,
        "不等於嗎?": .isNotEqual,
        "全等?": .isIdentityEqual,
        "同等?": .isIdentityEqual,
        "字典序小於?": .isBefore,
        "在之前?": .isBefore,
        "包含?": .isMember,
        "是成員?": .isMember,
        "是成員嗎?": .isMember,
        "有?": .isMember,
        "是子字串?": .isSubstring,
        "是子字串嗎?": .isSubstring,
        "子字串?": .isSubstring,
        "是函式?": .isProcedure,
        "是辦法?": .isProcedure,
        "是措施": .isProcedure,
        "是原語?": .isPrimitive,
        "是內建?": .isPrimitive,
        "是內建的?": .isPrimitive,
        "是內建的嗎?": .isPrimitive,
        "已定義?": .isDefined,
        "是變數名?": .isName,
        "計數": .count,
        "長度": .count,

        // Text Analysis, Transformations, CJK & Regex
        "ASCII碼": .ascii,
        "轉字元": .char,
        "包含項目": .member,
        "取此項之後": .member,
        "大寫": .uppercase,
        "轉大寫": .uppercase,
        "小寫": .lowercase,
        "轉小寫": .lowercase,
        "反白": .standout,
        "醒目": .standout,
        "轉寫": .translit,
        "繁體簡": .transformToHans,
        "簡轉繁": .transformToHant,
        "轉簡體": .transformToHans,
        "轉繁體": .transformToHant,
        "轉羅馬拼音": .transformToLatin,
        "轉拉丁": .transformToLatin,
        "轉平假名": .transformToHiragana,
        "轉片假名": .transformToKatakana,
        "轉羅馬字": .transformToRomaji,
        "中英加空格": .spacingCJK,
        "字元數": .charCount,
        "中文字數": .charCountCJK,
        "CJK字數": .charCountCJK,
        "單字數": .charCountWords,
        "顏文字數": .charCountEmoji,
        "Emoji數": .charCountEmoji,
        "Emoji字數": .charCountEmoji,
        "行數統計": .charCountLines,
        "解析": .parse,
        "執行解析": .runparse,
        "索引": .indexof,
        "位置": .indexof,
        "最後索引": .lastindexof,
        "最後位置": .lastindexof,
        "所有索引": .indexesof,
        "包含": .contains,
        "包括": .contains,
        "開頭是": .startswith,
        "始於": .startswith,
        "結尾是": .endswith,
        "終於": .endswith,
        "子字串": .substring,
        "截取": .substring,
        "取代": .replace,
        "替換": .replace,
        "修剪": .trim,
        "去前後空白": .trim,
        "重複字串": .repeatstr,
        "連接字串": .join,
        "合併字串": .join,
        "行列表": .lines,
        "分行列表": .lines,
        "合行": .unlines,
        "合併行列表": .unlines,
        "字串格式": .format,
        "左填補": .padleft,
        "右填補": .padright,
        "正則比對": .regexMatch,
        "正則取代": .regexReplace,
        "正則尋找": .regexFind,
        "正規比對": .regexMatch,
        "正規取代": .regexReplace,
        "正規尋找": .regexFind,


        // Formatting & Date
        "日期": .date,
        "時間": .time,
        "今天日期": .date,
        "現在時間": .time,
        "現在": .datetime,
        "現在完整時間": .datetime,
        "日期時間": .datetime,
        "輸出日期": .dateformat,
        "日期增加": .dateadd,
        "加日期": .dateadd,
        "日期差": .datediff,
        "日期相減": .datediff,
        "數字格式": .formatNumber,
        "列表格式": .formatList,
        "清單格式": .formatList,
        "時間格式": .formatRelativeTime,
        "相對時間格式": .formatRelativeTime,
        "位元格式": .formatBytes,
        "檔案大小格式": .formatBytes,
        "姓名格式": .formatName,
        "轉換曆法": .convertCalendar,
        "曆法轉換": .convertCalendar,
        "轉換度量": .convertMeasure,
        "度量轉換": .convertMeasure,
        "度量格式": .formatMeasure,
        "度量相加": .measureAdd,
        "度量相減": .measureSub,
        "度量乘倍": .measureScale,
        "度量相等?": .measureEqual,
        "度量小於?": .measureLess,
        "度量大於?": .measureGreater,
        "度量最小": .measureMin,
        "度量最大": .measureMax,

        // Codecs, Detectors & Hashes
        "偵測網址": .detectURL,
        "偵測郵件": .detectEmail,
        "偵測信箱": .detectEmail,
        "偵測電話": .detectPhone,
        "偵測日期": .detectDate,
        "偵測地址": .detectAddress,
        "UUID": .uuid,
        "是UUID?": .isUUID,
        "Base64編碼": .base64Encode,
        "Base64解碼": .base64Decode,
        "是Base64?": .isBase64,
        "網址編碼": .urlEncode,
        "URL編碼": .urlEncode,
        "網址解碼": .urlDecode,
        "URL解碼": .urlDecode,
        "十六進位編碼": .hexEncode,
        "Hex編碼": .hexEncode,
        "十六進位解碼": .hexDecode,
        "Hex解碼": .hexDecode,
        "SHA256雜湊": .hashSha256,
        "SHA1雜湊": .hashSha1,
        "MD5雜湊": .hashMd5,

        // Workspace, Sorting & System Helpers
        "排序": .sort,
        "在地化排序": .sortLocalized,
        "讀取字串": .readWord,
        "讀字串": .readWord,
        "讀取一行": .readWord,
        "讀取字元": .readChar,
        "讀字元": .readChar,
        "讀按鍵": .readChar,
        "所有變數": .names,
        "變數列表": .names,
        "所有程序": .procedures,
        "程序列表": .procedures,
        "所有原語": .primitives,
        "指令列表": .primitives,
        "工作區內容": .contents,
        "程序程式碼": .text,
        "清除項目": .erase,
        "清除程序": .erps,
        "清除變數": .erns,
        "清除全部": .erall,
        "參數個數": .arity,
        "參數": .arity,
        "說明": .doc,
        "說明文件": .doc,
        "手冊": .doc,
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
        "假": false,
        "是": true,
        "否": false,
        "對": true,
        "錯": false,
    ]

    public func parsePrimitive(_ token: String) -> LogoPrimitive? {
        let clean = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.hasPrefix("\"") && !clean.hasPrefix("'") && !clean.hasPrefix(":") else { return nil }
        return Self.primitiveMap[clean.uppercased()] ?? Self.primitiveMap[clean]
    }

    public func parseOperator(_ token: String) -> LogoOperator? {
        let clean = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.hasPrefix("\"") && !clean.hasPrefix("'") && !clean.hasPrefix(":") else { return nil }
        return Self.operatorMap[clean]
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
        case "下", "下方", "南": return .down
        default: return nil
        }
    }

    public func parseNumberStyle(_ token: String) -> LogoNumberStyle? {
        switch token.lowercased() {
        case "貨幣", "金額", "錢": return .currency
        case "百分比", "比例": return .percent
        case "中文數字", "讀音", "念法": return .spellout
        case "金融", "大寫金融", "大寫", "大寫數字": return .financial
        case "蘇州碼", "花碼": return .suzhou
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

    public func parsePersonNameField(_ token: String) -> LogoPersonNameField? {
        let clean = token.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\"' ")).trimmingCharacters(in: .whitespacesAndNewlines)
        switch clean {
        case "名", "名字", "名氏": return .givenName
        case "姓", "姓氏": return .familyName
        case "字", "中間名": return .middleName
        case "稱謂", "頭銜", "職稱": return .prefix
        case "後綴", "後稱": return .suffix
        case "暱稱", "綽號", "號": return .nickname
        case "全名", "姓名": return .fullName
        case "風格", "樣式": return .style
        case "語言", "語系", "地區": return .locale
        default: return nil
        }
    }

    public func parseFormatOptionField(_ token: String) -> LogoFormatOptionField? {
        let clean = token.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\"' ")).trimmingCharacters(in: .whitespacesAndNewlines)
        switch clean {
        case "類型", "種類": return .type
        case "風格", "樣式", "格式": return .style
        case "語言", "語系", "地區": return .locale
        case "貨幣", "幣別": return .currency
        case "精度", "小數位", "位數": return .precision
        case "單位", "轉為", "目標單位": return .unit
        case "自然換算", "自動換算", "適當單位": return .naturalScale
        case "曆法", "日曆": return .calendar
        case "日期": return .date
        case "時間": return .time
        default: return nil
        }
    }

    public func parseBorderStyle(_ token: String) -> BorderStyle? {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "單線", "單": return .single
        case "粗線", "粗": return .heavy
        case "雙線", "雙": return .double
        case "純字元", "字元", "ascii": return .ascii
        case "三段虛線", "三虛線", "三段線": return .tripleDash
        case "粗三段虛線", "粗三虛線", "粗三段線": return .heavyTripleDash
        case "四段虛線", "四虛線", "四段線": return .quadrupleDash
        case "粗四段虛線", "粗四虛線", "粗四段線": return .heavyQuadrupleDash
        case "二段虛線", "雙虛線", "雙段虛線", "二段線": return .doubleDash
        case "粗二段虛線", "粗雙虛線", "粗雙段虛線", "粗二段線": return .heavyDoubleDash
        default: return nil
        }
    }

    public func parseCalendarIdentifier(_ token: String) -> Calendar.Identifier? {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "西曆", "公曆", "陽曆": return .gregorian
        case "民國曆", "民國", "國曆": return .republicOfChina
        case "日本曆", "和曆": return .japanese
        case "農曆", "陰曆", "中曆": return .chinese
        case "佛曆", "泰國曆", "泰曆": return .buddhist
        case "伊斯蘭曆", "回曆": return .islamic
        case "猶太曆", "希伯來曆": return .hebrew
        case "波斯曆", "伊朗曆": return .persian
        case "印度曆": return .indian
        case "科普特曆": return .coptic
        case "衣索比亞曆": return .ethiopicAmeteMihret
        default: return nil
        }
    }

    public func parseDateTimeStylePreset(_ token: String) -> LogoDateTimeStylePreset? {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "簡短", "簡稱", "短": return .short
        case "標準", "中等", "中": return .medium
        case "詳細", "較長", "長": return .long
        case "全部", "完整", "最詳": return .full
        case "iso8601", "iso": return .iso8601
        default: return nil
        }
    }

    public var fillerTokens: Set<String> {
        ["為", "成", "次", "步", "到", "至", "則", "否則", "不然", "，", "。"]
    }

    public var keywordAliases: [String] {
        Array(Self.primitiveMap.keys)
            + Array(Self.operatorMap.keys)
            + Array(Self.headingMap.keys)
            + Array(Self.booleanMap.keys)
            + [
                "單線", "粗線", "雙線", "純字元", "三段虛線", "粗三段虛線", "四段虛線", "粗四段虛線", "二段虛線", "粗二段虛線",
                "西曆", "公曆", "陽曆", "民國曆", "民國", "日本曆", "和曆", "農曆", "陰曆", "中曆", "佛曆", "伊斯蘭曆", "猶太曆",
                "簡短", "標準", "完整", "全部",
                "為", "成", "次", "到", "至", "則", "否則", "不然",
            ]
    }

    public func aliases(for primitive: LogoPrimitive) -> [String] {
        Self.primitiveMap.compactMap { $0.value == primitive ? $0.key : nil }.sorted()
    }
}
