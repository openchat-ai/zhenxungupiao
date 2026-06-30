#!/usr/bin/env python3
"""通达信协议历史逐笔（可选 Python，非震巽运行时）。

仅抓取 **当年** 交易日（默认 2026-01-01 ~ 今日），不拉更久历史。

依赖：pip install easy-tdx
输出：research/archive/tick_hist/tick_<code>_<YYYYMMDD>.csv
      字段对齐东财：date,code,time,price,volume,bs

用法：
  fetch_tick_tdx_optional.py              # 默认当年
  fetch_tick_tdx_optional.py 2026        # 指定年份
  fetch_tick_tdx_optional.py 2026 --force # 覆盖已有
"""
from __future__ import annotations

import csv
import sys
import time
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCH = ROOT / "research" / "archive" / "tick_hist"

STOCKS = [
    ("600519", 1),
    ("000001", 0),
    ("601318", 1),
    ("600036", 1),
    ("000858", 0),
    ("601012", 1),
    ("600900", 1),
    ("000333", 0),
]


def market_enum(mkt: int):
    from easy_tdx import Market

    return Market.SH if mkt == 1 else Market.SZ


def bs_map(flag: int) -> int:
    if flag == 0:
        return 1
    if flag == 1:
        return 2
    return 4


def trading_days_in_year(year: int) -> list[int]:
    """当年 1 月 1 日 ~ 今日（含）的交易日。"""
    start = date(year, 1, 1)
    end = date.today()
    if end.year < year:
        return []
    d = start
    out: list[int] = []
    while d <= end:
        if d.weekday() < 5:
            out.append(d.year * 10000 + d.month * 100 + d.day)
        d += timedelta(days=1)
    return out


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--force"]
    force = "--force" in sys.argv
    year = date.today().year
    if args:
        year = int(args[0])

    from easy_tdx import MacClient

    ARCH.mkdir(parents=True, exist_ok=True)
    dates = trading_days_in_year(year)
    if not dates:
        print(f"SKIP no trading days for year={year}", flush=True)
        return 0

    total = skipped = empty = failed = 0
    need = len(dates) * len(STOCKS)
    print(f"START tick_hist year={year} days={len(dates)} stocks={len(STOCKS)} tasks~{need}", flush=True)

    with MacClient.from_best_host() as client:
        for code, mkt in STOCKS:
            for dint in dates:
                out = ARCH / f"tick_{code}_{dint}.csv"
                if not force and out.exists() and out.stat().st_size > 50:
                    skipped += 1
                    continue
                try:
                    df = client.get_transactions(
                        market_enum(mkt), code, count=8000, date=dint
                    )
                except Exception as e:
                    failed += 1
                    print(f"WARN {code} {dint}: {e}", file=sys.stderr, flush=True)
                    time.sleep(0.2)
                    continue
                if df is None or len(df) == 0:
                    empty += 1
                    continue
                ds = f"{dint // 10000:04d}-{(dint % 10000) // 100:02d}-{dint % 100:02d}"
                with out.open("w", newline="", encoding="utf-8") as f:
                    w = csv.writer(f, lineterminator="\n")
                    w.writerow(["date", "code", "time", "price", "volume", "bs"])
                    for row in df.itertuples(index=False):
                        w.writerow(
                            [
                                ds,
                                code,
                                row.time,
                                f"{float(row.price):.4f}",
                                int(row.vol),
                                bs_map(int(row.bs_flag)),
                            ]
                        )
                total += 1
                if total % 20 == 0:
                    print(f"PROGRESS written={total} skipped={skipped}", flush=True)
                time.sleep(0.05)

    print(
        f"DONE tick_hist year={year} written={total} skipped={skipped} empty={empty} failed={failed}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
