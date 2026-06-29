#!/usr/bin/awk -f
# 导出 .tri 三进制存档（仅 research 期跑 once，不进 yoyo 运行时）
# 格式 v1: "TRI\1" + u16 n + n×signal_trit + n×next_ret_trit
# trit: 0=卖 1=持 2=买；next_ret: 0=跌 1=平 2=涨

BEGIN {
    FS = ","
    eta_shock = 3.0
    eta_mid   = 2.0
    calm_pct  = 1.0
    wuwen_alert = 2
    sigma_neutral = 5
}

function abs(x) { return x < 0 ? -x : x }

function yoyo_trit(x) {
    if (x > 0) return 2
    if (x < 0) return 0
    return 1
}

function sma(i, n,    s, j) {
    if (i < n) return -1
    s = 0
    for (j = 0; j < n; j++) s += px[i - j]
    return s / n
}

function vote_ma(i) {
    a = sma(i, 3); b = sma(i, 5)
    if (a < 0 || b < 0) return 1
    return yoyo_trit(a - b)
}

function vote_trend(i) {
    b = sma(i, 5)
    if (b < 0) return 1
    return yoyo_trit(px[i] - b)
}

function vote_rsi_simple(i) {
    if (i < 3) return 1
    return yoyo_trit(px[i] - px[i - 3])
}

function vote_macd_simple(i) {
    a = sma(i, 2); b = sma(i, 4)
    if (a < 0 || b < 0) return 1
    return yoyo_trit(a - b)
}

function vote_perturb(i) {
    if (i < 1) return 1
    p = abs(pct[i]) * 100
    if (p >= eta_shock) return 0
    if (p >= eta_mid) return 1
    return 2
}

function decide_v2_trit(i,    v1, v2, v3, v4, v5, s) {
    v1 = vote_ma(i); v2 = vote_trend(i); v3 = vote_rsi_simple(i)
    v4 = vote_macd_simple(i); v5 = vote_perturb(i)
    s = v1 + v2 + v3 + v4 + v5
    if (s < sigma_neutral) return 0
    if (s == sigma_neutral) return 1
    return 2
}

function ret_trit(i) {
    if (px[i+1] > px[i]) return 2
    if (px[i+1] < px[i]) return 0
    return 1
}

function write_u16(n) {
    printf "%c%c", n % 256, int(n / 256) % 256
}

NR == 1 { next }
{ px[++n] = $4 + 0 }

END {
    if (n < 25) { print "SKIP too short" > "/dev/stderr"; exit 1 }
    pct[1] = 0
    for (i = 2; i <= n; i++) pct[i] = px[i] / px[i-1] - 1

    m = 0
    for (i = 20; i <= n; i++) {
        m++
        sig[m] = decide_v2_trit(i)
        if (i < n) ret[m] = ret_trit(i)
        else ret[m] = 1
    }

    printf "TRI%c", 1
    write_u16(m)
    for (i = 1; i <= m; i++) printf "%c", sig[i]
    for (i = 1; i <= m; i++) printf "%c", ret[i]
}
