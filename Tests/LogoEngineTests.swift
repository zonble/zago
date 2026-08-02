import Foundation
import Testing
import TextMetrics

@testable import Editor
@testable import LogoEngine
@testable import TextTransform

@Test func testSection81ControlStructures() throws {
    let logoEngine = LogoEngine()

    let ed1 = Editor()
    logoEngine.delegate = ed1
    logoEngine.execute("MAKE \"x 1 REPEAT 3 [ MAKE \"x :x + 1 ] TYPE :x")
    #expect(ed1.buffer.lines[0] == "4")
}

@Test func testSection4ArithmeticPrimitives() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SUM 10 20")
    #expect(logoEngine.lastResult == "30")

    logoEngine.execute("SUM [1 2 3 4 5]")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("SUM {1 2 3 4 5}")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("(SUM 1 2 3 4 5)")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("(SUM [1 2] 3 [4 5])")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("MIN 10 20")
    #expect(logoEngine.lastResult == "10")

    logoEngine.execute("MAX 10 20")
    #expect(logoEngine.lastResult == "20")

    logoEngine.execute("MIN [3 1 4 1 5]")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("MAX {3 1 4 1 5}")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("(MIN 3 1 4 1 5)")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("(MAX [3 1] 4 [1 5])")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("DIFFERENCE 20 5")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("PRODUCT 4 5")
    #expect(logoEngine.lastResult == "20")

    logoEngine.execute("QUOTIENT 20 4")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("QUOTIENT 4")
    #expect(logoEngine.lastResult == "0.25")

    logoEngine.execute("POWER 2 3")
    #expect(logoEngine.lastResult == "8")

    logoEngine.execute("REMAINDER 10 3")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("MODULO -10 3")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("MINUS 42")
    #expect(logoEngine.lastResult == "-42")

    logoEngine.execute("ABS -15")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("INT 3.7")
    #expect(logoEngine.lastResult == "3")

    logoEngine.execute("ROUND 3.7")
    #expect(logoEngine.lastResult == "4")

    // Infix Operators
    logoEngine.execute("10 + 5")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("20 - 4")
    #expect(logoEngine.lastResult == "16")

    logoEngine.execute("3 * 7")
    #expect(logoEngine.lastResult == "21")

    logoEngine.execute("15 / 3")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("2 ^ 4")
    #expect(logoEngine.lastResult == "16")

    logoEngine.execute("10 % 3")
    #expect(logoEngine.lastResult == "1")

    // Exponential & Logarithm
    logoEngine.execute("SQRT 16")
    #expect(logoEngine.lastResult == "4")

    logoEngine.execute("EXP 0")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("LOG10 100")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("LN 1")
    #expect(logoEngine.lastResult == "0")

    // Trigonometry (Degree & Radian)
    logoEngine.execute("SIN 90")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("COS 0")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("TAN 0")
    #expect(logoEngine.lastResult == "0")

    logoEngine.execute("ARCTAN 1")
    #expect(logoEngine.lastResult == "45")

    logoEngine.execute("RADSIN 0")
    #expect(logoEngine.lastResult == "0")

    logoEngine.execute("RADCOS 0")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("RADTAN 0")
    #expect(logoEngine.lastResult == "0")

    logoEngine.execute("RADARCTAN 0")
    #expect(logoEngine.lastResult == "0")

    // Sequences & Random & Formatting
    logoEngine.execute("ISEQ 1 5")
    #expect(logoEngine.lastResult == "[1 2 3 4 5]")

    logoEngine.execute("RANGE 1 5")
    #expect(logoEngine.lastResult == "[1 2 3 4 5]")

    logoEngine.execute("RANGE 5 1")
    #expect(logoEngine.lastResult == "[5 4 3 2 1]")

    logoEngine.execute("RANGE 1 10 2")
    #expect(logoEngine.lastResult == "[1 3 5 7 9]")

    logoEngine.execute("RSEQ 0 10 3")
    #expect(logoEngine.lastResult == "[0 5 10]")

    logoEngine.execute("RANDOM 10")
    #expect(logoEngine.lastResult != nil)

    logoEngine.execute("RERANDOM")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("FORM (1.0 / 3.0) 10 3")
    #expect(logoEngine.lastResult == "     0.333")

    // Bitwise Operations
    logoEngine.execute("BITAND 6 3")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("BITOR 6 3")
    #expect(logoEngine.lastResult == "7")

    logoEngine.execute("BITXOR 6 3")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("BITNOT 0")
    #expect(logoEngine.lastResult == "-1")

    logoEngine.execute("ASHIFT 1 3")
    #expect(logoEngine.lastResult == "8")

    logoEngine.execute("LSHIFT 1 3")
    #expect(logoEngine.lastResult == "8")
}

@Test func testSection5LogicalOperations() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("TRUE")
    #expect(logoEngine.lastResult == "true")

    logoEngine.execute("FALSE")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("AND TRUE FALSE")
    #expect(logoEngine.lastResult == "false")
}

@Test func testLogoIfAndIfElseConditionals() throws {
    let logoEngine = LogoEngine()

    let ifEditor1 = Editor()
    logoEngine.delegate = ifEditor1
    logoEngine.execute("MAKE \"i\" 10 IF :i > 5 [ TYPE \"GREATER\" ]")
    #expect(ifEditor1.buffer.lines[0] == "GREATER")

    let ifEditor2 = Editor()
    logoEngine.delegate = ifEditor2
    logoEngine.execute("MAKE \"i\" 2 IF :i > 5 [ TYPE \"GREATER\" ]")
    #expect(ifEditor2.buffer.lines[0] == "")

    let ifElseEditor1 = Editor()
    logoEngine.delegate = ifElseEditor1
    logoEngine.execute("MAKE \"i\" 10 IFELSE :i > 5 [ TYPE \"YES\" ] [ TYPE \"NO\" ]")
    #expect(ifElseEditor1.buffer.lines[0] == "YES")

    let ifElseEditor2 = Editor()
    logoEngine.delegate = ifElseEditor2
    logoEngine.execute("MAKE \"i\" 2 IFELSE :i > 5 [ TYPE \"YES\" ] [ TYPE \"NO\" ]")
    #expect(ifElseEditor2.buffer.lines[0] == "NO")

    let loopEditor = Editor()
    logoEngine.delegate = loopEditor
    logoEngine.execute("MAKE \"i\" 1 REPEAT 3 [ IFELSE :i == 2 [ TYPE \"TWO\" ] [ TYPE :i ] MAKE \"i\" ( :i + 1 ) ]")
    #expect(loopEditor.buffer.lines[0] == "1TWO3")
}

@Test func testLogoFloatingPointArithmetic() throws {
    let logoEngine = LogoEngine()

    let ed1 = Editor()
    logoEngine.delegate = ed1
    logoEngine.execute("TYPE ( 3.5 * 10 )")
    #expect(ed1.buffer.lines[0] == "35")

    let ed2 = Editor()
    logoEngine.delegate = ed2
    logoEngine.execute("TYPE ( 3.5 + 2.3 )")
    #expect(ed2.buffer.lines[0] == "5.8")

    let ed3 = Editor()
    logoEngine.delegate = ed3
    logoEngine.execute("MAKE \"x\" 3.5 TYPE ( :x * 2 )")
    #expect(ed3.buffer.lines[0] == "7")

    let ed4 = Editor()
    logoEngine.delegate = ed4
    logoEngine.execute("IF 3.5 > 2.0 [ TYPE \"YES\" ]")
    #expect(ed4.buffer.lines[0] == "YES")

    let ed5 = Editor()
    logoEngine.delegate = ed5
    logoEngine.execute("SHOW MINUS 9 5")
    #expect(ed5.statusMessage == "4")

    let ed6 = Editor()
    logoEngine.delegate = ed6
    logoEngine.execute("SHOW MINUS 9")
    #expect(ed6.statusMessage == "-9")

    let ed7 = Editor()
    logoEngine.delegate = ed7
    logoEngine.execute("TYPE MINUS 9 5")
    #expect(ed7.buffer.lines[0] == "4")

    let ed8 = Editor()
    logoEngine.delegate = ed8
    logoEngine.execute("SHOW ARCTAN 1")
    #expect(ed8.statusMessage == "45")

    let ed9 = Editor()
    logoEngine.delegate = ed9
    logoEngine.execute("SHOW (ARCTAN 0 1)")
    #expect(ed9.statusMessage == "90")

    let ed10 = Editor()
    logoEngine.delegate = ed10
    logoEngine.execute("SHOW (RADARCTAN 0 1)")
    #expect(ed10.statusMessage == "1.5707963267948966")
}

@Test func testLogoDataStructurePrimitives() throws {
    let logoEngine = LogoEngine()

    let ed1 = Editor()
    logoEngine.delegate = ed1
    logoEngine.execute("TYPE WORD \"hello\" \"world\" TYPE \" \" TYPE LIST 1 2 TYPE \" \" TYPE SE [1 2] [3 4]")
    #expect(ed1.buffer.lines[0] == "helloworld [1 2] [1 2 3 4]")

    let ed2 = Editor()
    logoEngine.delegate = ed2
    logoEngine.execute("TYPE FPUT 0 [1 2] TYPE \" \" TYPE LPUT 3 [1 2] TYPE \" \" TYPE REVERSE \"abc\"")
    #expect(ed2.buffer.lines[0] == "[0 1 2] [1 2 3] cba")

    let ed3 = Editor()
    logoEngine.delegate = ed3
    logoEngine.execute(
        "TYPE FIRST [10 20] TYPE \" \" TYPE LAST \"abc\" TYPE \" \" TYPE BF [10 20 30] TYPE \" \" TYPE BL \"abc\" TYPE \" \" TYPE ITEM 2 [10 20 30]"
    )
    #expect(ed3.buffer.lines[0] == "10 c [20 30] ab 20")

    let ed4 = Editor()
    logoEngine.delegate = ed4
    logoEngine.execute("TYPE REMDUP \"banana\" TYPE \" \" TYPE REMDUP [1 2 2 3 1]")
    #expect(ed4.buffer.lines[0] == "ban [1 2 3]")

    let ed5 = Editor()
    logoEngine.delegate = ed5
    logoEngine.execute(
        "MAKE \"s\" [2 1] PUSH \"s\" 3 TYPE :s TYPE \" pop: \" TYPE POP \"s\" TYPE \" remaining: \" TYPE :s")
    #expect(ed5.buffer.lines[0] == "[3 2 1] pop: 3 remaining: [2 1]")

    let ed6 = Editor()
    logoEngine.delegate = ed6
    logoEngine.execute(
        "MAKE \"q\" [1 2] QUEUE \"q\" 3 TYPE :q TYPE \" deq: \" TYPE DEQUEUE \"q\" TYPE \" remaining: \" TYPE :q")
    #expect(ed6.buffer.lines[0] == "[1 2 3] deq: 1 remaining: [2 3]")

    let ed7 = Editor()
    logoEngine.delegate = ed7
    logoEngine.execute(
        "TYPE LIST? [1 2] TYPE \" \" TYPE NUMBER? 123 TYPE \" \" TYPE EMPTY? \"\" TYPE \" \" TYPE MEMBER? \"b\" [a b c]"
    )
    #expect(ed7.buffer.lines[0] == "true true true true")

    let ed8 = Editor()
    logoEngine.delegate = ed8
    logoEngine.execute(
        "TYPE COUNT [1 2 3] TYPE \" \" TYPE ASCII \"a\" TYPE \" \" TYPE CHAR 97 TYPE \" \" TYPE UPPERCASE \"abc\" TYPE \" \" TYPE LOWERCASE \"XYZ\""
    )
    #expect(ed8.buffer.lines[0] == "3 97 a ABC xyz")
}

@Test func testLogoPredicates() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("WORDP \"a\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("WORDP 123")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("WORD? [1 2]")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("LISTP [1 2 3]")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("LIST? \"abc\"")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("ARRAYP {1 2}")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("ARRAY? [1 2]")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("NUMBERP 123.45")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("NUMBER? \"abc\"")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("EMPTYP \"\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("EMPTY? []")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("EMPTY? \"a\"")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("EQUALP [1 2] [1 2]")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("EQUAL? 12 12.0")
    #expect(logoEngine.lastResult == "true")

    logoEngine.execute("NOTEQUALP \"a\" \"b\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("NOTEQUAL? 1 1")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("BEFOREP \"apple\" \"banana\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("BEFORE? \"banana\" \"apple\"")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute(".EQ \"test\" \"test\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute(".EQ 12 12.0")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("SUBSTRINGP \"cat\" \"caterpillar\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("SUBSTRING? \"dog\" \"caterpillar\"")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("MEMBERP \"b\" [a b c]")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("MEMBER? \"x\" [a b c]")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("MEMBER \"a\" \"banana\"")
    #expect(logoEngine.lastResult == "anana")

    logoEngine.execute("MEMBER 2 [1 2 3 4]")
    #expect(logoEngine.lastResult == "[2 3 4]")

    logoEngine.execute("PARSE \"1+2\"")
    #expect(logoEngine.lastResult == "[1 + 2]")

    logoEngine.execute("PRIMITIVE? \"SUM")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("PRIMITIVEP \"MISSINGPROC")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("TO FOO OUTPUT 1 END")
    logoEngine.execute("DEFINED? \"FOO")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("DEFINEDP \"SUM")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("PROCEDURE? \"SUM")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("PROCEDUREP \"FOO")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("PROCEDURE? \"MISSINGPROC")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("MAKE \"x 10")
    logoEngine.execute("NAME? \"x")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("NAMEP \"y")
    #expect(logoEngine.lastResult == "false")
}

@Test func testLogoEngineTableCommands() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("TABLE")
    #expect(editor.buffer.lines.count >= 3)
    #expect(editor.buffer.lines[0].contains("┌"))

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    logoEngine2.execute("TABLE 4 5 12")
    #expect(editor2.buffer.lines.count >= 4)

    let editor3 = Editor()
    let logoEngine3 = LogoEngine(delegate: editor3)
    logoEngine3.execute("TABLE BORDER double-round")
    #expect(logoEngine3.hasSetStatusMessage)

    logoEngine3.execute("TABLE NEXTSTYLE")
    #expect(logoEngine3.hasSetStatusMessage)
}

@Test func testLogoEngineTemplatePrimitives() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("UPPERCASE \"hello")
    #expect(logoEngine.lastResult == "HELLO")

    logoEngine.execute("LOWERCASE \"WORLD")
    #expect(logoEngine.lastResult == "world")

    logoEngine.execute("APPLY [?1 + ?2] [3 4]")
    #expect(logoEngine.lastResult == "7")

    logoEngine.execute("INVOKE [?1 * 2] 5")
    #expect(logoEngine.lastResult == "10")

    logoEngine.execute("MAP [? * 2] [1 2 3]")
    #expect(logoEngine.lastResult == "[2 4 6]")

    logoEngine.execute("MAPSE [SENTENCE ? ?] [a b]")
    #expect(logoEngine.lastResult == "[ a b ]")

    logoEngine.execute("FILTER [? > 2] [1 2 3 4 5]")
    #expect(logoEngine.lastResult == "[3 4 5]")

    logoEngine.execute("FIND [? > 3] [1 2 3 4 5]")
    #expect(logoEngine.lastResult == "4")

    logoEngine.execute("REDUCE [?1 + ?2] [1 2 3 4]")
    #expect(logoEngine.lastResult == "10")

    logoEngine.execute("CROSSMAP [WORD ?1 ?2] [[a b] [1 2]]")
    #expect(logoEngine.lastResult == "[a1 a2 b1 b2]")

    logoEngine.execute("SORT [3 1 4 1 5 9 2]")
    #expect(logoEngine.lastResult == "[1 1 2 3 4 5 9]")

    logoEngine.execute("SORT DESC [3 1 4 1 5]")
    #expect(logoEngine.lastResult == "[5 4 3 1 1]")
}

@Test func testLogoValueTypeCoercionsAndArrays() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("ARRAY 3")
    #expect(logoEngine.lastResult?.hasPrefix("{") == true)

    logoEngine.execute("SETITEM 1 {a b c} \"z")
    #expect(logoEngine.lastResult?.contains("z") == true)

    logoEngine.execute("ITEM 1 {x y z}")
    #expect(logoEngine.lastResult == "x")
}
