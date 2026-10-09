---
name: codex
description: |
  Codex CLI（OpenAI）を使用してコードや文言の相談・レビューを行う。
  トリガー: "codex", "codexと相談", "codexに聞いて", "codexでレビュー"
  使用場面: (1) 文言・メッセージの検討、(2) コードレビュー、
  (3) 設計の相談、(4) バグ調査、(5) 解消困難な問題の調査
allowed-tools: Bash(codex exec -s read-only *), Bash(codex -s read-only *), Bash(git check-ignore *), Bash(git symbolic-ref *), Bash(git rev-parse *), Bash(pgrep *), Bash(ps *), Read, Write, Glob, Grep
---

# Codex

Codex CLI を使用してコードレビュー・分析を実行するスキル。

**このファイルのコマンドは codex-cli 0.154.0 で実際に実行して確認したものです。**
オプションの位置は `--help` の記載だけでは判断できません（グローバルオプションが
サブコマンドのヘルプに出ないため）。形を変える場合は必ず実行して確かめてください。

## 実行コマンド

**依頼文はファイルへ書き出し、stdin から渡します。**

```sh
codex exec -s read-only -C "$DIR" -o "$ANSWER_FILE" - < "$REQUEST_FILE"
```

`-` を置くと codex はプロンプトを stdin から読みます。この形には利点が 3 つあります。

- **`< /dev/null` が不要。** stdin がプロンプト本体になるので、stdin 待ちが起きません
- **シェルの展開・クォート事故が起きない。** `$HOME`・バッククォート・`EOF`・引用符を
  含む依頼文がそのまま渡ります（実測確認済み）
- **引数長の上限に当たらない。** 長文の依頼文を引数に載せません

`$DIR` / `$REQUEST_FILE` / `$ANSWER_FILE` は**実際の値に置き換えてください。**
`<...>` のような山括弧のまま実行すると、シェルがリダイレクトとして解釈して
構文エラーになります。

### 依頼文を引数で渡す場合（短文のみ）

```sh
codex exec -s read-only -C "$DIR" "$REQUEST" < /dev/null
```

**引数で渡すときは `< /dev/null` が必須です。** 付けないと `codex exec` は
`Reading additional input from stdin...` を出して**標準入力を永遠に待ちます**。
プロンプトを引数で渡していても stdin を読もうとするためです。

依頼文に `$`・バッククォート・引用符・単独行の `EOF` が含まれる場合は、
引数で渡さずファイル経由（上記）にしてください。シェルが展開・実行してしまいます。

### git リポジトリ外を対象にする場合

```sh
codex exec -s read-only --skip-git-repo-check -C "$DIR" - < "$REQUEST_FILE"
```

`--skip-git-repo-check` が必要になるのは、**`-C` に渡したディレクトリ自体が
git リポジトリ外のとき**です（資料の置き場所とは無関係）。付けないと
`Not inside a trusted directory and --skip-git-repo-check was not specified.`
で拒否され、**exit 1** を返します。

`codex review` にはこのオプションがありません（`codex exec` / `codex exec review` のみ）。
つまり **`codex review` は git リポジトリ外では使えません。**

## オプション

| オプション | 説明 |
| --- | --- |
| `-s read-only` | 読み取り専用サンドボックス。`--sandbox` の短縮形 |
| `-C <dir>` | 対象プロジェクトのディレクトリ。`--cd` の短縮形 |
| `-o <file>` | 最終回答だけをファイルへ書き出す。`--output-last-message` の短縮形 |
| `-m <model>` | モデルを指定する（任意） |
| `--skip-git-repo-check` | `-C` が git リポジトリ外のとき必要（上記参照） |

`-s` に渡せるのは `read-only` / `workspace-write` / `danger-full-access` の3つです。
**レビューや調査では `read-only` のままにしてください。**

> **`-s danger-full-access` / `--dangerously-bypass-approvals-and-sandbox` /
> `--dangerously-bypass-hook-trust` は使わないこと。** レビューや調査に書き込み権限は
> 不要で、これらを付けると codex がファイルを書き換えられます。

**`--full-auto` は使えません。** 現行版では廃止されており、指定すると
`error: unexpected argument '--full-auto' found` で即座に失敗します。

### オプションを置く位置

**`-s` / `-C` / `-a` は置ける場所が決まっています。** 間違えるとパースエラーです。

| 形 | 可否 |
| --- | --- |
| `codex exec -s read-only -C <dir> ...` | ✅ |
| `codex -s read-only -a never review ...` | ✅（サブコマンドより**前**） |
| `codex -s read-only exec review ...` | ✅（同じく前） |
| `codex review -a never ...` / `codex exec -a never ...` | ❌ `unexpected argument '-a'` |
| `codex review -C <dir> ...` | ❌ `unexpected argument '-C'` |
| `codex exec review -s read-only ...` | ❌ `unexpected argument '-s'` |

`-a never`（`--ask-for-approval never`）は**トップレベル `codex` のオプション**で、
`review` にも `exec` にもありません。stdin 待ちとは無関係なので、`-a` を付けても
ハングは解消しません。

## プロンプトのルール

依頼文の末尾には次の一文を必ず含めます。

> 「確認や質問は不要です。具体的な提案・修正案・コード例まで
> 自主的に出力してください。」

**ただし `codex review` / `codex exec review` に `--uncommitted` / `--base` /
`--commit` を付ける場合は、この定型文を渡せません。** 対象指定オプションは
プロンプト引数と排他で、両方渡すと **exit 2** で失敗します。

```
error: the argument '--uncommitted' cannot be used with '[PROMPT]'
```

追加の指示を出したいレビューは `codex exec` を使ってください。

## レビュー用途のサブコマンド

`codex exec` に自前のレビュー依頼を書く代わりに、専用サブコマンドが使えます。
**`codex exec review` のほうが上位互換です。**

```sh
codex -s read-only exec review --uncommitted
codex -s read-only exec review --commit "$SHA"
```

| | `codex exec` | `codex review` | `codex exec review` |
| --- | --- | --- | --- |
| 用途 | 任意の依頼 | コードレビュー専用 | コードレビュー専用 |
| 対象指定 | プロンプトに書く | `--uncommitted` / `--base` / `--commit` | 同左 |
| プロンプト | 必須 | 対象指定と**排他** | 対象指定と**排他** |
| stdin | 引数渡しなら `< /dev/null` 必須 | 待たない | 待たない |
| 作業ディレクトリ | `-C` | **指定不可**（トップレベル `-C` か事前 `cd`） | 同左 |
| `--skip-git-repo-check` | ○ | **✗** | ○ |
| `-o` / `-m` / `--json` | ○ | **✗** | ○ |

### ベースブランチの解決

**`origin/main` を決め打ちにしないこと。** リポジトリによって `master` や `develop` です。
**解決結果を変数に入れ、空なら実行を止めてください。**

```sh
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || base=
if [ -z "$base" ]; then
  for c in origin/main origin/master origin/develop; do
    if git rev-parse --verify -q "$c" >/dev/null; then base=$c; break; fi
  done
fi
[ -n "$base" ] || { echo "ベースブランチを解決できません"; exit 1; }
codex -s read-only exec review --base "$base"
```

`--base ""` は**エラーにならずセッションが開始します**。空のまま渡すと、意図しない
対象を静かにレビューします。`git rev-parse --abbrev-ref origin/HEAD` に差し替えても
`origin/HEAD` 未設定なら同じく失敗するので、**フォールバック連鎖が必要**です。

`--short refs/remotes/origin/HEAD` の出力は `origin/master` のように
`origin/` が付いた形で、そのまま `--base` に渡せます。

## codex へ渡す資料の置き場所

会話の中にしかない情報を判断材料にしてほしい場合は、ファイルへ書き出してから
パスを伝えます。**書き出しには Write ツールを使い、`cat > <file> <<'EOF'` の形は
使わないこと。** 資料に単独行の `EOF` が含まれるとそこでヒアドキュメントが終端し、
続きが親シェルのコマンドとして実行されます（bash / zsh / sh / dash で再現）。

**書き出し先は scratchpad を使ってください。** リポジトリ内へ置く場合は、先に
`git check-ignore "$DIR"` で無視されるか確認します。`local/` は無視されている
保証がなく（このリポジトリでは exit 1 で、そもそも存在しません）、コミットに
混入します。

**`-C` の外も読めます。** 「作業ルートの中しか読めない」わけではないので、
リポジトリ外のパスを渡しても参照できます。その代わり **read-only でも
機密ファイルに手が届きます**（書き込みはブロックされます）。`.env` / `*.pem` /
`~/.ssh` / `~/.aws` などを依頼文・資料・参照パスに含めないこと。

**資料は外部（OpenAI）へ送られます。** 認証情報や個人情報は書き出さないこと。
使い終わったら削除します。

依頼文の中で「この資料が一次情報である」ことと、各資料の性質（正確なもの／
誤変換を含むものなど）を明示すると、突き合わせの精度が上がります。

## 実行手順

1. ユーザーから依頼内容を受け取る
2. 対象ディレクトリ `$DIR` を決める（既定: 現在のワーキングディレクトリ）
3. `git -C "$DIR" rev-parse --is-inside-work-tree` で git リポジトリ内か判定し、
   外なら `--skip-git-repo-check` を足す
4. 依頼文を作り（末尾に上記の定型文を含める）、Write ツールで scratchpad へ
   `$REQUEST_FILE` として書き出す
5. `codex exec -s read-only -C "$DIR" -o "$ANSWER_FILE" - < "$REQUEST_FILE"` を実行する。
   7 分を超えそうな依頼は `run_in_background: true` で投げる（下記）
6. **終了コードを確認する。** 0 以外なら stderr の内容とあわせてそのまま報告する
7. 結果をユーザーに報告し、`$REQUEST_FILE` を削除する

### 実行時間と出力の読み方

**stdout と stderr は完全に分かれています。**

| | 内容 | 出方 |
| --- | --- | --- |
| stdout | 最終回答のみ | 最後にまとめて |
| stderr | バナー・進行ログ・MCP エラー・stdin 通知 | 実行中に即座に |

診断は **stderr** を見てください。stdout には進行状況が一生出ません。
`-o` を付けておけば、最終回答だけをファイルで受け取れます。

**Bash ツールのタイムアウトは既定 120 秒・上限 600 秒です。** 素朴に前景で実行すると
2 分で打ち切られ、その状態はハングと区別しづらいです。**10 分を超えそうなら
`run_in_background: true` 一択**にしてください。

### 止まっているときの切り分け

**`Reading additional input from stdin...` が出ていること自体は異常ではありません。**
引数渡しで `< /dev/null` を付けた正常系でも stderr に出ます。
メッセージの有無ではなく「**その先へ進んでいるか**」で判別します。

| 状態 | stderr | stdout | プロセス | 終了コード |
| --- | --- | --- | --- | --- |
| **stdin 待ち** | 当該 1 行・**39 バイトで停止** | 0 バイト | 生存 | — |
| **正常** | 直後に `OpenAI Codex v...` 以降のバナーが続く | 最後にまとめて | 完走 | 0 |
| **repo 外で拒否** | バナー無しで `Not inside a trusted directory` | 0 バイト | 即終了 | **1** |

- **stdin 待ちだった場合** → `pkill -f 'codex exec'` で止め、ファイル渡し（`-` + stdin）
  か `< /dev/null` を付けて再実行する
- **PID が必要な場合** → `PID=$(pgrep -f 'codex exec' | head -n 1)` で取得してから
  `ps -o stat,%cpu -p "$PID"` を見る
- **即終了して結果が無い場合** → まず終了コードを見る。1 なら repo 外の拒否、
  2 なら引数の組み合わせ違反（対象指定とプロンプトの併用など）

## 使用例

いずれも依頼文を `$REQUEST_FILE` へ書き出してから実行します。

### コードレビュー

```sh
codex exec -s read-only -C "$DIR" -o "$ANSWER_FILE" - < "$REQUEST_FILE"
```

依頼文の例:

```
このプロジェクトのコードをレビューして、改善点を指摘してください。
確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。
```

### 差分のレビュー

```sh
codex -s read-only exec review --uncommitted
```

### バグ調査・設計相談

同じ形で、依頼文だけを差し替えます。

```
認証処理でエラーが発生する原因を調査してください。
確認や質問は不要です。原因の特定と具体的な修正案まで自主的に出力してください。
```
