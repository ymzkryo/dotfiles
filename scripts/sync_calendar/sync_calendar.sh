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

# 複数カレンダー対応：WORK_CALENDARSが未設定の場合、WORK_CALENDARから生成
if [ ${#WORK_CALENDARS[@]} -eq 0 ] && [ -n "$WORK_CALENDAR" ]; then
    # 後方互換性：単一カレンダーの場合はデフォルトプレフィックス "dmm" を使用
    WORK_CALENDARS=("${WORK_CALENDAR}:dmm")
fi

# 必須設定の確認
if [ ${#WORK_CALENDARS[@]} -eq 0 ] || [ -z "$PERSONAL_CALENDAR" ]; then
    echo "エラー: WORK_CALENDARS（または WORK_CALENDAR）と PERSONAL_CALENDAR を設定してください"
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

# WORK_CALENDARSを環境変数としてエクスポート（改行区切り）
export WORK_CALENDARS_STR
WORK_CALENDARS_STR=$(printf '%s\n' "${WORK_CALENDARS[@]}")

# Pythonスクリプトを使用
python3 <<PYTHON
import subprocess
import re
import os
from datetime import datetime, timedelta

# 環境変数から設定を取得
WORK_CALENDARS_STR = os.environ.get("WORK_CALENDARS_STR", "")
PERSONAL_CALENDAR = "${PERSONAL_CALENDAR}"
DAYS_AHEAD = "${DAYS_AHEAD}"

# カレンダー設定をパース（形式: "カレンダー名:プレフィックス"）
calendars = []
for line in WORK_CALENDARS_STR.strip().split('\n'):
    if not line:
        continue
    if ':' in line:
        cal_name, prefix = line.rsplit(':', 1)
        calendars.append({'name': cal_name, 'prefix': prefix})
    else:
        # プレフィックスが指定されていない場合はカレンダー名から生成
        calendars.append({'name': line, 'prefix': line.split('@')[0]})

if not calendars:
    print("エラー: 同期元カレンダーが設定されていません")
    exit(1)

print(f"同期元カレンダー: {len(calendars)}件", flush=True)
for cal in calendars:
    print(f"  - {cal['name']} (プレフィックス: [{cal['prefix']}])", flush=True)

# 全カレンダーから予定を取得
all_events = []

for cal in calendars:
    cal_name = cal['name']
    prefix = cal['prefix']

    # icalBuddyでカレンダーから予定を取得
    cmd = ["icalBuddy", "-nc", "-iep", "title,datetime", "-df", "%Y-%m-%d", "-tf", "%H:%M", "-ic", cal_name, f"eventsToday+{DAYS_AHEAD}"]
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0 or not result.stdout.strip():
        print(f"  {cal_name}: 0件", flush=True)
        continue

    # 予定をパース
    lines = result.stdout.strip().split('\n')
    cal_events = []
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
                    elif date_part == 'day after tomorrow':
                        event_date = (datetime.now() + timedelta(days=2)).strftime('%Y-%m-%d')
                    else:
                        event_date = date_part

                    cal_events.append({
                        'title': title,
                        'date': event_date,
                        'start_time': start_time,
                        'end_time': end_time,
                        'prefix': prefix
                    })

        i += 1

    print(f"  {cal_name}: {len(cal_events)}件", flush=True)
    all_events.extend(cal_events)

print(f"取得できた予定: 合計{len(all_events)}件", flush=True)

if not all_events:
    subprocess.run(["osascript", "-e", 'display notification "新しい予定はありませんでした" with title "カレンダー同期完了"'])
    exit(0)

# 各予定を個人カレンダーにコピー
copied_count = 0
skipped_count = 0

for event in all_events:
    title = event['title']
    prefix = event['prefix']
    new_title = f"[{prefix}] {title}"
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
            make new event with properties {{summary:"{escaped_title}", start date:startDateTime, end date:endDateTime, description:"[カレンダー同期]"}}
        end tell
        return "COPIED"
    end if
end tell
'''

    try:
        result = subprocess.run(["osascript", "-e", applescript], capture_output=True, text=True, timeout=10)
        if "COPIED" in result.stdout:
            copied_count += 1
            print(f"コピー: [{prefix}] {title} ({event_date} {start_time}-{end_time})", flush=True)
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
