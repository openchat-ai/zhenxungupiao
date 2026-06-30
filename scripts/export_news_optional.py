#!/usr/bin/env python3
"""一次性新闻导出（可选 Python，非震巽运行时）。

数据源：AKShare stock_news_em（与 OpenBB provider=akshare 同源）。
OpenBB 路径需 akshare_api_key；本脚本直连 AKShare 免密钥。

输出：research/archive/news_<code>.csv
      research/archive/news_all.csv
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCH = ROOT / "research" / "archive"

STOCKS = [
    ("600519", "贵州茅台"),
    ("000001", "平安银行"),
    ("601318", "中国平安"),
    ("600036", "招商银行"),
    ("000858", "五粮液"),
    ("601012", "隆基绿能"),
    ("600900", "长江电力"),
    ("000333", "美的集团"),
]


BULL_KW = "涨,涨停,利好,回购,增持,分红,突破,创新高,盈利,超预期,反弹,大涨".split(",")
BEAR_KW = "跌,跌停,利空,减持,亏损,调查,处罚,暴跌,下滑,违约,退市,大跌".split(",")


def score_text(text: str) -> tuple[int, int]:
    b = sum(1 for k in BULL_KW if k in text)
    r = sum(1 for k in BEAR_KW if k in text)
    return b, r


def write_eta_csv(path: Path, rows: list[dict]) -> int:
    from collections import defaultdict

    agg: dict[tuple[str, str], list] = defaultdict(lambda: [0, 0, 0])
    for r in rows:
        if not r["date"]:
            continue
        key = (r["date"], r["code"])
        b, bear = score_text(r["title"] + " " + r["body"])
        agg[key][0] += 1
        agg[key][1] += b
        agg[key][2] += bear

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["date", "code", "news_score", "n_headlines", "bull_hits", "bear_hits"])
        for (d, c), (n, b, bear) in sorted(agg.items()):
            raw = b - bear
            score = max(0, min(100, 50 + raw * 8))
            w.writerow([d, c, score, n, b, bear])
    return len(agg)


def fetch_akshare(symbol: str):
    import akshare as ak

    return ak.stock_news_em(symbol=symbol)


def fetch_openbb(symbol: str):
    from openbb import obb

    r = obb.news.company(symbol, provider="akshare")
    rows = []
    for x in r.results:
        rows.append(
            {
                "发布时间": str(getattr(x, "date", "") or ""),
                "新闻标题": str(getattr(x, "title", "") or ""),
                "新闻内容": str(getattr(x, "text", "") or getattr(x, "content", "") or ""),
                "文章来源": str(getattr(x, "source", "") or ""),
                "新闻链接": str(getattr(x, "url", "") or ""),
            }
        )
    return rows


def normalize_rows(df_or_rows, code: str, name: str, source: str):
    out = []
    if hasattr(df_or_rows, "iterrows"):
        it = df_or_rows.iterrows()
        get = lambda row, k: str(row.get(k, "") or "")
    else:
        it = enumerate(df_or_rows)
        get = lambda row, k: str(row.get(k, "") or "")

    for _, row in it:
        if hasattr(row, "get"):
            r = row
        else:
            r = row[1] if isinstance(row, tuple) else row
        pub = get(r, "发布时间")
        title = get(r, "新闻标题")
        body = get(r, "新闻内容")
        src = get(r, "文章来源")
        url = get(r, "新闻链接")
        day = pub[:10] if len(pub) >= 10 else ""
        out.append(
            {
                "date": day,
                "code": code,
                "name": name,
                "title": title.replace("\n", " ").strip(),
                "body": body.replace("\n", " ").strip()[:500],
                "source": src,
                "url": url,
                "provider": source,
            }
        )
    return out


def write_stock_csv(path: Path, rows: list[dict]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = ["date", "code", "name", "title", "body", "source", "url", "provider"]
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow(r)
    return len(rows)


def main() -> int:
    use_openbb = "--openbb" in sys.argv
    all_rows: list[dict] = []

    for code, name in STOCKS:
        try:
            if use_openbb:
                raw = fetch_openbb(code)
                rows = normalize_rows(raw, code, name, "openbb-akshare")
            else:
                raw = fetch_akshare(code)
                rows = normalize_rows(raw, code, name, "akshare")
        except Exception as e:
            print(f"WARN {code}: {e}", file=sys.stderr)
            rows = []

        n = write_stock_csv(ARCH / f"news_{code}.csv", rows)
        all_rows.extend(rows)
        print(f"OK news_{code}.csv ({n} rows)", file=sys.stderr)

    combined = ARCH / "news_all.csv"
    write_stock_csv(combined, all_rows)
    eta_path = ARCH / "news_daily_eta.csv"
    write_eta_csv(eta_path, all_rows)
    print(f"OK {combined} ({len(all_rows)} rows total)", file=sys.stderr)
    print(f"OK {eta_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
