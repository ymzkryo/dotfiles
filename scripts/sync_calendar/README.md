# カレンダー同期スクリプト

会社のGoogleカレンダーから個人のGoogleカレンダーに予定を自動コピーするシェルスクリプトです。

## 必要なもの

- macOS
- icalBuddy（`brew install ical-buddy`）
- Python 3

## 設定方法

1. **カレンダー名の確認**

   以下のコマンドでカレンダー一覧を表示：
   ```bash
   ~/dotfiles/scripts/sync_calendar/list_calendars.sh
   ```

   または、macOSのカレンダーアプリで左サイドバーのカレンダー名を確認

2. **設定ファイルの作成**

   テンプレートをコピー：
   ```bash
   mkdir -p ~/dotfiles/private/.config/sync_calendar
   cp ~/dotfiles/private/.config/sync_calendar/sync_calendar.conf.example ~/dotfiles/private/.config/sync_calendar/sync_calendar.conf
   ```

3. **設定ファイルの編集**

   ```bash
   vim ~/dotfiles/private/.config/sync_calendar/sync_calendar.conf
   ```

   以下の部分を実際のカレンダー名に変更：

   **単一カレンダーの場合（従来形式）:**
   ```bash
   WORK_CALENDAR="your-work-email@company.com"  # ← あなたの会社カレンダー名
   PERSONAL_CALENDAR="your-personal-email@gmail.com"  # ← あなたの個人カレンダー名
   DAYS_AHEAD=7  # 今日から7日先まで同期
   ```

   **複数カレンダーの場合（新形式）:**
   ```bash
   # 複数の同期元カレンダーを配列で指定
   # 形式: "カレンダー名:プレフィックス"
   WORK_CALENDARS=(
       "work@company.com:dmm"           # → [dmm] タイトル
       "project@example.com:project"    # → [project] タイトル
       "team@company.com:team"          # → [team] タイトル
   )
   PERSONAL_CALENDAR="your-personal-email@gmail.com"
   DAYS_AHEAD=7
   ```

   - `WORK_CALENDARS` を使うと複数の同期元を設定可能
   - 各エントリは `カレンダー名:プレフィックス` の形式
   - プレフィックスは同期先でのタイトルに `[プレフィックス]` として付与される
   - `WORK_CALENDAR`（単数形）も後方互換性のためサポート

4. **シンボリックリンクの作成**

   ```bash
   ln -sf ~/dotfiles/private/.config/sync_calendar/sync_calendar.conf ~/.config/sync_calendar.conf
   ```

   **注意:** `private/` は個人用のサブモジュールで、設定ファイルを含みます

## 使い方

### 手動実行
```bash
~/dotfiles/scripts/sync_calendar/sync_calendar.sh
```

実行すると：
- 会社カレンダーから今日以降の予定を取得（繰り返し予定にも対応）
- 個人カレンダーに予定をコピー（タイトルに `[dmm]` プレフィックスを追加）
- 既に同じ予定があればスキップ（重複チェック）
- macOS通知で結果を表示

**例:**
- 会社カレンダー: `定例会議`
- 個人カレンダー: `[dmm] 定例会議`

### 自動実行（定期実行）

#### 方法1: launchd を使用（推奨）

1. plistファイルを作成：
```bash
cat > ~/Library/LaunchAgents/com.user.calendar-sync.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.calendar-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/ymzkryo/dotfiles/scripts/sync_calendar/sync_calendar.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>1800</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/ymzkryo/Library/Logs/calendar_sync.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/ymzkryo/Library/Logs/calendar_sync.stderr.log</string>
</dict>
</plist>
EOF
```

2. 読み込み：
```bash
launchctl load ~/Library/LaunchAgents/com.user.calendar-sync.plist
```

3. 確認：
```bash
launchctl list | grep calendar-sync
```

4. 停止・削除（必要な場合）：
```bash
launchctl unload ~/Library/LaunchAgents/com.user.calendar-sync.plist
```

**実行間隔の変更:**
- `StartInterval` の値を秒単位で指定
- 例: `1800` = 30分おき、`3600` = 1時間おき

#### 方法2: cron を使用

```bash
crontab -e
```

以下を追加（30分おきに実行）：
```
*/30 * * * * /Users/ymzkryo/dotfiles/scripts/sync_calendar/sync_calendar.sh
```

## ログ確認

```bash
tail -f ~/Library/Logs/calendar_sync.log
```

## トラブルシューティング

### カレンダーが見つからない
- カレンダー名が正確か確認
- カレンダーアプリで該当のGoogleアカウントが有効か確認

### アクセス許可エラー
1. システム設定 → プライバシーとセキュリティ → 自動化
2. 「ターミナル」または「シェル」に「カレンダー」へのアクセスを許可

### 予定が同期されない
- ログファイルを確認: `cat ~/Library/Logs/calendar_sync.log`
- 手動実行してエラーメッセージを確認

## カスタマイズ

- **タイトルの変更**: スクリプト内の `eventTitle` に接頭辞を追加
- **全日イベントのみ同期**: `isAllDay` でフィルタリング
- **特定キーワードの除外**: タイトルで条件分岐を追加

## 注意事項

- 既存の予定は変更されません（タイトルと開始時刻が同じ場合はスキップ）
- 削除の同期はしません（手動削除が必要）
- プライベートな予定も全てコピーされるので注意
