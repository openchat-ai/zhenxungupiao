#!/bin/bash
# v5 对照：v4 全日第7票 | 尾盘30分第7票 | 六票+flow否决（仅 2026 tick archive）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/backtest_v5_flow.awk"
TAIL="$ARCH/tick_tail_daily.csv"
TICK="$ARCH/tick_hist_daily.csv"
FROM="2026-01-01"
TO="2026-12-31"
OUT_CSV="$ARCH/backtest_v5_compare_by_stock.csv"
OUT_JSON="$ARCH/backtest_v5_compare_summary.json"
OUT_MD="$ARCH/BACKTEST_V5_COMPARE_REPORT.md"

chmod +x "$ROOT/scripts/tick_tail_to_daily.sh" "$AWK"
"$ROOT/scripts/tick_tail_to_daily.sh"

stock_row() {
  mode="$1"
  f="$2"
  code="$3"
  name="$4"
  awk -v code="$code" -v name="$name" -v mode="$mode" \
      -v tailfile="$TAIL" -v tickfile="$TICK" \
      -v date_from="$FROM" -v date_to="$TO" \
      -f "$AWK" "$f" 2>/dev/null || true
}

{
  echo "code,name,mode,n_days,strategy_return,buyhold_return,sharpe,corr_signal_nextday,corr_signal_nextopen,corr_flow_vs_nextopen,veto_pct"
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
    stock_row v4 "$f" "$code" "$name"
    stock_row tail "$f" "$code" "$name"
    stock_row veto "$f" "$code" "$name"
  done
} > "$OUT_CSV"

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
awk -F, -v ts="$ts" 'NR==1{next} {
  m=$3
  n[m]++
  for (i=5;i<=NF;i++) s[m,i]+=$i
} END {
  printf "{\n  \"version\": \"v5_flow_compare\",\n  \"generated_at\": \"%s\",\n", ts
  printf "  \"window\": \"%s .. %s (days with tick only)\",\n", "2026-01-01", "2026-06-29"
  printf "  \"modes\": [\"v4\", \"tail\", \"veto\"],\n"
  for (m in n) {
    printf "  \"%s_mean_return\": %.6f,\n", m, s[m,5]/n[m]
    printf "  \"%s_mean_sharpe\": %.6f,\n", m, s[m,7]/n[m]
    printf "  \"%s_corr_nextday\": %.6f,\n", m, s[m,8]/n[m]
    printf "  \"%s_corr_nextopen\": %.6f,\n", m, s[m,9]/n[m]
    printf "  \"%s_corr_flow_nextopen\": %.6f,\n", m, s[m,10]/n[m]
  }
  v4bm=0; tabm=0; vebm=0
} ' "$OUT_CSV" > "$OUT_JSON.tmp"

# 聚合 beats buyhold
v4bm=$(awk -F, '$3=="v4" && $5+0>$6+0 {c++} END{print c+0}' "$OUT_CSV")
tabm=$(awk -F, '$3=="tail" && $5+0>$6+0 {c++} END{print c+0}' "$OUT_CSV")
vebm=$(awk -F, '$3=="veto" && $5+0>$6+0 {c++} END{print c+0}' "$OUT_CSV")
v4cg=$(awk -F, '$3=="v4" {s+=$9;n++} END{printf "%.6f", s/n}' "$OUT_CSV")
tailcg=$(awk -F, '$3=="tail" {s+=$9;n++} END{printf "%.6f", s/n}' "$OUT_CSV")
vetocg=$(awk -F, '$3=="veto" {s+=$9;n++} END{printf "%.6f", s/n}' "$OUT_CSV")
v4fg=$(awk -F, '$3=="v4" {s+=$10;n++} END{printf "%.6f", s/n}' "$OUT_CSV")
tailfg=$(awk -F, '$3=="tail" {s+=$10;n++} END{printf "%.6f", s/n}' "$OUT_CSV")
vetofg=$(awk -F, '$3=="veto" {s+=$10;n++} END{printf "%.6f", s/n}' "$OUT_CSV")
vetov=$(awk -F, '$3=="veto" {s+=$11;n++} END{printf "%.6f", s/n}' "$OUT_CSV")

{
  echo "{"
  echo "  \"version\": \"v5_flow_compare\","
  echo "  \"generated_at\": \"$ts\","
  echo "  \"window\": \"2026 tick archive only\","
  echo "  \"v4_mean_return\": $(awk -F, '$3=="v4"{s+=$5;n++}END{print s/n}' "$OUT_CSV"),"
  echo "  \"tail_mean_return\": $(awk -F, '$3=="tail"{s+=$5;n++}END{print s/n}' "$OUT_CSV"),"
  echo "  \"veto_mean_return\": $(awk -F, '$3=="veto"{s+=$5;n++}END{print s/n}' "$OUT_CSV"),"
  echo "  \"v4_corr_nextday\": $(awk -F, '$3=="v4"{s+=$8;n++}END{print s/n}' "$OUT_CSV"),"
  echo "  \"tail_corr_nextday\": $(awk -F, '$3=="tail"{s+=$8;n++}END{print s/n}' "$OUT_CSV"),"
  echo "  \"veto_corr_nextday\": $(awk -F, '$3=="veto"{s+=$8;n++}END{print s/n}' "$OUT_CSV"),"
  echo "  \"v4_corr_nextopen\": $v4cg,"
  echo "  \"tail_corr_nextopen\": $tailcg,"
  echo "  \"veto_corr_nextopen\": $vetocg,"
  echo "  \"v4_corr_flow_nextopen\": $v4fg,"
  echo "  \"tail_corr_flow_nextopen\": $tailfg,"
  echo "  \"veto_corr_flow_nextopen\": $vetofg,"
  echo "  \"v4_beats_buyhold\": $v4bm,"
  echo "  \"tail_beats_buyhold\": $tabm,"
  echo "  \"veto_beats_buyhold\": $vebm,"
  echo "  \"veto_mean_veto_pct\": $vetov"
  echo "}"
} > "$OUT_JSON"

{
  echo "# v5 逐笔特征对照（免费 2026 archive）"
  echo ""
  echo "生成：\`make research-v5-compare\`"
  echo ""
  echo "| 模式 | 说明 |"
  echo "|------|------|"
  echo "| **v4** | 全日主动买% 作第 7 票（基线） |"
  echo "| **tail** | **尾盘 14:30–15:00** 主动买% 作第 7 票 |"
  echo "| **veto** | **六票** + flow 弱否决买/强否决卖 |"
  echo ""
  echo "## 组合均值"
  echo ""
  cat "$OUT_JSON"
  echo ""
  echo "## 分标的"
  echo '```'
  column -t -s, "$OUT_CSV" 2>/dev/null || cat "$OUT_CSV"
  echo '```'
  echo ""
  echo "## 怎么读"
  echo ""
  echo "- \`corr_signal_nextopen\`：信号 vs **次日开盘跳空**（close→open）"
  echo "- \`corr_flow_nextopen\`：原始 flow% vs 次日跳空（不经过七票）"
  echo "- \`veto_pct\`：否决模式下降级为「持」的比例"
} > "$OUT_MD"

echo "OK $OUT_CSV"
echo "OK $OUT_JSON"
echo "OK $OUT_MD"
