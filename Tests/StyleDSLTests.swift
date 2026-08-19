import Testing
@testable import Drawing
@testable import LogoEngine
@testable import Editor

struct StyleDSLTests {
    @Test
    func testBoxStyleDSLParser() {
        #expect(StyleDSL.parseBoxStyle("-")?.border == .single)
        #expect(StyleDSL.parseBoxStyle("-")?.rounded == false)
        #expect(StyleDSL.parseBoxStyle("-)")?.border == .single)
        #expect(StyleDSL.parseBoxStyle("-)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("+")?.border == .heavy)
        #expect(StyleDSL.parseBoxStyle("+)")?.border == .heavy)
        #expect(StyleDSL.parseBoxStyle("+)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("=")?.border == .double)
        #expect(StyleDSL.parseBoxStyle("=)")?.border == .double)
        #expect(StyleDSL.parseBoxStyle("=)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("a")?.border == .ascii)
        #expect(StyleDSL.parseBoxStyle("A)")?.border == .ascii)
        #expect(StyleDSL.parseBoxStyle("A)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("--")?.border == .doubleDash)
        #expect(StyleDSL.parseBoxStyle("--)")?.border == .doubleDash)
        #expect(StyleDSL.parseBoxStyle("--)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("++")?.border == .heavyDoubleDash)
        #expect(StyleDSL.parseBoxStyle("++)")?.border == .heavyDoubleDash)
        #expect(StyleDSL.parseBoxStyle("++)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("---")?.border == .tripleDash)
        #expect(StyleDSL.parseBoxStyle("---)")?.border == .tripleDash)
        #expect(StyleDSL.parseBoxStyle("---)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("+++")?.border == .heavyTripleDash)
        #expect(StyleDSL.parseBoxStyle("+++)")?.border == .heavyTripleDash)
        #expect(StyleDSL.parseBoxStyle("+++)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("----")?.border == .quadrupleDash)
        #expect(StyleDSL.parseBoxStyle("----)")?.border == .quadrupleDash)
        #expect(StyleDSL.parseBoxStyle("----)")?.rounded == true)

        #expect(StyleDSL.parseBoxStyle("++++")?.border == .heavyQuadrupleDash)
        #expect(StyleDSL.parseBoxStyle("++++)")?.border == .heavyQuadrupleDash)
        #expect(StyleDSL.parseBoxStyle("++++)")?.rounded == true)

        // Invalid box DSLs
        #expect(StyleDSL.parseBoxStyle("") == nil)
        #expect(StyleDSL.parseBoxStyle("xyz") == nil)
        #expect(StyleDSL.parseBoxStyle("---x") == nil)
    }

    @Test
    func testLineStyleDSLParser() {
        let defaultLine = StyleDSL.parseLineStyle("-")
        #expect(defaultLine?.border == .single)
        #expect(defaultLine?.arrowMode == LineArrowMode.none)

        let rightArrow = StyleDSL.parseLineStyle("->")
        #expect(rightArrow?.border == .single)
        #expect(rightArrow?.arrowMode == .forward)
        #expect(rightArrow?.endArrowStyle == .ascii)

        let leftArrow = StyleDSL.parseLineStyle("<-")
        #expect(leftArrow?.border == .single)
        #expect(leftArrow?.arrowMode == .backward)
        #expect(leftArrow?.startArrowStyle == .ascii)

        let bothArrow = StyleDSL.parseLineStyle("<->")
        #expect(bothArrow?.border == .single)
        #expect(bothArrow?.arrowMode == .both)

        let stemmedHollow = StyleDSL.parseLineStyle("<~+|>")
        #expect(stemmedHollow?.border == .heavy)
        #expect(stemmedHollow?.arrowMode == .both)
        #expect(stemmedHollow?.startArrowStyle == .stemmed)
        #expect(stemmedHollow?.endArrowStyle == .hollow)

        let solidDoubleDash = StyleDSL.parseLineStyle("<<+++>>")
        #expect(solidDoubleDash?.border == .heavyTripleDash)
        #expect(solidDoubleDash?.arrowMode == .both)
        #expect(solidDoubleDash?.startArrowStyle == .solid)
        #expect(solidDoubleDash?.endArrowStyle == .solid)

        let smallArrows = StyleDSL.parseLineStyle("<.=.>")
        #expect(smallArrows?.border == .double)
        #expect(smallArrows?.arrowMode == .both)
        #expect(smallArrows?.startArrowStyle == .small)
        #expect(smallArrows?.endArrowStyle == .small)

        // Invalid line DSLs
        #expect(StyleDSL.parseLineStyle("") == nil)
        #expect(StyleDSL.parseLineStyle(">>>") == nil)
        #expect(StyleDSL.parseLineStyle("invalid") == nil)
    }

    @Test
    func testAllBorderStylesRoundedCharacters() {
        let singleRounded = BoxStyle.style(for: .single, rounded: true)
        #expect(singleRounded.topLeft == "╭" && singleRounded.bottomRight == "╯")

        let heavyRounded = BoxStyle.style(for: .heavy, rounded: true)
        #expect(heavyRounded.topLeft == "╭" && heavyRounded.topChar == "━" && heavyRounded.bottomRight == "╯")

        let doubleRounded = BoxStyle.style(for: .double, rounded: true)
        #expect(doubleRounded.topLeft == "╭" && doubleRounded.topChar == "═" && doubleRounded.bottomRight == "╯")

        let asciiRounded = BoxStyle.style(for: .ascii, rounded: true)
        #expect(asciiRounded.topLeft == "/" && asciiRounded.topRight == "\\" && asciiRounded.bottomLeft == "\\" && asciiRounded.bottomRight == "/")

        let tripleDashRounded = BoxStyle.style(for: .tripleDash, rounded: true)
        #expect(tripleDashRounded.topLeft == "╭" && tripleDashRounded.topChar == "┄" && tripleDashRounded.bottomRight == "╯")

        let heavyTripleDashRounded = BoxStyle.style(for: .heavyTripleDash, rounded: true)
        #expect(heavyTripleDashRounded.topLeft == "╭" && heavyTripleDashRounded.topChar == "┅" && heavyTripleDashRounded.bottomRight == "╯")

        let doubleDashRounded = BoxStyle.style(for: .doubleDash, rounded: true)
        #expect(doubleDashRounded.topLeft == "╭" && doubleDashRounded.topChar == "╌" && doubleDashRounded.bottomRight == "╯")

        let heavyDoubleDashRounded = BoxStyle.style(for: .heavyDoubleDash, rounded: true)
        #expect(heavyDoubleDashRounded.topLeft == "╭" && heavyDoubleDashRounded.topChar == "╍" && heavyDoubleDashRounded.bottomRight == "╯")

        let quadDashRounded = BoxStyle.style(for: .quadrupleDash, rounded: true)
        #expect(quadDashRounded.topLeft == "╭" && quadDashRounded.topChar == "┈" && quadDashRounded.bottomRight == "╯")

        let heavyQuadDashRounded = BoxStyle.style(for: .heavyQuadrupleDash, rounded: true)
        #expect(heavyQuadDashRounded.topLeft == "╭" && heavyQuadDashRounded.topChar == "┉" && heavyQuadDashRounded.bottomRight == "╯")
    }

    @Test
    func testLogoExecutionWithStyleDSL() {
        let singleBox = LogoExecutionService.render(script: "BOX 6 3 -)")
        #expect(singleBox[0] == "╭────╮")
        #expect(singleBox[1] == "│    │")
        #expect(singleBox[2] == "╰────╯")

        let heavyBox = LogoExecutionService.render(script: "BOX 6 3 +)")
        #expect(heavyBox[0] == "╭━━━━╮")
        #expect(heavyBox[1] == "┃    ┃")
        #expect(heavyBox[2] == "╰━━━━╯")

        let doubleBox = LogoExecutionService.render(script: "BOX 6 3 =)")
        #expect(doubleBox[0] == "╭════╮")
        #expect(doubleBox[1] == "║    ║")
        #expect(doubleBox[2] == "╰════╯")

        let asciiRoundBox = LogoExecutionService.render(script: "BOX 6 3 a)")
        #expect(asciiRoundBox[0] == "/----\\")
        #expect(asciiRoundBox[1] == "|    |")
        #expect(asciiRoundBox[2] == "\\----/")

        let tripleDashRoundBox = LogoExecutionService.render(script: "BOX 6 3 ---)")
        #expect(tripleDashRoundBox[0] == "╭┄┄┄┄╮")
        #expect(tripleDashRoundBox[1] == "┆    ┆")
        #expect(tripleDashRoundBox[2] == "╰┄┄┄┄╯")

        let lineRendered = LogoExecutionService.render(script: "LINE 5 ->")
        #expect(lineRendered[0] == "────>")

        let solidLine = LogoExecutionService.render(script: "LINE 5 <<+++>>")
        #expect(solidLine[0] == "◀┅┅┅▶")

        let vlineRendered = LogoExecutionService.render(script: "VLINE 4 ->")
        #expect(vlineRendered == ["│", "│", "│", "v"])

        let solidVline = LogoExecutionService.render(script: "VLINE 4 <<=>>")
        #expect(solidVline == ["▲", "║", "║", "▼"])

        let tableRound = LogoExecutionService.render(script: "TABLE 1 1 4 =)")
        #expect(tableRound[0] == "╭════╮")
        #expect(tableRound[1] == "║    ║")
        #expect(tableRound[2] == "╰════╯")
    }
}
