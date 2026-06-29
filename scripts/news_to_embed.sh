#!/bin/sh
# 从 news_daily_eta.csv 取最近一日新闻分 → build/news_embed.ty（state[51]）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CSV="${1:-$ROOT/research/archive/news_daily_eta.csv}"
OUT="${2:-$ROOT/build/news_embed.ty}"
CODE="${3:-600519}"

mkdir -p "$(dirname "$OUT")"
SCORE=$(awk -F, -v c="$CODE" '$2==c {score=$3; date=$1} END {print score+0}' "$CSV" 2>/dev/null)
[ -n "$SCORE" ] && [ "$SCORE" -gt 0 ] || SCORE=50

{
  echo "; auto-generated from $CSV for $CODE"
  printf "30 33 %02x\n" "$SCORE"   # state[51] = news_score (0x33=51)
} > "$OUT"
echo "Wrote $OUT news_score=$SCORE"
