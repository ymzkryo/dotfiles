---
description: 手元のコードをreviewerエージェントでセルフレビューし、指摘に基づいて自動修正するループ
argument-hint: [レビュー対象] [reviewer名 or heavy]
---

以下の手順を順番に実行してください。

## ステップ1: 引数の解釈

$ARGUMENTS を以下のルールで解釈してください：
- 第一引数: レビュー対象（省略時は `diff` = 現在のunstaged changes + untracked files）
- 第二引数: reviewer名 または `heavy`（省略時はデフォルトセットを並列実行）

### レビュー対象の指定方法
- 指定なし / `diff`: `git diff` + `git ls-files --others --exclude-standard` で新規ファイルも取得
- `staged`: `git diff --cached`
- `branch` または `ブランチ`: `git diff origin/main...HEAD`
- `PR #123` または `pr 123`: `gh pr diff 123`
- その他: そのまま渡す

### reviewerセット

#### デフォルト（省略時 — 5並列）
- `reviewer` - Claude自身による詳細レビュー
- `codex-reviewer` - Codex CLIを使ったレビュー
- `copilot-reviewer` - GitHub Copilot CLIを使ったレビュー
- `simplify-reviewer` - 可読性・一貫性・保守性に特化したレビュー
- `security-reviewer` - セキュリティに特化したレビュー

#### heavy（全reviewer — 7並列）
`heavy` を指定すると以下の全reviewerを並列実行する：
- `reviewer` - Claude自身による詳細レビュー
- `codex-reviewer` - Codex CLIを使ったレビュー
- `copilot-reviewer` - GitHub Copilot CLIを使ったレビュー
- `simplify-reviewer` - 可読性・一貫性・保守性に特化したレビュー
- `security-reviewer` - セキュリティに特化したレビュー
- `performance-reviewer` - パフォーマンスに特化したレビュー
- `test-reviewer` - テスト品質に特化したレビュー

#### 個別指定
特定のreviewer名を指定すると、そのreviewerのみ実行する。
利用可能なreviewer名は上記 heavy セットの一覧を参照。

reviewer名が上記のいずれにも一致しない場合は、エラーとしてユーザーに利用可能なreviewer名を案内してください。

## ステップ2: レビュー実行

- 個別のreviewer名が指定された場合: そのreviewerのエージェントを起動し、レビュー対象の情報を渡してコードレビューを実行する
- `heavy` が指定された場合: 全7reviewerのエージェントを**同時に並列起動**し、レビュー対象の情報を渡してコードレビューを実行する
- 省略された場合: デフォルト5reviewerのエージェントを**同時に並列起動**し、レビュー対象の情報を渡してコードレビューを実行する

## ステップ3: レビュー修正

すべてのレビューが完了したら、/fix-review-comments スキルを実行して、レビュー指摘に対応してください。
