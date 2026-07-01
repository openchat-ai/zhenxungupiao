#!/bin/sh
# 震巽股票 M1+M2 — 横截面因子评估（点时面板 + rank-IC/ICIR + 多空 + 成本）
# 纯 awk/shell，零依赖。universe = research/archive/hist_*.csv 里的全部股票。
# 注意：当前 archive 仅 8 只 → 这是【方法/管线验证】，不是研究级结论；
#       广度太小,ICIR 极不可靠(见报告"广度诊断")。加更多 hist_*.csv 即自动扩池。
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
OUT="$ROOT/research/panel"
FEAT="$ROOT/scripts/panel_features.awk"
XSEC="$ROOT/scripts/backtest_xsec.awk"
H="${H:-5}"                       # 前瞻/调仓天数
SPLIT="${SPLIT:-2024-01-01}"
FACTORS="${FACTORS:-mom,rev,vol,turn}"
mkdir -p "$OUT"

# ---- M1: 组装点时横截面面板 ----
PANEL="$OUT/panel_h${H}.csv"
{
  echo "date,code,mom,rev,vol,turn,fwd"
  for f in "$ARCH"/hist_*.csv; do awk -v h="$H" -f "$FEAT" "$f"; done
} > "$PANEL"

nstocks=$(awk -F, 'NR>1{print $2}' "$PANEL" | sort -u | wc -l | tr -d ' ')

# ---- 非重叠调仓日：按 h 步长抽样交易日 ----
REB="$OUT/reb_h${H}.txt"
awk -F, 'NR>1{print $1}' "$PANEL" | sort -u | awk -v h="$H" 'NR%h==1' > "$REB"
nreb=$(wc -l < "$REB" | tr -d ' ')

# ---- M2: 横截面 rank-IC / ICIR ----
AGG="$OUT/xsec_agg.csv"
{
  echo "factor,segment,n_periods,mean_ic,ic_t,icir,ls_ann_gross,ls_t,lo_ann_net,avg_breadth"
  awk -v rebfile="$REB" -v split_date="$SPLIT" -v h="$H" -v factors="$FACTORS" \
      -f "$XSEC" "$PANEL"
} > "$AGG"

# ---- Bonferroni 临界 t（因子族大小 = 因子数）----
nfac=$(echo "$FACTORS" | awk -F, '{print NF}')
critt=$(awk -v m="$nfac" 'function erf(x, t,y,s,a1,a2,a3,a4,a5,p){s=(x<0)?-1:1;x=(x<0)?-x:x;
  a1=0.254829592;a2=-0.284496736;a3=1.421413741;a4=-1.453152027;a5=1.061405429;p=0.3275911;
  t=1/(1+p*x);y=1-(((((a5*t+a4)*t)+a3)*t+a2)*t+a1)*t*exp(-x*x);return s*y}
  function pv2(t){if(t<0)t=-t;return 1-erf(t/1.4142135623730951)}
  BEGIN{tg=0.05/m;lo=0;hi=8;for(i=0;i<80;i++){md=(lo+hi)/2;if(pv2(md)>tg)lo=md;else hi=md}printf "%.3f",(lo+hi)/2}')

# ---- 报告 ----
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REP="$OUT/XSEC_REPORT.md"
{
  echo "# 震巽 横截面因子评估（M1 面板 + M2 rank-IC/ICIR）"
  echo ""
  echo "- 生成: \`make research-xsec\` · $TS"
  echo "- 引擎: \`scripts/panel_features.awk\`（点时特征）+ \`scripts/backtest_xsec.awk\`（横截面 IC）"
  echo "- Universe: **$nstocks** 只（archive hist_*.csv）· 调仓周期 h=**$H** 交易日 · 非重叠调仓 **$nreb** 次"
  echo "- 样本外起点: **$SPLIT** · 因子: \`$FACTORS\` · Bonferroni 临界 |t|(m=$nfac) = **$critt**"
  echo ""
  echo "## ⚠ 广度诊断（先看这个）"
  echo ""
  echo "- 主动管理基本定律 \`IR ≈ IC·√breadth\`。当前横截面每期仅约 **$nstocks** 只 →"
  echo "  \`√breadth ≈ $(awk -v n=$nstocks 'BEGIN{printf "%.1f", sqrt(n)}')\`,广度**严重不足**。"
  echo "- 因此下表**主要验证管线正确性**（IC 能算、方向合理、成本/年化到位），"
  echo "  **不足以对因子是否有效下结论**。要下结论需 §SPEC 的 M1 扩池到数百只点时成分。"
  echo ""
  echo "## 结果（样本外 OOS 优先看）"
  echo ""
  echo "| 因子 | 段 | 期数 | 均值IC | IC t | ICIR(年化) | 多空年化(毛) | 多空 t | 多头超额年化(净) | 平均广度 |"
  echo "|------|----|------|--------|------|------------|--------------|--------|------------------|----------|"
  awk -F, 'NR>1{printf "| %s | %s | %d | %+.4f | %+.2f | %+.3f | %+.4f | %+.2f | %+.4f | %.1f |\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' "$AGG" \
    | sort -t'|' -k3,3
  echo ""
  echo "## 读法"
  echo ""
  echo "1. **均值IC / IC t / ICIR** 是因子质量的金标准（Gate A 用 ICIR≥0.5 且 t 过多重检验）。"
  echo "2. **多空/多头超额** 是把 IC 变现的组合口径；A 股融券受限,多空为学术参照,实盘看**多头超额(净)**。"
  echo "3. 任何 |IC t| < $critt 都**未过多重检验**;在广度=$nstocks 下,即便数值好看也不足信。"
  echo ""
  echo "复现: \`H=$H SPLIT=$SPLIT FACTORS=$FACTORS make research-xsec\`"
} > "$REP"

echo "OK $PANEL ($nstocks stocks)"
echo "OK $REB ($nreb rebalances)"
echo "OK $AGG"
echo "OK $REP"
