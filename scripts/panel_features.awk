#!/usr/bin/awk -f
# 震巽股票 M1 — 点时横截面面板特征（纯 awk）
# 输入：一只股票的 hist_*.csv（含表头）
# 输出：date,code,mom,rev,vol,turn,fwd
#   所有特征仅用 <=t 信息（point-in-time）；fwd 是 t→t+h 的前瞻收益（标签）。
#   仅当全部特征与 fwd 均有效时才输出该行。
# 参数：-v h=<前瞻/调仓天数，默认 5>
BEGIN {
    FS = ","
    if (h == "") h = 5
    mom_lag = 21     # 跳过最近 21 日（12-1 动量的 "1"）
    mom_look = 252   # 约 12 个月
    rev_look = 5     # 1 周短期反转
    vol_look = 20    # 20 日已实现波动
    turn_look = 20   # 20 日平均换手
}
function std(from, to,    j, m, s, c) {
    m = 0; c = 0
    for (j = from; j <= to; j++) { m += r[j]; c++ }
    if (c < 2) return -1
    m /= c; s = 0
    for (j = from; j <= to; j++) s += (r[j]-m)*(r[j]-m)
    return sqrt(s/(c-1))
}
function mean_turn(from, to,    j, m, c) {
    m = 0; c = 0
    for (j = from; j <= to; j++) { m += tn[j]; c++ }
    return (c>0)? m/c : -1
}
NR == 1 { next }
{
    n++
    dt[n] = $1; code = $2
    px[n] = $4 + 0
    tn[n] = $12 + 0
    if (n > 1) r[n] = px[n]/px[n-1] - 1
}
END {
    if (n < mom_look + 5) { print "SKIP " FILENAME " too short" > "/dev/stderr"; exit 1 }
    for (i = 1; i <= n; i++) {
        if (i <= mom_look) continue                 # need momentum history
        if (i + h > n) continue                     # need forward window
        mom = px[i-mom_lag]/px[i-mom_look] - 1      # (t-21)/(t-252)-1, point-in-time
        rev = -(px[i]/px[i-rev_look] - 1)           # 短期反转：近 1 周收益取负
        vol = std(i-vol_look+1, i)
        turn = mean_turn(i-turn_look+1, i)
        if (vol < 0 || turn < 0) continue
        fwd = px[i+h]/px[i] - 1                      # 标签：前瞻 h 日收益
        printf("%s,%s,%.6f,%.6f,%.6f,%.6f,%.6f\n", dt[i], code, mom, rev, vol, turn, fwd)
    }
}
