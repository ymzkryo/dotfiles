#!/usr/bin/env python3
"""編集者レビューの出力からラベルを数え、2 回の実行を並べて比べる。

count は機械で決まる。diff は**並べるだけ**で、同じ指摘かどうかの判定は人がやる。

**なぜ機械で判定しないか。** LLM は同じ指摘を毎回違う言い方で返す。実測では
codex が「README の引用に個人パスが残っています」と「個人のディレクトリ構成が
引用に残っています」を別の回で返した。同じ指摘だが文字列は一致しない。
前方一致や類似度で寄せると、**取りこぼしを見逃すか、無いものを取りこぼしと言う**。
どちらも判定を信用できなくする。

**本数の一致だけでは足りない。** 実測では [must] が 6 → 6 で一致したまま、
中身が 2 件入れ替わっていた。だから本数と並びの両方を出す。

**変更の影響を見るときは対照を取る。** 同じプロンプトを 2 回流して、
入れ替わりがどれだけ起きるかを先に測る。それを超えた差だけが変更の影響。

usage:
  compare_reviews.py count <out.md> ...              ラベルを数える
  compare_reviews.py diff <dir_a> <dir_b>            本数と [must] の並びを出す
"""
import pathlib
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


def cmd_diff(dir_a: str, dir_b: str) -> int:
    """本数と [must] の並びを出す。同じ指摘かどうかは読んだ人が決める。"""
    a, b = load(pathlib.Path(dir_a)), load(pathlib.Path(dir_b))

    for r in REVIEWERS:
        at = sum(len(v) for v in a[r].values())
        bt = sum(len(v) for v in b[r].values())
        am, bm = len(a[r]["[must]"]), len(b[r]["[must]"])

        print(f"\n  == {r} ==")
        print(f"    指摘件数   {at:3d} -> {bt:3d}   差 {bt - at:+d}")
        print(f"    [must]     {am:3d} -> {bm:3d}   差 {bm - am:+d}")
        print("    [must] の並び（同じ指摘かどうかは読んで判断する）")
        for i in range(max(am, bm)):
            left = a[r]["[must]"][i][:46] if i < am else "—"
            right = b[r]["[must]"][i][:46] if i < bm else "—"
            print(f"      {i+1}. A: {left}")
            print(f"         B: {right}")

    print("\n  本数が合っていても中身が入れ替わることがある。並びを読んで、")
    print("  A にあって B に無い指摘を自分で拾うこと。")
    return 0


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
