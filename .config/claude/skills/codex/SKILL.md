---
name: codex
description: |
  Codex CLI（OpenAI）を使用してコードや文言の相談・レビューを行う。
  トリガー: "codex", "codexと相談", "codexに聞いて", "codexでレビュー"
  使用場面: (1) 文言・メッセージの検討、(2) コードレビュー、
  (3) 設計の相談、(4) バグ調査、(5) 解消困難な問題の調査
allowed-tools: Bash(codex *), Read, Glob, Grep
---

# Codex

Codex CLIを使用してコードレビュー・分析を実行するスキル。

## 実行コマンド

```sh
codex exec -s read-only -C "$PWD" "<request>" < /dev/null
```

> **`< /dev/null` は必須です。** 付けないと `codex exec` は
> `Reading additional input from stdin...` と表示して**標準入力を永遠に待ちます**。
> プロンプトを引数で渡していても stdin を読もうとするため、非対話で呼ぶと必ずハングします。
> 2026-10-09 に 35 分ハングさせて特定しました（CPU 0%、ネットワーク接続なし、出力 0 バイト）。
> `-a never` では解決しません（`-a` は `codex review` のオプション）。
>
> **git リポジトリ外で使うなら `--skip-git-repo-check` も必要です。**
> stdin を閉じただけだと、今度は
> `Not inside a trusted directory and --skip-git-repo-check was not specified.`
> で実行を拒否されます。すぐ終了するので一見成功に見えますが、**出力の中身を見ないと
> 気づけません**（実際にこれで誤判定しました）。
>
> | 条件 | 結果 |
> | --- | --- |
> | stdin 開放 | 無限待ち |
> | `< /dev/null` のみ・repo 外 | 拒否されて即終了 |
> | `< /dev/null` + `--skip-git-repo-check`・repo 外 | 正常 |
> | `< /dev/null` のみ・**repo 内** | 正常 |
>
> **`--full-auto` は使えません。** codex-cli 0.149.1 で廃止されており、指定すると
> `error: unexpected argument '--full-auto' found` で即座に失敗します。
> `--sandbox` は `-s`、`--cd` は `-C` として現行も有効です。

## プロンプトのルール

**重要**: codexに渡すリクエストには、以下の指示を必ず含めること：

> 「確認や質問は不要です。具体的な提案・修正案・コード例まで
> 自主的に出力してください。」

## パラメータ

| パラメータ | 説明 |
| --- | --- |
| `-s read-only` | 読み取り専用サンドボックス（分析・レビュー用）。`--sandbox` の短縮形 |
| `-C <dir>` | 対象プロジェクトのディレクトリ。`--cd` の短縮形 |
| `"<request>"` | 依頼内容（日本語可） |
| `-m <model>` | モデルを指定する（任意） |
| `< /dev/null` | **必須。** stdin を閉じないとハングする（上記参照） |
| `--skip-git-repo-check` | git リポジトリ外を対象にするとき必須。付けないと拒否される |

`-s` に渡せるのは `read-only` / `workspace-write` / `danger-full-access` の3つです。
レビューや調査では `read-only` のままにしてください（codex にファイルを書かせない）。

## 長文リクエストの安全な渡し方

依頼文に引用符が含まれる場合、ヒアドキュメントを使用すると安全：

```sh
REQUEST=$(cat <<'EOF'
ここに依頼文を記載...
確認や質問は不要です。具体的な提案・修正案・コード例まで
自主的に出力してください。
EOF
)
codex exec -s read-only -C /path/to/project "$REQUEST" < /dev/null
```

## レビュー用途には `codex review` もある

`codex exec` に自前のレビュー依頼を書く代わりに、専用サブコマンドが使えます。

```sh
codex -a never review --uncommitted
codex -a never review --base "$(git symbolic-ref --short refs/remotes/origin/HEAD)"
codex -a never review --commit <SHA>
```

| | `codex exec` | `codex review` |
| --- | --- | --- |
| 用途 | 任意の依頼 | コードレビュー専用 |
| 対象指定 | プロンプトに書く | `--uncommitted` / `--base` / `--commit` |
| stdin | **`< /dev/null` が必須** | 不要 |
| 承認 | オプション無し | `-a never` で非対話 |

`--base` にブランチ名を渡すときは `origin/main` を決め打ちにしないこと
（リポジトリによって `master` や `develop`）。

## codex へ渡す資料の置き場所

codex はサンドボックスの作業ルート（`-C` で指定したディレクトリ）の中しか読めません。
会話の中にしかない情報や、リポジトリ外のファイルを判断材料にしてほしい場合は、
**`local/` 配下へ書き出してから渡します**（`.gitignore` 済みなのでコミットに乗りません）。

```sh
mkdir -p local/codex-review
cat > local/codex-review/source-1-<資料名>.md <<'EOF'
（判断材料をここに書き出す）
EOF
```

**scratchpad など git リポジトリ外へ資料を置いた場合は `--skip-git-repo-check` を
忘れないこと。** リポジトリ内の `local/` に置けば不要です。

依頼文の中で「この資料が一次情報である」ことと、各資料の性質（正確なもの／
誤変換を含むものなど）を明示すると、突き合わせの精度が上がります。

## 実行手順

1. ユーザーから依頼内容を受け取る
2. 対象プロジェクトのディレクトリを特定する（デフォルト: 現在のワーキングディレクトリ）
3. **プロンプト末尾に「確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。」を必ず追加する**
4. 判断材料がリポジトリ外にある場合は `local/` へ書き出す（→ 上記）
5. 上記コマンド形式で Codex を実行する
6. 結果をユーザーに報告する

### 実行時間について

**codex は出力をまとめて最後に出す**ため、実行中は途中経過が一切見えません。
規模によっては 7 分を超えます。長くかかりそうな依頼では、はじめから
`run_in_background: true` で投げて、完了通知を待つほうが確実です。

**ただし「無反応だから正常」とは限りません。** `< /dev/null` を付け忘れると
同じく出力 0 バイトのまま止まり、見た目で区別できません。
10 分を超えて出力が 0 バイトのままなら、次を確認してください。

- 出力の先頭に `Reading additional input from stdin...` が出ていないか
  → 出ていれば `< /dev/null` の付け忘れ
- すぐ終了したのに結果が無い場合、出力に
  `Not inside a trusted directory` が無いか
  → 出ていれば `--skip-git-repo-check` の付け忘れ
- `ps -o stat,%cpu -p <pid>` が `S` / `0.0%` で、`lsof -p <pid>` に TCP が無いか
  → API へ到達する前に止まっている

この誤認で 35 分待ったことがあります。「応答がないのは正常」という思い込みが
診断を妨げました。

## 使用例

### コードレビュー

```sh
codex exec -s read-only -C /path/to/project \
  "このプロジェクトのコードをレビューして、改善点を指摘してください。
  確認や質問は不要です。具体的な提案・修正案・コード例まで自主的に出力してください。" < /dev/null
```

### バグ調査

```sh
codex exec -s read-only -C /path/to/project \
  "認証処理でエラーが発生する原因を調査してください。
  確認や質問は不要です。原因の特定と具体的な修正案まで自主的に出力してください。" < /dev/null
```

### 設計相談

```sh
codex exec -s read-only -C /path/to/project \
  "このプロジェクトのアーキテクチャを分析して説明してください。
  確認や質問は不要です。改善提案まで自主的に出力してください。" < /dev/null
```
