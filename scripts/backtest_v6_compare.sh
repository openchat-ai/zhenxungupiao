#!/bin/bash
# v6 多维逐笔特征 → 买入/卖出指示对照（2026 tick archive）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/backtest_v6_signals.awk"
FEAT="$ARCH/tick_features_daily.csv"
FROM="2026-01-01"
TO="2026-12-31"
OUT_CSV="$ARCH/backtest_v6_compare_by_stock.csv"
OUT_JSON="$ARCH/backtest_v6_compare_summary.json"
OUT_MD="$ARCH/BACKTEST_V6_COMPARE_REPORT.md"

MODES="flow_pure vw_pure open30_pure big_pure delta_pure tail_pure chg_pure flow_delta intensity vw7 delta7 big7 contra open30_gap combo volatile_flow"

chmod +x "$ROOT/scripts/tick_features_to_daily.sh" "$AWK"
"$ROOT/scripts/tick_features_to_daily.sh"

stock_row() {
  mode="$1"
  f="$2"
  code="$3"
  name="$4"
  awk -v code="$code" -v name="$name" -v mode="$mode" \
      -v featfile="$FEAT" \
      -v date_from="$FROM" -v date_to="$TO" \
      -f "$AWK" "$f" 2>/dev/null || true
}

{
  echo "code,name,mode,n_days,strategy_return,buyhold_return,sharpe,corr_signal_nextday,corr_signal_nextopen,corr_feat_vs_nextopen,pct_buy_days"
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
    for mode in $MODES; do
      stock_row "$mode" "$f" "$code" "$name"
    done
  done
} > "$OUT_CSV"

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 按 mode 聚合
agg() {
  awk -F, -v m="$1" -v col="$2" 'NR>1 && $3==m {s+=$col; n++} END{if(n>0) printf "%.6f", s/n; else print "0"}' "$OUT_CSV"
}

best_mode=$(awk -F, 'NR>1 {
  m=$3; s[m,8]+=$8; s[m,9]+=$9; s[m,10]+=$10; s[m,5]+=$5; n[m]++
} END {
  best=""; best_ic=-999
  for (m in n) {
    ic = s[m,8]/n[m] + s[m,9]/n[m]
    if (ic > best_ic) { best_ic=ic; best=m }
  }
  print best
}' "$OUT_CSV")

{
  echo "{"
  echo "  \"version\": \"v6_signal_compare\","
  echo "  \"generated_at\": \"$ts\","
  echo "  \"window\": \"2026 tick archive (115 trading days x 8 stocks)\","
  echo "  \"modes\": [$(echo $MODES | sed 's/ /", "/g;s/^/"/;s/$/"/')],"
  echo "  \"best_mode_by_ic_sum\": \"$best_mode\","
  for mode in $MODES; do
    echo "  \"${mode}_mean_return\": $(agg "$mode" 5),"
    echo "  \"${mode}_mean_sharpe\": $(agg "$mode" 7),"
    echo "  \"${mode}_corr_nextday\": $(agg "$mode" 8),"
    echo "  \"${mode}_corr_nextopen\": $(agg "$mode" 9),"
    echo "  \"${mode}_corr_feat_nextopen\": $(agg "$mode" 10),"
    echo "  \"${mode}_beats_buyhold\": $(awk -F, -v m="$mode" '$3==m && $5+0>$6+0 {c++} END{print c+0}' "$OUT_CSV"),"
  done
  echo "  \"note\": \"IC>0.03 stable = worth integrating; else research-only\""
  echo "}"
} > "$OUT_JSON"

{
  echo "# v6 买入/卖出指示对照（多维逐笔特征）"
  echo ""
  echo "生成：\`make research-v6-compare\`"
  echo ""
  echo "## 模式说明"
  echo ""
  echo "| 模式 | 逻辑 |"
  echo "|------|------|"
  echo "| **flow_pure** | 全日主动买% 纯指示（≥55买 ≤45卖） |"
  echo "| **vw_pure** | **成交量加权**主动买% 纯指示 |"
  echo "| **open30_pure** | 开盘 30 分钟主动买% 纯指示 |"
  echo "| **big_pure** | **大单**（≥100股）主动买% 纯指示 |"
  echo "| **delta_pure** | 上午−下午主动买差 纯指示 |"
  echo "| **tail_pure** | 尾盘 30 分钟主动买% 纯指示 |"
  echo "| **chg_pure** | 主动买% **日变化** 纯指示 |"
  echo "| **flow_delta** | flow + 上午/下午分化 **双确认** |"
  echo "| **intensity** | 加权强度分（flow+vw+delta） |"
  echo "| **vw7** | 六票 + 成交量加权第 7 票 |"
  echo "| **delta7** | 六票 + 上午/下午分化第 7 票 |"
  echo "| **big7** | 六票 + 大单第 7 票 |"
  echo "| **contra** | 价量背离：跌+强买=买，涨+强卖=卖 |"
  echo "| **open30_gap** | 开盘 30 分 flow → 赌次日跳空 |"
  echo "| **combo** | 六票 + vw 第7票 + delta 否决 |"
  echo "| **volatile_flow** | 仅高振幅日（\|Δ\|≥1%）用 flow 决策 |"
  echo ""
  echo "## 组合均值（按 mode 八股平均）"
  echo ""
  echo "| mode | 收益 | Sharpe | corr→次日 | corr→跳空 | feat→跳空 | 跑赢B&H |"
  echo "|------|------|--------|-----------|-----------|------------|---------|"
  for mode in $MODES; do
    ret=$(agg "$mode" 5)
    sh=$(agg "$mode" 7)
    cn=$(agg "$mode" 8)
    cg=$(agg "$mode" 9)
    fg=$(agg "$mode" 10)
    bm=$(awk -F, -v m="$mode" '$3==m && $5+0>$6+0 {c++} END{print c+0}' "$OUT_CSV")
    echo "| **$mode** | $ret | $sh | $cn | $cg | $fg | $bm/8 |"
  done
  echo ""
  echo "**IC 综合最佳 mode**：\`$best_mode\`"
  echo ""
  echo "## 完整 JSON"
  echo ""
  echo '```json'
  cat "$OUT_JSON"
  echo '```'
  echo ""
  echo "## 分标的明细"
  echo '```'
  column -t -s, "$OUT_CSV" 2>/dev/null || cat "$OUT_CSV"
  echo '```'
} > "$OUT_MD"

echo "OK $OUT_CSV"
echo "OK $OUT_JSON"
echo "OK $OUT_MD"
echo "Best mode by IC sum: $best_mode"
