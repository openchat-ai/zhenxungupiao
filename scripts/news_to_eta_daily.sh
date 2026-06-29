#!/bin/sh
# news_all.csv → news_daily_eta.csv（纯 awk，运行时可用）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
IN="${1:-$ARCH/news_all.csv}"
OUT="${2:-$ARCH/news_daily_eta.csv}"
AWK="$ROOT/scripts/news_to_eta_daily.awk"

if [ ! -f "$IN" ]; then
  echo "SKIP: $IN missing (run fetch-news first)" >&2
  exit 0
fi

awk -f "$AWK" "$IN" | sort -t, -k1,1 -k2,2 > "$OUT"
echo "OK $OUT ($(tail -n +2 "$OUT" | wc -l | tr -d ' ') rows)"
