import ANSIStyle
import Config
import Foundation
import TextMetrics

struct SymbolItem: Sendable {
    let symbol: String
    let descriptionKey: String

    init(symbol: String, descriptionKey: String) {
        self.symbol = symbol
        self.descriptionKey = descriptionKey
    }
}

enum SymbolCategoryLayout: Sendable, Equatable {
    case grid(columns: Int)
    case list
}

struct SymbolCategory: Sendable {
    let nameKey: String
    let layout: SymbolCategoryLayout
    let items: [SymbolItem]

    init(nameKey: String, layout: SymbolCategoryLayout, items: [SymbolItem]) {
        self.nameKey = nameKey
        self.layout = layout
        self.items = items
    }
}

enum SymbolCategories {
    static let categories: [SymbolCategory] = [
        SymbolCategory(
            nameKey: "symbol_category.arrows",
            layout: .grid(columns: 4),
            items: [
                // 1. Cycles & Open Loops (循環與環狀)
                SymbolItem(symbol: "↺", descriptionKey: "symbol.arrow.loop_ccw"),
                SymbolItem(symbol: "↻", descriptionKey: "symbol.arrow.loop_cw"),
                SymbolItem(symbol: "⟲", descriptionKey: "symbol.arrow.open_circle_ccw"),
                SymbolItem(symbol: "⟳", descriptionKey: "symbol.arrow.open_circle_cw"),

                // 2. Closed Circle & Top Arcs (圓弧與封閉圓)
                SymbolItem(symbol: "⥀", descriptionKey: "symbol.arrow.closed_circle_ccw"),
                SymbolItem(symbol: "⥁", descriptionKey: "symbol.arrow.closed_circle_cw"),
                SymbolItem(symbol: "↷", descriptionKey: "symbol.arrow.top_arc_cw"),
                SymbolItem(symbol: "↶", descriptionKey: "symbol.arrow.top_arc_ccw"),

                // 3. Curved Tips (弧形轉角)
                SymbolItem(symbol: "⤾", descriptionKey: "symbol.arrow.curve_up_left"),
                SymbolItem(symbol: "⤿", descriptionKey: "symbol.arrow.curve_up_right"),
                SymbolItem(symbol: "⤼", descriptionKey: "symbol.arrow.curve_down_left"),
                SymbolItem(symbol: "⤽", descriptionKey: "symbol.arrow.curve_down_right"),

                // 4. Semicircle Segments (圓弧分段)
                SymbolItem(symbol: "⮌", descriptionKey: "symbol.arrow.arc_top_left"),
                SymbolItem(symbol: "⮎", descriptionKey: "symbol.arrow.arc_top_right"),
                SymbolItem(symbol: "⮍", descriptionKey: "symbol.arrow.arc_bottom_left"),
                SymbolItem(symbol: "⮏", descriptionKey: "symbol.arrow.arc_bottom_right"),

                // 5. Corner Arrows (直角轉彎)
                SymbolItem(symbol: "↳", descriptionKey: "symbol.arrow.corner_down_right"),
                SymbolItem(symbol: "↲", descriptionKey: "symbol.arrow.corner_down_left"),
                SymbolItem(symbol: "↱", descriptionKey: "symbol.arrow.corner_up_right"),
                SymbolItem(symbol: "↰", descriptionKey: "symbol.arrow.corner_up_left"),

                // 6. Turn & Hook (折角與鉤形)
                SymbolItem(symbol: "↴", descriptionKey: "symbol.arrow.corner_right_down"),
                SymbolItem(symbol: "↵", descriptionKey: "symbol.arrow.return_symbol"),
                SymbolItem(symbol: "↩", descriptionKey: "symbol.arrow.hook_left"),
                SymbolItem(symbol: "↪", descriptionKey: "symbol.arrow.hook_right"),

                // 7. Curve & Branch (弧形跳轉與分支)
                SymbolItem(symbol: "⤴", descriptionKey: "symbol.arrow.curve_up"),
                SymbolItem(symbol: "⤵", descriptionKey: "symbol.arrow.curve_down"),
                SymbolItem(symbol: "⤶", descriptionKey: "symbol.arrow.turn_down_left"),
                SymbolItem(symbol: "⤷", descriptionKey: "symbol.arrow.turn_down_right"),

                // 8. Curved Corners & Elbows (彎折弧角與尖折直角)
                SymbolItem(symbol: "⤹", descriptionKey: "symbol.arrow.curved_corner_left"),
                SymbolItem(symbol: "⤸", descriptionKey: "symbol.arrow.curved_corner_right"),
                SymbolItem(symbol: "⮠", descriptionKey: "symbol.arrow.bent_elbow_left"),
                SymbolItem(symbol: "⮡", descriptionKey: "symbol.arrow.bent_elbow_right"),

                // 9. Lightning & Waves (閃電與波浪)
                SymbolItem(symbol: "↯", descriptionKey: "symbol.arrow.lightning"),
                SymbolItem(symbol: "⇜", descriptionKey: "symbol.arrow.wave_left"),
                SymbolItem(symbol: "⇝", descriptionKey: "symbol.arrow.wave_right"),
                SymbolItem(symbol: "↭", descriptionKey: "symbol.arrow.wave_bidi"),

                // 10. Squiggle & Wave Tail (波浪尾翼與曲折)
                SymbolItem(symbol: "↜", descriptionKey: "symbol.arrow.wave_tail_left"),
                SymbolItem(symbol: "↝", descriptionKey: "symbol.arrow.wave_tail_right"),
                SymbolItem(symbol: "⤳", descriptionKey: "symbol.arrow.squiggle_right"),
                SymbolItem(symbol: "⟿", descriptionKey: "symbol.arrow.long_squiggle_right"),

                // 11. Long Arrows (長單線與長魚鉤)
                SymbolItem(symbol: "⟵", descriptionKey: "symbol.arrow.long_left"),
                SymbolItem(symbol: "⟶", descriptionKey: "symbol.arrow.long_right"),
                SymbolItem(symbol: "⟷", descriptionKey: "symbol.arrow.long_bidi"),
                SymbolItem(symbol: "⟽", descriptionKey: "symbol.arrow.long_harpoon_left"),

                // 12. Long Double Arrows (長雙線與長右魚鉤)
                SymbolItem(symbol: "⟸", descriptionKey: "symbol.arrow.long_double_left"),
                SymbolItem(symbol: "⟹", descriptionKey: "symbol.arrow.long_double_right"),
                SymbolItem(symbol: "⟺", descriptionKey: "symbol.arrow.long_double_bidi"),
                SymbolItem(symbol: "⟾", descriptionKey: "symbol.arrow.long_harpoon_right"),

                // 13. Negated & Crossed (禁止與劃線)
                SymbolItem(symbol: "↚", descriptionKey: "symbol.arrow.negated_left"),
                SymbolItem(symbol: "↛", descriptionKey: "symbol.arrow.negated_right"),
                SymbolItem(symbol: "↮", descriptionKey: "symbol.arrow.negated_bidi"),
                SymbolItem(symbol: "⤄", descriptionKey: "symbol.arrow.crossed_bidi"),

                // 14. Negated Double (雙線否定)
                SymbolItem(symbol: "⇍", descriptionKey: "symbol.arrow.negated_double_left"),
                SymbolItem(symbol: "⇏", descriptionKey: "symbol.arrow.negated_double_right"),
                SymbolItem(symbol: "⇎", descriptionKey: "symbol.arrow.negated_double_bidi"),
                SymbolItem(symbol: "⇸", descriptionKey: "symbol.arrow.stroke_right"),

                // 15. Bar Stroke & Double Slash (槓線與雙斜槓修飾)
                SymbolItem(symbol: "⇹", descriptionKey: "symbol.arrow.stroke_bidi"),
                SymbolItem(symbol: "⇺", descriptionKey: "symbol.arrow.double_stroke_left"),
                SymbolItem(symbol: "⇻", descriptionKey: "symbol.arrow.double_stroke_right"),
                SymbolItem(symbol: "⇼", descriptionKey: "symbol.arrow.double_stroke_bidi"),

                // 16. Stroke Tail & Diagonal Stroke (帶尾劃線與對角劃線)
                SymbolItem(symbol: "⇽", descriptionKey: "symbol.arrow.stroke_tail_left"),
                SymbolItem(symbol: "⇾", descriptionKey: "symbol.arrow.stroke_tail_right"),
                SymbolItem(symbol: "⇿", descriptionKey: "symbol.arrow.stroke_tail_bidi"),
                SymbolItem(symbol: "⤡", descriptionKey: "symbol.arrow.diagonal_stroke"),

                // 17. Triple Shaft Bus (三線總線)
                SymbolItem(symbol: "⇚", descriptionKey: "symbol.arrow.triple_left"),
                SymbolItem(symbol: "⇛", descriptionKey: "symbol.arrow.triple_right"),
                SymbolItem(symbol: "⤊", descriptionKey: "symbol.arrow.triple_up"),
                SymbolItem(symbol: "⤋", descriptionKey: "symbol.arrow.triple_down"),

                // 18. Barbed & Multi-head (帶橫槓與倒鉤)
                SymbolItem(symbol: "⤂", descriptionKey: "symbol.arrow.barb_left"),
                SymbolItem(symbol: "⤃", descriptionKey: "symbol.arrow.barb_right"),
                SymbolItem(symbol: "⤅", descriptionKey: "symbol.arrow.double_bar_right"),
                SymbolItem(symbol: "⇶", descriptionKey: "symbol.arrow.stacked_three_right"),

                // 19. Fish-tail & Feathered (魚尾與羽毛)
                SymbolItem(symbol: "⥅", descriptionKey: "symbol.arrow.fishtail_right"),
                SymbolItem(symbol: "⥆", descriptionKey: "symbol.arrow.fishtail_left"),
                SymbolItem(symbol: "⥇", descriptionKey: "symbol.arrow.fishtail_bidi"),
                SymbolItem(symbol: "⤖", descriptionKey: "symbol.arrow.feathered_right"),

                // 20. Stems, Barbs & Tail (折角柄、羽尾與帶尾端點)
                SymbolItem(symbol: "⤔", descriptionKey: "symbol.arrow.corner_down_stem"),
                SymbolItem(symbol: "⤕", descriptionKey: "symbol.arrow.corner_up_stem"),
                SymbolItem(symbol: "⤗", descriptionKey: "symbol.arrow.feathered_left"),
                SymbolItem(symbol: "⤝", descriptionKey: "symbol.arrow.arrow_tail_left"),

                // 21. White Block Arrows (空心立體箭頭)
                SymbolItem(symbol: "⇧", descriptionKey: "symbol.arrow.block_up"),
                SymbolItem(symbol: "⇩", descriptionKey: "symbol.arrow.block_down"),
                SymbolItem(symbol: "⇦", descriptionKey: "symbol.arrow.block_left"),
                SymbolItem(symbol: "⇨", descriptionKey: "symbol.arrow.block_right"),

                // 22. Block Bidi & Diagonal (立體雙向與斜向)
                SymbolItem(symbol: "⬄", descriptionKey: "symbol.arrow.block_bidi_horizontal"),
                SymbolItem(symbol: "⇳", descriptionKey: "symbol.arrow.block_bidi_vertical"),
                SymbolItem(symbol: "⬀", descriptionKey: "symbol.arrow.block_diag_up_right"),
                SymbolItem(symbol: "⬁", descriptionKey: "symbol.arrow.block_diag_up_left"),

                // 23. South Diagonals & Bent Black (南向對角與黑體直角)
                SymbolItem(symbol: "⬂", descriptionKey: "symbol.arrow.block_diag_down_right"),
                SymbolItem(symbol: "⬃", descriptionKey: "symbol.arrow.block_diag_down_left"),
                SymbolItem(symbol: "⬎", descriptionKey: "symbol.arrow.bent_black_down_right"),
                SymbolItem(symbol: "⬏", descriptionKey: "symbol.arrow.bent_black_up_right"),

                // 24. Bent Black & Caps Lock (黑體直角與大寫鎖定)
                SymbolItem(symbol: "⬐", descriptionKey: "symbol.arrow.bent_black_down_left"),
                SymbolItem(symbol: "⬑", descriptionKey: "symbol.arrow.bent_black_up_left"),
                SymbolItem(symbol: "⇪", descriptionKey: "symbol.arrow.caps_lock"),
                SymbolItem(symbol: "⇫", descriptionKey: "symbol.arrow.caps_lock_bar"),

                // 25. Diagonal Stemmed (斜向細線)
                SymbolItem(symbol: "↖", descriptionKey: "symbol.arrow.diag_up_left"),
                SymbolItem(symbol: "↗", descriptionKey: "symbol.arrow.diag_up_right"),
                SymbolItem(symbol: "↘", descriptionKey: "symbol.arrow.diag_down_right"),
                SymbolItem(symbol: "↙", descriptionKey: "symbol.arrow.diag_down_left"),

                // 26. Double Diagonal (斜向雙線)
                SymbolItem(symbol: "⇖", descriptionKey: "symbol.arrow.double_diag_up_left"),
                SymbolItem(symbol: "⇗", descriptionKey: "symbol.arrow.double_diag_up_right"),
                SymbolItem(symbol: "⇘", descriptionKey: "symbol.arrow.double_diag_down_right"),
                SymbolItem(symbol: "⇙", descriptionKey: "symbol.arrow.double_diag_down_left"),

                // 27. Diagonal Triangle (斜向三角)
                SymbolItem(symbol: "⬉", descriptionKey: "symbol.arrow.tri_diag_up_left"),
                SymbolItem(symbol: "⬈", descriptionKey: "symbol.arrow.tri_diag_up_right"),
                SymbolItem(symbol: "⬊", descriptionKey: "symbol.arrow.tri_diag_down_right"),
                SymbolItem(symbol: "⬋", descriptionKey: "symbol.arrow.tri_diag_down_left"),

                // 28. Crossing Diagonals (對角線交叉組)
                SymbolItem(symbol: "⤢", descriptionKey: "symbol.arrow.diagonal_double_ended"),
                SymbolItem(symbol: "⤪", descriptionKey: "symbol.arrow.diagonal_cross_1"),
                SymbolItem(symbol: "⤭", descriptionKey: "symbol.arrow.diagonal_cross_2"),
                SymbolItem(symbol: "⤮", descriptionKey: "symbol.arrow.diagonal_cross_3"),

                // 29. Maps-to (映射)
                SymbolItem(symbol: "↥", descriptionKey: "symbol.arrow.maps_up"),
                SymbolItem(symbol: "↧", descriptionKey: "symbol.arrow.maps_down"),
                SymbolItem(symbol: "↤", descriptionKey: "symbol.arrow.maps_left"),
                SymbolItem(symbol: "↦", descriptionKey: "symbol.arrow.maps_right"),

                // 30. Long Maps-to & From-bar (長映射與底座箭頭)
                SymbolItem(symbol: "⟻", descriptionKey: "symbol.arrow.long_maps_left"),
                SymbolItem(symbol: "⟼", descriptionKey: "symbol.arrow.long_maps_right"),
                SymbolItem(symbol: "⤉", descriptionKey: "symbol.arrow.from_bar_up"),
                SymbolItem(symbol: "⤈", descriptionKey: "symbol.arrow.from_bar_down"),

                // 31. Two-headed Surjection (雙頭滿射)
                SymbolItem(symbol: "↟", descriptionKey: "symbol.arrow.two_headed_up"),
                SymbolItem(symbol: "↡", descriptionKey: "symbol.arrow.two_headed_down"),
                SymbolItem(symbol: "↞", descriptionKey: "symbol.arrow.two_headed_left"),
                SymbolItem(symbol: "↠", descriptionKey: "symbol.arrow.two_headed_right"),

                // 32. Tailed Injection & Multimap (帶尾單射與棒棒糖)
                SymbolItem(symbol: "↢", descriptionKey: "symbol.arrow.tailed_left"),
                SymbolItem(symbol: "↣", descriptionKey: "symbol.arrow.tailed_right"),
                SymbolItem(symbol: "⊸", descriptionKey: "symbol.arrow.multimap"),
                SymbolItem(symbol: "⤇", descriptionKey: "symbol.arrow.double_bar_right_heavy"),

                // 33. Bar Tab Stop (邊界停駐端點)
                SymbolItem(symbol: "⇤", descriptionKey: "symbol.arrow.bar_left"),
                SymbolItem(symbol: "⇥", descriptionKey: "symbol.arrow.bar_right"),
                SymbolItem(symbol: "⤒", descriptionKey: "symbol.arrow.bar_up"),
                SymbolItem(symbol: "⤓", descriptionKey: "symbol.arrow.bar_down"),

                // 34. Double From-bar & Bar Shafts (雙線底座與橫中槓)
                SymbolItem(symbol: "⤆", descriptionKey: "symbol.arrow.double_from_bar_left"),
                SymbolItem(symbol: "⤏", descriptionKey: "symbol.arrow.arrow_crossbar_left"),
                SymbolItem(symbol: "⤎", descriptionKey: "symbol.arrow.arrow_crossbar_right"),
                SymbolItem(symbol: "⤑", descriptionKey: "symbol.arrow.arrow_wave_shaft_right"),

                // 35. Wave Shaft & Loops (波浪柄與迴路組)
                SymbolItem(symbol: "⤐", descriptionKey: "symbol.arrow.arrow_wave_shaft_left"),
                SymbolItem(symbol: "⤲", descriptionKey: "symbol.arrow.loop_down"),
                SymbolItem(symbol: "⤱", descriptionKey: "symbol.arrow.loop_up"),
                SymbolItem(symbol: "⤰", descriptionKey: "symbol.arrow.loop_left"),

                // 36. Loops & Ribbon Turns (右迴路與緞帶拐角)
                SymbolItem(symbol: "⤯", descriptionKey: "symbol.arrow.loop_right"),
                SymbolItem(symbol: "⮢", descriptionKey: "symbol.arrow.ribbon_turn_left"),
                SymbolItem(symbol: "⮣", descriptionKey: "symbol.arrow.ribbon_turn_right"),
                SymbolItem(symbol: "⮤", descriptionKey: "symbol.arrow.ribbon_turn_up"),

                // 37. Paired Opposite (對向配對箭頭)
                SymbolItem(symbol: "⇆", descriptionKey: "symbol.arrow.pair_left_right"),
                SymbolItem(symbol: "⇄", descriptionKey: "symbol.arrow.pair_right_left"),
                SymbolItem(symbol: "⇅", descriptionKey: "symbol.arrow.pair_up_down"),
                SymbolItem(symbol: "⇵", descriptionKey: "symbol.arrow.pair_down_up"),

                // 38. Paired Parallel (並行配對箭頭)
                SymbolItem(symbol: "⇉", descriptionKey: "symbol.arrow.paired_right"),
                SymbolItem(symbol: "⇇", descriptionKey: "symbol.arrow.paired_left"),
                SymbolItem(symbol: "⇈", descriptionKey: "symbol.arrow.paired_up"),
                SymbolItem(symbol: "⇊", descriptionKey: "symbol.arrow.paired_down"),

                // 39. Equilibrium & Harpoon Pairs (化學平衡與魚鉤對)
                SymbolItem(symbol: "⇋", descriptionKey: "symbol.arrow.equilibrium_left_right"),
                SymbolItem(symbol: "⇌", descriptionKey: "symbol.arrow.equilibrium_right_left"),
                SymbolItem(symbol: "⥮", descriptionKey: "symbol.arrow.harpoon_pair_up_down"),
                SymbolItem(symbol: "⥯", descriptionKey: "symbol.arrow.harpoon_pair_down_up"),

                // 40. Paired Double Harpoons (雙重並行魚鉤)
                SymbolItem(symbol: "⥢", descriptionKey: "symbol.arrow.paired_harpoon_left"),
                SymbolItem(symbol: "⥤", descriptionKey: "symbol.arrow.paired_harpoon_right"),
                SymbolItem(symbol: "⥦", descriptionKey: "symbol.arrow.paired_harpoon_up"),
                SymbolItem(symbol: "⥧", descriptionKey: "symbol.arrow.paired_harpoon_down"),

                // 41. Harpoons with Barb (單側魚鉤倒鉤)
                SymbolItem(symbol: "⥒", descriptionKey: "symbol.arrow.harpoon_barb_up_left"),
                SymbolItem(symbol: "⥓", descriptionKey: "symbol.arrow.harpoon_barb_down_left"),
                SymbolItem(symbol: "⥔", descriptionKey: "symbol.arrow.harpoon_barb_up_right"),
                SymbolItem(symbol: "⥕", descriptionKey: "symbol.arrow.harpoon_barb_down_right"),

                // 42. Vertical Harpoons (垂直單側魚鉤)
                SymbolItem(symbol: "⥖", descriptionKey: "symbol.arrow.harpoon_barb_left_up"),
                SymbolItem(symbol: "⥗", descriptionKey: "symbol.arrow.harpoon_barb_right_up"),
                SymbolItem(symbol: "⥘", descriptionKey: "symbol.arrow.harpoon_barb_left_down"),
                SymbolItem(symbol: "⥙", descriptionKey: "symbol.arrow.harpoon_barb_right_down"),

                // 43. Stacked Harpoon Pairs (雙重堆疊魚鉤)
                SymbolItem(symbol: "⥚", descriptionKey: "symbol.arrow.harpoon_stacked_left_1"),
                SymbolItem(symbol: "⥛", descriptionKey: "symbol.arrow.harpoon_stacked_left_2"),
                SymbolItem(symbol: "⥞", descriptionKey: "symbol.arrow.harpoon_stacked_right_1"),
                SymbolItem(symbol: "⥟", descriptionKey: "symbol.arrow.harpoon_stacked_right_2"),

                // 44. Long Bar & Bidi Harpoons (長槓魚鉤與雙向魚鉤)
                SymbolItem(symbol: "⥨", descriptionKey: "symbol.arrow.harpoon_long_bar_left"),
                SymbolItem(symbol: "⥩", descriptionKey: "symbol.arrow.harpoon_long_bar_right"),
                SymbolItem(symbol: "⥪", descriptionKey: "symbol.arrow.harpoon_bidi_barb_up"),
                SymbolItem(symbol: "⥫", descriptionKey: "symbol.arrow.harpoon_bidi_barb_down"),

                // 45. Dingbat Sans & Circled (粗體與帶圈)
                SymbolItem(symbol: "➔", descriptionKey: "symbol.arrow.dingbat_heavy_right"),
                SymbolItem(symbol: "➜", descriptionKey: "symbol.arrow.dingbat_triangle_right"),
                SymbolItem(symbol: "➲", descriptionKey: "symbol.arrow.dingbat_circled_right"),
                SymbolItem(symbol: "➾", descriptionKey: "symbol.arrow.dingbat_open_double"),

                // 46. Dart Arrows (飛鏢與虛線柄)
                SymbolItem(symbol: "➝", descriptionKey: "symbol.arrow.dingbat_dart_small"),
                SymbolItem(symbol: "➞", descriptionKey: "symbol.arrow.dingbat_heavy_dart"),
                SymbolItem(symbol: "➟", descriptionKey: "symbol.arrow.dingbat_dashed_dart"),
                SymbolItem(symbol: "➠", descriptionKey: "symbol.arrow.dingbat_heavy_dashed"),

                // 47. Dingbat Notched & 3D (凹槽與立體陰影)
                SymbolItem(symbol: "⮂", descriptionKey: "symbol.arrow.dingbat_black_triangle_left"),
                SymbolItem(symbol: "➢", descriptionKey: "symbol.arrow.dingbat_notched"),
                SymbolItem(symbol: "➣", descriptionKey: "symbol.arrow.dingbat_notched_shadowed"),
                SymbolItem(symbol: "➤", descriptionKey: "symbol.arrow.dingbat_curved_stem"),

                // 48. Heavy Hooks & Wedges (粗體鉤與粗楔形)
                SymbolItem(symbol: "➥", descriptionKey: "symbol.arrow.dingbat_heavy_bottom_hook"),
                SymbolItem(symbol: "➦", descriptionKey: "symbol.arrow.dingbat_heavy_top_hook"),
                SymbolItem(symbol: "➧", descriptionKey: "symbol.arrow.dingbat_heavy_wedge"),
                SymbolItem(symbol: "➨", descriptionKey: "symbol.arrow.dingbat_heavy_wedge_large"),

                // 49. Shaded & Outlined Dingbats (開口與陰影)
                SymbolItem(symbol: "➪", descriptionKey: "symbol.arrow.dingbat_open_white"),
                SymbolItem(symbol: "➫", descriptionKey: "symbol.arrow.dingbat_shaded_white"),
                SymbolItem(symbol: "➬", descriptionKey: "symbol.arrow.dingbat_shaded_left_fat"),
                SymbolItem(symbol: "➭", descriptionKey: "symbol.arrow.dingbat_shaded_right_fat"),

                // 50. Shaded Notched & Black Wedge Up (陰影凹槽與黑色向上楔形)
                SymbolItem(symbol: "➮", descriptionKey: "symbol.arrow.dingbat_shaded_notched"),
                SymbolItem(symbol: "➯", descriptionKey: "symbol.arrow.dingbat_shaded_pointed"),
                SymbolItem(symbol: "➱", descriptionKey: "symbol.arrow.dingbat_shaded_wedge"),
                SymbolItem(symbol: "⮄", descriptionKey: "symbol.arrow.black_wedge_up"),

                // 51. Black Wedges & Ribbons (黑色楔形與黑色緞帶)
                SymbolItem(symbol: "⮅", descriptionKey: "symbol.arrow.black_wedge_down"),
                SymbolItem(symbol: "⮆", descriptionKey: "symbol.arrow.black_wedge_left"),
                SymbolItem(symbol: "⮇", descriptionKey: "symbol.arrow.black_wedge_right"),
                SymbolItem(symbol: "⮈", descriptionKey: "symbol.arrow.black_ribbon_left"),

                // 52. Black Ribbons & Diagonal Ribbon (黑色緞帶與東北緞帶)
                SymbolItem(symbol: "⮉", descriptionKey: "symbol.arrow.black_ribbon_up"),
                SymbolItem(symbol: "⮊", descriptionKey: "symbol.arrow.black_ribbon_right"),
                SymbolItem(symbol: "⮋", descriptionKey: "symbol.arrow.black_ribbon_down"),
                SymbolItem(symbol: "⮥", descriptionKey: "symbol.arrow.ribbon_diag_ne"),

                // 53. Feathered Darts & Ribbon (羽箭與緞帶花式)
                SymbolItem(symbol: "➳", descriptionKey: "symbol.arrow.dart_feathered_left"),
                SymbolItem(symbol: "➵", descriptionKey: "symbol.arrow.dart_feathered_center"),
                SymbolItem(symbol: "➸", descriptionKey: "symbol.arrow.dart_feathered_right"),
                SymbolItem(symbol: "➺", descriptionKey: "symbol.arrow.ribbon_arrow"),

                // 54. Heavy Feathers & Circled Triangles (粗羽毛與帶圈三角)
                SymbolItem(symbol: "➻", descriptionKey: "symbol.arrow.teardrop_feather"),
                SymbolItem(symbol: "➼", descriptionKey: "symbol.arrow.heavy_feather_right"),
                SymbolItem(symbol: "➽", descriptionKey: "symbol.arrow.heavy_dart_right"),
                SymbolItem(symbol: "⮰", descriptionKey: "symbol.arrow.circled_tri_up"),

                // 55. Circled Triangles & Ribbon SE (帶圈三角與東南緞帶)
                SymbolItem(symbol: "⮱", descriptionKey: "symbol.arrow.circled_tri_down"),
                SymbolItem(symbol: "⮲", descriptionKey: "symbol.arrow.circled_tri_left"),
                SymbolItem(symbol: "⮳", descriptionKey: "symbol.arrow.circled_tri_right"),
                SymbolItem(symbol: "⮦", descriptionKey: "symbol.arrow.ribbon_diag_se"),

                // 56. Ribbon SW & Conical Wedge (西南緞帶、圓弧緞帶與錐形楔角)
                SymbolItem(symbol: "⮧", descriptionKey: "symbol.arrow.ribbon_diag_sw"),
                SymbolItem(symbol: "⮨", descriptionKey: "symbol.arrow.ribbon_curve_left"),
                SymbolItem(symbol: "⮩", descriptionKey: "symbol.arrow.ribbon_curve_right"),
                SymbolItem(symbol: "⌲", descriptionKey: "symbol.arrow.conical_wedge"),

                // 57. Angle Chevrons (角括號)
                SymbolItem(symbol: "«", descriptionKey: "symbol.arrow.angle_double_left"),
                SymbolItem(symbol: "»", descriptionKey: "symbol.arrow.angle_double_right"),
                SymbolItem(symbol: "‹", descriptionKey: "symbol.arrow.angle_single_left"),
                SymbolItem(symbol: "›", descriptionKey: "symbol.arrow.angle_single_right"),

                // 58. Precedence & Relations (順序與偏序)
                SymbolItem(symbol: "≺", descriptionKey: "symbol.arrow.precedes"),
                SymbolItem(symbol: "≻", descriptionKey: "symbol.arrow.succeeds"),
                SymbolItem(symbol: "≼", descriptionKey: "symbol.arrow.precedes_equal"),
                SymbolItem(symbol: "≽", descriptionKey: "symbol.arrow.succeeds_equal"),

                // 59. Open Triangles (開口三角關係箭頭)
                SymbolItem(symbol: "⊲", descriptionKey: "symbol.arrow.open_triangle_left"),
                SymbolItem(symbol: "⊳", descriptionKey: "symbol.arrow.open_triangle_right"),
                SymbolItem(symbol: "⊴", descriptionKey: "symbol.arrow.open_triangle_underbar_left"),
                SymbolItem(symbol: "⊵", descriptionKey: "symbol.arrow.open_triangle_underbar_right"),

                // 60. Square Subsets / Sockets (方框球窩與子集包含)
                SymbolItem(symbol: "⊏", descriptionKey: "symbol.arrow.square_subset_left"),
                SymbolItem(symbol: "⊐", descriptionKey: "symbol.arrow.square_subset_right"),
                SymbolItem(symbol: "⊑", descriptionKey: "symbol.arrow.square_subset_equal_left"),
                SymbolItem(symbol: "⊒", descriptionKey: "symbol.arrow.square_subset_equal_right"),
            ]
        ),
        SymbolCategory(
            nameKey: "symbol_category.steps",
            layout: .grid(columns: 5),
            items: [
                SymbolItem(symbol: "①", descriptionKey: "symbol.step.circled_1"),
                SymbolItem(symbol: "②", descriptionKey: "symbol.step.circled_2"),
                SymbolItem(symbol: "③", descriptionKey: "symbol.step.circled_3"),
                SymbolItem(symbol: "④", descriptionKey: "symbol.step.circled_4"),
                SymbolItem(symbol: "⑤", descriptionKey: "symbol.step.circled_5"),
                SymbolItem(symbol: "⑥", descriptionKey: "symbol.step.circled_6"),
                SymbolItem(symbol: "⑦", descriptionKey: "symbol.step.circled_7"),
                SymbolItem(symbol: "⑧", descriptionKey: "symbol.step.circled_8"),
                SymbolItem(symbol: "⑨", descriptionKey: "symbol.step.circled_9"),
                SymbolItem(symbol: "⑩", descriptionKey: "symbol.step.circled_10"),

                SymbolItem(symbol: "❶", descriptionKey: "symbol.step.filled_circled_1"),
                SymbolItem(symbol: "❷", descriptionKey: "symbol.step.filled_circled_2"),
                SymbolItem(symbol: "❸", descriptionKey: "symbol.step.filled_circled_3"),
                SymbolItem(symbol: "❹", descriptionKey: "symbol.step.filled_circled_4"),
                SymbolItem(symbol: "❺", descriptionKey: "symbol.step.filled_circled_5"),
                SymbolItem(symbol: "❻", descriptionKey: "symbol.step.filled_circled_6"),
                SymbolItem(symbol: "❼", descriptionKey: "symbol.step.filled_circled_7"),
                SymbolItem(symbol: "❽", descriptionKey: "symbol.step.filled_circled_8"),
                SymbolItem(symbol: "❾", descriptionKey: "symbol.step.filled_circled_9"),
                SymbolItem(symbol: "❿", descriptionKey: "symbol.step.filled_circled_10"),

                SymbolItem(symbol: "Ⅰ", descriptionKey: "symbol.step.roman_1"),
                SymbolItem(symbol: "Ⅱ", descriptionKey: "symbol.step.roman_2"),
                SymbolItem(symbol: "Ⅲ", descriptionKey: "symbol.step.roman_3"),
                SymbolItem(symbol: "Ⅳ", descriptionKey: "symbol.step.roman_4"),
                SymbolItem(symbol: "Ⅴ", descriptionKey: "symbol.step.roman_5"),
                SymbolItem(symbol: "Ⅵ", descriptionKey: "symbol.step.roman_6"),
                SymbolItem(symbol: "Ⅶ", descriptionKey: "symbol.step.roman_7"),
                SymbolItem(symbol: "Ⅷ", descriptionKey: "symbol.step.roman_8"),
                SymbolItem(symbol: "Ⅸ", descriptionKey: "symbol.step.roman_9"),
                SymbolItem(symbol: "Ⅹ", descriptionKey: "symbol.step.roman_10"),

                SymbolItem(symbol: "ⓐ", descriptionKey: "symbol.step.circled_a"),
                SymbolItem(symbol: "ⓑ", descriptionKey: "symbol.step.circled_b"),
                SymbolItem(symbol: "ⓒ", descriptionKey: "symbol.step.circled_c"),
                SymbolItem(symbol: "ⓓ", descriptionKey: "symbol.step.circled_d"),
                SymbolItem(symbol: "ⓔ", descriptionKey: "symbol.step.circled_e"),

                SymbolItem(symbol: "▸", descriptionKey: "symbol.step.right_pointer_small"),
                SymbolItem(symbol: "▹", descriptionKey: "symbol.step.right_pointer_small_hollow"),
                SymbolItem(symbol: "►", descriptionKey: "symbol.step.right_pointer_med"),
                SymbolItem(symbol: "▻", descriptionKey: "symbol.step.right_pointer_med_hollow"),
            ]
        ),
        SymbolCategory(
            nameKey: "symbol_category.badges",
            layout: .grid(columns: 5),
            items: [
                SymbolItem(symbol: "✓", descriptionKey: "symbol.badge.check"),
                SymbolItem(symbol: "✔", descriptionKey: "symbol.badge.heavy_check"),
                SymbolItem(symbol: "✅", descriptionKey: "symbol.badge.check_button"),
                SymbolItem(symbol: "✕", descriptionKey: "symbol.badge.cross"),
                SymbolItem(symbol: "✖", descriptionKey: "symbol.badge.heavy_cross"),

                SymbolItem(symbol: "★", descriptionKey: "symbol.badge.black_star"),
                SymbolItem(symbol: "☆", descriptionKey: "symbol.badge.white_star"),
                SymbolItem(symbol: "◆", descriptionKey: "symbol.badge.black_diamond"),
                SymbolItem(symbol: "◇", descriptionKey: "symbol.badge.white_diamond"),

                SymbolItem(symbol: "💡", descriptionKey: "symbol.badge.bulb"),
                SymbolItem(symbol: "⚠️", descriptionKey: "symbol.badge.warning"),
                SymbolItem(symbol: "📌", descriptionKey: "symbol.badge.pushpin"),
                SymbolItem(symbol: "🚀", descriptionKey: "symbol.badge.rocket"),
                SymbolItem(symbol: "📦", descriptionKey: "symbol.badge.package"),
                SymbolItem(symbol: "📥", descriptionKey: "symbol.badge.inbox"),
                SymbolItem(symbol: "📖", descriptionKey: "symbol.badge.open_book"),
                SymbolItem(symbol: "📚", descriptionKey: "symbol.badge.books"),
                SymbolItem(symbol: "❓", descriptionKey: "symbol.badge.question"),
                SymbolItem(symbol: "💬", descriptionKey: "symbol.badge.speech_balloon"),
                SymbolItem(symbol: "📄", descriptionKey: "symbol.badge.document"),
                SymbolItem(symbol: "⚖️", descriptionKey: "symbol.badge.scale"),
                SymbolItem(symbol: "🤝", descriptionKey: "symbol.badge.handshake"),
                SymbolItem(symbol: "👥", descriptionKey: "symbol.badge.team"),
                SymbolItem(symbol: "🔒", descriptionKey: "symbol.badge.lock"),
                SymbolItem(symbol: "⚡", descriptionKey: "symbol.badge.lightning"),
            ]
        ),
        SymbolCategory(
            nameKey: "symbol_category.math_keys",
            layout: .grid(columns: 5),
            items: [
                SymbolItem(symbol: "±", descriptionKey: "symbol.math.plus_minus"),
                SymbolItem(symbol: "×", descriptionKey: "symbol.math.multiply"),
                SymbolItem(symbol: "÷", descriptionKey: "symbol.math.divide"),
                SymbolItem(symbol: "≠", descriptionKey: "symbol.math.not_equal"),
                SymbolItem(symbol: "≈", descriptionKey: "symbol.math.approx_equal"),
                SymbolItem(symbol: "≤", descriptionKey: "symbol.math.less_equal"),
                SymbolItem(symbol: "≥", descriptionKey: "symbol.math.greater_equal"),
                SymbolItem(symbol: "∞", descriptionKey: "symbol.math.infinity"),
                SymbolItem(symbol: "∑", descriptionKey: "symbol.math.summation"),
                SymbolItem(symbol: "∏", descriptionKey: "symbol.math.product"),
                SymbolItem(symbol: "√", descriptionKey: "symbol.math.square_root"),
                SymbolItem(symbol: "∫", descriptionKey: "symbol.math.integral"),
                SymbolItem(symbol: "∈", descriptionKey: "symbol.math.element_of"),
                SymbolItem(symbol: "∉", descriptionKey: "symbol.math.not_element_of"),
                SymbolItem(symbol: "∩", descriptionKey: "symbol.math.intersection"),
                SymbolItem(symbol: "∪", descriptionKey: "symbol.math.union"),

                SymbolItem(symbol: "⌘", descriptionKey: "symbol.key.command"),
                SymbolItem(symbol: "⌥", descriptionKey: "symbol.key.option"),
                SymbolItem(symbol: "⇧", descriptionKey: "symbol.key.shift"),
                SymbolItem(symbol: "⌃", descriptionKey: "symbol.key.control"),
                SymbolItem(symbol: "⎋", descriptionKey: "symbol.key.escape"),
                SymbolItem(symbol: "⏎", descriptionKey: "symbol.key.return"),
                SymbolItem(symbol: "⌫", descriptionKey: "symbol.key.backspace"),
            ]
        ),
        SymbolCategory(
            nameKey: "symbol_category.gfm",
            layout: .list,
            items: [
                SymbolItem(symbol: "> [!NOTE]", descriptionKey: "symbol.callout.note"),
                SymbolItem(symbol: "> [!TIP]", descriptionKey: "symbol.callout.tip"),
                SymbolItem(symbol: "> [!IMPORTANT]", descriptionKey: "symbol.callout.important"),
                SymbolItem(symbol: "> [!WARNING]", descriptionKey: "symbol.callout.warning"),
                SymbolItem(symbol: "> [!CAUTION]", descriptionKey: "symbol.callout.caution"),
            ]
        ),
    ]
}

/// Interactive TUI Symbol Picker dialog window.
final class SymbolPickerView {
    private let terminal: EditorTerminal
    private let language: Language
    private weak var editor: Editor?
    private let onSelect: (String) -> Void

    var categoryIndex: Int = 0
    var selectedIndex: Int = 0
    var scrollRowOffset: Int = 0

    init(
        terminal: EditorTerminal,
        editor: Editor? = nil,
        language: Language = .detectSystemLanguage(),
        onSelect: @escaping (String) -> Void
    ) {
        self.terminal = terminal
        self.editor = editor
        self.language = language
        self.onSelect = onSelect
    }

    func show() {
        render()
        while true {
            let event = terminal.readInputEvent()
            switch event {
            case .key(let key):
                switch key {
                case .esc:
                    terminal.clearScreen()
                    return

                case .char(let ch):
                    let lowerStr = String(ch).lowercased()
                    if let num = Int(lowerStr), num >= 1 && num <= SymbolCategories.categories.count {
                        setCategory(num - 1)
                        render()
                    } else if let firstChar = lowerStr.first,
                        let ascii = firstChar.asciiValue,
                        let aVal = Character("a").asciiValue,
                        ascii >= aVal && ascii <= Character("z").asciiValue!
                    {
                        let idx = Int(ascii - aVal)
                        let itemsCount = currentCategoryItems().count
                        if idx >= 0 && idx < itemsCount {
                            selectedIndex = idx
                            render()
                        }
                    }

                case .tab:
                    setCategory((categoryIndex + 1) % SymbolCategories.categories.count)
                    render()

                case .arrowLeft:
                    moveSelection(by: -1)
                    render()
                case .arrowRight:
                    moveSelection(by: 1)
                    render()
                case .arrowUp:
                    moveSelectionInGrid(rowDelta: -1, colsCount: gridColumnsCount())
                    render()
                case .arrowDown:
                    moveSelectionInGrid(rowDelta: 1, colsCount: gridColumnsCount())
                    render()
                case .pageUp:
                    moveSelectionInGrid(rowDelta: -10, colsCount: gridColumnsCount())
                    render()
                case .pageDown:
                    moveSelectionInGrid(rowDelta: 10, colsCount: gridColumnsCount())
                    render()
                case .home:
                    selectedIndex = 0
                    render()
                case .end:
                    selectedIndex = max(0, currentCategoryItems().count - 1)
                    render()

                case .enter:
                    let currentItems = currentCategoryItems()
                    if selectedIndex >= 0 && selectedIndex < currentItems.count {
                        let chosenSymbol = currentItems[selectedIndex].symbol
                        onSelect(chosenSymbol)
                    }
                    terminal.clearScreen()
                    return

                case .resize:
                    terminal.clearScreen()
                    render()

                default:
                    break
                }

            case .mouse(let mouse):
                switch mouse.action {
                case .scrollUp:
                    moveSelectionInGrid(rowDelta: -1, colsCount: gridColumnsCount())
                    render()
                case .scrollDown:
                    moveSelectionInGrid(rowDelta: 1, colsCount: gridColumnsCount())
                    render()
                default:
                    break
                }

            case .openFile:
                break
            }
        }
    }

    private func letterIndicator(for idx: Int) -> String? {
        guard idx >= 0 && idx < 26 else { return nil }
        let aVal = Character("a").asciiValue!
        let scalar = UnicodeScalar(aVal + UInt8(idx))
        return String(scalar)
    }

    private func currentCategoryItems() -> [SymbolItem] {
        guard categoryIndex >= 0 && categoryIndex < SymbolCategories.categories.count else { return [] }
        return SymbolCategories.categories[categoryIndex].items
    }

    private func setCategory(_ index: Int) {
        if index >= 0 && index < SymbolCategories.categories.count {
            categoryIndex = index
            selectedIndex = 0
            scrollRowOffset = 0
        }
    }

    private func moveSelection(by delta: Int) {
        let count = currentCategoryItems().count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + delta + count) % count
    }

    private var currentCategoryLayout: SymbolCategoryLayout {
        guard categoryIndex >= 0 && categoryIndex < SymbolCategories.categories.count else { return .list }
        return SymbolCategories.categories[categoryIndex].layout
    }

    private func gridColumnsCount() -> Int {
        guard case .grid(let columns) = currentCategoryLayout else { return 1 }
        return max(1, columns)
    }

    private func moveSelectionInGrid(rowDelta: Int, colsCount: Int) {
        let count = currentCategoryItems().count
        guard count > 0 else { return }
        let newIndex = selectedIndex + (rowDelta * colsCount)
        if newIndex >= 0 && newIndex < count {
            selectedIndex = newIndex
        }
    }

    private func ensureVisible(contentRows: Int) {
        let colsCount = gridColumnsCount()
        let selectedRow = selectedIndex / colsCount
        if selectedRow < scrollRowOffset {
            scrollRowOffset = selectedRow
        } else if selectedRow >= scrollRowOffset + contentRows {
            scrollRowOffset = selectedRow - contentRows + 1
        }
    }

    private func render() {
        let (rows, cols) = terminal.getWindowSize()
        guard rows > 6 && cols > 20 else { return }

        let dialogWidth = min(cols - 4, 76)
        let dialogHeight = min(rows - 4, 20)
        let startRow = max(1, (rows - dialogHeight) / 2)
        let startCol = max(1, (cols - dialogWidth) / 2)

        var output = ""
        if let editor = editor {
            editor.menuBarController.isActive = false
            let geometry = ScreenGeometry(rows: rows, cols: cols, editor: editor)
            editor.adjustViewport(mainAreaHeight: geometry.mainAreaHeight, textWidth: geometry.textWidth)
            output += editor.renderer.render(editor: editor, geometry: geometry)
        } else {
            output += "\u{001B}[H"
        }

        let l10n = editor?.l10n ?? L10n(language: language)
        let title = l10n["dialog.symbol_picker.title"]

        // Top Frame
        let topBar = "╔" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╗"
        output += "\u{001B}[\(startRow);\(startCol)H\(topBar)"
        output += "\u{001B}[\(startRow);\(startCol + 2)H\(title.ansiStyled(style: ANSIStyle.bold))"

        // Tab Bar
        let tabRow = startRow + 1
        output += "\u{001B}[\(tabRow);\(startCol)H║"
        output += String(repeating: " ", count: max(0, dialogWidth - 2))
        output += "\u{001B}[\(tabRow);\(startCol + dialogWidth - 1)H║"

        var currentTabCol = startCol + 2
        for (idx, cat) in SymbolCategories.categories.enumerated() {
            let catName = l10n[cat.nameKey]
            output += "\u{001B}[\(tabRow);\(currentTabCol)H"
            if idx == categoryIndex {
                output += "[\(catName)]".ansiStyled(style: ANSIStyle.boldInverse)
                currentTabCol += catName.displayWidth + 3
            } else {
                output += " \(catName) "
                currentTabCol += catName.displayWidth + 3
            }
        }

        // Separator
        let sepRow = startRow + 2
        let midBar = "╠" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╣"
        output += "\u{001B}[\(sepRow);\(startCol)H\(midBar)"

        // Grid Content
        let items = currentCategoryItems()
        let contentRows = dialogHeight - 6
        let contentStartRow = startRow + 3
        ensureVisible(contentRows: contentRows)

        for r in 0..<contentRows {
            let currentRow = contentStartRow + r
            output += "\u{001B}[\(currentRow);\(startCol)H║"
            output += String(repeating: " ", count: max(0, dialogWidth - 2))
            output += "\u{001B}[\(currentRow);\(startCol + dialogWidth - 1)H║"
        }

        // Draw items with letter indicators [a]..[z]
        if case .list = currentCategoryLayout {
            // GFM Callout List Mode - uniform full row selection bar
            let maxListWidth = max(10, dialogWidth - 6)
            for (idx, item) in items.enumerated() {
                let rowInView = idx - scrollRowOffset
                if rowInView >= 0 && rowInView < contentRows {
                    let r = contentStartRow + rowInView
                    output += "\u{001B}[\(r);\(startCol + 3)H"
                    let hint = letterIndicator(for: idx).map { "[\($0)] " } ?? "    "
                    let rawStr = "\(hint)\(item.symbol)"
                    let paddedStr = rawStr.paddedToDisplayWidth(maxListWidth)
                    if idx == selectedIndex {
                        output += paddedStr.ansiStyled(style: ANSIStyle.boldInverse)
                    } else {
                        output += paddedStr
                    }
                }
            }
        } else {
            // Grid Mode - uniform cell width selection bar
            let colsCount = gridColumnsCount()
            let colWidth = max(1, (dialogWidth - 6) / colsCount)
            let cellWidth = max(1, colWidth - 1)
            for (idx, item) in items.enumerated() {
                let rowOffset = idx / colsCount
                let colOffset = idx % colsCount
                let rowInView = rowOffset - scrollRowOffset
                if rowInView >= 0 && rowInView < contentRows {
                    let r = contentStartRow + rowInView
                    let c = startCol + 3 + (colOffset * colWidth)
                    output += "\u{001B}[\(r);\(c)H"
                    let hint = letterIndicator(for: idx).map { "[\($0)]" } ?? "   "
                    let rawStr = " \(hint) \(item.symbol) "
                    let paddedStr = rawStr.paddedToDisplayWidth(cellWidth)
                    if idx == selectedIndex {
                        output += paddedStr.ansiStyled(style: ANSIStyle.boldInverse)
                    } else {
                        output += paddedStr
                    }
                }
            }
        }

        // Scroll indicators on right edge if total rows exceed contentRows
        let totalRows = (items.count + gridColumnsCount() - 1) / gridColumnsCount()
        if totalRows > contentRows {
            if scrollRowOffset > 0 {
                output += "\u{001B}[\(contentStartRow);\(startCol + dialogWidth - 1)H▲".ansiStyled(style: ANSIStyle.boldCyan)
            }
            if scrollRowOffset + contentRows < totalRows {
                output += "\u{001B}[\(contentStartRow + contentRows - 1);\(startCol + dialogWidth - 1)H▼".ansiStyled(style: ANSIStyle.boldCyan)
            }
        }

        // Preview Line
        let previewRow = startRow + dialogHeight - 3
        output += "\u{001B}[\(previewRow);\(startCol)H║"
        output += String(repeating: " ", count: max(0, dialogWidth - 2))
        output += "\u{001B}[\(previewRow);\(startCol + dialogWidth - 1)H║"

        if selectedIndex >= 0 && selectedIndex < items.count {
            let item = items[selectedIndex]
            let desc = l10n[item.descriptionKey]
            let previewText = "\(l10n["dialog.symbol_picker.selected"])\(item.symbol) (\(desc))"
            output += "\u{001B}[\(previewRow);\(startCol + 1)H\(previewText)"
        }

        // Footer Instruction Line (inside the dialog box)
        let footerRow = startRow + dialogHeight - 2
        output += "\u{001B}[\(footerRow);\(startCol)H║"
        output += String(repeating: " ", count: max(0, dialogWidth - 2))
        output += "\u{001B}[\(footerRow);\(startCol + dialogWidth - 1)H║"

        let footerText = l10n["dialog.symbol_picker.footer"]
        output += "\u{001B}[\(footerRow);\(startCol + 2)H\(footerText.ansiStyled(style: ANSIStyle.boldCyan))"

        // Bottom Frame
        let bottomRow = startRow + dialogHeight - 1
        let bottomBar = "╚" + String(repeating: "═", count: max(0, dialogWidth - 2)) + "╝"
        output += "\u{001B}[\(bottomRow);\(startCol)H\(bottomBar)"

        terminal.write(output)
        fflush(nil)
    }
}
