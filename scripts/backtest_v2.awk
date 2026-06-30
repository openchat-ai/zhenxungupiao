#!/usr/bin/awk -f
# 震巽股票 v2 回测引擎（纯 awk，零 Python）
# 五票逻辑对齐 yoyo/lib/indicators.ty + perturbation.ty + wuwen.ty + ternary_signal.ty
# 并对比经典量化策略：动量、均值回归

BEGIN {
    FS = ","
    eta_shock = 3.0   # |日涨跌幅%| >= 3 → 卖票
    eta_mid   = 2.0   # |日涨跌幅%| >= 2 → 持票
    calm_pct  = 1.0   # |日涨跌幅%| <= 1 → 平淡市
    wuwen_alert = 2   # 持票数 <= 2 → 一致风险
    sigma_neutral = 5
    rf = 0.02
}

function abs(x) { return x < 0 ? -x : x }

function trit_sign(x,    r) {
    if (x > 0) return 1
    if (x < 0) return -1
    return 0
}

function yoyo_trit(x,    r) {
  # 0卖 1持 2买
    if (x > 0) return 2
    if (x < 0) return 0
    return 1
}

function sma(i, n,    s, j, k) {
    if (i < n) return -1
    s = 0
    for (j = 0; j < n; j++) s += px[i - j]
    return s / n
}

function vote_ma(i,    a, b) {
    a = sma(i, 3); b = sma(i, 5)
    if (a < 0 || b < 0) return 1
    return yoyo_trit(a - b)
}

function vote_trend(i,    p, b) {
    b = sma(i, 5)
    if (b < 0) return 1
    return yoyo_trit(px[i] - b)
}

function vote_rsi_simple(i,    d) {
    if (i < 3) return 1
    d = px[i] - px[i - 3]
    return yoyo_trit(d)
}

function vote_macd_simple(i,    a, b) {
    a = sma(i, 2); b = sma(i, 4)
    if (a < 0 || b < 0) return 1
    return yoyo_trit(a - b)
}

function vote_perturb(i,    p) {
    if (i < 1) return 1
    p = abs(pct[i]) * 100
    if (p >= eta_shock) return 0
    if (p >= eta_mid) return 1
    return 2
}

function decide_v2(i,    v1, v2, v3, v4, v5, s) {
    v1 = vote_ma(i); v2 = vote_trend(i); v3 = vote_rsi_simple(i)
    v4 = vote_macd_simple(i); v5 = vote_perturb(i)
    s = v1 + v2 + v3 + v4 + v5
    votes_sum[i] = s
    hold_votes[i] = (v1==1) + (v2==1) + (v3==1) + (v4==1) + (v5==1)
    wuwen_pct[i] = hold_votes[i] * 20
    calm[i] = (abs(pct[i]) * 100 <= calm_pct) ? 1 : 0
    consensus[i] = (hold_votes[i] <= wuwen_alert && calm[i] == 0) ? 1 : 0
  # signal: +1买 0持 -1卖
    if (s < sigma_neutral) return -1
    if (s == sigma_neutral) return 0
    return 1
}

function rsi14(i,    gain, loss, g, l, j, d) {
    if (i < 14) return 50
    gain = 0; loss = 0
    for (j = 0; j < 14; j++) {
        d = px[i - j] - px[i - j - 1]
        if (d > 0) gain += d; else loss -= d
    }
    if (loss == 0) return 100
    return 100 - 100 / (1 + gain / loss)
}

function signal_momentum(i,    d) {
    d = sma(i, 5) - sma(i, 20)
    if (d < 0) return -1
    if (d > 0) return 1
    return 0
}

function signal_meanrev(i,    r) {
    r = rsi14(i)
    if (r < 35) return 1
    if (r > 65) return -1
    return 0
}

function run_equity(mode,    i, sig, r, next_pos) {
    next_pos = 0
    for (i = 1; i <= n; i++) {
        if (i > 1) {
            r = (px[i] / px[i-1] - 1) * next_pos
            if (mode == "v2") ret_v2[i] = r
            else if (mode == "mom") ret_mom[i] = r
            else ret_mr[i] = r
        }
        if (mode == "v2") sig = signal_v2[i]
        else if (mode == "mom") sig = signal_momentum(i)
        else sig = signal_meanrev(i)
        if (sig == 1) next_pos = 1
        else if (sig == -1) next_pos = 0
    }
}

function total_return(mode,    i, eq) {
    eq = 1
    for (i = 2; i <= n; i++) {
        if (mode == "v2") eq *= (1 + ret_v2[i])
        else if (mode == "mom") eq *= (1 + ret_mom[i])
        else eq *= (1 + ret_mr[i])
    }
    return eq - 1
}

function sharpe_rets(mode,    i, m, s, v, c) {
    m = 0; c = 0
    for (i = 2; i <= n; i++) {
        if (mode == "v2") v = ret_v2[i]
        else if (mode == "mom") v = ret_mom[i]
        else if (mode == "mr") v = ret_mr[i]
        else v = ret_bh[i]
        m += v; c++
    }
    if (c < 2) return 0
    m /= c
    s = 0
    for (i = 2; i <= n; i++) {
        if (mode == "v2") v = ret_v2[i] - m
        else if (mode == "mom") v = ret_mom[i] - m
        else if (mode == "mr") v = ret_mr[i] - m
        else v = ret_bh[i] - m
        s += v * v
    }
    s = sqrt(s / (c - 1))
    if (s == 0) return 0
    return (m - rf/252) / s * sqrt(252)
}

function maxdd_mode(mode,    i, peak, dd, eq) {
    peak = 1; dd = 0; eq = 1
    for (i = 2; i <= n; i++) {
        if (mode == "v2") eq *= (1 + ret_v2[i])
        else if (mode == "mom") eq *= (1 + ret_mom[i])
        else eq *= (1 + ret_mr[i])
        if (eq > peak) peak = eq
        if ((eq - peak) / peak < dd) dd = (eq - peak) / peak
    }
    return dd
}

NR == 1 { next }
{
    px[++n] = $4 + 0
}
END {
    if (n < 60) { print "SKIP " FILENAME " too short" > "/dev/stderr"; exit 1 }
    pct[1] = 0
    for (i = 2; i <= n; i++) pct[i] = px[i] / px[i-1] - 1

    buy = hold = sell = 0
  wuwen_sum = calm_sum = cons_sum = 0
    for (i = 20; i <= n; i++) signal_v2[i] = decide_v2(i)
    for (i = 20; i <= n; i++) {
        if (signal_v2[i] == 1) buy++
        else if (signal_v2[i] == 0) hold++
        else sell++
        wuwen_sum += wuwen_pct[i]
        calm_sum += calm[i]
        cons_sum += consensus[i]
    }
    days = n - 19
    pct_buy = buy / days
    pct_hold = hold / days
    pct_sell = sell / days
    mean_wuwen = wuwen_sum / days
    mean_calm = calm_sum / days
    mean_consensus = cons_sum / days

    run_equity("v2")
    run_equity("mom")
    run_equity("mr")
    for (i = 2; i <= n; i++) ret_bh[i] = px[i] / px[i-1] - 1

    eq_v2 = total_return("v2")
    eq_mom = total_return("mom")
    eq_mr = total_return("mr")
    eq_bh = px[n] / px[20] - 1

    sh_v2 = sharpe_rets("v2")
    sh_mom = sharpe_rets("mom")
    sh_mr = sharpe_rets("mr")

    mdd_v2 = maxdd_mode("v2")
    mdd_mom = maxdd_mode("mom")
    mdd_mr = maxdd_mode("mr")

    cnt = 0; sx = 0; sy = 0; sxx = 0; syy = 0; sxy = 0
    for (i = 20; i < n; i++) {
        x = signal_v2[i]; y = pct[i+1]
        cnt++; sx += x; sy += y; sxx += x*x; syy += y*y; sxy += x*y
    }
    denom = sqrt(cnt*sxx - sx*sx) * sqrt(cnt*syy - sy*sy)
    corr = (denom > 0) ? (cnt*sxy - sx*sy) / denom : 0

    printf("%s,%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
        code, name, days,
        pct_buy, pct_hold, pct_sell,
        mean_wuwen, mean_calm, mean_consensus,
        eq_v2 - 1, eq_mom - 1, eq_mr - 1, eq_bh - 1,
        sh_v2, sh_mom, sh_mr,
        mdd_v2, mdd_mom, mdd_mr,
        corr)
}
