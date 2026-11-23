#!/usr/bin/env bash
# lib/terminal.wap: clear_screen() writes ANSI's erase-display and cursor-home, so a frame redraws in place (the snake
# sample). Run it with bash test/wap/test_terminal.sh
source "$(dirname "$0")/compile.sh"

# the characters of an output, the escapes and line ends visible
shown() { od -An -c | xargs; }
check "clear_screen erases the terminal and homes the cursor" "$(ran clear_line 'use terminal
clear_screen()
print("frame")' | shown)" "$(printf '\033[2J\033[H\nframe\n' | shown)"
exit $((failures > 0))
