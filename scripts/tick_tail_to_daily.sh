#!/bin/sh
# 从 tick_hist/*.csv 提取尾盘 30 分钟（14:30–15:00）主动买占比
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$ROOT/research/archive/tick_hist}"
OUT="${2:-$ROOT/research/archive/tick_tail_daily.csv}"

mkdir -p "$(dirname "$OUT")"
{
  echo "date,code,tail_buy_pct,tail_sell_pct,n_tail_ticks,day_buy_pct,day_sell_pct,n_day_ticks"
  for f in "$DIR"/tick_[0-9]*.csv; do
    [ -f "$f" ] || continue
    awk -F, '
      function pct(b, s, n) { return (n > 0) ? 100 * b / n : -1 }
      NR == 2 { d = $1; c = $2 }
      NR > 1 {
        gsub(/\r/, "", $6)
        bs = $6 + 0
        t = $3
        if (t >= "14:30:00" && t <= "15:00:00") {
          nt++
          if (bs == 1) tb++
          else if (bs == 2) ts++
        }
        nd++
        if (bs == 1) db++
        else if (bs == 2) ds++
      }
      END {
        if (nd > 0)
          printf "%s,%s,%.2f,%.2f,%d,%.2f,%.2f,%d\n",
            d, c, pct(tb, ts, nt), pct(ts, tb, nt), nt,
            pct(db, ds, nd), pct(ds, db, nd), nd
      }
    ' "$f"
  done
} | sort -t, -k1,1 -k2,2 > "$OUT"

echo "OK $OUT ($(tail -n +2 "$OUT" | wc -l | tr -d ' ') rows)"
