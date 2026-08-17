import Foundation

/// Strongly-typed enum representing all UCB LOGO primitives and editor commands.
public enum LogoPrimitive: String, CaseIterable, Equatable, Sendable {
    // Statement / Control Primitives
    case make
    case name
    case type
    case show
    case delete
    case backspace
    case deleteLine
    case top
    case bottom
    case lineStart
    case lineEnd
    case appendText
    case prependText
    case changeText
    case joinLine
    case splitLine
    case indentLines
    case outdentLines
    case move
    case mark
    case cut
    case uncut
    case justify
    case goto
    case box
    case drawBox
    case inset
    case line
    case vline
    case table
    case newline
    case penDown
    case penUp
    case forward
    case back
    case turnRight
    case turnLeft
    case setHeading
    case headingPrimitive
    case ifCondition
    case ifElseCondition
    case output
    case repeatLoop
    case forLoop
    case dotimesLoop
    case whileLoop
    case doWhileLoop
    case untilLoop
    case doUntilLoop
    case caseSwitch
    case condSwitch
    case testCondition
    case assertCondition
    case local
    case pons
    case pops
    case povas
    case ifTrue
    case ifFalse
    case stop
    case catchTag
    case throwTag
    case wait
    case bye
    case apply
    case invoke
    case foreach
    case map
    case mapSe
    case filter
    case find
    case reduce
    case crossmap
    case run
    case runResult
    case ignore
    case to
    case exec

    // Multi-Buffer & Buffer Primitives
    case buffers
    case buffer
    case clearBuffer
    case getline
    case setline
    case gotoline
    case gotocol
    case row
    case col
    case lineCount
    case bufferText
    case selection
    case isModified
    case fileName

    // Expression & Data Primitives
    case thing
    case word
    case list
    case sentence
    case fput
    case lput
    case array
    case mdarray
    case mditem
    case mdsetItem
    case listToArray
    case arrayToList
    case combine
    case reverse
    case gensym
    case first
    case last
    case firsts
    case butFirst
    case butLast
    case butFirsts
    case item
    case pick
    case remove
    case remdup
    case quoted
    case split
    case setItem
    case setFirst
    case setBFL
    case push
    case pop
    case dequeue
    case pprop
    case gprop
    case remprop
    case plist
    case plists
    case error
    case isWord
    case isList
    case isArray
    case isNumber
    case isEmpty
    case isEqual
    case isNotEqual
    case isIdentityEqual
    case isBefore
    case isMember
    case isSubstring
    case isProcedure
    case isPrimitive
    case isDefined
    case isName
    case count
    case ascii
    case char
    case member
    case uppercase
    case lowercase
    case standout
    case translit
    case transformToHans
    case transformToHant
    case transformToLatin
    case transformToHiragana
    case transformToKatakana
    case transformToRomaji
    case spacingCJK
    case charCount
    case charCountCJK
    case charCountWords
    case charCountEmoji
    case charCountLines
    case parse
    case runparse

    // String & Regex Primitives
    case indexof
    case lastindexof
    case indexesof
    case contains
    case startswith
    case endswith
    case substring
    case replace
    case trim
    case repeatstr
    case join
    case lines
    case unlines
    case format
    case padleft
    case padright
    case regexMatch
    case regexReplace
    case regexFind

    // Comparison Primitives
    case less
    case greater
    case lessOrEqual
    case greaterOrEqual

    // Logical Primitives
    case trueVal
    case falseVal
    case andLogic
    case orLogic
    case xorLogic
    case notLogic

    // Math & Bitwise Primitives
    case sum
    case min
    case max
    case difference
    case product
    case quotient
    case power
    case remainder
    case modulo
    case minus
    case abs
    case int
    case round
    case sqrt
    case exp
    case log10
    case ln
    case arctan
    case sin
    case cos
    case tan
    case radArctan
    case radSin
    case radCos
    case radTan
    case iseq
    case rseq
    case random
    case rerandom
    case form
    case bitAnd
    case bitOr
    case bitXor
    case bitNot
    case ashift
    case lshift
    case rshift
    case date
    case time
    case datetime
    case dateformat
    case dateadd
    case datediff
    case formatNumber
    case formatList
    case formatRelativeTime
    case formatBytes
    case convertArea
    case convertLength
    case convertVolume
    case convertAngle
    case convertMass
    case convertPressure
    case convertAcceleration
    case convertDuration
    case convertFrequency
    case convertSpeed
    case convertEnergy
    case convertPower
    case convertTemperature
    case convertIlluminance
    case convertElectricCharge
    case convertElectricCurrent
    case convertElectricPotentialDifference
    case convertElectricResistance
    case convertConcentrationMass
    case convertDispersion
    case convertFuelEfficiency
    case convertInformationStorage
    case formatArea
    case formatLength
    case formatVolume
    case formatAngle
    case formatMass
    case formatPressure
    case formatAcceleration
    case formatDuration
    case formatFrequency
    case formatSpeed
    case formatEnergy
    case formatPower
    case formatTemperature
    case formatIlluminance
    case formatElectricCharge
    case formatElectricCurrent
    case formatElectricPotentialDifference
    case formatElectricResistance
    case formatConcentrationMass
    case formatDispersion
    case formatFuelEfficiency
    case formatInformationStorage
    case detectURL
    case detectEmail
    case detectPhone
    case detectDate
    case detectAddress
    case search
    case sort
    case fill
    case readWord
    case readChar
    case names
    case procedures
    case primitives
    case contents
    case text
    case define
    case erase
    case erps
    case erns
    case erall
    case arity
    case doc
    case end

    private static let rawMappings: [([String], LogoPrimitive)] = [
        (["END"], .end),
        (["READWORD", "RW", "READLINE", "READ"], .readWord),
        (["READCHAR", "RC", "READKEY", "RK"], .readChar),
        (["NAMES"], .names),
        (["PROCEDURES", "PROCS"], .procedures),
        (["PRIMITIVES", "PRIMS"], .primitives),
        (["CONTENTS"], .contents),
        (["TEXT", "FULLTEXT"], .text),
        (["DEFINE"], .define),
        (["ERASE", "ER"], .erase),
        (["ERPS", "ERASEPROCS"], .erps),
        (["ERNS", "ERASENAMES"], .erns),
        (["ERALL"], .erall),
        (["ARITY"], .arity),
        (["DOC", "DOCSTRING"], .doc),
        (["FILL"], .fill),
        (["INSET"], .inset),
        (["SORT"], .sort),
        (["MAKE", "VAR"], .make),
        (["NAME"], .name),
        (["THING"], .thing),
        (["TYPE", "PRINT"], .type),
        (["SHOW", "MESSAGE"], .show),
        (["DEL", "DELETE"], .delete),
        (["BS", "BACKSPACE"], .backspace),
        (["DELETELINE", "DELLINE", "KILLLINE"], .deleteLine),
        (["TOP"], .top),
        (["BOTTOM"], .bottom),
        (["LINESTART"], .lineStart),
        (["LINEEND"], .lineEnd),
        (["APPEND"], .appendText),
        (["PREPEND"], .prependText),
        (["CHANGE"], .changeText),
        (["JOIN"], .joinLine),
        (["SPLITLINE"], .splitLine),
        (["INDENT"], .indentLines),
        (["OUTDENT"], .outdentLines),
        (["MOVE"], .move),
        (["MARK"], .mark),
        (["CUT"], .cut),
        (["PASTE", "UNCUT"], .uncut),
        (["JUSTIFY"], .justify),
        (["GOTO"], .goto),
        (["BOX"], .box),
        (["DRAWBOX"], .drawBox),
        (["LINE"], .line),
        (["VLINE"], .vline),
        (["TABLE"], .table),
        (["NEWLINE", "NL"], .newline),
        (["PD", "PENDOWN"], .penDown),
        (["PU", "PENUP"], .penUp),
        (["FD", "FORWARD"], .forward),
        (["BK", "BACK", "BACKWARD"], .back),
        (["RT", "RIGHT"], .turnRight),
        (["LT", "LEFT"], .turnLeft),
        (["SETHEADING", "SETH"], .setHeading),
        (["HEADING"], .headingPrimitive),
        (["IF"], .ifCondition),
        (["IFELSE"], .ifElseCondition),
        (["OUTPUT", "OP", "RETURN"], .output),
        (["REPEAT"], .repeatLoop),
        (["FOR"], .forLoop),
        (["DOTIMES"], .dotimesLoop),
        (["WHILE"], .whileLoop),
        (["DO.WHILE"], .doWhileLoop),
        (["UNTIL"], .untilLoop),
        (["DO.UNTIL"], .doUntilLoop),
        (["CASE"], .caseSwitch),
        (["COND"], .condSwitch),
        (["TEST"], .testCondition),
        (["ASSERT", "EXPECT"], .assertCondition),
        (["LOCAL"], .local),
        (["PONS"], .pons),
        (["POPS"], .pops),
        (["POVAS"], .povas),
        (["IFTRUE", "IFT"], .ifTrue),
        (["IFFALSE", "IFF"], .ifFalse),
        (["STOP"], .stop),
        (["CATCH"], .catchTag),
        (["THROW"], .throwTag),
        (["WAIT"], .wait),
        (["BYE"], .bye),
        (["APPLY"], .apply),
        (["INVOKE"], .invoke),
        (["FOREACH"], .foreach),
        (["MAP"], .map),
        (["MAP.SE", "MAPSE"], .mapSe),
        (["FILTER"], .filter),
        (["FIND"], .find),
        (["REDUCE"], .reduce),
        (["CROSSMAP"], .crossmap),
        (["RUN"], .run),
        (["RUNRESULT"], .runResult),
        (["IGNORE"], .ignore),
        (["TO"], .to),
        (["EXEC"], .exec),

        // Buffer Primitives
        (["BUFFERS", "BUFFERLIST"], .buffers),
        (["BUFFER"], .buffer),
        (["CLEARBUFFER"], .clearBuffer),
        (["GETLINE"], .getline),
        (["SETLINE"], .setline),
        (["GOTOLINE"], .gotoline),
        (["GOTOCOL"], .gotocol),
        (["ROW"], .row),
        (["COL"], .col),
        (["LINECOUNT", "LINES"], .lineCount),
        (["BUFFERTEXT"], .bufferText),
        (["SELECTION", "SELECTEDTEXT"], .selection),
        (["MODIFIED?", "CHANGED?"], .isModified),
        (["FILENAME", "BUFFERNAME"], .fileName),

        // Data & Array Primitives
        (["WORD"], .word),
        (["LIST"], .list),
        (["SENTENCE", "SE"], .sentence),
        (["FPUT"], .fput),
        (["LPUT", "QUEUE"], .lput),
        (["ARRAY"], .array),
        (["MDARRAY"], .mdarray),
        (["MDITEM"], .mditem),
        (["MDSETITEM"], .mdsetItem),
        (["LISTTOARRAY"], .listToArray),
        (["ARRAYTOLIST"], .arrayToList),
        (["COMBINE"], .combine),
        (["REVERSE"], .reverse),
        (["GENSYM"], .gensym),
        (["FIRST"], .first),
        (["LAST"], .last),
        (["FIRSTS"], .firsts),
        (["BUTFIRST", "BF"], .butFirst),
        (["BUTLAST", "BL"], .butLast),
        (["BUTFIRSTS", "BFS"], .butFirsts),
        (["ITEM"], .item),
        (["PICK"], .pick),
        (["REMOVE"], .remove),
        (["REMDUP"], .remdup),
        (["QUOTED"], .quoted),
        (["SPLIT"], .split),
        ([".SETITEM", "SETITEM"], .setItem),
        ([".SETFIRST", "SETFIRST"], .setFirst),
        ([".SETBF", "SETBF", ".SETBUTFIRST", "SETBUTFIRST"], .setBFL),
        (["PUSH"], .push),
        (["POP"], .pop),
        (["DEQUEUE"], .dequeue),
        (["PPROP", "PUTPROP"], .pprop),
        (["GPROP", "GETPROP"], .gprop),
        (["REMPROP", "ERASEPROP"], .remprop),
        (["PLIST", "PROPLIST"], .plist),
        (["PLISTS", "PROPLISTS"], .plists),
        (["ERROR"], .error),

        // Predicates & Comparisons
        (["WORD?", "WORDP"], .isWord),
        (["LIST?", "LISTP"], .isList),
        (["ARRAY?", "ARRAYP"], .isArray),
        (["NUMBER?", "NUMBERP"], .isNumber),
        (["EMPTY?", "EMPTYP"], .isEmpty),
        (["EQUAL?", "EQUALP"], .isEqual),
        ([".EQ"], .isIdentityEqual),
        (["NOTEQUAL?", "NOTEQUALP"], .isNotEqual),
        (["BEFORE?", "BEFOREP"], .isBefore),
        (["MEMBER?", "MEMBERP"], .isMember),
        (["SUBSTRING?", "SUBSTRINGP"], .isSubstring),
        (["PROCEDURE?", "PROCEDUREP"], .isProcedure),
        (["PRIMITIVE?", "PRIMITIVEP"], .isPrimitive),
        (["DEFINED?", "DEFINEDP"], .isDefined),
        (["NAME?", "NAMEP"], .isName),
        (["LESSP", "LESS?"], .less),
        (["GREATERP", "GREATER?"], .greater),
        (["LESSEQUALP", "LESSEQUAL?"], .lessOrEqual),
        (["GREATEREQUALP", "GREATEREQUAL?"], .greaterOrEqual),
        (["COUNT"], .count),
        (["ASCII", "ORD"], .ascii),
        (["CHAR", "CHR"], .char),
        (["MEMBER"], .member),
        (["UPPERCASE"], .uppercase),
        (["LOWERCASE"], .lowercase),
        (["STANDOUT"], .standout),
        (["TRANSLIT", "TRANSFORM"], .translit),
        (["TOHANS", "TRANSFORM.TOHANS"], .transformToHans),
        (["TOHANT", "TRANSFORM.TOHANT"], .transformToHant),
        (["TOLATIN", "TRANSFORM.TOLATIN"], .transformToLatin),
        (["TOHIRAGANA", "TRANSFORM.TOHIRAGANA"], .transformToHiragana),
        (["TOKATAKANA", "TRANSFORM.TOKATAKANA"], .transformToKatakana),
        (["TOROMAJI", "TRANSFORM.TOROMAJI"], .transformToRomaji),
        (["SPACING.CJK"], .spacingCJK),
        (["CHARCOUNT"], .charCount),
        (["CHARCOUNT.CJK"], .charCountCJK),
        (["CHARCOUNT.WORDS"], .charCountWords),
        (["CHARCOUNT.EMOJI"], .charCountEmoji),
        (["CHARCOUNT.LINES"], .charCountLines),
        (["PARSE"], .parse),
        (["RUNPARSE"], .runparse),
        (["INDEXOF", "INDEX_OF"], .indexof),
        (["LASTINDEXOF", "LAST_INDEX_OF"], .lastindexof),
        (["INDEXESOF", "INDICESOF"], .indexesof),
        (["CONTAINS?", "CONTAINSP", "INCLUDES?"], .contains),
        (["STARTSWITH?", "HAS_PREFIX?"], .startswith),
        (["ENDSWITH?", "HAS_SUFFIX?"], .endswith),
        (["SUBSTRING", "SUBSTR", "SLICE"], .substring),
        (["REPLACE", "SUBSTITUTE"], .replace),
        (["TRIM", "STRIP"], .trim),
        (["REPEATSTR", "STR_REPEAT"], .repeatstr),
        (["TOKENIZE_BY"], .split),
        (["IMPLODE", "JOINSTR", "JOIN_LIST"], .join),
        (["LINES", "TO_LINES"], .lines),
        (["UNLINES", "FROM_LINES"], .unlines),
        (["FORMAT", "SPRINTF"], .format),
        (["PADLEFT"], .padleft),
        (["PADRIGHT"], .padright),
        (["REGEX.MATCH"], .regexMatch),
        (["REGEX.REPLACE"], .regexReplace),
        (["REGEX.FIND"], .regexFind),

        // Logical
        (["TRUE"], .trueVal),
        (["FALSE"], .falseVal),
        (["AND"], .andLogic),
        (["OR"], .orLogic),
        (["XOR"], .xorLogic),
        (["NOT"], .notLogic),

        // Math
        (["SUM"], .sum),
        (["MIN"], .min),
        (["MAX"], .max),
        (["DIFFERENCE"], .difference),
        (["PRODUCT"], .product),
        (["QUOTIENT"], .quotient),
        (["REMAINDER", "MOD"], .remainder),
        (["MODULO"], .modulo),
        (["POWER"], .power),
        (["MINUS"], .minus),
        (["ABS"], .abs),
        (["INT"], .int),
        (["ROUND"], .round),
        (["SQRT"], .sqrt),
        (["EXP"], .exp),
        (["LOG10"], .log10),
        (["LN"], .ln),
        (["ARCTAN"], .arctan),
        (["SIN"], .sin),
        (["COS"], .cos),
        (["TAN"], .tan),
        (["RADARCTAN"], .radArctan),
        (["RADSIN"], .radSin),
        (["RADCOS"], .radCos),
        (["RADTAN"], .radTan),
        (["RANGE", "ISEQ"], .iseq),
        (["RSEQ"], .rseq),
        (["RANDOM"], .random),
        (["RERANDOM"], .rerandom),
        (["FORM"], .form),
        (["BIT.AND"], .bitAnd),
        (["BIT.OR"], .bitOr),
        (["BIT.XOR"], .bitXor),
        (["BIT.NOT"], .bitNot),
        (["ASHIFT"], .ashift),
        (["LSHIFT", "BIT.SHL"], .lshift),
        (["RSHIFT", "BIT.SHR"], .rshift),
        (["DATE"], .date),
        (["TIME"], .time),
        (["DATETIME", "NOW"], .datetime),
        (["FORMAT.DATE"], .dateformat),
        (["DATE.ADD"], .dateadd),
        (["DATE.DIFF"], .datediff),
        (["FORMAT.NUMBER"], .formatNumber),
        (["FORMAT.LIST"], .formatList),
        (["FORMAT.RELATIVETIME"], .formatRelativeTime),
        (["FORMAT.BYTES"], .formatBytes),
        (["CONVERT.AREA"], .convertArea),
        (["CONVERT.LENGTH"], .convertLength),
        (["CONVERT.VOLUME"], .convertVolume),
        (["CONVERT.ANGLE"], .convertAngle),
        (["CONVERT.MASS"], .convertMass),
        (["CONVERT.PRESSURE"], .convertPressure),
        (["CONVERT.ACCELERATION"], .convertAcceleration),
        (["CONVERT.DURATION"], .convertDuration),
        (["CONVERT.FREQUENCY"], .convertFrequency),
        (["CONVERT.SPEED"], .convertSpeed),
        (["CONVERT.ENERGY"], .convertEnergy),
        (["CONVERT.POWER"], .convertPower),
        (["CONVERT.TEMPERATURE"], .convertTemperature),
        (["CONVERT.ILLUMINANCE"], .convertIlluminance),
        (["CONVERT.ELECTRICCHARGE", "CONVERT.ELECTRIC.CHARGE"], .convertElectricCharge),
        (["CONVERT.ELECTRICCURRENT", "CONVERT.ELECTRIC.CURRENT"], .convertElectricCurrent),
        (
            [
                "CONVERT.ELECTRICPOTENTIALDIFFERENCE", "CONVERT.ELECTRIC.POTENTIAL.DIFFERENCE", "CONVERT.VOLTAGE",
                "CONVERT.ELECTRIC.POTENTIAL",
            ], .convertElectricPotentialDifference
        ),
        (["CONVERT.ELECTRICRESISTANCE", "CONVERT.ELECTRIC.RESISTANCE"], .convertElectricResistance),
        (["CONVERT.CONCENTRATIONMASS", "CONVERT.CONCENTRATION.MASS"], .convertConcentrationMass),
        (["CONVERT.DISPERSION"], .convertDispersion),
        (["CONVERT.FUELEFFICIENCY", "CONVERT.FUEL.EFFICIENCY"], .convertFuelEfficiency),
        (
            ["CONVERT.INFORMATIONSTORAGE", "CONVERT.STORAGE"],
            .convertInformationStorage
        ),
        (["FORMAT.AREA"], .formatArea),
        (["FORMAT.LENGTH"], .formatLength),
        (["FORMAT.VOLUME"], .formatVolume),
        (["FORMAT.ANGLE"], .formatAngle),
        (["FORMAT.MASS"], .formatMass),
        (["FORMAT.PRESSURE"], .formatPressure),
        (["FORMAT.ACCELERATION"], .formatAcceleration),
        (["FORMAT.DURATION"], .formatDuration),
        (["FORMAT.FREQUENCY"], .formatFrequency),
        (["FORMAT.SPEED"], .formatSpeed),
        (["FORMAT.ENERGY"], .formatEnergy),
        (["FORMAT.POWER"], .formatPower),
        (["FORMAT.TEMPERATURE"], .formatTemperature),
        (["FORMAT.ILLUMINANCE"], .formatIlluminance),
        (["FORMAT.ELECTRICCHARGE", "FORMAT.ELECTRIC.CHARGE"], .formatElectricCharge),
        (["FORMAT.ELECTRICCURRENT", "FORMAT.ELECTRIC.CURRENT"], .formatElectricCurrent),
        (
            [
                "FORMAT.ELECTRICPOTENTIALDIFFERENCE", "FORMAT.ELECTRIC.POTENTIAL.DIFFERENCE", "FORMAT.VOLTAGE",
            ], .formatElectricPotentialDifference
        ),
        (["FORMAT.ELECTRICRESISTANCE", "FORMAT.ELECTRIC.RESISTANCE"], .formatElectricResistance),
        (["FORMAT.CONCENTRATIONMASS", "FORMAT.CONCENTRATION.MASS"], .formatConcentrationMass),
        (["FORMAT.DISPERSION"], .formatDispersion),
        (["FORMAT.FUELEFFICIENCY", "FORMAT.FUEL.EFFICIENCY"], .formatFuelEfficiency),
        (
            ["FORMAT.INFORMATIONSTORAGE", "FORMAT.STORAGE"],
            .formatInformationStorage
        ),
        (["DETECT.URL"], .detectURL),
        (["DETECT.EMAIL"], .detectEmail),
        (["DETECT.PHONE"], .detectPhone),
        (["DETECT.DATE"], .detectDate),
        (["DETECT.ADDRESS"], .detectAddress),
        (["SEARCH"], .search),
    ]

    private static let primitiveMap: [String: LogoPrimitive] = {
        var map: [String: LogoPrimitive] = [:]
        for (aliases, prim) in rawMappings {
            for alias in aliases {
                map[alias] = prim
            }
        }
        return map
    }()

    /// All public command aliases accepted by the LOGO parser.
    public static let keywordAliases: [String] = {
        rawMappings
            .flatMap { aliases, _ in aliases }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count { return lhs < rhs }
                return lhs.count > rhs.count
            }
    }()

    /// Resolves a string token (case-insensitive) to a strongly-typed LogoPrimitive enum.
    public static func from(_ token: String) -> LogoPrimitive? {
        primitiveMap[token.uppercased()]
    }
}

extension LogoPrimitive {
    /// Single source of truth for parser-facing primitive metadata.
    internal static let statementCommands: Set<Self> = [
        .make, .name, .type, .show, .delete, .backspace, .deleteLine, .top, .bottom, .lineStart, .lineEnd,
        .appendText, .prependText, .changeText, .joinLine, .splitLine, .indentLines, .outdentLines, .move,
        .mark, .cut, .uncut, .justify, .goto, .box, .drawBox, .inset, .line, .vline, .table,
        .newline, .penDown, .penUp, .forward, .back, .turnRight, .turnLeft, .setHeading, .setline, .gotoline,
        .gotocol, .clearBuffer, .ifCondition, .ifElseCondition, .output, .run, .repeatLoop, .forLoop,
        .dotimesLoop, .whileLoop, .doWhileLoop, .untilLoop, .doUntilLoop, .caseSwitch, .condSwitch,
        .testCondition, .assertCondition, .local, .pons, .pops, .povas, .ifTrue, .ifFalse, .stop, .catchTag,
        .throwTag, .wait, .bye, .ignore, .foreach, .to, .exec, .search, .sort, .fill, .end, .mdsetItem,
        .setFirst, .setBFL, .pprop, .remprop, .define, .erase, .erps, .erns, .erall,
    ]

    internal static let expressionPrimitives: Set<Self> = Set(allCases).subtracting(statementCommands).subtracting([
        .setHeading, .rshift, .readWord, .readChar,
    ])
    internal static let variadicPrimitives: Set<Self> = [
        .word, .list, .sentence, .sum, .product, .min, .max, .andLogic, .orLogic, .date, .time, .datetime,
        .dateformat, .dateadd, .datediff, .formatNumber, .formatList, .formatRelativeTime, .formatBytes,
        .convertArea, .convertLength, .convertVolume, .convertAngle, .convertMass, .convertPressure,
        .convertAcceleration, .convertDuration, .convertFrequency, .convertSpeed, .convertEnergy,
        .convertPower, .convertTemperature, .convertIlluminance, .convertElectricCharge,
        .convertElectricCurrent, .convertElectricPotentialDifference, .convertElectricResistance,
        .convertConcentrationMass, .convertDispersion, .convertFuelEfficiency, .convertInformationStorage,
        .formatArea, .formatLength, .formatVolume, .formatAngle, .formatMass, .formatPressure,
        .formatAcceleration, .formatDuration, .formatFrequency, .formatSpeed, .formatEnergy,
        .formatPower, .formatTemperature, .formatIlluminance, .formatElectricCharge,
        .formatElectricCurrent, .formatElectricPotentialDifference, .formatElectricResistance,
        .formatConcentrationMass, .formatDispersion, .formatFuelEfficiency, .formatInformationStorage,
        .detectURL, .detectEmail, .detectPhone, .detectDate, .detectAddress,
    ]
}
