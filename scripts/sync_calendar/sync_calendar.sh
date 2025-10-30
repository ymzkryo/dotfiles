#!/bin/bash

# カレンダー同期スクリプト（icalBuddy + Python使用）
# 会社のGoogleカレンダーから個人のGoogleカレンダーに予定をコピー

# 設定ファイルのパス
CONFIG_FILE="$HOME/.config/sync_calendar.conf"

# 設定ファイルの読み込み
if [ ! -f "$CONFIG_FILE" ]; then
    echo "エラー: 設定ファイルが見つかりません: $CONFIG_FILE"
    echo ""
    echo "以下の手順で設定してください："
    echo "  1. mkdir -p ~/dotfiles/private/.config"
    echo "  2. cp ~/dotfiles/private/.config/sync_calendar.conf.example ~/dotfiles/private/.config/sync_calendar.conf"
    echo "  3. vim ~/dotfiles/private/.config/sync_calendar.conf"
    echo "  4. ln -sf ~/dotfiles/private/.config/sync_calendar.conf ~/.config/sync_calendar.conf"
    exit 1
fi

# 設定を読み込み
source "$CONFIG_FILE"

# 必須設定の確認
if [ -z "$WORK_CALENDAR" ] || [ -z "$PERSONAL_CALENDAR" ]; then
    echo "エラー: WORK_CALENDAR と PERSONAL_CALENDAR を設定してください"
    exit 1
fi

# デフォルト値
DAYS_AHEAD=${DAYS_AHEAD:-7}

# ログファイル
LOG_FILE="$HOME/Library/Logs/calendar_sync.log"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== カレンダー同期開始 ==="

# Pythonスクリプトを使用
python3 <<PYTHON
import subprocess
import re
import os
from datetime import datetime, timedelta

# 環境変数から設定を取得
WORK_CALENDAR = "${WORK_CALENDAR}"
PERSONAL_CALENDAR = "${PERSONAL_CALENDAR}"
DAYS_AHEAD = "${DAYS_AHEAD}"

# icalBuddyで会社カレンダーから予定を取得
cmd = ["icalBuddy", "-nc", "-iep", "title,datetime", "-df", "%Y-%m-%d", "-tf", "%H:%M", "-ic", WORK_CALENDAR, f"eventsToday+{DAYS_AHEAD}"]
result = subprocess.run(cmd, capture_output=True, text=True)

if result.returncode != 0 or not result.stdout.strip():
    print("取得できた予定: 0件")
    subprocess.run(["osascript", "-e", 'display notification "新しい予定はありませんでした" with title "カレンダー同期完了"'])
    exit(0)

# 予定をパース
lines = result.stdout.strip().split('\n')
events = []
i = 0

while i < len(lines):
    line = lines[i].strip()

    # 予定タイトル（• で始まる）
    if line.startswith('•'):
        title = line[1:].strip()

        # 次の行が日時情報
        if i + 1 < len(lines):
            i += 1
            datetime_line = lines[i].strip()

            # 日時をパース
            # 例: "today at 16:00 - 16:30"
            # 例: "2025-11-03 at 10:00 - 11:30"
            match = re.match(r'(.+?)\s+at\s+(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})', datetime_line)

            if match:
                date_part = match.group(1)
                start_time = match.group(2)
                end_time = match.group(3)

                # 日付を変換
                if date_part == 'today':
                    event_date = datetime.now().strftime('%Y-%m-%d')
                elif date_part == 'tomorrow':
                    event_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
                else:
                    event_date = date_part

                events.append({
                    'title': title,
                    'date': event_date,
                    'start_time': start_time,
                    'end_time': end_time
                })

    i += 1

print(f"取得できた予定: {len(events)}件", flush=True)

# 各予定を個人カレンダーにコピー
copied_count = 0
skipped_count = 0

for event in events:
    title = event['title']
    new_title = f"[dmm] {title}"
    event_date = event['date']
    start_time = event['start_time']
    end_time = event['end_time']

    # AppleScriptで個人カレンダーに追加
    # 特殊文字のエスケープ
    escaped_title = new_title.replace('"', '\\"')

    applescript = f'''
tell application "Calendar"
    set personalCal to first calendar whose name is "{PERSONAL_CALENDAR}"

    -- 開始・終了日時を設定
    set startDateTime to date "{event_date} {start_time}:00"
    set endDateTime to date "{event_date} {end_time}:00"

    -- 既存イベントをチェック
    set existingEvents to (every event of personalCal whose summary is "{escaped_title}" and start date is startDateTime)

    if (count of existingEvents) > 0 then
        return "SKIPPED"
    else
        tell personalCal
            make new event with properties {{summary:"{escaped_title}", start date:startDateTime, end date:endDateTime, description:"[会社カレンダーより同期]"}}
        end tell
        return "COPIED"
    end if
end tell
'''

    try:
        result = subprocess.run(["osascript", "-e", applescript], capture_output=True, text=True, timeout=10)
        if "COPIED" in result.stdout:
            copied_count += 1
            print(f"コピー: {title} ({event_date} {start_time}-{end_time})", flush=True)
        elif "SKIPPED" in result.stdout:
            skipped_count += 1
        elif result.returncode != 0:
            print(f"エラー: {title} - {result.stderr.strip()}", flush=True)
    except Exception as e:
        print(f"エラー: {title} - {e}", flush=True)

print(f"コピー: {copied_count}件, スキップ: {skipped_count}件", flush=True)

# 通知
if copied_count > 0:
    subprocess.run(["osascript", "-e", f'display notification "{copied_count}件の予定を同期しました" with title "カレンダー同期完了"'])
else:
    subprocess.run(["osascript", "-e", 'display notification "新しい予定はありませんでした" with title "カレンダー同期完了"'])

PYTHON

log "=== カレンダー同期終了 ==="
