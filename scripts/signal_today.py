#!/usr/bin/env python3
"""从 flow_v5_*.tri 读出各股最新一日 v4/tail/veto 信号（仅展示，非预测）。"""
from __future__ import annotations

import struct
from datetime import datetime, timezone
from pathlib import Path

ARCH = Path(__file__).resolve().parents[1] / "research" / "archive"
NAMES = {
    "600519": "贵州茅台", "000001": "平安银行", "601318": "中国平安",
    "600036": "招商银行", "000858": "五粮液", "601012": "隆基绿能",
    "600900": "长江电力", "000333": "美的集团",
}
LABEL = {0: "卖", 1: "持", 2: "买"}


def last_sig(path: Path) -> tuple[int, int, int, int]:
    b = path.read_bytes()
    if b[:3] != b"TRI" or b[3] != 2:
        raise ValueError(f"not v5 tri: {path}")
    n = struct.unpack_from("<H", b, 4)[0]
    base = 6
    return (
        n,
        b[base + n - 1],
        b[base + 2 * n - 1],
        b[base + 3 * n - 1],
    )


def main() -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    lines = [
        "# 八股最新信号（来自 flow_v5_*.tri 末日）",
        "",
        f"生成：`make signal-today` · {ts}",
        "",
        "> **注意**：这是七票规则在 **2026 tick 窗口最后一交易日** 的输出，",
        "> 不是「明天一定涨/跌」。实证 corr≈0，见 `结论.md`。",
        "",
        "| 代码 | 名称 | 交易日数 | v4 | tail | veto |",
        "|------|------|----------|-----|------|------|",
    ]
    for path in sorted(ARCH.glob("flow_v5_*.tri")):
        code = path.stem.replace("flow_v5_", "")
        n, v4, tail, veto = last_sig(path)
        name = NAMES.get(code, code)
        lines.append(
            f"| {code} | {name} | {n} | {LABEL[v4]} | {LABEL[tail]} | {LABEL[veto]} |"
        )
    lines += [
        "",
        "## 怎么用",
        "",
        "- 电脑：`make signal-today` 刷新本表",
        "- 纯 yoyo 单股：`make research-v5-yoyo CODE=600519`（需 Wine）",
        "- 手机 App：`cursor/mobile-capacitor-app-5236` 分支，**目前是假 K 线**，未接 archive",
        "",
    ]
    out = ARCH / "SIGNALS_TODAY.md"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(out)
    print(out.read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()
