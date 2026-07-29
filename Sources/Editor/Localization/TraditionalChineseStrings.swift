import Foundation

/// Traditional Chinese (zh_TW) translation table for se text editor.
public struct TraditionalChineseStrings {
    public static let table: [String: String] = [
        // Help Bar Labels
        "help.get_help":   "輔助說明",
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

        // Prompts
        "prompt.write_name": "寫出檔案名稱：",
        "prompt.confirm_exit_save": "是否儲存已修改的內容？(回答 \"N\" 將捨棄修改) [Y/N]：",
        "prompt.confirm_reload": "檔案已於外部變更，是否重新載入？(回答 \"N\" 將保留當前修改) [Y/N]：",
        "prompt.search": "搜尋",
        "prompt.insert_file": "欲插入之檔案：",
        "prompt.edit_spelled_word": "修改拼錯字詞 \"%@\"：",
        "prompt.logo": "❯ ",
        "prompt.goto_line": "請輸入列號與欄號：",

        // Status Messages
        "status.mark_set": "標記已設定",
        "status.mark_unset": "標記已取消",
        "status.cut_text": "已剪下文字",
        "status.cut_one_line": "已剪下 1 行",
        "status.uncut_text": "已貼上文字",
        "status.clipboard_empty": "剪貼簿為空",
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
        "menu.tools.eval_logo": "Eval LOGO 腳本\t^Q",

        // Help Viewer (HelpView.swift)
        "helpview.title": "  se - 完整指令與快速鍵說明手冊",
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
        "helpview.edit_2": "    ^^ (Ctrl+^)        設定/取消選取標記（啟動範圍選取）",
        "helpview.edit_3": "    ^K / F9            剪下選取文字（無標記時剪下整行）",
        "helpview.edit_4": "    ^U / F10           貼上最後剪下的文字至游標位置",
        "helpview.edit_5": "    ^I / Tab           於游標位置插入 Tab 縮排",

        "helpview.sec_search": "  搜尋與段落重排對齊：",
        "helpview.search_1": "    ^W / F6            文字搜尋（不區分大小寫）",
        "helpview.search_2": "    ^J                 重排與自動對齊當前段落（中英文混排）",
        "helpview.search_3": "    ^L                 重新繪製 Terminal 畫面",
        "helpview.search_4": "    ^C / F11           顯示當前游標與行列位置資訊",
        "helpview.search_5": "    ^T / F12           啟動拼字檢查工具",

        "helpview.sec_file": "  檔案與 Buffer 操作指令：",
        "helpview.file_1": "    ^O / ^S / F3       WriteOut (將 Buffer 儲存至檔案)",
        "helpview.file_2": "    ^R / F5            Read file (插入外部檔案內容至當前 Buffer)",
        "helpview.file_3": "    ^N                 New Buffer (開啟新的空白 Buffer)",
        "helpview.file_4": "    M+. / M+>          Next Buffer (切換至下一個 Buffer)",
        "helpview.file_5": "    M+, / M+<          Previous Buffer (切換至上一個 Buffer)",
        "helpview.file_6": "    ^X / F2            關閉當前 Buffer / 退出編輯器",
        "helpview.file_7": "    F4                 儲存並關閉編輯器（Save & Exit）",
        "helpview.file_8": "    ^G                 顯示本完整幫助說明頁面",
        "helpview.file_9": "    F1 / M+M / ^M      開啟/關閉頂端選單列 (Menu Bar)",

        "helpview.sec_logo": "  LOGO 巨集語言與海龜繪圖指令：",
        "helpview.logo_1": "    Esc / M+L / M+:    呼叫指令 Prompt",
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
        "msg.cursor_info": "第 %d/%d 行 (%d%%), 第 %d/%d 欄",
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
        "menu.search": "搜尋(S)",
        "menu.buffer": "Buffer(B)",
        "menu.tools": "工具(T)",
        "menu.help": "說明(H)",

        // Menu Bar Items
        "menu.file.new": "新建空白頁\t^N",
        "menu.file.open": "讀取外部檔案…\t^R",
        "menu.file.save": "儲存檔案\t^O",
        "menu.file.save_exit": "儲存並關閉\tF4",
        "menu.file.exit": "關閉頁面 / 退出\t^X",

        "menu.edit.undo": "復原\t^Z",
        "menu.edit.mark": "標記選取區\t^M",
        "menu.edit.cut": "剪下\t^K",
        "menu.edit.paste": "貼上\t^U",
        "menu.edit.delete_line": "刪除整行\t^BS",
        "menu.edit.justify": "重排與對齊段落\t^J",

        "menu.search.whereis": "搜尋文字…\t^W",
        "menu.search.spell": "拼字檢查…\t^T",
        "menu.search.goto_line": "跳轉至指定行…\t^/",

        "menu.buffer.next": "下一個 Buffer\tM+.",
        "menu.buffer.prev": "上一個 Buffer\tM+,",

        "menu.tools.logo": "指令 Prompt...\tEsc",
        "menu.tools.table_mode": "切換表格隔離模式\tM+T",
        "menu.tools.line_numbers": "切換行號顯示",
        "menu.tools.table_style": "切換預設表格風格\tM+S",
        "menu.tools.ruler": "切換 WordStar 標尺規列",
        "menu.tools.wrap_80": "自動換行：80",
        "menu.tools.wrap_60": "自動換行：60",
        "menu.tools.wrap_40": "自動換行：40",
        "menu.tools.wrap_reset": "自動換行：動態",

        "menu.help.show": "顯示完整說明手冊 (Help)\t^G"
    ]
}
