#!/bin/sh
# tick_hist/*.csv + tick_daily_summary.csv → tick_hist_daily.csv（纯 awk）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$ROOT/research/archive/tick_hist}"
OUT="${2:-$ROOT/research/archive/tick_hist_daily.csv}"
EM="$ROOT/research/archive/tick_daily_summary.csv"

mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp)"
{
  echo "date,code,active_buy_pct,active_sell_pct,n_ticks,source"
  for f in "$DIR"/tick_[0-9]*.csv; do
    [ -f "$f" ] || continue
    awk -F, 'BEGIN{gsub(/\r/,"")} NR==2 {d=$1; c=$2} NR>1 {
      gsub(/\r/, "", $6)
      if ($6+0==1) b++; else if ($6+0==2) s++; n++
    } END {
      if (n>0) printf "%s,%s,%.2f,%.2f,%d,easy_tdx\n", d, c, 100*b/n, 100*s/n, n
    }' "$f"
  done
  if [ -f "$EM" ]; then
    awk -F, 'NR>1 && $1!="date" {printf "%s,%s,%s,%s,%s,eastmoney_push2\n",$1,$2,$3,$4,$5}' "$EM"
  fi
} > "$TMP"
# 去重：同 date+code 保留 eastmoney（较新）；剔除脏行
awk -F, 'NR==1{print;next} $1!="date" && $2!="code" {
  k=$1","$2
  if (!($6 ~ /eastmoney/) && (k in seen)) next
  if ($6 ~ /eastmoney/) seen[k]=1
  lines[k]=$0
} END {for (k in lines) print lines[k]}' "$TMP" | sort -t, -k1,1 -k2,2 > "$OUT"
rm -f "$TMP"

echo "OK $OUT ($(tail -n +2 "$OUT" | wc -l | tr -d ' ') rows)"
