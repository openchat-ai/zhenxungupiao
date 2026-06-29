#!/usr/bin/env python3
"""将八股日线延伸至今日（可选 Python，AKShare qfq，与 OpenBB akshare 同源）。"""
from __future__ import annotations

import csv
from pathlib import Path

import akshare as ak

ROOT = Path(__file__).resolve().parents[1]
ARCH = ROOT / "research" / "archive"

STOCKS = [
    "600519", "000001", "601318", "600036",
    "000858", "601012", "600900", "000333",
]


def extend_one(code: str) -> int:
    path = ARCH / f"hist_{code}.csv"
    if not path.exists():
        return 0
    with path.open(encoding="utf-8") as f:
        rows = list(csv.reader(f))
    if len(rows) < 2:
        return 0
    header = rows[0]
    last_date = rows[-1][0]
    sym = code
    df = ak.stock_zh_a_hist(symbol=sym, period="daily", start_date=last_date.replace("-", ""), adjust="qfq")
    if df is None or len(df) == 0:
        return 0
    added = 0
    existing = {r[0] for r in rows[1:]}
    with path.open("a", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        for _, r in df.iterrows():
            d = str(r["日期"])
            if d in existing or d <= last_date:
                continue
            w.writerow([
                d, code,
                r["开盘"], r["收盘"], r["最高"], r["最低"],
                r["成交量"], r["成交额"], r["振幅"], r["涨跌幅"], r["涨跌额"], r["换手率"],
            ])
            added += 1
    return added


def main() -> int:
    total = 0
    for code in STOCKS:
        n = extend_one(code)
        total += n
        print(f"OK hist_{code}.csv +{n} rows", flush=True)
    print(f"OK extend hist ({total} rows)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
