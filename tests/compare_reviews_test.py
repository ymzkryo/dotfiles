#!/usr/bin/env python3
"""editorial-review の scripts/compare_reviews.py のテスト。

    python3 tests/compare_reviews_test.py

追加の依存は使わない（標準ライブラリの unittest だけ）。
"""
import importlib.util
import pathlib
import unittest

_SCRIPT = (pathlib.Path(__file__).resolve().parent.parent
           / ".config/claude/skills/editorial-review/scripts/compare_reviews.py")
_spec = importlib.util.spec_from_file_location("compare_reviews", _SCRIPT)
cr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cr)


def counts(text: str) -> dict[str, int]:
    return {label: len(v) for label, v in cr.findings(text).items()}


class FindingsTest(unittest.TestCase):
    def test_レビュアーごとの装飾を剥がして数える(self):
        text = "\n".join([
            "- **[must]** claude の形",
            "- [imo] codex の形",
            "#### `[nits]` agy の形",
            "[must] **codex の装飾なしの形**",
        ])
        self.assertEqual(counts(text), {"[must]": 2, "[imo]": 1, "[nits]": 1})

    def test_太字の中に番号が入る形も数える(self):
        # 2026-10-13 の claude 3 周目がこの形で、0 件と数えていた
        text = "\n".join([
            "**1. [must] 「あと 3 行足すと落ちます」の計算が違います**",
            "**2. [imo] 見出しが弱いです**",
            "### 3. [nits] 表記ゆれ",
        ])
        self.assertEqual(counts(text), {"[must]": 1, "[imo]": 1, "[nits]": 1})

    def test_タイトル案より後ろの補足は数えない(self):
        # 2026-10-10 の claude 対照が末尾の補足まで数えて 16 件になっていた（正しくは 15）
        text = "\n".join([
            "## 指摘一覧",
            "### [must] 本物の指摘",
            "## タイトル案",
            "1. 案その 1",
            "`[imo]` のいつかやるの件は、事実誤認ではないので外しました。",
        ])
        self.assertEqual(counts(text), {"[must]": 1, "[imo]": 0, "[nits]": 0})

    def test_太字の見出しのタイトル案でも止まる(self):
        text = "\n".join([
            "[must] **本物の指摘**",
            "**タイトル案**",
            "[imo] 補足",
        ])
        self.assertEqual(counts(text), {"[must]": 1, "[imo]": 0, "[nits]": 0})

    def test_本文中に出てくるラベルは数えない(self):
        text = "迷ったら [imo] に倒してください。"
        self.assertEqual(counts(text), {"[must]": 0, "[imo]": 0, "[nits]": 0})


class ReviewersTest(unittest.TestCase):
    def test_diff_の対象に_copilot_を含める(self):
        self.assertIn("copilot", cr.REVIEWERS)


if __name__ == "__main__":
    unittest.main()
