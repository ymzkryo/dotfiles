#!/usr/bin/env python3
"""編集者レビューの出力を比較して、切り出しが指摘を落としていないかを判定する。

~/memo の 2026-10-02「編集者レビュー skill の再構築」で決めた同値の定義に従う。

  - 指摘件数が ±2 件に収まる
  - [must] の本数が一致する
  - 切り出し前に出た [must] が、切り出し後に 1 件も落ちていない  ← 本番の判定

LLM の出力は非決定的なので完全一致は取れない。だから「前に出た指摘が出なくなること」
を見る。件数の増減より取りこぼしが危ない。

usage:
  compare_reviews.py count <out.md> ...              ラベルを数える
  compare_reviews.py diff <before_dir> <after_dir>   取りこぼしを見る
"""
import pathlib
import re
import sys

LABELS = ("[must]", "[imo]", "[nits]")
REVIEWERS = ("claude", "codex", "agy")


# ラベルの前に付く装飾。レビュアーごとに違う形で返ってくる。
#   claude: "- **[must]** ..."     codex: "- [must] ..."
#   agy:    "#### `[must]` ..."
# 行頭を全部剥がしてから判定しないと、agy が 0 件に見えて取りこぼしを検出できない。
_DECOR = "-*#`> \t　"


def findings(text: str) -> dict[str, list[str]]:
    """ラベル付きの指摘を拾う。ラベルは行頭に置くよう指示してある。"""
    out: dict[str, list[str]] = {label: [] for label in LABELS}
    for line in text.splitlines():
        stripped = line.lstrip(_DECOR)
        for label in LABELS:
            if stripped.startswith(label):
                claim = stripped[len(label):].lstrip(_DECOR).strip()
                out[label].append(claim)
                break
    return out


def key(claim: str) -> str:
    """表現の揺れを吸収した突き合わせ用のキー。

    同じ指摘が言い換えで返ってくるので、記号と空白を落として先頭だけを見る。
    完全一致は取れないため、取りこぼしの候補を出すところまでが仕事。
    """
    s = re.sub(r"[`*_「」『』（）()\[\]【】、。・:：,.\s]", "", claim)
    return s[:24]


def load(d: pathlib.Path) -> dict[str, dict[str, list[str]]]:
    got = {}
    for r in REVIEWERS:
        p = d / f"out-{r}.md"
        got[r] = findings(p.read_text(errors="replace")) if p.exists() else {l: [] for l in LABELS}
    return got


def cmd_count(paths: list[str]) -> int:
    for path in paths:
        f = findings(pathlib.Path(path).read_text(errors="replace"))
        total = sum(len(v) for v in f.values())
        counts = "  ".join(f"{l} {len(f[l]):2d}" for l in LABELS)
        print(f"  {pathlib.Path(path).name:18s} 計 {total:3d}   {counts}")
    return 0


def cmd_diff(before: str, after: str) -> int:
    b, a = load(pathlib.Path(before)), load(pathlib.Path(after))
    failed = False

    for r in REVIEWERS:
        bt = sum(len(v) for v in b[r].values())
        at = sum(len(v) for v in a[r].values())
        bm, am = len(b[r]["[must]"]), len(a[r]["[must]"])

        print(f"\n  == {r} ==")
        print(f"    指摘件数   {bt:3d} -> {at:3d}   差 {at - bt:+d}" + ("" if abs(at - bt) <= 2 else "   ★ ±2 を超えた"))
        print(f"    [must]     {bm:3d} -> {am:3d}" + ("" if bm == am else "   ★ 本数が一致しない"))
        if abs(at - bt) > 2 or bm != am:
            failed = True

        after_keys = {key(c) for c in a[r]["[must]"]}
        lost = [c for c in b[r]["[must]"] if key(c) not in after_keys]
        if lost:
            failed = True
            print(f"    ★ 落ちた [must] {len(lost)} 件（本番の判定）")
            for c in lost:
                print(f"       - {c[:72]}")
        else:
            print("    落ちた [must] なし")

    print("\n  " + ("切り出し失敗。上の ★ を解消すること" if failed else "同値とみなせる"))
    return 1 if failed else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(2)
    mode = sys.argv[1]
    if mode == "count":
        raise SystemExit(cmd_count(sys.argv[2:]))
    if mode == "diff" and len(sys.argv) == 4:
        raise SystemExit(cmd_diff(sys.argv[2], sys.argv[3]))
    print(__doc__)
    raise SystemExit(2)
