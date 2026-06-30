#!/bin/sh
# v2 全量回测：8 股 hist_*.csv → research/archive/backtest_v2_*
# 纯 awk/shell，零 Python
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/backtest_v3.awk"
OUT_CSV="$ARCH/backtest_v3_by_stock.csv"
OUT_JSON="$ARCH/backtest_v3_summary.json"
OUT_MD="$ARCH/BACKTEST_V3_REPORT.md"

mkdir -p "$ARCH"

{
  echo "code,name,n_days,pct_buy,pct_hold,pct_sell,mean_wuwen_pct,mean_calm_pct,mean_consensus_risk_pct,v3_return,momentum_return,meanrev_return,buyhold_return,v3_sharpe,momentum_sharpe,meanrev_sharpe,v3_mdd,momentum_mdd,meanrev_mdd,corr_signal_nextday"
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
    awk -v code="$code" -v name="$name" -f "$AWK" "$f"
  done
} > "$OUT_CSV"

# 汇总（awk 聚合）
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
awk -F, -v ts="$ts" 'NR==1{next} {
  n++
  for (i=4;i<=NF;i++) s[i]+=$i
} END {
  printf "{\n"
  printf "  \"version\": \"v3\",\n"
  printf "  \"generated_at\": \"%s\",\n", ts
  printf "  \"engine\": \"scripts/backtest_v3.awk (yoyo 6-vote + psych + wuwen)\",\n"
  printf "  \"n_stocks\": %d,\n", n
  printf "  \"v3_mean_return\": %.6f,\n", s[10]/n
  printf "  \"momentum_mean_return\": %.6f,\n", s[11]/n
  printf "  \"meanrev_mean_return\": %.6f,\n", s[12]/n
  printf "  \"buyhold_mean_return\": %.6f,\n", s[13]/n
  printf "  \"v3_mean_sharpe\": %.6f,\n", s[14]/n
  printf "  \"momentum_mean_sharpe\": %.6f,\n", s[15]/n
  printf "  \"meanrev_mean_sharpe\": %.6f,\n", s[16]/n
  printf "  \"v3_mean_mdd\": %.6f,\n", s[17]/n
  printf "  \"v3_mean_hold_pct\": %.6f,\n", s[5]/n
  printf "  \"v3_mean_wuwen_vote_pct\": %.6f,\n", s[7]/n
  printf "  \"v3_mean_calm_market_pct\": %.6f,\n", s[8]/n
  printf "  \"v3_mean_consensus_risk_pct\": %.6f,\n", s[9]/n
  printf "  \"corr_signal_nextday_mean\": %.6f,\n", s[20]/n
  printf "  \"v3_beats_momentum_count\": 0,\n"
  printf "  \"v3_beats_meanrev_count\": 0,\n"
  printf "  \"v3_beats_buyhold_count\": 0\n"
  printf "}\n"
}' "$OUT_CSV" > "$OUT_JSON.tmp"

# 修正 beats 计数
v3bm=$(awk -F, 'NR>1 && $10+0 > $11+0 {c++} END{print c+0}' "$OUT_CSV")
v3br=$(awk -F, 'NR>1 && $10+0 > $12+0 {c++} END{print c+0}' "$OUT_CSV")
v3bh=$(awk -F, 'NR>1 && $10+0 > $13+0 {c++} END{print c+0}' "$OUT_CSV")
sed -i "s/\"v3_beats_momentum_count\": 0/\"v3_beats_momentum_count\": $v3bm/" "$OUT_JSON.tmp"
sed -i "s/\"v3_beats_meanrev_count\": 0/\"v3_beats_meanrev_count\": $v3br/" "$OUT_JSON.tmp"
sed -i "s/\"v3_beats_buyhold_count\": 0/\"v3_beats_buyhold_count\": $v3bh/" "$OUT_JSON.tmp"
mv "$OUT_JSON.tmp" "$OUT_JSON"

# Markdown 报告
{
  echo "# 震巽 v3 回测报告（六票 + 心理学 + 无问占比）"
  echo ""
  echo "- 生成: \`make research-v3\`"
  echo "- 引擎: \`scripts/backtest_v3.awk\`"
  echo "- 心理学: \`yoyo/docs/PSYCHOLOGY.md\`"
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
