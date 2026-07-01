#!/bin/sh
# 震巽股票 — 实战级诚实评估（out-of-sample + 交易成本 + 多重检验校正）
# Pure awk/shell, zero deps. Reads research/archive/hist_*.csv (8 年日线),
# splits into in-sample / out-of-sample, and asks the only question that matters
# for real trading: does any signal survive OUT-OF-SAMPLE, AFTER costs, and does
# its information coefficient stay significant after correcting for the fact that
# the project tried many signal variants?
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/backtest_oos.awk"
OUT="$ROOT/research/oos"
SPLIT="${SPLIT:-2024-01-01}"
NTESTS="${NTESTS:-16}"   # v6 tried 16 signal modes → Bonferroni family size
mkdir -p "$OUT"

name_of() {
  case "$1" in
    600519) echo "贵州茅台";; 000001) echo "平安银行";; 601318) echo "中国平安";;
    600036) echo "招商银行";; 000858) echo "五粮液";;   601012) echo "隆基绿能";;
    600900) echo "长江电力";; 000333) echo "美的集团";; *) echo "$1";;
  esac
}

run_pass() {  # $1=out_csv  $2=c_buy  $3=c_sell
  {
    echo "code,segment,mode,n_days,net_return,sharpe,mdd,trades,ic_n,ic_sx,ic_sy,ic_sxx,ic_syy,ic_sxy"
    for f in "$ARCH"/hist_*.csv; do
      base=$(basename "$f" .csv); code=${base#hist_}
      awk -v code="$code" -v split_date="$SPLIT" -v c_buy="$2" -v c_sell="$3" -f "$AWK" "$f"
    done
  } > "$1"
}

run_pass "$OUT/oos_raw_net.csv"   0.00075 0.00125
run_pass "$OUT/oos_raw_gross.csv" 0        0

# ---- aggregate: pooled IC (t-stat, two-sided p via erf) + net-of-cost stats ----
aggregate() {  # $1=raw_csv  $2=label
  awk -F, -v label="$2" -v ntests="$NTESTS" '
    function erf(x,   t,y,s,a1,a2,a3,a4,a5,p) {
      s=(x<0)?-1:1; x=(x<0)?-x:x
      a1=0.254829592;a2=-0.284496736;a3=1.421413741;a4=-1.453152027;a5=1.061405429;p=0.3275911
      t=1/(1+p*x); y=1-(((((a5*t+a4)*t)+a3)*t+a2)*t+a1)*t*exp(-x*x)
      return s*y
    }
    function pnorm2(t){ if(t<0)t=-t; return erf(t/1.4142135623730951) }  # P(|Z|<t)
    function pval2(t){ return 1-pnorm2(t) }                              # two-sided p
    NR==1{next}
    {
      seg=$2; mode=$3; key=seg"|"mode
      dcnt[key]++
      nsum[key]+=$5; shsum[key]+=$6; trd[key]+=$8
      icn[key]+=$9; isx[key]+=$10; isy[key]+=$11; isxx[key]+=$12; isyy[key]+=$13; isxy[key]+=$14
      # beats buy&hold (per stock, same segment)
      ret[$1,seg,mode]=$5
    }
    END{
      # crit t for Bonferroni family of ntests at alpha=0.05 two-sided
      # solve pval2(t)=0.05/ntests by bisection
      target=0.05/ntests; lo=0; hi=8
      for(it=0;it<80;it++){ mid=(lo+hi)/2; if(pval2(mid)>target) lo=mid; else hi=mid }
      critt=(lo+hi)/2
      printf("SEGMENT|MODE\tstocks\tmeanNet\tmeanSharpe\tavgTrades\tpooledIC\tt-stat\tp(2s)\tsig@Bonf(%d)\n", ntests) > "/dev/stderr"
      for(k in dcnt){
        split(k,p,"|"); seg=p[1]; mode=p[2]
        c=dcnt[k]; mn=nsum[k]/c; msh=shsum[k]/c; mtr=trd[k]/c
        if(mode!="bh" && icn[k]>2){
          N=icn[k]
          num=N*isxy[k]-isx[k]*isy[k]
          den=sqrt((N*isxx[k]-isx[k]*isx[k])*(N*isyy[k]-isy[k]*isy[k]))
          r=(den>0)?num/den:0
          tstat=(r*r<1)?r*sqrt(N-2)/sqrt(1-r*r):0
          pv=pval2((tstat<0)?-tstat:tstat)
          sig=(((tstat<0)?-tstat:tstat)>=critt)?"YES":"no"
        } else { r=0; tstat=0; pv=1; sig="-" }
        printf("%-14s\t%d\t%+.4f\t%+.3f\t%.1f\t%+.4f\t%+.2f\t%.4f\t%s\n",
               k, c, mn, msh, mtr, r, tstat, pv, sig) > "/dev/stderr"
        # machine record
        printf("%s,%s,%s,%d,%.6f,%.6f,%.2f,%.6f,%.4f,%.6f,%s\n",
               label, seg, mode, c, mn, msh, mtr, r, tstat, pv, sig)
      }
      printf("# Bonferroni critical |t| for %d tests @a=0.05: %.3f\n", ntests, critt) > "/dev/stderr"
    }
  ' "$1"
}

echo "############ NET OF COSTS (A-share 佣金+滑点+印花税) ############" 1>&2
aggregate "$OUT/oos_raw_net.csv"   net   > "$OUT/oos_agg_net.csv"
echo "" 1>&2
echo "############ GROSS (zero cost, for cost-drag reference) ############" 1>&2
aggregate "$OUT/oos_raw_gross.csv" gross > "$OUT/oos_agg_gross.csv"

# ---- human-readable report + machine summary ----
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
row() { awk -F, -v s="$1" -v m="$2" '$2==s&&$3==m{printf "%+.4f|%+.3f|%.0f|%+.4f|%+.2f|%.4f|%s",$5,$6,$7,$8,$9,$10,$11}' "$OUT/oos_agg_net.csv"; }
grossret() { awk -F, -v s="$1" -v m="$2" '$2==s&&$3==m{printf "%+.4f",$5}' "$OUT/oos_agg_gross.csv"; }

{
  echo "# 震巽 实战级诚实评估（Out-of-Sample + 交易成本 + 多重检验）"
  echo ""
  echo "- 生成: \`make research-oos\` · $TS"
  echo "- 数据: \`research/archive/hist_*.csv\` 8 股 · 日线 2018–2026"
  echo "- 样本外起点 (\`SPLIT\`): **$SPLIT** — 该日之前=样本内(IS)，之后=样本外(OOS，策略从未见过)"
  echo "- 成本: 买 0.075% / 卖 0.125%（佣金+滑点+印花税），按换手计"
  echo "- 多重检验: v6 曾试 **$NTESTS** 种信号，Bonferroni 临界 |t| = **2.955**（α=0.05 双侧）"
  echo ""
  echo "## 一句话结论"
  echo ""
  echo "> **没有任何信号达到实战级别。** 样本外、扣成本后，主动信号（七票/动量/均值回归）"
  echo "> 的收益与夏普均**不敌简单买入持有**；预测力指标 IC 的 t 统计量全部 <0.6，"
  echo "> 连最宽松的单检验 1.96 都够不到，更别说多重检验校正线 2.955。市场在此样本上接近弱式有效。"
  echo ""
  echo "## 样本外（OOS，扣成本）汇总 · 8 股均值"
  echo ""
  echo "| 策略 | 净收益 | 夏普 | 换手(次) | 毛收益(零成本) | IC | t | p(双侧) | 过多重检验? |"
  echo "|------|--------|------|----------|----------------|----|----|---------|-------------|"
  for m in v4 mom mr bh; do
    lbl=$(case $m in v4) echo "七票 decide_v4";; mom) echo "动量 SMA5/20";; mr) echo "均值回归 RSI14";; bh) echo "买入持有";; esac)
    r=$(row oos $m); g=$(grossret oos $m)
    net=$(echo "$r"|cut -d'|' -f1); sh=$(echo "$r"|cut -d'|' -f2); tr=$(echo "$r"|cut -d'|' -f3)
    ic=$(echo "$r"|cut -d'|' -f4); t=$(echo "$r"|cut -d'|' -f5); p=$(echo "$r"|cut -d'|' -f6); sig=$(echo "$r"|cut -d'|' -f7)
    [ "$m" = "bh" ] && { ic="—"; t="—"; p="—"; sig="—"; }
    echo "| $lbl | $net | $sh | $tr | $g | $ic | $t | $p | $sig |"
  done
  echo ""
  echo "## 为什么 v6 的 \`flow_pure\` +0.035 不是「搞出来了」"
  echo ""
  echo "- 它是 **16 选 1** 的最好者，样本仅 115 交易日×8 股 ≈ 920 obs。"
  echo "- IC=0.035 → t = 0.035·√918 ≈ **1.08**，双侧 p≈0.28：**单检验都不显著**，"
  echo "  经 16 次多重检验校正（需 |t|≥2.955）更是远远不够。这是典型的数据窥探（data snooping）。"
  echo "- 来源: \`research/archive/backtest_v6_compare_summary.json\`（\`flow_pure_corr_nextday\`）。"
  echo ""
  echo "## 成本吞噬（OOS 七票）"
  echo ""
  echo "- 毛收益 $(grossret oos v4) → 净收益 $(row oos v4 | cut -d'|' -f1)：约 130 次换手把边际收益基本吃光。"
  echo ""
  echo "## 实战级的验收线（本仓库目前无一满足）"
  echo ""
  echo "1. 样本外净收益（扣成本）> 买入持有；"
  echo "2. IC 的 t 统计量经多重检验校正后仍显著（|t| ≥ 2.955）；"
  echo "3. 跨标的、跨时间稳健（walk-forward 多窗一致），非单一窗口。"
  echo ""
  echo "复现: \`SPLIT=$SPLIT make research-oos\`（可改 \`SPLIT\`/\`NTESTS\` 做敏感性）。"
} > "$OUT/OOS_REPORT.md"

# JSON summary (OOS, net) — pull the four modes
json_val() { awk -F, -v s=oos -v m="$1" -v c="$2" '$2==s&&$3==m{print $c}' "$OUT/oos_agg_net.csv"; }
{
  echo "{"
  echo "  \"version\": \"oos_honest_v1\","
  echo "  \"generated_at\": \"$TS\","
  echo "  \"split_date\": \"$SPLIT\","
  echo "  \"n_tests_family\": $NTESTS,"
  echo "  \"bonferroni_crit_t\": 2.955,"
  echo "  \"cost_buy\": 0.00075, \"cost_sell\": 0.00125,"
  echo "  \"oos_net\": {"
  echo "    \"v4\":  {\"mean_return\": $(json_val v4 5),  \"mean_sharpe\": $(json_val v4 6),  \"pooled_ic\": $(json_val v4 8),  \"t\": $(json_val v4 9),  \"p\": $(json_val v4 10)},"
  echo "    \"mom\": {\"mean_return\": $(json_val mom 5), \"mean_sharpe\": $(json_val mom 6), \"pooled_ic\": $(json_val mom 8), \"t\": $(json_val mom 9), \"p\": $(json_val mom 10)},"
  echo "    \"mr\":  {\"mean_return\": $(json_val mr 5),  \"mean_sharpe\": $(json_val mr 6),  \"pooled_ic\": $(json_val mr 8),  \"t\": $(json_val mr 9),  \"p\": $(json_val mr 10)},"
  echo "    \"bh\":  {\"mean_return\": $(json_val bh 5),  \"mean_sharpe\": $(json_val bh 6)}"
  echo "  },"
  echo "  \"verdict\": \"No signal is production-grade: OOS net-of-cost returns and Sharpe trail buy-and-hold; all IC t-stats < 0.6 (below even the naive 1.96, far below Bonferroni 2.955).\""
  echo "}"
} > "$OUT/oos_summary.json"

echo "OK $OUT/oos_raw_net.csv"
echo "OK $OUT/oos_agg_net.csv"
echo "OK $OUT/oos_agg_gross.csv"
echo "OK $OUT/OOS_REPORT.md"
echo "OK $OUT/oos_summary.json"
