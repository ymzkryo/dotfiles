#!/bin/bash

# カレンダー同期スクリプト（icalBuddy + Python使用）
# 会社のGoogleカレンダーから個人のGoogleカレンダーに予定をコピー
#
# 使い方:
#   sync_calendar.sh              # 順方向同期（会社→個人）
#   sync_calendar.sh --reverse    # 逆方向同期（個人→会社）
#   sync_calendar.sh --dry-run    # 実行せずに確認（-n でも可）
#   sync_calendar.sh -r -n        # 逆方向のdry-run

# 引数の解析
MODE="forward"
DRY_RUN="false"

for arg in "$@"; do
    case $arg in
        --reverse|-r)
            MODE="reverse"
            ;;
        --dry-run|-n)
            DRY_RUN="true"
            ;;
    esac
done

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

if [ "$DRY_RUN" = "true" ]; then
    log "=== カレンダー同期開始（dry-run モード） ==="
else
    log "=== カレンダー同期開始 ==="
fi

export DRY_RUN

# ===== 順方向同期（会社→個人） =====
if [ "$MODE" = "forward" ]; then
    log "順方向同期（会社→個人）"

    # WORK_CALENDARSを環境変数としてエクスポート（改行区切り）
    export WORK_CALENDARS_STR
    WORK_CALENDARS_STR=$(printf '%s\n' "${WORK_CALENDARS[@]}")

    # 逆方向同期のタイトル（これを除外するため）
    export REVERSE_SYNC_TITLE="${REVERSE_SYNC_TITLE:-予定あり}"

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
DRY_RUN = os.environ.get("DRY_RUN", "false") == "true"
REVERSE_SYNC_TITLE = os.environ.get("REVERSE_SYNC_TITLE", "予定あり")

if DRY_RUN:
    print("【dry-run モード】実際の同期は行いません\n", flush=True)

# カレンダー設定をパース（形式: "カレンダー名:プレフィックス:逆方向同期フラグ"）
calendars = []
for line in WORK_CALENDARS_STR.strip().split('\n'):
    if not line:
        continue
    parts = line.split(':')
    if len(parts) >= 2:
        cal_name = parts[0]
        prefix = parts[1]
        # 3番目以降（逆方向同期フラグ）は無視
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

            # 逆方向同期で追加した予定は除外（循環同期を防ぐ）
            if title == REVERSE_SYNC_TITLE:
                i += 1
                continue

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

    if DRY_RUN:
        # dry-runモード: 実行せずに表示のみ
        print(f"  → [{prefix}] {title} ({event_date} {start_time}-{end_time})", flush=True)
        copied_count += 1
    else:
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

if DRY_RUN:
    print(f"\n同期予定: {copied_count}件", flush=True)
else:
    print(f"コピー: {copied_count}件, スキップ: {skipped_count}件", flush=True)
    # 通知
    if copied_count > 0:
        subprocess.run(["osascript", "-e", f'display notification "{copied_count}件の予定を同期しました" with title "カレンダー同期完了"'])
    else:
        subprocess.run(["osascript", "-e", 'display notification "新しい予定はありませんでした" with title "カレンダー同期完了"'])

PYTHON
fi

# ===== 逆方向同期（個人→会社） =====
if [ "$MODE" = "reverse" ]; then
    # WORK_CALENDARSから逆方向同期先を探す（形式: カレンダー名:プレフィックス:true）
    # 形式: "カレンダー名:プレフィックス" で、自分由来の予定を除外するために使用
    REVERSE_TARGETS=()
    REVERSE_TARGET_PREFIXES=()
    for entry in "${WORK_CALENDARS[@]}"; do
        IFS=':' read -r cal_name prefix reverse_flag <<< "$entry"
        if [ "$reverse_flag" = "true" ]; then
            REVERSE_TARGETS+=("$cal_name:$prefix")
        fi
    done

    # WORK_CALENDARSで見つからなければ、REVERSE_SYNC_TARGETを使用（後方互換性）
    if [ ${#REVERSE_TARGETS[@]} -eq 0 ] && [ -n "$REVERSE_SYNC_TARGET" ]; then
        REVERSE_TARGETS=("$REVERSE_SYNC_TARGET:")
    fi

    if [ ${#REVERSE_TARGETS[@]} -eq 0 ]; then
        echo "エラー: 逆方向同期先が設定されていません"
        echo "WORK_CALENDARSで ':true' を指定するか、REVERSE_SYNC_TARGETを設定してください"
        exit 1
    fi

    # ログ用にカレンダー名だけを抽出
    TARGET_NAMES=()
    for entry in "${REVERSE_TARGETS[@]}"; do
        IFS=':' read -r cal_name prefix <<< "$entry"
        TARGET_NAMES+=("$cal_name")
    done
    log "逆方向同期（個人→会社）: ${TARGET_NAMES[*]}"

    # デフォルト値
    REVERSE_SYNC_TITLE=${REVERSE_SYNC_TITLE:-"予定あり"}

    export REVERSE_SYNC_TARGETS_STR
    REVERSE_SYNC_TARGETS_STR=$(printf '%s\n' "${REVERSE_TARGETS[@]}")  # 形式: "カレンダー名:プレフィックス"
    export REVERSE_SYNC_TITLE

    export PERSONAL_CALENDAR
    export DAYS_AHEAD

    python3 <<'REVERSE_PYTHON'
import subprocess
import re
import os
from datetime import datetime, timedelta

# 環境変数から設定を取得
PERSONAL_CALENDAR = os.environ.get("PERSONAL_CALENDAR", "")
REVERSE_SYNC_TARGETS_STR = os.environ.get("REVERSE_SYNC_TARGETS_STR", "")
# 形式: "カレンダー名:プレフィックス" をパース
REVERSE_SYNC_TARGETS = []
for line in REVERSE_SYNC_TARGETS_STR.strip().split('\n'):
    if not line:
        continue
    if ':' in line:
        cal_name, own_prefix = line.split(':', 1)
        REVERSE_SYNC_TARGETS.append({'name': cal_name, 'own_prefix': own_prefix})
    else:
        REVERSE_SYNC_TARGETS.append({'name': line, 'own_prefix': ''})

REVERSE_SYNC_TITLE = os.environ.get("REVERSE_SYNC_TITLE", "予定あり")
DAYS_AHEAD = os.environ.get("DAYS_AHEAD", "7")
DRY_RUN = os.environ.get("DRY_RUN", "false") == "true"

if DRY_RUN:
    print("\n【dry-run モード】実際の同期は行いません", flush=True)

targets_str = ', '.join([t['name'] for t in REVERSE_SYNC_TARGETS])
print(f"\n逆方向同期: {PERSONAL_CALENDAR} → {targets_str}", flush=True)
print(f"タイトル: {REVERSE_SYNC_TITLE}", flush=True)
for t in REVERSE_SYNC_TARGETS:
    if t['own_prefix']:
        print(f"除外: [{t['own_prefix']}] プレフィックス付きの予定（{t['name']} への同期時）", flush=True)

# icalBuddyで個人カレンダーから予定を取得
cmd = ["icalBuddy", "-nc", "-iep", "title,datetime", "-df", "%Y-%m-%d", "-tf", "%H:%M", "-ic", PERSONAL_CALENDAR, f"eventsToday+{DAYS_AHEAD}"]
result = subprocess.run(cmd, capture_output=True, text=True)

if result.returncode != 0 or not result.stdout.strip():
    print("個人カレンダーの予定: 0件", flush=True)
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

        # プレフィックスのチェック（ターゲットごとの除外判定で使用）
        prefix_match = re.match(r'^\[(.+?)\]', title)
        source_prefix = prefix_match.group(1) if prefix_match else ''
        clean_title = title

        # 次の行が日時情報
        if i + 1 < len(lines):
            i += 1
            datetime_line = lines[i].strip()

            # 日時をパース
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

                events.append({
                    'title': clean_title,
                    'source_prefix': source_prefix,
                    'date': event_date,
                    'start_time': start_time,
                    'end_time': end_time
                })

    i += 1

print(f"個人カレンダーの予定（プレフィックス除く）: {len(events)}件", flush=True)

if not events:
    exit(0)

# 各ターゲットカレンダーに予定をコピー
total_copied = 0
total_skipped = 0

for target in REVERSE_SYNC_TARGETS:
    target_cal = target['name']
    target_own_prefix = target['own_prefix']

    print(f"\n--- {target_cal} への同期 ---", flush=True)
    if target_own_prefix:
        print(f"    （[{target_own_prefix}] 由来の予定は除外）", flush=True)

    copied_count = 0
    skipped_count = 0
    excluded_count = 0

    for event in events:
        # 自分由来の予定は除外
        if target_own_prefix and event['source_prefix'] == target_own_prefix:
            excluded_count += 1
            continue

        event_date = event['date']
        start_time = event['start_time']
        end_time = event['end_time']

        # 特殊文字のエスケープ
        escaped_title = REVERSE_SYNC_TITLE.replace('"', '\\"')
        escaped_cal = target_cal.replace('"', '\\"')

        applescript = f'''
tell application "Calendar"
    set workCal to first calendar whose name is "{escaped_cal}"

    -- 開始・終了日時を設定
    set startDateTime to date "{event_date} {start_time}:00"
    set endDateTime to date "{event_date} {end_time}:00"

    -- 既存イベントをチェック（同じタイトル・開始時刻・終了時刻）
    set existingEvents to (every event of workCal whose summary is "{escaped_title}" and start date is startDateTime and end date is endDateTime)

    if (count of existingEvents) > 0 then
        return "SKIPPED"
    else
        tell workCal
            make new event with properties {{summary:"{escaped_title}", start date:startDateTime, end date:endDateTime, description:"[個人カレンダーより同期]"}}
        end tell
        return "COPIED"
    end if
end tell
'''

        if DRY_RUN:
            # dry-runモード: 実行せずに表示のみ
            title = event['title']
            print(f"  → {REVERSE_SYNC_TITLE} ← {title} ({event_date} {start_time}-{end_time})", flush=True)
            copied_count += 1
        else:
            try:
                result = subprocess.run(["osascript", "-e", applescript], capture_output=True, text=True, timeout=10)
                if "COPIED" in result.stdout:
                    copied_count += 1
                    print(f"コピー: {REVERSE_SYNC_TITLE} ({event_date} {start_time}-{end_time})", flush=True)
                elif "SKIPPED" in result.stdout:
                    skipped_count += 1
                elif result.returncode != 0:
                    print(f"エラー: {result.stderr.strip()}", flush=True)
            except Exception as e:
                print(f"エラー: {e}", flush=True)

    if DRY_RUN:
        print(f"同期予定: {copied_count}件（除外: {excluded_count}件）", flush=True)
    else:
        print(f"コピー: {copied_count}件, スキップ: {skipped_count}件, 除外: {excluded_count}件", flush=True)

    total_copied += copied_count
    total_skipped += skipped_count

if not DRY_RUN and total_copied > 0:
    subprocess.run(["osascript", "-e", f'display notification "逆方向: {total_copied}件の予定を同期しました" with title "カレンダー同期完了"'])

REVERSE_PYTHON
fi

log "=== カレンダー同期終了 ==="
