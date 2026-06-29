#!/bin/bash
# 近段 v4 回测：2025+ 全窗 + 新闻/逐笔重叠窗
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/backtest_v4_recent.awk"
NEWS="$ARCH/news_daily_eta.csv"
TICK="$ARCH/tick_hist_daily.csv"

run_window() {
  suffix="$1"
  from="$2"
  to="$3"
  overlap="$4"
  OUT_CSV="$ARCH/backtest_v4_recent_${suffix}_by_stock.csv"
  OUT_JSON="$ARCH/backtest_v4_recent_${suffix}_summary.json"
  OUT_MD="$ARCH/BACKTEST_V4_RECENT_${suffix}_REPORT.md"

  {
    echo "code,name,n_days,date_from,date_to,overlap_only,pct_buy,pct_hold,pct_sell,mean_wuwen_pct,mean_calm_pct,mean_consensus_risk_pct,v4_return,momentum_return,meanrev_return,buyhold_return,v4_sharpe,momentum_sharpe,meanrev_sharpe,v4_mdd,momentum_mdd,meanrev_mdd,corr_signal_nextday,tick_coverage_pct,news_coverage_pct"
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
      awk -v code="$code" -v name="$name" \
          -v newsfile="$NEWS" -v tickfile="$TICK" \
          -v date_from="$from" -v date_to="$to" \
          -v overlap_only="$overlap" \
          -f "$AWK" "$f" 2>/dev/null || true
    done
  } > "$OUT_CSV"

  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  awk -F, -v ts="$ts" -v from="$from" -v to="$to" -v ov="$overlap" 'NR==1{next} {
    n++
    for (i=7;i<=NF;i++) s[i]+=$i
  } END {
    if (n==0) { print "{}" ; exit }
    printf "{\n"
    printf "  \"version\": \"v4_recent\",\n"
    printf "  \"generated_at\": \"%s\",\n", ts
    printf "  \"date_from\": \"%s\",\n", from
    printf "  \"date_to\": \"%s\",\n", to
    printf "  \"overlap_only\": %s,\n", ov
    printf "  \"n_stocks\": %d,\n", n
    printf "  \"v4_mean_return\": %.6f,\n", s[13]/n
    printf "  \"momentum_mean_return\": %.6f,\n", s[14]/n
    printf "  \"meanrev_mean_return\": %.6f,\n", s[15]/n
    printf "  \"buyhold_mean_return\": %.6f,\n", s[16]/n
    printf "  \"v4_mean_sharpe\": %.6f,\n", s[17]/n
    printf "  \"corr_signal_nextday_mean\": %.6f,\n", s[23]/n
    printf "  \"tick_coverage_mean_pct\": %.6f,\n", s[24]/n
    printf "  \"news_coverage_mean_pct\": %.6f,\n", s[25]/n
    printf "  \"v4_beats_momentum_count\": 0,\n"
    printf "  \"v4_beats_buyhold_count\": 0\n"
    printf "}\n"
  }' "$OUT_CSV" > "$OUT_JSON.tmp"

  v4bm=$(awk -F, 'NR>1 && $13+0 > $14+0 {c++} END{print c+0}' "$OUT_CSV")
  v4bh=$(awk -F, 'NR>1 && $13+0 > $16+0 {c++} END{print c+0}' "$OUT_CSV")
  sed -i "s/\"v4_beats_momentum_count\": 0/\"v4_beats_momentum_count\": $v4bm/" "$OUT_JSON.tmp"
  sed -i "s/\"v4_beats_buyhold_count\": 0/\"v4_beats_buyhold_count\": $v4bh/" "$OUT_JSON.tmp"
  mv "$OUT_JSON.tmp" "$OUT_JSON"

  {
    echo "# 震巽 v4 近段回测：${suffix}"
    echo ""
    echo "- 窗口：\`${from}\` ~ \`${to}\` overlap_only=${overlap}"
    echo "- 生成：\`make research-v4-recent\`"
    echo ""
    echo "## 组合均值"
    grep -E 'mean_|corr_|coverage' "$OUT_JSON" | sed 's/[",]//g' | while read -r line; do echo "- $line"; done
    echo ""
    echo "## 分标的"
    echo '```'
    column -t -s, "$OUT_CSV" 2>/dev/null || cat "$OUT_CSV"
    echo '```'
  } > "$OUT_MD"

  echo "OK $OUT_CSV"
  echo "OK $OUT_JSON"
}

chmod +x "$AWK"
run_window "2025" "2025-01-01" "2026-12-31" 0
run_window "june2026" "2026-06-16" "2026-06-29" 0
run_window "overlap" "2025-01-01" "2026-12-31" 1

# 合并人类可读总报告
{
  echo "# 震巽 v4 近段回测对照"
  echo ""
  echo "## 为什么要做近段？"
  echo ""
  echo "全样本 corr≈0 且 v4 收益变差，部分因 2025–26 行情与新闻/逐笔层未覆盖。"
  echo "本报告切两段："
  echo ""
  echo "1. **2025+**：宏观近段（价量票全参与）"
  echo "2. **overlap**：仅有新闻或逐笔数据的交易日（七票全参与）"
  echo ""
  echo "## 全样本 v4（对照）"
  echo ""
  echo '```json'
  cat "$ARCH/backtest_v4_summary.json"
  echo '```'
  echo ""
  echo "## 近段 2025+"
  echo ""
  echo '```json'
  cat "$ARCH/backtest_v4_recent_2025_summary.json"
  echo '```'
  echo ""
  echo "## 逐笔窗 2026-06-16~29"
  echo ""
  echo '```json'
  cat "$ARCH/backtest_v4_recent_june2026_summary.json"
  echo '```'
  echo ""
  echo "## 重叠窗（新闻∪逐笔有数据日）"
  echo ""
  echo '```json'
  cat "$ARCH/backtest_v4_recent_overlap_summary.json"
  echo '```'
} > "$ARCH/BACKTEST_V4_RECENT_REPORT.md"

echo "OK $ARCH/BACKTEST_V4_RECENT_REPORT.md"
