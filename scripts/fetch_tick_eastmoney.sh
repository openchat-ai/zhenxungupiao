#!/bin/sh
# 东方财富逐笔成交抓取（纯 curl + awk，零 Python）
# 用法: fetch_tick_eastmoney.sh <code> <market> [out.csv]
#   market: 1=上交所 0=深交所
# 字段: time,price,volume,trade_id,bs  (bs: 1=主动买 2=主动卖 4=集合竞价/其他)
set -e
CODE="${1:?code}"
MKT="${2:?market 0|1}"
OUT="${3:-research/archive/tick_${CODE}.csv}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "$OUT" in /*) OUT_ABS="$OUT" ;; *) OUT_ABS="$ROOT/$OUT" ;; esac
URL="https://16.push2.eastmoney.com/api/qt/stock/details/get?fields1=f1,f2,f3,f4&fields2=f51,f52,f53,f54,f55&mpi=2000&ut=bd1d9ddb04089700cf9c27f6f7426281&fltt=2&pos=-0&secid=${MKT}.${CODE}"

mkdir -p "$(dirname "$OUT_ABS")"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

curl -sSL -m 60 \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" \
  -H "Referer: https://quote.eastmoney.com/${CODE}.html" \
  "$URL" > "$TMP"

DATE="$(date -u +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)"

{
  echo "date,code,time,price,volume,bs"
  tr '"' '\n' < "$TMP" | awk -F, -v d="$DATE" -v c="$CODE" '
    /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9],/ && $1 >= "09:30:00" && $1 <= "15:00:00" {
      print d "," c "," $1 "," $2 "," $3 "," $5
    }
  '
} > "$OUT_ABS"

N=$(tail -n +2 "$OUT_ABS" | wc -l | tr -d ' ')
echo "OK $OUT_ABS ($N ticks)" >&2
