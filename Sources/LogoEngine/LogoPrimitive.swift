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
    case line
    case hr
    case vline
    case vhr
    case table
    case diagram
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
    case foreverLoop
    case forLoop
    case dotimesLoop
    case whileLoop
    case doWhileLoop
    case untilLoop
    case doUntilLoop
    case caseSwitch
    case condSwitch
    case testCondition
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
    case parse
    case runparse

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
    case date
    case time
    case search
    case sort
    case fill
    case end

    private static let rawMappings: [([String], LogoPrimitive)] = [
        (["END"], .end),
        (["FILL"], .fill),
        (["SORT"], .sort),
        (["MAKE", "VAR"], .make),
        (["NAME"], .name),
        (["THING"], .thing),
        (["TYPE", "PRINT", "INSERT"], .type),
        (["MSG", "MESSAGE", "SHOW"], .show),
        (["DEL", "DELETE"], .delete),
        (["BS", "BACKSPACE"], .backspace),
        (["DELETELINE", "DELLINE", "KILLLINE", "DL"], .deleteLine),
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
        (["LINE", "HR"], .line),
        (["VLINE", "VR", "VHR"], .vline),
        (["TABLE"], .table),
        (["DIAGRAM", "SNIPPET"], .diagram),
        (["NEWLINE", "NL", "ENTER"], .newline),
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
        (["OUTPUT", "OP"], .output),
        (["REPEAT"], .repeatLoop),
        (["FOREVER"], .foreverLoop),
        (["FOR"], .forLoop),
        (["DOTIMES"], .dotimesLoop),
        (["WHILE"], .whileLoop),
        (["DO.WHILE"], .doWhileLoop),
        (["UNTIL"], .untilLoop),
        (["DO.UNTIL"], .doUntilLoop),
        (["CASE"], .caseSwitch),
        (["COND"], .condSwitch),
        (["TEST"], .testCondition),
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
        (["MAP.SE"], .mapSe),
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
        (["CLEARBUFFER", "ERASEBUFFER"], .clearBuffer),
        (["GETLINE"], .getline),
        (["SETLINE"], .setline),
        (["GOTOLINE", "SETROW"], .gotoline),
        (["GOTOCOL", "SETCOL"], .gotocol),
        (["ROW", "LINE.NO"], .row),
        (["COL", "COL.NO"], .col),
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
        (["PARSE"], .parse),
        (["RUNPARSE"], .runparse),

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
        (["POWER"], .power),
        (["REMAINDER"], .remainder),
        (["MODULO"], .modulo),
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
        (["BITAND"], .bitAnd),
        (["BITOR"], .bitOr),
        (["BITXOR"], .bitXor),
        (["BITNOT"], .bitNot),
        (["ASHIFT"], .ashift),
        (["LSHIFT"], .lshift),
        (["DATE"], .date),
        (["TIME"], .time),
        (["SEARCH"], .search)
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
