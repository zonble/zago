import Foundation

/// Traditional Chinese (zh_TW) translation table for zago text editor.
public struct TraditionalChineseStrings {
    public static let table: [String: String] = [
        // Help Bar Labels
        "help.get_help": "輔助說明",
        "help.menu": "主選單",
        "help.cancel": "取消",
        "help.write_out": "存檔",
        "help.read_file": "讀檔",
        "help.prev_pg": "前往上頁",
        "help.cut_text": "剪下文字",
        "help.cur_pos": "游標位置",
        "help.exit": "離開",
        "help.canvas_mode": "畫布",
        "help.table_mode": "表格",
        "help.text_mode": "文字",
        "help.justify": "重排文字",
        "help.where_is": "搜尋",
        "help.next_pg": "前往下頁",
        "help.uncut_text": "貼上文字",
        "help.to_spell": "拼字檢查",
        "help.open_link": "開啟連結",
        "help.table_exit": "離開表格",
        "help.next_cell": "下個儲存格",
        "help.prev_cell": "上個儲存格",
        "help.cell_width": "儲存格寬度 -/+",
        "help.cell_height": "儲存格高度 -/+",
        "help.center_text": "置中對齊",
        "help.clear_cell": "清空儲存格",
        "help.select_text": "選取文字",
        "help.complete": "補完",
        "help.confirm": "確認",
        "help.yes": "是",
        "help.no": "否",
        "help.clear": "清除",
        "help.move": "移動",
        "help.jump": "跳轉",
        "help.command": "指令",
        "help.mark_block": "標記區塊",
        "help.cut_block": "剪下區塊",
        "help.copy_block": "複製區塊",
        "help.uncut_block": "貼上區塊",
        "help.line": "線段",
        "help.arrow": "箭頭",
        "chrome.end_of_file": "檔案結尾",

        // Prompts
        "prompt.write_name": "寫出檔案名稱：",
        "prompt.confirm_exit_save": "是否儲存已修改的內容？(回答 \"N\" 將捨棄修改)：",
        "prompt.confirm_reload": "檔案已在磁碟上變更。是否重新載入？（答「N」將保留本地緩衝區）：",
        "prompt.encoding_fallback": "編碼 \"%@\" 無法支援新文字，是否改以 UTF-8 格式儲存？(y/n) ",
        "prompt.search": "搜尋",
        "prompt.insert_file": "欲插入之檔案：",
        "prompt.edit_spelled_word": "修改拼錯字詞 \"%@\"：",
        "prompt.logo": "❯ ",
        "prompt.fill_text": "填滿文字：",
        "prompt.table_dimensions": "表格列 欄 寬：",
        "status.directory_buffer_readonly": "目錄頁面為唯讀狀態",
        "dirbuf.header_directory": "\" 目錄: %@",
        "dirbuf.header_instructions": "\" 在檔案上按 Enter 開啟，在資料夾上按 Enter 瀏覽",
        "dirbuf.up_dir": ".. (上一層目錄)",
        "status.cannot_open_binary_file": "無法開啟非文字檔 (Binary File)",
        "prompt.goto_line": "請輸入列號與欄號：",
        "textview.footer": "  上/下：捲動   PgUp/PgDn：翻頁   Home/End：跳轉   其他按鍵：關閉",
        "logoview.reference_title": "  zago - Editor LOGO 指令參考",
        "logoview.workspace_title": "  zago - Editor LOGO 工作區",
        "logoref.content": """
          Editor LOGO 指令參考
          ================================================================

          Editor LOGO 是編輯器巨集語言。指令會操作目前文件、
          游標、選取範圍、表格、狀態列與多文件 Buffer 狀態。

          1. 文字圖形與樣式
            BOX [text|width height [style]]      插入邊框（自動置中/內嵌文字）
            DRAWBOX [text|w h [style]]           覆蓋繪製邊框（框住畫布標記）
            LINE [len] [style] [arrow]           繪製/連接水平線
            VLINE [height] [style]               繪製/連接垂直線
            FILL text                            填滿選取區、表格儲存格或方框內部
            TABLE [rows cols width]              插入 ASCII 表格

            邊界限制：BOX/DRAWBOX 寬 3...200、高 2...100；LINE/VLINE 1...200
            框線樣式：single, double, round, double-round, ascii, markdown
            箭頭樣式：solid (▲▼◀▶), stemmed (↑↓←→), hollow (△▽◁▷), small (▴▾◂▸)

          2. 四則運算與運算子
            +  -  *  /  %  ^                     加、減、乘、除、取餘數、次方
            =  <>  !=   <  >  <=  >=             等於、不等於、小於、大於、小於等於、大於等於
            SUM a b                              加法運算 (+)
            DIFFERENCE a b                       減法運算 (-)
            PRODUCT a b                          乘法運算 (*)
            QUOTIENT a b                         除法運算 (/)
            MODULO a b                           取餘數運算 (%)
            POWER base exp                       次方運算 (^)

          3. 核心功能
            TYPE text                            插入文字或運算結果
            SHOW expr                            在狀態列顯示狀態訊息
            MAKE "name value                     定義全域變數
            :name                                讀取變數值
            MOVE direction [n]                   移動游標 (UP, DOWN, LEFT, RIGHT)
            GOTO row [col]                       跳轉至 1-based 指定列/欄
            FIND "query                          搜尋指定文字
            INDENT / OUTDENT                     增加 / 減少縮排 (4 個空格)
            JOINLINE / SPLITLINE                 接合下一行 / 拆分當前行
            MARK / CUT / UNCUT                   標記選取區 / 剪下 / 貼上剪貼簿

          4. 字串處理
            WORD a b ...                         串接多個值為單一字串
            SUBSTRING s start len / SUBSTR       取出子字串 (1-based 起始索引)
            INDEXOF s "sub"                      搜尋子字串第一次出現的位置 (1-based)
            LASTINDEXOF s "sub"                  搜尋子字串最後一次出現的位置
            STARTSWITH? s "prefix"               檢查字串是否以指定前綴開頭
            ENDSWITH? s "suffix"                 檢查字串是否以指定後綴結尾
            CONTAINS? s "sub"                    檢查字串是否包含指定子字串
            UPPERCASE s / LOWERCASE s            轉換字串為全大寫 / 全小寫
            TRIM s                               去除字串前後空白字元
            REPLACE s "old" "new"                取代字串中所有匹配字樣
            REPEATSTR s count                    重複字串指定次數
            SPLIT s "delim"                      依分隔符拆分字串為 List
            JOIN list "delim"                    以分隔符將 List 項目合併為字串
            PADLEFT s len [char]                 左側對齊填補字元至指定長度
            PADRIGHT s len [char]                右側對齊填補字元至指定長度
            FORMAT "fmt" val ...                 依照 C 語言 printf 格式化字串
            COUNT item                           計算字串長度或清單項目數
            ASCII char / CHAR code               取得 ASCII 碼 / 依 ASCII 碼產生字元

          5. Lists, Arrays & Plist
            LIST a b ...                         建立 List
            SENTENCE a b / SE                    合併多個字串或清單為扁平 List
            FIRST data / LAST data               取得第一項或最後一項
            BUTFIRST data / BUTLAST data         除去第一項或最後一項
            ITEM n data                          取得 1-based 指定位置項目
            FPUT item list / LPUT item list      於清單首位或末位插入項目
            FIRSTS list / BUTFIRSTS list         取得子清單首項集 / 其餘項集
            COMBINE a b / REVERSE list           接合或反轉清單
            PICK list|array                      隨機抽樣單一項目
            REMOVE item list / REMDUP list       移除指定項目 / 移除重複項目
            SORT list [template]                 排序清單項目
            ARRAY size / MDARRAY dims            建立一維或多維 Array 陣列
            MDITEM dims arr / MDSETITEM dims v   存取/修改多維陣列元素
            LISTTOARRAY list / ARRAYTOLIST arr   List 與 Array 轉置
            PPROP "plist "prop val               設定屬性清單數值
            GPROP "plist "prop                   讀取屬性清單數值
            REMPROP "plist "prop                 從屬性清單移除屬性
            PLIST "plist / PLISTS                取得完整屬性清單 / 列出所有屬性清單

            • List (清單)：使用 中括號 [ ... ] 包裹，元素間以空格分隔。
              • 例如：[apple banana orange] 或 [1 2 3]
              • 動態列表：長度可隨時伸縮，適合做首尾增刪與列表拼接。
              • 常用建立與操作 Primitives：LIST、SENTENCE (或 SE)、FPUT (頭部插入)、
                LPUT (尾部插入)、FIRST / BUTFIRST。
            • Array (陣列)：使用 大括號 { ... } 包裹，元素間以空格分隔。
              • 例如：{1 2 3} 或 {"apple" "banana"}
              • 固定長度 / 矩陣空間：通常先宣告大小或維度，適合需要依索引隨機存取或
                進行多維計算的情境。
              • 常用建立 Primitives：
                • ARRAY size（建立指定大小的一維陣列，如 ARRAY 3 產生 {"" "" ""}）
                • MDARRAY dims（建立指定維度的多維陣列，如 MDARRAY [3 3] 產生 3 × 3 矩陣）

          6. Date / Datetime
            DATE                                 取得當前系統日期字串 ("YYYY-MM-DD")
            TIME                                 取得當前系統時間字串 ("HH:MM:SS")

          7. CJK
            TRANSFORM.TOHANS text / TOHANS       繁體中文轉簡體中文
            TRANSFORM.TOHANT text / TOHANT       簡體中文轉繁體中文
            TRANSFORM.TOHIRAGANA text            轉日文平假名
            TRANSFORM.TOKATAKANA text            轉日文片假名
            TRANSFORM.TOROMAJI text              轉日文羅馬字
            SPACING.CJK text                     自動於中英/數字交界處補空格
            CHARCOUNT.CJK text                   精準統計中文字數 (忽略英數)
            CHARCOUNT.EMOJI text                 統計 Emoji 圖像符號個數
            CHARCOUNT.WORDS text                 統計英文單字數量
            CHARCOUNT.LINES text                 統計總行數

          8. Turtle
            PD / PU                              落筆 / 提筆 (Pen Down / Pen Up)
            FD len / BK len                      前進 / 後退指定長度
            RT / LT                              右轉 90° / 左轉 90° (無參數)
            SETHEADING dir                       設定繪圖方向 (UP, DOWN, LEFT, RIGHT)
            HEADING                              回傳目前繪圖方向

          9. Regex
            REGEX_MATCH s "pattern"              正規表達式全字串匹配 (REMATCH?)
            REGEX_REPLACE s "pat" "repl"         正規表達式全域搜尋與取代 (RREPLACE)
            REGEX_FIND s "pattern"               正規表達式搜尋並回傳匹配項清單 (RFIND)

          10. Flow
            REPEAT n [ commands ]                重複執行 n 次（可用 # 或 repcount）
            FOR [ var start end step ] [ ]       數值迴圈控制
            DOTIMES [ var n ] [ commands ]       執行 n 次 (var 從 0 至 n-1)
            WHILE [ test ] [ commands ]          條件成立時持續執行
            DO.WHILE [ commands ] [ test ]       先執行一次，條件成立時持續執行
            UNTIL [ test ] [ commands ]          直到條件成立前持續執行
            DO.UNTIL [ commands ] [ test ]       先執行一次，直到條件成立前持續執行
            IF test [ commands ]                 單向條件分支
            IFELSE test [ yes ] [ no ]           雙向條件分支
            CASE val [ [ match [cmds] ] ]        多重模式匹配分支

          11. RC/RW
            READWORD [prompt] / RW               讀取整行文字輸入 (預設從 console/stdin)
            READCHAR [prompt] / RC               讀取單一字元按鍵 (預設從 console/stdin)

          12. Math/Bitwise
            ABS / INT / ROUND / SQRT             絕對值 / 無條件捨去 / 四捨五入 / 平方根
            MIN a b ... / MAX a b ...            取得極小值 / 極大值
            SIN / COS / TAN degrees              以角度為單位的三角函數
            RANDOM n / RERANDOM [seed]           產生 0...n-1 隨機整數 / 重置隨機種子
            ISEQ start end                       產生連續整數 List (例如 ISEQ 1 5)
            BITAND a b / BIT.AND                 整數位元 logic AND 運算
            BITOR a b / BIT.OR                   整數位元 logic OR 運算
            BITXOR a b / BIT.XOR                 整數位元 logic XOR 運算
            BITNOT a / BIT.NOT                   整數位元邏輯反轉運算
            LSHIFT a bits / BIT.SHL              整數位元邏輯左移
            RSHIFT a bits / BIT.SHR              整數位元邏輯右移

          13. Program
            TO name :arg ... END                 定義自訂 User Procedure
            DEFINE "name [[args] [body]]         動態由 List 結構建立 User Procedure
            TEXT "name                           取得 Procedure 的原始定義文字/結構
            ARITY "name                          取得 Procedure 的參數個數 (Arity)
            PROCEDURES / PROCS                   列出所有自訂 Procedure 名稱清單
            PRIMITIVES / PRIMS                   列出所有 Built-in Primitive 名稱清單
            NAMES                                列出所有全域變數名稱清單
            CONTENTS                             列出工作區完整內容 (Procedures, Vars, Plists)
            ERASE "name / ER                     清除指定 Procedure 或變數
            ERPS / ERNS / ERALL                  清除所有自訂程序 / 全域變數 / 全域工作區

          14. Higher function
            MAP template list                    對 List 項目進行 Map 映射 (可用 ? 表示項目)
            MAPSE template list                  對 List 項目進行 Map 映射並扁平化
            FILTER template list                 過濾符合條件的 List 項目
            REDUCE template list                 對 List 項目進行累加歸納 (可用 ?1, ?2)
            CROSSMAP template lists              對多組 List 計算笛卡兒積映射
            APPLY "proc args                     以名稱與參數 List 動態呼叫 Procedure
            INVOKE "proc arg1 arg2               以名稱與獨立參數動態呼叫 Procedure

          15. Exception
            CATCH "tag [ commands ]              捕捉指定 Tag 的例外（"ERROR 捕捉執行時期錯誤）
            THROW "tag                           主動拋出指定 Tag 的例外
            ERROR                                取得最後一次捕捉到的錯誤細節資訊物件

          16. Predicate
            WORD? LIST? ARRAY? NUMBER?           檢查資料型別是否為字串/清單/陣列/數值
            EMPTY? val                           檢查字串或清單是否為空
            EQUAL? a b / NOTEQUAL? a b           比較兩值是否相等 / 不相等
            LESS? a b / GREATER? a b             比較大小 (小於 / 大於)
            PROCEDURE? name                      檢查 built-in 或自訂 Procedure 是否存在
            PRIMITIVE? name                      檢查 built-in Primitive 是否存在
            DEFINED? name                        檢查自訂 Procedure 是否存在
            NAME? name                           檢查指定名稱的變數是否存在

          17. Buffer
            BUFFERS / BUFFERLIST                 列出所有已開啟的 Buffer 列表
            BUFFER "name / BUFFER index          切換至指定名稱或索引的 Buffer
            CLEARBUFFER                          清空當前 Buffer 的全部內容
            GETLINE [row]                        取得指定列 (預設當前列) 的邏輯行文字
            SETLINE row "text"                   設定指定列的邏輯行文字
            LINECOUNT                            回傳當前 Buffer 的總行數
            BUFFERTEXT                           回傳當前 Buffer 的完整內文
            SELECTION                            回傳當前選取範圍的文字
            FILENAME                             回傳當前 Buffer 的檔案路徑
        """,
        "logoref.all_aliases_header": "所有 Primitive 別名與關鍵字 (All Primitive Keywords & Aliases)",
        "logoworkspace.heading": "  Editor LOGO 工作區",
        "logoworkspace.procedures": "  User Procedures:",
        "logoworkspace.variables": "  變數：",
        "logoworkspace.none": "    （無）",
        "logoworkspace.tip_1": "  在 LOGO 腳本中可用 PROCEDURE?、PRIMITIVE?、DEFINED?、NAME?",
        "logoworkspace.tip_2": "  做可程式化的存在檢查。",

        // Status Messages
        "status.mark_set": "標記已設定",
        "status.mark_unset": "標記已取消",
        "status.cut_text": "文字已剪下",
        "status.cut_one_line": "已剪下 1 行",
        "status.uncut_text": "文字已貼上",
        "status.clipboard_empty": "剪貼簿為空",
        "status.no_selection": "沒有選取範圍",
        "status.no_block_marked": "未標記區塊",
        "status.block_mark_canvas_only": "區塊標記僅限在畫布模式使用",
        "status.copied_text": "文字已複製",
        "status.copied_block": "區塊已複製",
        "status.path_required": "需要路徑",
        "status.no_such_buffer": "沒有這個 buffer",
        "status.buffer_position": "Buffer %d / %d",
        "status.invalid_line": "無效的列號",
        "status.invalid_column": "無效的欄號",
        "status.command_completions": "%@：%@",
        "status.no_completions": "沒有可補完項目",
        "status.fill_text_required": "需要填滿文字",
        "status.justified_paragraph": "已完成段落重排",
        "status.already_oldest": "已至最舊復原紀錄",
        "status.undo_performed": "復原完成",
        "status.unknown_command": "未知指令",
        "status.cancelled": "已取消",
        "status.cancelled_exit": "已取消離開",
        "status.cancelled_search": "已取消搜尋",
        "status.search_cleared": "已清除搜尋",
        "status.no_active_search": "沒有作用中的搜尋",
        "status.invalid_regex": "無效的 regex：%@",
        "status.cancelled_insert": "已取消插入檔案",
        "status.spell_check_skipped": "跳過拼字檢查",
        "status.word_kept": "保留原字詞",
        "status.no_misspelled": "[ 未發現拼錯字詞 ]",
        "status.file_reloaded": "[ 已從磁碟重新載入檔案 ]",
        "status.saved_as_utf8": "[ 已改用 UTF-8 儲存 ]",
        "status.save_cancelled": "[ 存檔已取消 ]",
        "status.kept_local": "[ 已保留本地修改 ]",
        "status.logo_executed": "[ 已執行 LOGO 巨集腳本 ]",
        "status.logo_evaluated": "[ LOGO 腳本求值成功 ]",
        "status.filled_block": "[ 已填滿區塊 ]",
        "status.filled_cell": "[ 已填滿儲存格 ]",
        "status.goto_disabled_in_table_mode": "[ 表格模式下停用 GOTO ]",
        "status.default_border": "[ 預設框線：%@ ]",
        "status.unknown_border_style": "[ 未知的框線樣式：%@ ]",
        "status.unknown_table_border": "[ 未知的表格框線：%@ ]",
        "status.disabled_in_table_mode": "[ 表格模式下停用 %@ ]",
        "status.table_mode_exited": "[ 已退出表格模式 ]",
        "status.table_mode_hint": "(F7 / M+T 退出 | Tab 移動)",
        "status.canvas_mode_hint": "(F8 / M+V 退出)",
        "status.canvas_row_limit_exceeded": "[ 已超過畫布列數上限 ]",
        "status.canvas_column_limit_exceeded": "[ 已超過畫布欄數上限 ]",
        "mode.canvas": "畫布",
        "mode.table": "表格",
        "subline.char_count": "%d 字",
        "status.table_mode_cancelled": "[ 已取消表格模式 ]",
        "status.table_created": "[ 表格已建立 ]",
        "status.cell_text_centered": "[ 已居中表格文字 (^J) ]",
        "status.editing_config": "[ 編輯 %@ ]",
        "status.config_reloaded": "[ 已重新載入設定檔 ]",
        "status.justify_disabled_in_canvas_mode": "[ 畫布模式下停用文字重排 ]",
        "status.inserted_diagram_snippet": "[ 已插入 %@ 圖表範本 ]",
        "status.line_numbers_state": "[ 行號顯示 %@ ]",
        "status.wrap_column_set": "[ 自動折行欄數設為 %d ]",
        "status.wrap_column_reset": "[ 自動折行欄數重設為動態 ]",
        "status.deleted_selection": "[ 已刪除選取範圍 ]",
        "status.cannot_shrink_width": "[ 無法再縮小欄寬 ]",
        "status.cannot_shrink_height": "[ 無法再縮小列高 ]",
        "status.cannot_expand_width_collision": "[ 無法再增加欄寬（已碰觸鄰近圖形）]",
        "status.replaced_occurrences": "[ 已替換 %d 處 ]",
        "status.no_document_link": "[ 游標所在位置沒有文件連結 ]",
        "status.document_link_same_file": "[ 連結指向目前檔案 ]",
        "status.opened_document_link": "[ 已開啟 %@ ]",
        "status.no_headings": "[ 沒有標題 ]",
        "status.heading_position": "[ 標題 %d/%d：%@ ]",
        "status.heading_nav_disabled_directory": "[ 目錄模式下停用標題導航 ]",
        "status.heading_nav_disabled_canvas": "[ 畫布模式下停用標題導航 ]",
        "status.heading_nav_disabled_table": "[ 表格模式下停用標題導航 ]",
        "status.heading_nav_unsupported_format": "[ 目前檔案格式不支援文件大綱 ]",
        "status.outline_cancelled": "[ 已取消大綱 ]",
        "status.no_text_selection": "[ 沒有選取文字 ]",
        "status.transformed_selection": "[ 已轉換選取文字：%@ ]",
        "status.text_transform_failed": "[ 文字轉換失敗：%@ ]",
        "status.word_count_selection": "[ 選取範圍：%@ ]",
        "status.word_count_document": "[ 文件：%@ ]",
        "menu.tools.eval_logo": "Eval LOGO 腳本\t^Q",
        "menu.edit.copy": "複製\tM+W",

        // Help Viewer
        "helpview.title": "  zago - 完整指令與快速鍵說明手冊",
        "helpview.header": "  快捷鍵與指令對照表",
        "helpview.sec_nav": "  游標移動與導航：",
        "helpview.nav_1": "    ^F / 右方向鍵      游標向前移動一個字元",
        "helpview.nav_2": "    ^B / 左方向鍵      游標向後移動一個字元",
        "helpview.nav_3": "    ^P / 上方向鍵      游標移動至上一行",
        "helpview.nav_4": "    ^N / 下方向鍵      游標移動至下一行",
        "helpview.nav_5": "    ^A / Home          游標移動至當前行行首",
        "helpview.nav_6": "    ^E / End           游標移動至當前行行尾",
        "helpview.nav_7": "    ^V / PgDn          向下捲動一頁文字",
        "helpview.nav_8": "    ^Y / PgUp          向上捲動一頁文字",

        "helpview.sec_edit": "  編輯、剪貼與選取：",
        "helpview.edit_1": "    ^D / Delete        刪除游標所在位置的字元",
        "helpview.edit_2": "    Shift+方向鍵/Home/End 延伸選取文字範圍",
        "helpview.edit_3": "    ^K / F9            剪下選取文字、畫布區塊或目前行",
        "helpview.edit_4": "    ^U / F10           貼上最後剪下的文字至游標位置",
        "helpview.edit_5": "    ^I / Tab           於游標位置插入 Tab 縮排",

        "helpview.sec_canvas": "  畫布模式：",
        "helpview.canvas_1": "    F7 / M+V           切換畫布",
        "helpview.canvas_2": "    Shift+方向鍵       畫出框線並移動畫布游標",
        "helpview.canvas_3": "    Ctrl+Shift+方向鍵  畫出箭頭線，並在終點放置箭頭",
        "helpview.canvas_4": "    ^^ / M+B           設定畫布區塊標記",

        "helpview.sec_search": "  搜尋與段落重排對齊：",
        "helpview.search_1": "    ^W / F6, M+N/P    搜尋；跳到下一個/上一個結果",
        "helpview.search_2": "    M+O                開啟游標所在的 Markdown/Org/rst/AsciiDoc 文件連結",
        "helpview.search_3": "    M+[ / M+] / M+\\   上/下一個標題；開啟文件大綱",
        "helpview.search_4": "    ^L                 重新繪製 Terminal 畫面",
        "helpview.search_5": "    ^C / F11           顯示當前游標與行列位置資訊",
        "helpview.search_6": "    ^T / F12           啟動拼字檢查工具",
        "helpview.search_7": "    ^J                 重排與自動對齊當前段落（中英文混排）",

        "outlineview.title": "  文件大綱",
        "outlineview.footer": "  Up/Down 移動  Enter 跳轉  Esc/^G 關閉",

        "helpview.sec_file": "  檔案與 Buffer 操作指令：",
        "helpview.file_1": "    ^S                 儲存目前文件；^O / F3 可選擇路徑",
        "helpview.file_2": "    ^R / F5            插入外部檔案內容至當前文件中",
        "helpview.file_3": "    ^N                 開啟新的空白頁",
        "helpview.file_4": "    M+. / M+>          切換至下一個文件",
        "helpview.file_5": "    M+, / M+<          切換至上一個文件",
        "helpview.file_6": "    ^X / F2            關閉當前文件 / 退出編輯器",
        "helpview.file_7": "    F4                 儲存並關閉編輯器",
        "helpview.file_8": "    ^G                 取消目前選取範圍或畫布標記",
        "helpview.file_10": "    ^^ / M+B           設定/取消矩形畫布區塊標記 (僅適用畫布模式)",
        "helpview.file_9": "    F1 / M+M / ^M      開啟/關閉頂端選單列",

        "helpview.sec_set": "  使用 'set / unset' 指令可調整的設定選項：",
        "helpview.set_1": "    set wrap <col|off>      自動換行欄位上限（例如 set wrap 80 或 set wrap off）",
        "helpview.set_2": "    set ruler <on|off>      開啟/關閉欄位尺規列",
        "helpview.set_3": "    set linenumbers <on|off> 開啟/關閉行號欄位",
        "helpview.set_4": "    set sublinenumbers <on|off> 開啟/關閉自動換行子行號",
        "helpview.set_5": "    set canvas-mode <on|off> 啟動畫布模式",
        "helpview.set_6": "    set syntax <on|off>     開啟/關閉語法高亮",
        "helpview.set_7": "    set tab <size>          設定 Tab 縮排寬度（例如 set tab 4）",
        "helpview.set_8": "    set auto-reload <on|off> 自動重新載入外部修改的檔案",
        "helpview.set_9": "    set border <style>      預設繪圖/表格框線樣式 (single/double/round/ascii)",
        "helpview.set_10": "    set arrow <style>       預設箭頭樣式 (solid/stemmed/hollow/small)",
        "helpview.set_11": "    set regex <on|off>      開啟/關閉正則表達式搜尋模式",
        "helpview.set_12": "    set lang <en|zh_TW>     設定介面語言",
        "helpview.set_13": "    set spell <lang>        設定拼字檢查字典語言（例如 set spell en_US）",
        "helpview.set_14": "    set trim-trailing-whitespace <on|off> 儲存時自動清除行尾空白",

        "helpview.sec_logo": "  Editor LOGO 巨集語言與海龜繪圖指令：",
        "helpview.logo_1": "    Esc / M+:          移動到指令列",
        "helpview.logo_2": "    TYPE / PRINT       於游標位置輸出/插入指定文字",
        "helpview.logo_3": "    BOX / DRAWBOX / LINE / VLINE 畫框與橫豎分隔線（支援自動交點融合）",
        "helpview.logo_4": "    MAKE / VAR / :var  宣告變數與進行四則運算求值",
        "helpview.logo_5": "    REPEAT / TO / EXEC 迴圈執行與自訂程序定義呼叫",
        "helpview.logo_6": "    PD / PU / FD / BK  海龜繪圖：落筆、提筆、前進、後退",
        "helpview.logo_7": "    RT / LT / GOTO     海龜繪圖：右轉/左轉 90 度、指定行列跳轉",
        "helpview.logo_8": "    DATE / TIME / SET  插入當前日期時間、設定編輯器選項",
        "helpview.logo_9": "    IF / IFELSE        條件判斷（IF 條件 [...] / IFELSE 條件 [...] [...]）",

        "helpview.footer": "  [ ↑/↓/PgUp/PgDn: 捲動頁面 | 按任意鍵返回編輯器 ]",

        // Common Messages
        "msg.cancelled": "[ 已取消 ]",
        "buffer.new_buffer": "空白頁",
        "buffer.modified": "已修改",

        // Format Messages
        "msg.read_lines": "[ 已讀取 %d 行 ]",
        "msg.wrote_to_file": "[ 已儲存至 %@ ]",
        "msg.config_loaded_with_errors": "[ 已載入設定檔（含有 %d 個語法錯誤）]",
        "msg.cursor_info": "第 %d/%d 行 (%d%%), 第 %d/%d 欄, 視覺欄 %d/%d",
        "msg.found_query_at_line": "於第 %2$d 行找到 \"%1$@\"",
        "msg.search_wrapped_found": "搜尋回到開頭，於第 %2$d 行找到 \"%1$@\"",
        "msg.not_found": "找不到 \"%@\"",
        "msg.inserted_lines": "[ 已插入 %d 行內容 ]",
        "msg.error_inserting_file": "插入檔案錯誤：%@",
        "msg.error_saving_file": "儲存檔案錯誤：%@",
        "msg.replaced_word": "已將 '%@' 替換為 '%@'",

        // Menu Bar Titles
        "menu.file": "檔案(F)",
        "menu.edit": "編輯(E)",
        "menu.buffer": "Buffer(B)",
        "menu.run": "執行(R)",
        "menu.shapes": "圖形(S)",
        "menu.borders": "框線(O)",
        "menu.tools": "工具(T)",
        "menu.diagrams": "圖表(D)",
        "menu.help": "說明(H)",

        // Menu Bar Items
        "menu.file.new": "新建空白頁\t^N",
        "menu.file.open": "讀取外部檔案…\t^R",
        "menu.file.directory": "瀏覽目錄\tDIR",
        "menu.file.save": "儲存檔案\t^S",
        "menu.file.write_out": "另存寫出…\t^O",
        "menu.file.save_exit": "儲存並關閉\tF4",
        "menu.file.exit": "關閉頁面 / 退出\t^X",
        "menu.file.edit_config": "編輯設定檔(C)",
        "menu.file.reload_config": "重新載入設定檔(R)",

        "menu.edit.undo": "復原\t^Z",
        "menu.edit.mark": "標記區塊\t^^ / M+B",
        "menu.edit.cancel_selection": "取消標記\t^G / M+U",
        "menu.edit.cut": "剪下\t^K",
        "menu.edit.paste": "貼上\t^U",
        "menu.edit.delete_line": "刪除整行\t^BS",
        "menu.edit.search": "搜尋文字…\t^W",
        "menu.edit.open_link": "開啟連結\tM+O",
        "menu.edit.outline": "文件大綱\tM+\\",
        "menu.edit.next_heading": "下一個標題\tM+]",
        "menu.edit.previous_heading": "上一個標題\tM+[",
        "menu.edit.spell": "拼字檢查…\t^T",
        "menu.edit.goto_line": "跳轉至指定行…\t^/",
        "menu.edit.justify": "重排與對齊段落\t^J",
        "menu.edit.text_editing_mode": "一般模式",
        "menu.edit.canvas_mode": "畫布模式\tF8",
        "menu.edit.table_editing_mode": "表格模式\tF7",

        "menu.buffer.next": "下一個 Buffer\tM+.",
        "menu.buffer.prev": "上一個 Buffer\tM+,",
        "menu.buffer.output": "LOGO 輸出紀錄\tM+L",

        "menu.run.script": "執行腳本\tF5",
        "menu.run.eval": "求值行/選取區\t^Q",
        "menu.run.output": "LOGO 輸出紀錄\tM+L",
        "menu.run.canvas": "LOGO 繪圖畫布\tM+C",
        "menu.run.clear": "清除畫布與輸出",

        "menu.shapes.box": "方框",
        "menu.shapes.draw_box": "繪製方框",
        "menu.shapes.line": "水平線",
        "menu.shapes.vline": "垂直線",
        "menu.shapes.table": "表格",
        "menu.shapes.fill": "填滿區域/儲存格",

        "menu.borders.single": "單線",
        "menu.borders.double": "雙線",
        "menu.borders.round": "單線圓角",
        "menu.borders.double_round": "雙線圓角",
        "menu.borders.ascii": "ASCII",
        "menu.borders.ascii_round": "ASCII 圓角",
        "menu.borders.markdown": "Markdown",
        "menu.borders.next_style": "下一種框線\tM+S",
        "menu.borders.arrow_solid": "箭頭：實心 ▲▼◀▶",
        "menu.borders.arrow_stemmed": "箭頭：細線 ↑↓←→",
        "menu.borders.arrow_hollow": "箭頭：空心 △▽◁▷",
        "menu.borders.arrow_small": "箭頭：微型 ▴▾◂▸",

        "menu.tools.logo": "指令列\tEsc",
        "menu.tools.word_count": "字數統計",
        "menu.tools.transform_tohant": "轉換：繁體中文",
        "menu.tools.transform_tohans": "轉換：簡體中文",
        "menu.tools.transform_tolatin": "轉換：拉丁轉寫",
        "menu.tools.transform_hiragana": "轉換：平假名",
        "menu.tools.transform_katakana": "轉換：片假名",
        "menu.tools.transform_romaji": "轉換：羅馬字",
        "menu.tools.transform_cjk_spacing": "轉換：CJK 空格",
        "menu.tools.line_numbers": "顯示/隱藏行號",
        "menu.tools.sub_line_numbers": "顯示/隱藏子行號",
        "menu.tools.ruler": "顯示/隱藏尺標",
        "menu.tools.wrap_80": "換行: 80",
        "menu.tools.wrap_60": "換行: 60",
        "menu.tools.wrap_40": "換行: 40",
        "menu.tools.wrap_reset": "換行: 動態",

        "menu.diagrams.mermaid_sequence": "Mermaid 時序圖 (Sequence)",
        "menu.diagrams.mermaid_flowchart": "Mermaid 流程圖 (Flowchart)",
        "menu.diagrams.mermaid_class": "Mermaid 類別圖 (Class)",
        "menu.diagrams.mermaid_state": "Mermaid 狀態圖 (State)",
        "menu.diagrams.mermaid_er": "Mermaid 實體關係圖 (ER)",
        "menu.diagrams.mermaid_mindmap": "Mermaid 心智圖 (Mindmap)",

        "menu.diagrams.puml_sequence": "PlantUML 時序圖 (Sequence)",
        "menu.diagrams.puml_flowchart": "PlantUML 流程圖 (Flowchart)",
        "menu.diagrams.puml_class": "PlantUML 類別圖 (Class)",
        "menu.diagrams.puml_state": "PlantUML 狀態圖 (State)",
        "menu.diagrams.puml_er": "PlantUML 實體關係圖 (ER)",

        "menu.diagrams.dot_digraph": "Graphviz 有向圖 (digraph)",
        "menu.diagrams.dot_graph": "Graphviz 無向圖 (graph)",

        "menu.help.show": "顯示完整說明手冊 (Help)",
        "menu.help.logo_reference": "Editor LOGO 指令參考",
        "menu.help.logo_workspace": "Procedures 與變數",

        "transform.tohant": "繁體中文",
        "transform.tohans": "簡體中文",
        "transform.tolatin": "拉丁轉寫",
        "transform.hiragana": "平假名",
        "transform.katakana": "片假名",
        "transform.romaji": "羅馬字",
        "transform.cjk_spacing": "CJK 空格",
    ]
}
