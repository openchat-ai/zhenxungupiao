#!/usr/bin/env python3
"""校验 flow_v5_*.tri 并输出 backtest_v5_tri_summary.json + REPORT.md"""
from __future__ import annotations

import json
import struct
from pathlib import Path

ARCH = Path(__file__).resolve().parents[1] / "research" / "archive"
CODES = [
    "000001", "000333", "000858", "600036",
    "600519", "600900", "601012", "601318",
]
NAMES = {
    "600519": "贵州茅台", "000001": "平安银行", "601318": "中国平安",
    "600036": "招商银行", "000858": "五粮液", "601012": "隆基绿能",
    "600900": "长江电力", "000333": "美的集团",
}


def load_v5(path: Path) -> dict:
    b = path.read_bytes()
    assert b[:3] == b"TRI" and b[3] == 2, path
    n = struct.unpack_from("<H", b, 4)[0]
    base = 6
    v4 = list(b[base : base + n])
    tail = list(b[base + n : base + 2 * n])
    veto = list(b[base + 2 * n : base + 3 * n])
    ret = list(b[base + 3 * n : base + 4 * n])
    vflag = list(b[base + 4 * n : base + 5 * n])
    return {"n": n, "v4": v4, "tail": tail, "veto": veto, "ret": ret, "vflag": vflag}


def agree(sig: list[int], ret: list[int]) -> tuple[int, int]:
    hits = active = 0
    for s, r in zip(sig, ret):
        if r == 1:
            continue
        active += 1
        if (s == 2 and r == 2) or (s == 0 and r == 0):
            hits += 1
    return hits, active


def net_wins(sig: list[int], ret: list[int]) -> int:
    pos = 0
    score = 0
    for s, r in zip(sig, ret):
        if s == 2:
            pos = 1
        elif s == 0:
            pos = 0
        if r == 1 or not pos:
            continue
        score += 1 if r == 2 else -1
    return score


def buyhold_wins(ret: list[int]) -> int:
    return sum(1 if r == 2 else -1 for r in ret if r != 1)


def main() -> None:
    rows = []
    beats = {"v4": 0, "tail": 0, "veto": 0}
    totals = {m: {"agree": 0, "active": 0, "wins": 0} for m in ("v4", "tail", "veto")}
    veto_days = total_n = 0

    for code in CODES:
        d = load_v5(ARCH / f"flow_v5_{code}.tri")
        n = d["n"]
        total_n += n
        bh = buyhold_wins(d["ret"])
        for mode, sig in (("v4", d["v4"]), ("tail", d["tail"]), ("veto", d["veto"])):
            h, a = agree(sig, d["ret"])
            w = net_wins(sig, d["ret"])
            totals[mode]["agree"] += h
            totals[mode]["active"] += a
            totals[mode]["wins"] += w
            if w > bh:
                beats[mode] += 1
            rows.append({
                "code": code, "name": NAMES.get(code, code), "mode": mode,
                "n_days": n, "agree": h, "active": a, "net_wins": w,
                "buyhold_wins": bh, "beats_bh": int(w > bh),
                "veto_days": sum(d["vflag"]) if mode == "veto" else 0,
            })
        veto_days += sum(d["vflag"])

    summary = {
        "version": "v5_tri_compare",
        "window": "2026 tick archive (flow_v5_*.tri)",
        "engine": "pure trit — tri_io.ty + flow_v5_*.tri",
        "v4_agree_rate": totals["v4"]["agree"] / totals["v4"]["active"],
        "tail_agree_rate": totals["tail"]["agree"] / totals["tail"]["active"],
        "veto_agree_rate": totals["veto"]["agree"] / totals["veto"]["active"],
        "v4_net_wins": totals["v4"]["wins"],
        "tail_net_wins": totals["tail"]["wins"],
        "veto_net_wins": totals["veto"]["wins"],
        "buyhold_net_wins": sum(buyhold_wins(load_v5(ARCH / f"flow_v5_{c}.tri")["ret"]) for c in CODES),
        "v4_beats_buyhold": beats["v4"],
        "tail_beats_buyhold": beats["tail"],
        "veto_beats_buyhold": beats["veto"],
        "veto_mean_veto_pct": veto_days / total_n,
    }

    (ARCH / "backtest_v5_tri_summary.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )

    md = [
        "# v5 三进制对照（flow_v5_*.tri）",
        "",
        "生成：`make tri-archive-v5 && make research-v5-tri-validate`",
        "",
        "| 模式 | 同向率 | 净胜场 | 跑赢买入持有 |",
        "|------|--------|--------|--------------|",
        f"| v4 | {summary['v4_agree_rate']:.3f} | {summary['v4_net_wins']} | {summary['v4_beats_buyhold']}/8 |",
        f"| tail | {summary['tail_agree_rate']:.3f} | {summary['tail_net_wins']} | {summary['tail_beats_buyhold']}/8 |",
        f"| veto | {summary['veto_agree_rate']:.3f} | {summary['veto_net_wins']} | {summary['veto_beats_buyhold']}/8 |",
        f"| buyhold | — | {summary['buyhold_net_wins']} | — |",
        "",
        f"否决触发率：**{summary['veto_mean_veto_pct']*100:.1f}%**",
        "",
        "对照 awk 版：`research/archive/backtest_v5_compare_summary.json`",
        "",
        "## 分标的",
        "",
        "```",
        "code    mode  n   agree  active  net_wins  bh_wins  beats",
    ]
    for r in rows:
        md.append(
            f"{r['code']}  {r['mode']:4}  {r['n_days']}  {r['agree']:5}  {r['active']:6}  "
            f"{r['net_wins']:8}  {r['buyhold_wins']:7}  {r['beats_bh']}"
        )
    md.append("```")
    (ARCH / "BACKTEST_V5_TRI_REPORT.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
