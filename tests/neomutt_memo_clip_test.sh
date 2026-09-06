#!/bin/sh
# scripts/neomutt-memo-clip のテスト。
#
#   ./tests/neomutt_memo_clip_test.sh
#
# 実際の memo ディレクトリには一切触らない(MEMO_INBOX を一時ディレクトリへ向ける)。
# --translate のテストでは fake な ja を PATH に差し込み、ネットワークへは出ない。
#
# 追加の依存(bats 等)は使わない。POSIX sh だけで動く。

set -u

repo_root=$(cd "$(dirname "$0")/.." && pwd)
CLIP="$repo_root/scripts/neomutt-memo-clip"

work=$(mktemp -d "${TMPDIR:-/tmp}/clip_test.XXXXXX")
trap 'rm -rf "$work"' EXIT INT TERM

mkdir -p "$work/bin" "$work/inbox"
MEMO_INBOX="$work/inbox"
export MEMO_INBOX

pass=0
fail=0

ok() {
  pass=$((pass + 1))
  printf '  ok   %s\n' "$1"
}

ng() {
  fail=$((fail + 1))
  printf '  FAIL %s\n' "$1"
  shift
  for line in "$@"; do
    printf '       %s\n' "$line"
  done
}

assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else ng "$1" "期待: $2" "実際: $3"; fi
}

assert_contains() {
  case "$3" in
    *"$2"*) ok "$1" ;;
    *) ng "$1" "「$2」を含むはずだが含まれていない" "実際: $3" ;;
  esac
}

assert_not_contains() {
  case "$3" in
    *"$2"*) ng "$1" "「$2」を含んではいけないのに含まれている" "実際: $3" ;;
    *) ok "$1" ;;
  esac
}

# neomutt が pipe_decode で渡してくる形のメールを組み立てる
mail_with_subject() {
  printf 'From: %s\n' "${2:-山田 太郎 <taro@example.co.jp>}"
  printf 'To: Bob <bob@example.com>\n'
  printf 'Subject: %s\n' "$1"
  printf 'Date: Fri, 05 Sep 2026 18:30:00 +0900\n'
  printf 'Message-ID: <test@example.co.jp>\n'
  printf 'Content-Type: text/plain; charset=utf-8\n'
  printf '\n'
  printf '%s\n' "${3:-本文の1行目。
本文の2行目。}"
}

out=''
status=0
run_clip() {
  # run_clip <入力> [引数...]
  in=$1
  shift
  out=$(printf '%s' "$in" | "$CLIP" "$@" 2>&1)
  status=$?
}

saved_path() {
  printf '%s\n' "$out" | tail -1
}

echo '== scripts/neomutt-memo-clip =='

# ------------------------------------------------------------------------
echo '-- 基本 --'

rm -f "$MEMO_INBOX"/*
run_clip "$(mail_with_subject '【重要】9/10 の打ち合わせ資料について (Re: Q3)')"
assert_eq '保存に成功する' '0' "$status"

file=$(saved_path)
name=$(basename "$file")
content=$(cat "$file" 2>/dev/null)

assert_contains 'ファイル名に日付と mail が入る' "$(date '+%Y-%m-%d')-mail-" "$name"
assert_contains 'ファイル名にかな漢字がそのまま残る' '打ち合わせ資料について' "$name"
assert_not_contains 'ファイル名に全角の【】を使わない' '【' "$name"
assert_not_contains 'ファイル名に全角の】を使わない' '】' "$name"
assert_not_contains 'ファイル名にスラッシュを使わない' '9/10' "$name"
assert_not_contains 'ファイル名に半角スペースを使わない' ' ' "$name"
assert_not_contains 'ファイル名に丸括弧を使わない' '(' "$name"
assert_not_contains 'ファイル名にコロンを使わない' ':' "$name"
assert_contains 'スラッシュはハイフンになる' '9-10' "$name"

assert_contains '見出しは元の件名のまま(全角も残る)' '# 【重要】9/10 の打ち合わせ資料について (Re: Q3)' "$content"
assert_contains 'From が入る' '- From: 山田 太郎 <taro@example.co.jp>' "$content"
assert_contains 'To が入る' '- To: Bob <bob@example.com>' "$content"
assert_contains 'Date が入る' '- Date: Fri, 05 Sep 2026 18:30:00 +0900' "$content"
assert_contains 'Message-ID が入る' '- Message-ID: <test@example.co.jp>' "$content"
assert_contains 'Clipped が入る' '- Clipped: ' "$content"
assert_contains '本文が入る(1行目)' '本文の1行目。' "$content"
assert_contains '本文が入る(2行目)' '本文の2行目。' "$content"
assert_not_contains 'Content-Type は書き出さない' 'Content-Type' "$content"
assert_not_contains 'Cc が無ければ Cc 行を出さない' '- Cc:' "$content"

# ------------------------------------------------------------------------
echo '-- frontmatter (memo の規約) --'

# memo の Actions は INBOX のファイルに frontmatter を後付けしないので、
# ここで規約どおりのものを出せていないと validate_vault.py に弾かれ、
# organize_files.py にも拾われず INBOX に残り続ける。
rm -f "$MEMO_INBOX"/*
run_clip "$(mail_with_subject 'Re: 見積もりの件 (至急)')"
content=$(cat "$(saved_path)")
fm=$(printf '%s\n' "$content" | awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f {print}')

assert_contains 'frontmatter で始まる' '---' "$(printf '%s\n' "$content" | head -1)"
assert_contains 'title はダブルクォートで囲む' 'title: "Re: 見積もりの件 (至急)"' "$fm"
assert_contains 'date はクリップ日' "date: $(date '+%Y-%m-%d')" "$fm"
assert_contains 'tags は type/mail' 'tags: [type/mail]' "$fm"
assert_contains 'project は空文字' 'project: ""' "$fm"

# validate_vault.py は KEYS が揃っていることを見る
for k in title date status review_date due_date estimate project tags context; do
  assert_contains "frontmatter に $k がある" "$k:" "$fm"
done

# 「キー行の末尾に空白」で弾かれないこと
if printf '%s\n' "$fm" | LC_ALL=C grep -qE '^[A-Za-z_]+:[ \t]+$'; then
  ng '空のキー行の末尾に空白を置かない' "$(printf '%s\n' "$fm" | LC_ALL=C grep -nE '^[A-Za-z_]+:[ \t]+$')"
else
  ok '空のキー行の末尾に空白を置かない'
fi

# frontmatter の date はファイル名の日付と一致していなければならない
fn_date=$(basename "$(saved_path)" | cut -c1-10)
fm_date=$(printf '%s\n' "$fm" | awk -F': ' '/^date:/ {print $2}')
assert_eq 'date がファイル名の日付と一致する' "$fn_date" "$fm_date"

assert_contains 'frontmatter の後に見出しが来る' '# Re: 見積もりの件 (至急)' "$content"
assert_contains '本文は ## 本文 の下に置く' '## 本文' "$content"

# タグは環境変数で差し替えられる
rm -f "$MEMO_INBOX"/*
MEMO_CLIP_TAGS='type/meeting' run_clip "$(mail_with_subject '定例')"
assert_contains 'MEMO_CLIP_TAGS で tags を差し替えられる' 'tags: [type/meeting]' "$(cat "$(saved_path)")"

# 件名にダブルクォートやバックスラッシュが入っても frontmatter が壊れない
rm -f "$MEMO_INBOX"/*
run_clip "$(mail_with_subject 'say "hi" and C:\\path')"
fm=$(awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f {print}' "$(saved_path)")
assert_contains '件名のダブルクォートをエスケープする' '\"hi\"' "$fm"
assert_contains 'frontmatter は 1 行の title に収まる' 'title: "say' "$fm"
lines=$(printf '%s\n' "$fm" | grep -c '^title:')
assert_eq 'title 行は 1 行だけ' '1' "$lines"

# ------------------------------------------------------------------------
echo '-- ファイル名のサニタイズ --'

check_name() {
  # check_name <説明> <件名> <期待するスラッグ>
  rm -f "$MEMO_INBOX"/*
  run_clip "$(mail_with_subject "$2")"
  n=$(basename "$(saved_path)" .md)
  assert_eq "$1" "$(date '+%Y-%m-%d')-mail-$3" "$n"
}

# 展開されないこと自体がテスト対象なので、リテラルのまま渡す
# shellcheck disable=SC2016
check_name 'エスケープが要る記号をハイフンに潰す' 'a"b$(c)d`e`f;g|h&i' 'a-b-c-d-e-f-g-h-i'
check_name '全角スペースと中黒を潰す' '設計　メモ・改' '設計-メモ-改'
check_name 'バックスラッシュとアスタリスクを潰す' 'path\to *.log' 'path-to-log'
check_name 'ハイフンとアンダースコアは残す' 'daily_report-2026' 'daily_report-2026'
check_name '連続する記号は 1 個のハイフンにまとめる' 'a   ---   b' 'a-b'
check_name '前後の記号は落とす' '  ...hello...  ' 'hello'
check_name '件名が空なら no-subject' '' 'no-subject'
check_name '記号だけの件名も no-subject' '!!! ???' 'no-subject'

# 長い件名は切り詰める
rm -f "$MEMO_INBOX"/*
long=$(printf 'あ%.0s' $(seq 1 200))
run_clip "$(mail_with_subject "$long")"
n=$(basename "$(saved_path)" .md)
slug=${n#"$(date '+%Y-%m-%d')-mail-"}
chars=$(printf '%s' "$slug" | wc -m | tr -d ' ')
if [ "$chars" -le 50 ]; then
  ok "長い件名は 50 文字までに切る (実際 $chars 文字)"
else
  ng '長い件名は 50 文字までに切る' "$chars 文字あった"
fi

# ------------------------------------------------------------------------
echo '-- 件名がシェルに解釈されない --'

rm -f "$MEMO_INBOX"/* "$work/pwned"
run_clip "$(mail_with_subject "safe \$(touch $work/pwned) \`touch $work/pwned\`" 'A <a@b.c>' "body \$(touch $work/pwned)")"
if [ -e "$work/pwned" ]; then
  ng '件名や本文のコマンド置換が実行されない' "$work/pwned が作られてしまった"
else
  ok '件名や本文のコマンド置換が実行されない'
fi
assert_contains '本文のコマンド置換は文字列として保存される' 'touch' "$(cat "$(saved_path)")"

# ------------------------------------------------------------------------
echo '-- 折り返しヘッダ --'

rm -f "$MEMO_INBOX"/*
folded='From: A <a@example.com>
Subject: 折り返された
 長い件名です
Date: Fri, 05 Sep 2026 18:30:00 +0900

本文
'
run_clip "$folded"
assert_contains '折り返された件名を 1 行に戻す' '# 折り返された 長い件名です' "$(cat "$(saved_path)")"

# ------------------------------------------------------------------------
echo '-- 同名ファイル --'

rm -f "$MEMO_INBOX"/*
run_clip "$(mail_with_subject '同じ件名')"
first=$(saved_path)
run_clip "$(mail_with_subject '同じ件名')"
second=$(saved_path)
if [ "$first" != "$second" ]; then
  ok '同名があれば別ファイルにする(上書きしない)'
else
  ng '同名があれば別ファイルにする(上書きしない)' "同じパスに 2 回書いた: $first"
fi
assert_contains '2 つ目には連番が付く' '-2.md' "$second"
count=$(find "$MEMO_INBOX" -name '*.md' | wc -l | tr -d ' ')
assert_eq 'ファイルが 2 つできる' '2' "$count"

# ------------------------------------------------------------------------
echo '-- 異常系 --'

rm -f "$MEMO_INBOX"/*
run_clip ''
assert_eq '空入力は終了コード 65' '65' "$status"
assert_contains '空入力はエラーを出す' '入力が空' "$out"

run_clip 'ヘッダの無いただのテキスト'
assert_eq 'ヘッダが無ければ終了コード 65' '65' "$status"
assert_contains 'ヘッダが無ければエラーを出す' 'メールとして読めませんでした' "$out"

run_clip "$(mail_with_subject 'x')" --bogus
assert_eq '知らない引数は終了コード 64' '64' "$status"
assert_contains '知らない引数はエラーを出す' '知らない引数' "$out"

count=$(find "$MEMO_INBOX" -name '*.md' | wc -l | tr -d ' ')
assert_eq '異常系ではファイルを作らない' '0' "$count"

# ------------------------------------------------------------------------
echo '-- --translate --'

cat > "$work/bin/fake-ja" <<'FAKE_EOF'
#!/bin/sh
sed 's/^/[訳] /'
FAKE_EOF
chmod +x "$work/bin/fake-ja"

cat > "$work/bin/fail-ja" <<'FAKE_EOF'
#!/bin/sh
cat > /dev/null
echo 'ja: 翻訳に失敗しました' >&2
exit 1
FAKE_EOF
chmod +x "$work/bin/fail-ja"

PATH="$work/bin:$PATH"
export PATH

rm -f "$MEMO_INBOX"/*
JA_CLI_WRAPPER=fake-ja run_clip "$(mail_with_subject 'Hello' 'A <a@b.c>' 'first line
second line')" --translate
assert_eq '--translate は成功する' '0' "$status"
content=$(cat "$(saved_path)")
assert_contains '本文が翻訳されている(1行目)' '[訳] first line' "$content"
assert_contains '本文が翻訳されている(2行目)' '[訳] second line' "$content"
assert_contains '翻訳した旨を書き残す' '本文は ja で翻訳したもの' "$content"
assert_contains '件名は翻訳せず原文のまま' '# Hello' "$content"

rm -f "$MEMO_INBOX"/*
JA_CLI_WRAPPER=fail-ja run_clip "$(mail_with_subject 'Hello')" --translate
assert_eq '翻訳が失敗したら終了コード 70' '70' "$status"
assert_contains '翻訳失敗の旨を出す' '翻訳に失敗' "$out"
count=$(find "$MEMO_INBOX" -name '*.md' | wc -l | tr -d ' ')
assert_eq '翻訳が失敗したらファイルを作らない' '0' "$count"

# ------------------------------------------------------------------------
echo '-- 保存先の自動作成 --'

deep="$work/inbox-new/00000_INBOX"
rm -rf "$work/inbox-new"
out=$(printf '%s' "$(mail_with_subject 'dir test')" | MEMO_INBOX="$deep" "$CLIP" 2>&1)
status=$?
assert_eq '保存先が無ければ作る' '0' "$status"
if [ -f "$(printf '%s\n' "$out" | tail -1)" ]; then
  ok '作った保存先にファイルができる'
else
  ng '作った保存先にファイルができる' "$out"
fi

# ------------------------------------------------------------------------
# memo リポジトリがローカルにあるなら、本物の validate_vault.py に通す。
# 無ければ黙って飛ばす(このリポジトリ単体でもテストが通るように)。
VALIDATOR="$HOME/memo/.github/scripts/validate_vault.py"
if [ -f "$VALIDATOR" ] && command -v python3 >/dev/null 2>&1; then
  echo '-- memo の validate_vault.py による検証 --'
  rm -f "$MEMO_INBOX"/*
  run_clip "$(mail_with_subject '【重要】9/10 の打ち合わせ資料について (Re: Q3)')"
  run_clip "$(mail_with_subject 'plain english subject')"
  if result=$(python3 - "$VALIDATOR" "$MEMO_INBOX" <<'PYEOF'
import collections, importlib.util, sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("vv", sys.argv[1])
vv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vv)

target = Path(sys.argv[2])
issues = collections.defaultdict(list)
for f in sorted(target.rglob("*.md")):
    vv.validate(f, f.read_text(encoding="utf-8"), f.name, issues)
if issues:
    for k, v in issues.items():
        print(f"{k}: {v}")
    sys.exit(1)
PYEOF
  ); then
    ok 'memo の validate_vault.py が問題を報告しない'
  else
    ng 'memo の validate_vault.py が問題を報告しない' "$result"
  fi
else
  echo '-- memo の validate_vault.py が無いので飛ばす --'
fi

# ------------------------------------------------------------------------
printf '\n%s 件成功 / %s 件失敗\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
