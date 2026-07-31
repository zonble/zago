import Foundation

/// Traditional Chinese (zh_TW) translation table for zago text editor.
public struct TraditionalChineseStrings {
    public static let table: [String: String] = [
        // Help Bar Labels
        "help.get_help":   "輔助說明",
        "help.menu":       "主選單",
        "help.cancel":     "取消",
        "help.write_out":  "寫入檔案",
        "help.read_file":  "讀入檔案",
        "help.prev_pg":    "前往上頁",
        "help.cut_text":   "剪下文字",
        "help.cur_pos":    "游標位置",
        "help.exit":       "離開",
        "help.justify":    "重排文字",
        "help.where_is":   "搜尋",
        "help.next_pg":    "前往下頁",
        "help.uncut_text": "貼上文字",
        "help.to_spell":   "拼字檢查",
        "help.table_exit": "離開表格",
        "help.next_cell":  "下個儲存格",
        "help.prev_cell":  "上個儲存格",
        "help.cell_width": "寬度 -/+",
        "help.cell_height": "高度 -/+",
        "help.center_text": "置中對齊",
        "help.clear_cell": "清空儲存格",
        "help.select_text": "選取文字",
        "chrome.end_of_file": "檔案結尾",

        // Prompts
        "prompt.write_name": "寫出檔案名稱：",
        "prompt.confirm_exit_save": "是否儲存已修改的內容？(回答 \"N\" 將捨棄修改)：",
        "prompt.confirm_reload": "檔案已於外部變更，是否重新載入？(回答 \"N\" 將保留當前修改)：",
        "prompt.search": "搜尋",
        "prompt.insert_file": "欲插入之檔案：",
        "prompt.edit_spelled_word": "修改拼錯字詞 \"%@\"：",
        "prompt.logo": "❯ ",
        "prompt.fill_text": "填滿文字：",
        "prompt.table_dimensions": "表格列 欄 寬：",
        "prompt.goto_line": "請輸入列號與欄號：",
        "textview.footer": "  上/下：捲動   PgUp/PgDn：翻頁   Home/End：跳轉   其他按鍵：關閉",
        "logoview.reference_title": "  zago - LOGO 指令參考",
        "logoview.workspace_title": "  zago - LOGO 工作區",
        "logoref.content": """
  LOGO 指令參考
  ================================================================

  Editor LOGO 是編輯器巨集語言。指令會操作目前文字 buffer、
  游標、選取範圍、表格、狀態列與多 buffer。

  基本編輯
    TYPE text                    插入文字或運算結果
    SHOW expr                    顯示狀態訊息
    MAKE "name value             定義變數
    :name                        讀取變數
    MOVE UP|DOWN|LEFT|RIGHT      移動游標
    GOTO row [col]               跳到 1-based 列/欄
    FIND "query                  搜尋文字

  形狀與表格
    BOX text [align] [style]     插入有框文字方塊
    DRAWBOX width height [style] 在畫布上覆蓋繪製方框
    LINE [len] [style] [arrow]   繪製/連接水平線
    VLINE [height] [style]       繪製/連接垂直線
    FILL text                    填滿選取範圍或方框內部
    TABLE [rows cols width]      插入表格
    TABLE BORDER style           設定預設框線樣式
    TABLE NEXTSTYLE              切換下一個框線樣式
    邊界：BOX/DRAWBOX 限制為寬 3...200、高 2...100；
          LINE 限制為 1...200，VLINE 限制為 1...100。

  框線樣式
    single, double, round, double-round, ascii, markdown

  類海龜繪圖
    PD / PU                      落筆/提筆
    FD n / BK n                  前進/後退
    RT angle / LT angle          右轉/左轉
    SETHEADING angle|direction   設定方向
    HEADING                      回傳目前方向
    Turtle 會停在上/左最小邊界；從邊界往外移動不會繪製。
    往下/右移動可延伸 buffer。

  控制流程與 procedure
    REPEAT n [ commands ]        重複執行；# 與 repcount 從 1 開始
    IF test [ commands ]         條件執行
    IFELSE test [ yes ] [ no ]   條件分支
    FOREACH list [ commands ]    逐項執行，? 是目前項目
    TO name :arg ... END         定義 user procedure
    OUTPUT value                 從 reporter procedure 回傳值
    STOP                         從 procedure 返回

  常用 predicate
    PROCEDURE? name              built-in 或 user-defined procedure 是否存在
    PRIMITIVE? name              built-in primitive 是否存在
    DEFINED? name                user-defined procedure 是否存在
    NAME? name                   變數是否存在
    WORD? LIST? ARRAY? NUMBER? EMPTY?

  資料操作
    WORD, LIST, SENTENCE, FIRST, LAST, BUTFIRST, BUTLAST
    ITEM, PICK, REMOVE, REMDUP, SPLIT, SORT
    ARRAY, MDARRAY, SETITEM, MDSETITEM, ARRAYTOLIST, LISTTOARRAY

  數學與邏輯
    SUM, DIFFERENCE, MINUS, PRODUCT, QUOTIENT, POWER
    REMAINDER, MODULO, ABS, INT, ROUND, SQRT, EXP, LN, LOG10
    SIN, COS, TAN, ARCTAN, RADSIN, RADCOS, RADTAN, RADARCTAN
    LESS? GREATER? LESSEQUAL? GREATEREQUAL? EQUAL? NOTEQUAL?
    TRUE, FALSE, AND, OR, XOR, NOT

  Buffer 與檔案
    BUFFERS, BUFFER, CLEARBUFFER, GETLINE, SETLINE, BUFFERTEXT
    ROW, COL, LINECOUNT, FILENAME, MODIFIED?

  所有 primitive alias
""",
        "logoworkspace.heading": "  LOGO 工作區",
        "logoworkspace.procedures": "  User Procedures:",
        "logoworkspace.variables": "  變數：",
        "logoworkspace.none": "    （無）",
        "logoworkspace.tip_1": "  在 LOGO 腳本中可用 PROCEDURE?、PRIMITIVE?、DEFINED?、NAME?",
        "logoworkspace.tip_2": "  做可程式化的存在檢查。",

        // Status Messages
        "status.mark_set": "標記已設定",
        "status.mark_unset": "標記已取消",
        "status.cut_text": "已剪下文字",
        "status.cut_one_line": "已剪下 1 行",
        "status.uncut_text": "已貼上文字",
        "status.clipboard_empty": "剪貼簿為空",
        "status.no_selection": "沒有選取範圍",
        "status.no_block_marked": "未標記區塊",
        "status.block_mark_canvas_only": "區塊標記只可在 canvas mode 使用",
        "status.copied_text": "已複製文字",
        "status.copied_block": "已複製區塊",
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
        "status.undo_performed": "已完成復原",
        "status.unknown_command": "未知指令",
        "status.cancelled": "已取消",
        "status.cancelled_exit": "已取消離開",
        "status.cancelled_search": "已取消搜尋",
        "status.cancelled_insert": "已取消插入檔案",
        "status.spell_check_skipped": "跳過拼字檢查",
        "status.word_kept": "保留原字詞",
        "status.no_misspelled": "[ 未發現拼錯字詞 ]",
        "status.file_reloaded": "[ 已從磁碟重新載入檔案 ]",
        "status.kept_local": "[ 已保留本地修改 ]",
        "status.logo_executed": "[ 已執行 LOGO 巨集腳本 ]",
        "status.logo_evaluated": "[ LOGO 腳本求值成功 ]",
        "status.filled_block": "[ 已填滿區塊 ]",
        "status.goto_disabled_in_table_mode": "[ 表格模式下停用 GOTO ]",
        "status.default_border": "[ 預設框線：%@ ]",
        "status.unknown_border_style": "[ 未知的框線樣式：%@ ]",
        "status.unknown_table_border": "[ 未知的表格框線：%@ ]",
        "status.disabled_in_table_mode": "[ 表格模式下停用 %@ ]",
        "status.frame_mode_exited": "[ 已退出框線模式 ]",
        "status.frame_mode_disabled_in_table_mode": "[ 表格模式下停用框線模式 ]",
        "status.frame_mode": "[ 框線模式 ]",
        "status.table_mode_exited": "[ 已退出表格模式 ]",
        "status.table_mode_disabled_in_frame_mode": "[ 框線模式下停用表格模式 ]",
        "status.table_mode_hint": "(M+T 退出 | Tab 移動)",
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
        "menu.tools.eval_logo": "Eval LOGO 腳本\t^Q",
        "menu.edit.copy": "複製\tM+W",

        // Help Viewer (HelpView.swift)
        "helpview.title": "  zago - 完整指令與快速鍵說明手冊",
        "helpview.header": "  快捷鍵與指令對照表",
        "helpview.sec_nav": "  游標移動與導航：",
        "helpview.nav_1": "    ^F / 右方向鍵      游標向前移動一個字元",
        "helpview.nav_2": "    ^B / 左方向鍵      游標向後移動一個字元",
        "helpview.nav_3": "    ^P / 上方向鍵      游標移動至上一行",
        "helpview.nav_4": "    ^N / 下方向鍵      游標移動至下一行",
        "helpview.nav_5": "    ^A / Home          游標移動至當前行行首",
        "helpview.nav_6": "    ^E / End           游標移動至當前行行尾",
        "helpview.nav_7": "    ^V / F8 / PgDn     向下捲動一頁文字",
        "helpview.nav_8": "    ^Y / F7 / PgUp     向上捲動一頁文字",

        "helpview.sec_edit": "  編輯、剪貼與選取：",
        "helpview.edit_1": "    ^D / Delete        刪除游標所在位置的字元",
        "helpview.edit_2": "    Shift+方向鍵       延伸 text/table 選取範圍",
        "helpview.edit_3": "    ^K / F9            剪下選取文字、canvas 區塊或目前行",
        "helpview.edit_4": "    ^U / F10           貼上最後剪下的文字至游標位置",
        "helpview.edit_5": "    ^I / Tab           於游標位置插入 Tab 縮排",

        "helpview.sec_search": "  搜尋與段落重排對齊：",
        "helpview.search_1": "    ^W / F6            文字搜尋（不區分大小寫）",
        "helpview.search_2": "    ^J                 重排與自動對齊當前段落（中英文混排）",
        "helpview.search_3": "    ^L                 重新繪製 Terminal 畫面",
        "helpview.search_4": "    ^C / F11           顯示當前游標與行列位置資訊",
        "helpview.search_5": "    ^T / F12           啟動拼字檢查工具",

        "helpview.sec_file": "  檔案與 Buffer 操作指令：",
        "helpview.file_1": "    ^S                 儲存目前檔案；^O / F3 WriteOut (選擇路徑)",
        "helpview.file_2": "    ^R / F5            Read file (插入外部檔案內容至當前 Buffer)",
        "helpview.file_3": "    ^N                 New Buffer (開啟新的空白 Buffer)",
        "helpview.file_4": "    M+. / M+>          Next Buffer (切換至下一個 Buffer)",
        "helpview.file_5": "    M+, / M+<          Previous Buffer (切換至上一個 Buffer)",
        "helpview.file_6": "    ^X / F2            關閉當前 Buffer / 退出編輯器",
        "helpview.file_7": "    F4                 儲存並關閉編輯器（Save & Exit）",
        "helpview.file_8": "    ^G                 取消目前選取範圍或 canvas mark",
        "helpview.file_10": "    ^^ (Canvas)        設定/取消矩形 canvas 區塊標記",
        "helpview.file_9": "    F1 / M+M / ^M      開啟/關閉頂端選單列 (Menu Bar)",

        "helpview.sec_logo": "  LOGO 巨集語言與海龜繪圖指令：",
        "helpview.logo_1": "    Esc / M+:          呼叫指令 Prompt",
        "helpview.logo_2": "    TYPE / PRINT       於游標位置輸出/插入指定文字",
        "helpview.logo_3": "    MAKE / VAR / :var  宣告變數與進行四則運算求值",
        "helpview.logo_4": "    REPEAT / TO / EXEC 迴圈執行與自訂程序定義呼叫",
        "helpview.logo_5": "    BOX / DRAWBOX / LINE / VLINE 畫框與橫豎分隔線（支援自動交點融合）",
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
        "menu.shapes": "形狀(S)",
        "menu.borders": "框線(O)",
        "menu.tools": "工具(T)",
        "menu.diagrams": "圖表(D)",
        "menu.help": "說明(H)",

        // Menu Bar Items
        "menu.file.new": "新建空白頁\t^N",
        "menu.file.open": "讀取外部檔案…\t^R",
        "menu.file.save": "儲存檔案\t^S",
        "menu.file.write_out": "另存寫出…\t^O",
        "menu.file.save_exit": "儲存並關閉\tF4",
        "menu.file.exit": "關閉頁面 / 退出\t^X",
        "menu.file.edit_config": "編輯設定檔(C)",
        "menu.file.reload_config": "重新載入設定檔(R)",

        "menu.edit.undo": "復原\t^Z",
        "menu.edit.mark": "標記 Canvas 區塊\t^^",
        "menu.edit.cut": "剪下\t^K",
        "menu.edit.paste": "貼上\t^U",
        "menu.edit.delete_line": "刪除整行\t^BS",
        "menu.edit.search": "搜尋文字…\t^W",
        "menu.edit.spell": "拼字檢查…\t^T",
        "menu.edit.goto_line": "跳轉至指定行…\t^/",
        "menu.edit.justify": "重排與對齊段落\t^J",
        "menu.edit.text_editing_mode": "文字編輯模式",
        "menu.edit.canvas_mode": "畫布模式\tM+V",
        "menu.edit.table_editing_mode": "表格編輯模式\tM+T",

        "menu.buffer.next": "下一個 Buffer\tM+.",
        "menu.buffer.prev": "上一個 Buffer\tM+,",

        "menu.shapes.box": "方框",
        "menu.shapes.draw_box": "繪製方框",
        "menu.shapes.line": "水平線",
        "menu.shapes.vline": "垂直線",
        "menu.shapes.table": "表格",
        "menu.shapes.frame_mode": "框線模式",
        "menu.shapes.fill": "填滿區域",

        "menu.borders.single": "單線",
        "menu.borders.double": "雙線",
        "menu.borders.round": "圓角",
        "menu.borders.double_round": "雙線圓角",
        "menu.borders.ascii": "ASCII",
        "menu.borders.markdown": "Markdown",
        "menu.borders.next_style": "下一個風格\tM+S",

        "menu.tools.logo": "指令 Prompt...\tEsc",
        "menu.tools.line_numbers": "切換行號顯示",
        "menu.tools.ruler": "切換 WordStar 標尺規列",
        "menu.tools.wrap_80": "自動換行：80",
        "menu.tools.wrap_60": "自動換行：60",
        "menu.tools.wrap_40": "自動換行：40",
        "menu.tools.wrap_reset": "自動換行：動態",

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
        "menu.help.logo_reference": "LOGO 指令參考",
        "menu.help.logo_workspace": "Procedures 與變數"
    ]
}
