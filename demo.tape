# VHS tape for recording the ll (interactive bookmark selector) demo
Output demo/ll_demo.gif

Set Shell "bash"
Set FontSize 16
Set Width 1100
Set Height 600
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

# Source the demo RC file (hidden setup)
Hide
Type "source ./demo_rc.sh"
Enter
Sleep 2s
Show

# Type ll and run
Type "ll"
Sleep 500ms
Enter
Sleep 3s

# Navigate down through bookmarks
Down
Sleep 1.5s
Down
Sleep 1.5s

# Select one
Enter
Sleep 1s

# Show we landed
Type "pwd"
Enter
Sleep 2s
