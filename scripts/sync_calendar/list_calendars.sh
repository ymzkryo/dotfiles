#!/bin/bash

# カレンダー一覧を表示

echo "=== あなたのカレンダー一覧 ==="
echo ""

osascript <<'EOF'
tell application "Calendar"
    set calendarList to every calendar
    set output to ""
    repeat with cal in calendarList
        set calName to name of cal
        set output to output & "📅 " & calName & "\n"
    end repeat
    return output
end tell
EOF

echo ""
echo "上記のカレンダー名を sync_calendar.sh で使用してください"
