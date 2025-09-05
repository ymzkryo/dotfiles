#!/bin/bash

# 引数チェック
if [ $# -ne 2 ]; then
    echo "Usage: $0 <keyword> <target_dir>"
    echo "keyword: daily_report | oatmeal | coffee | run"
    exit 1
fi

keyword="$1"
target_dir="$2"
inbox_dir="$(pwd)/00000_INBOX"

# キーワードに対応するファイル名パターンを定義
case "$keyword" in
    daily_report)
        pattern="*-daily_report.md"
        ;;
    oatmeal)
        pattern="*-オートミール.md"
        ;;
    coffee)
        pattern="*-バターコーヒー.md"
        ;;
    run)
        pattern="*-ランニング.md"
        ;;
    *)
        echo "Unknown keyword: $keyword"
        exit 1
        ;;
esac

# 対象ファイル一覧を取得
files=$(find "$inbox_dir" -maxdepth 1 -type f -name "$pattern")

# ファイルが存在しない場合
if [ -z "$files" ]; then
    echo "No files found matching pattern: $pattern in $inbox_dir"
    exit 0
fi

# ターゲットディレクトリを作成
target_path=$(realpath "$target_dir")
mkdir -p "$target_path"

# ファイルを一つずつ移動
for file in $files; do
    mv "$file" "$target_path/"
    echo "Moved $(basename "$file") to $target_path/"
done
