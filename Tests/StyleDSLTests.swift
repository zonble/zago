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

        let complexLine = StyleDSL.parseLineStyle("<~+|>")
        #expect(complexLine?.border == .heavy)
        #expect(complexLine?.arrowMode == .both)
        #expect(complexLine?.startArrowStyle == .stemmed)
        #expect(complexLine?.endArrowStyle == .hollow)

        let solidDoubleDash = StyleDSL.parseLineStyle("<<+++>>")
        #expect(solidDoubleDash?.border == .heavyTripleDash)
        #expect(solidDoubleDash?.arrowMode == .both)
        #expect(solidDoubleDash?.startArrowStyle == .solid)
        #expect(solidDoubleDash?.endArrowStyle == .solid)
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

        let tripleDashRoundBox = LogoExecutionService.render(script: "BOX 6 3 ---)")
        #expect(tripleDashRoundBox[0] == "╭┄┄┄┄╮")
        #expect(tripleDashRoundBox[1] == "┆    ┆")
        #expect(tripleDashRoundBox[2] == "╰┄┄┄┄╯")

        let lineRendered = LogoExecutionService.render(script: "LINE 5 ->")
        #expect(lineRendered[0] == "────>")

        let solidLine = LogoExecutionService.render(script: "LINE 5 <<+++>>")
        #expect(solidLine[0] == "◀┅┅┅▶")
    }
}
