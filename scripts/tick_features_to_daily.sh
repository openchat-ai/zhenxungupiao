#!/bin/sh
# 从 tick_hist/*.csv 提取多维度逐笔特征（纯 awk，零 Python）
# 输出 research/archive/tick_features_daily.csv
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$ROOT/research/archive/tick_hist}"
OUT="${2:-$ROOT/research/archive/tick_features_daily.csv}"
BIG_VOL="${3:-100}"   # 大单阈值（股）

mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp)"
for f in "$DIR"/tick_[0-9]*.csv; do
  [ -f "$f" ] || continue
  awk -F, -v big="$BIG_VOL" '
    function pct(b, s, n) { return (n > 0) ? 100 * b / n : -1 }
    function vw_pct(bv, sv) {
      t = bv + sv
      return (t > 0) ? 100 * bv / t : -1
    }
    NR == 2 { d = $1; c = $2 }
    NR > 1 {
      gsub(/\r/, "", $6)
      bs = $6 + 0
      vol = $5 + 0
      t = $3
      nd++
      if (bs == 1) { db++; dbv += vol }
      else if (bs == 2) { ds++; dsv += vol }
      if (t >= "09:30:00" && t <= "10:00:00") {
        no30++
        if (bs == 1) o30b++
        else if (bs == 2) o30s++
      }
      if (t >= "09:30:00" && t <= "11:30:00") {
        nam++
        if (bs == 1) amb++
        else if (bs == 2) ams++
      }
      if (t >= "13:00:00" && t <= "14:30:00") {
        npm++
        if (bs == 1) pmb++
        else if (bs == 2) pms++
      }
      if (t >= "14:30:00" && t <= "15:00:00") {
        nt++
        if (bs == 1) tb++
        else if (bs == 2) ts++
      }
      if (vol >= big) {
        nbig++
        if (bs == 1) bbig++
        else if (bs == 2) sbig++
      }
    }
    END {
      if (nd == 0) exit
      day_b = pct(db, ds, nd)
      printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%.2f,%d\n",
        d, c,
        day_b, pct(ds, db, nd),
        vw_pct(dbv, dsv), vw_pct(dsv, dbv),
        pct(o30b, o30s, no30),
        pct(amb, ams, nam),
        pct(pmb, pms, npm),
        pct(tb, ts, nt),
        pct(amb, ams, nam) - pct(pmb, pms, npm),
        pct(bbig, sbig, nbig),
        nbig,
        0,
        nd
    }
  ' "$f"
done | sort -t, -k1,1 -k2,2 > "$TMP"

# flow_chg = 当日 day_buy - 前一日 day_buy（同 code）
awk -F, '
  {
    k = $2
    chg = (k in prev) ? $3 - prev[k] : 0
    prev[k] = $3
    printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%.2f,%d\n",
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, chg, $15
  }
' "$TMP" > "$OUT.tmp"

{
  echo "date,code,day_buy_pct,day_sell_pct,vw_buy_pct,vw_sell_pct,open30_buy_pct,am_buy_pct,pm_buy_pct,tail_buy_pct,am_pm_delta,big_buy_pct,big_n_ticks,flow_chg,n_ticks"
  cat "$OUT.tmp"
} > "$OUT"
rm -f "$TMP" "$OUT.tmp"

echo "OK $OUT ($(tail -n +2 "$OUT" | wc -l | tr -d ' ') rows, big_vol>=$BIG_VOL)"
