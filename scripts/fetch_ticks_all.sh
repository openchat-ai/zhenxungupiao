#!/bin/sh
# 抓取八股当日逐笔 + 生成日级主动买卖汇总
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
chmod +x "$ROOT/scripts/fetch_tick_eastmoney.sh"

fetch() { "$ROOT/scripts/fetch_tick_eastmoney.sh" "$1" "$2" "$ARCH/tick_$1.csv"; }

fetch 600519 1
fetch 000001 0
fetch 601318 1
fetch 600036 1
fetch 000858 0
fetch 601012 1
fetch 600900 1
fetch 000333 0

SUM="$ARCH/tick_daily_summary.csv"
DATE="$(ls "$ARCH"/tick_*.csv 2>/dev/null | grep -v daily | head -1 | xargs head -2 | tail -1 | cut -d, -f1)"
[ -n "$DATE" ] || DATE="$(date +%Y-%m-%d)"
{
  echo "date,code,active_buy_pct,active_sell_pct,n_ticks,source"
  for f in "$ARCH"/tick_[0-9]*.csv; do
    [ -f "$f" ] || continue
    awk -F, 'NR>1 {
      if ($6==1) b++; else if ($6==2) s++; n++
    } END {
      if (n>0) printf "%s,%s,%.2f,%.2f,%d,eastmoney_push2\n", $1, $2, 100*b/n, 100*s/n, n
    }' "$f"
  done
} > "$SUM"

echo "OK $SUM"
