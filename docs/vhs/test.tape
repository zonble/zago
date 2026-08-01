# Output demo.gif
Output demo.mp4

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 800
# Set CornerRadius 10
Set Padding 20
Set Theme "Catppuccin Mocha"

Type "zago new.md"
Sleep 500ms
Enter
Sleep 500ms
Type "# welcome to zago"
Enter
Enter
Sleep 500ms
Type `Let's work on a new file!`
Sleep 500ms
Enter
Enter

Type "```"
Enter
Escape
Type `BOX "zago - terminal text editing and diagrams" 56`
Enter
Down
Down
Enter
Enter
Enter

Escape
Type `foreach ["📝 Text Mode" "🎨 Canvas Mode" "⏎ Drawing Commands"] [box ? double]`
Sleep 500ms
Enter
Sleep 500ms

Escape
Type `GOTO 8 10`
Enter
Sleep 500ms
Escape
Type `VLINE`
Enter
Sleep 500ms

Escape
Type `GOTO 8 24`
Enter
Sleep 500ms
Escape
Type `VLINE DOUBLE`
Sleep 500ms
Enter
Sleep 500ms

Escape
Type `GOTO 8 44`
Enter
Sleep 500ms
Escape
Type `VLINE ASCII ARROW`
Sleep 500ms
Enter

Escape
Type `GOTO 13 60`
Sleep 500ms
Enter
Sleep 500ms
Enter

Type "```"
Enter
Escape
Type `repeat 10 [type "- " :# " zago rocks! 🔥" nl]`
Sleep 500ms
Enter
Sleep 500ms

Escape
Sleep 500ms
Type `pd seth right repeat 10 [fd 4 ifelse :# % 2 == 0 [left][right]]`
Sleep 500ms
Enter
Sleep 500ms

Sleep 2000ms
