#!/bin/sh
# v4 全量回测：七票 + 新闻 η + 历史逐笔（有数据日启用）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/backtest_v4.awk"
NEWS="$ARCH/news_daily_eta.csv"
TICK="$ARCH/tick_hist_daily.csv"
OUT_CSV="$ARCH/backtest_v4_by_stock.csv"
OUT_JSON="$ARCH/backtest_v4_summary.json"
OUT_MD="$ARCH/BACKTEST_V4_REPORT.md"

mkdir -p "$ARCH"
[ -f "$NEWS" ] || echo "WARN: $NEWS missing — news η 层无覆盖" >&2
[ -f "$TICK" ] || echo "WARN: $TICK missing — 第7票仅缺逐笔日持票" >&2

{
  echo "code,name,n_days,pct_buy,pct_hold,pct_sell,mean_wuwen_pct,mean_calm_pct,mean_consensus_risk_pct,v4_return,momentum_return,meanrev_return,buyhold_return,v4_sharpe,momentum_sharpe,meanrev_sharpe,v4_mdd,momentum_mdd,meanrev_mdd,corr_signal_nextday,tick_coverage_pct,news_coverage_pct"
  for f in "$ARCH"/hist_*.csv; do
    base=$(basename "$f" .csv)
    code=${base#hist_}
    case "$code" in
      600519) name="贵州茅台" ;;
      000001) name="平安银行" ;;
      601318) name="中国平安" ;;
      600036) name="招商银行" ;;
      000858) name="五粮液" ;;
      601012) name="隆基绿能" ;;
      600900) name="长江电力" ;;
      000333) name="美的集团" ;;
      *) name="$code" ;;
    esac
    awk -v code="$code" -v name="$name" -v newsfile="$NEWS" -v tickfile="$TICK" -f "$AWK" "$f"
  done
} > "$OUT_CSV"

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
awk -F, -v ts="$ts" 'NR==1{next} {
  n++
  for (i=4;i<=NF;i++) s[i]+=$i
} END {
  printf "{\n"
  printf "  \"version\": \"v4\",\n"
  printf "  \"generated_at\": \"%s\",\n", ts
  printf "  \"engine\": \"scripts/backtest_v4.awk (7-vote + news eta + tick hist)\",\n"
  printf "  \"n_stocks\": %d,\n", n
  printf "  \"v4_mean_return\": %.6f,\n", s[10]/n
  printf "  \"momentum_mean_return\": %.6f,\n", s[11]/n
  printf "  \"meanrev_mean_return\": %.6f,\n", s[12]/n
  printf "  \"buyhold_mean_return\": %.6f,\n", s[13]/n
  printf "  \"v4_mean_sharpe\": %.6f,\n", s[14]/n
  printf "  \"v4_mean_hold_pct\": %.6f,\n", s[5]/n
  printf "  \"v4_mean_wuwen_vote_pct\": %.6f,\n", s[7]/n
  printf "  \"corr_signal_nextday_mean\": %.6f,\n", s[20]/n
  printf "  \"tick_coverage_mean_pct\": %.6f,\n", s[21]/n
  printf "  \"news_coverage_mean_pct\": %.6f,\n", s[22]/n
  printf "  \"v4_beats_momentum_count\": 0,\n"
  printf "  \"v4_beats_meanrev_count\": 0,\n"
  printf "  \"v4_beats_buyhold_count\": 0\n"
  printf "}\n"
}' "$OUT_CSV" > "$OUT_JSON.tmp"

v4bm=$(awk -F, 'NR>1 && $10+0 > $11+0 {c++} END{print c+0}' "$OUT_CSV")
v4br=$(awk -F, 'NR>1 && $10+0 > $12+0 {c++} END{print c+0}' "$OUT_CSV")
v4bh=$(awk -F, 'NR>1 && $10+0 > $13+0 {c++} END{print c+0}' "$OUT_CSV")
sed -i "s/\"v4_beats_momentum_count\": 0/\"v4_beats_momentum_count\": $v4bm/" "$OUT_JSON.tmp"
sed -i "s/\"v4_beats_meanrev_count\": 0/\"v4_beats_meanrev_count\": $v4br/" "$OUT_JSON.tmp"
sed -i "s/\"v4_beats_buyhold_count\": 0/\"v4_beats_buyhold_count\": $v4bh/" "$OUT_JSON.tmp"
mv "$OUT_JSON.tmp" "$OUT_JSON"

{
  echo "# 震巽 v4 回测报告（七票 + 新闻 η + 历史逐笔）"
  echo ""
  echo "- 生成: \`make research-v4\`"
  echo "- 新闻: \`make fetch-news\` → \`news_daily_eta.csv\`"
  echo "- 逐笔: \`make fetch-ticks-tdx\` → \`tick_hist_daily.csv\`"
  echo ""
  echo "## 组合均值"
  echo ""
  grep -E 'mean_' "$OUT_JSON" | sed 's/[",]//g' | while read -r line; do echo "- $line"; done
  echo ""
  echo "## 分标的"
  echo ""
  echo '```'
  column -t -s, "$OUT_CSV" 2>/dev/null || cat "$OUT_CSV"
  echo '```'
} > "$OUT_MD"

echo "OK $OUT_CSV"
echo "OK $OUT_JSON"
echo "OK $OUT_MD"
