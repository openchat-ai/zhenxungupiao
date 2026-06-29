#!/usr/bin/awk -f
# v4 近段回测：按 date_from/date_to 切片（仍用全历史预热 SMA）
# -v date_from=2025-01-01  -v date_to=2026-12-31
# -v overlap_only=1  仅统计有新闻或逐笔数据的交易日

BEGIN {
    FS = ","
    eta_shock = 3.0
    eta_mid   = 2.0
    calm_pct  = 1.0
    wuwen_alert = 2
    sigma_neutral = 7
    news_bear = 35
    news_bull = 65
    tick_buy_thr = 55
    tick_sell_thr = 45
    rf = 0.02
    if (date_from == "") date_from = "2025-01-01"
    if (date_to == "") date_to = "2099-12-31"
    overlap_only = overlap_only + 0

    if (newsfile != "") {
        while ((getline line < newsfile) > 0) {
            split(line, a, ",")
            if (a[1] == "date") continue
            if (a[2] == code) news_score[a[1]] = a[3] + 0
        }
        close(newsfile)
    }
    if (tickfile != "") {
        while ((getline line < tickfile) > 0) {
            split(line, a, ",")
            if (a[1] == "date") continue
            if (a[2] == code) tick_buy_pct[a[1]] = a[3] + 0
        }
        close(tickfile)
    }
}

function abs(x) { return x < 0 ? -x : x }

function yoyo_trit(x) {
    if (x > 0) return 2
    if (x < 0) return 0
    return 1
}

function in_window(d) {
    if (d < date_from || d > date_to) return 0
    if (overlap_only) {
        if ((d in news_score) || (d in tick_buy_pct)) return 1
        return 0
    }
    return 1
}

function sma(i, n,    s, j) {
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

function vote_trend(i,    b) {
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

function vote_perturb_price(i,    p) {
    if (i < 1) return 1
    p = abs(pct[i]) * 100
    if (p >= eta_shock) return 0
    if (p >= eta_mid) return 1
    return 2
}

function vote_perturb_news(i,    v, d, ns) {
    v = vote_perturb_price(i)
    d = dt[i]
    if (d in news_score) {
        ns = news_score[d]
        if (ns <= news_bear) return 0
        if (ns >= news_bull) return 2
    }
    return v
}

function vote_psych(i,    dc, uc, hi, lo, j) {
    if (i < 5) return 1
    dc = 0
    if (px[i-1] < px[i-2]) dc++
    if (px[i] < px[i-1]) dc++
    if (dc >= 2) return 0
    uc = 0
    if (px[i-1] > px[i-2]) uc++
    if (px[i] > px[i-1]) uc++
    hi = px[i]; lo = px[i]
    for (j = 1; j <= 4; j++) {
        if (px[i-j] > hi) hi = px[i-j]
        if (px[i-j] < lo) lo = px[i-j]
    }
    if (px[i] <= lo && px[i] < px[i-1]) return 0
    if (uc >= 2 && px[i] >= hi) return 2
    return 1
}

function vote_aggressive(i,    d, p) {
    d = dt[i]
    if (d in tick_buy_pct) {
        p = tick_buy_pct[d]
        if (p >= tick_buy_thr) return 2
        if (p <= tick_sell_thr) return 0
        return 1
    }
    return 1
}

function decide_v4(i,    v1, v2, v3, v4, v5, v6, v7, s) {
    v1 = vote_ma(i); v2 = vote_trend(i); v3 = vote_rsi_simple(i)
    v4 = vote_macd_simple(i); v5 = vote_perturb_news(i); v6 = vote_psych(i)
    v7 = vote_aggressive(i)
    s = v1 + v2 + v3 + v4 + v5 + v6 + v7
    votes_sum[i] = s
    hold_votes[i] = (v1==1) + (v2==1) + (v3==1) + (v4==1) + (v5==1) + (v6==1) + (v7==1)
    wuwen_pct[i] = int(hold_votes[i] * 100 / 7 + 0.5)
    calm[i] = (abs(pct[i]) * 100 <= calm_pct) ? 1 : 0
    consensus[i] = (hold_votes[i] <= wuwen_alert && calm[i] == 0) ? 1 : 0
    if (s < sigma_neutral) return -1
    if (s == sigma_neutral) return 0
    return 1
}

function rsi14(i,    gain, loss, j, d) {
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

function run_equity_slice(mode, i0,    i, sig, r, next_pos) {
    next_pos = 0
    for (i = 1; i <= n; i++) {
        if (i > i0) {
            r = (px[i] / px[i-1] - 1) * next_pos
            if (mode == "v4") ret_v4[i] = r
            else if (mode == "mom") ret_mom[i] = r
            else ret_mr[i] = r
        }
        if (i >= 20 && in_window(dt[i])) {
            if (mode == "v4") sig = signal_v4[i]
            else if (mode == "mom") sig = signal_momentum(i)
            else sig = signal_meanrev(i)
            if (sig == 1) next_pos = 1
            else if (sig == -1) next_pos = 0
        }
    }
}

function total_return_slice(mode, i0,    i, eq) {
    eq = 1
    for (i = i0 + 1; i <= n; i++) {
        if (mode == "v4") eq *= (1 + ret_v4[i])
        else if (mode == "mom") eq *= (1 + ret_mom[i])
        else eq *= (1 + ret_mr[i])
    }
    return eq - 1
}

function sharpe_slice(mode, i0,    i, m, s, v, c) {
    m = 0; c = 0
    for (i = i0 + 1; i <= n; i++) {
        if (mode == "v4") v = ret_v4[i]
        else if (mode == "mom") v = ret_mom[i]
        else v = ret_mr[i]
        m += v; c++
    }
    if (c < 2) return 0
    m /= c
    s = 0
    for (i = i0 + 1; i <= n; i++) {
        if (mode == "v4") v = ret_v4[i] - m
        else if (mode == "mom") v = ret_mom[i] - m
        else v = ret_mr[i] - m
        s += v * v
    }
    s = sqrt(s / (c - 1))
    if (s == 0) return 0
    return (m - rf/252) / s * sqrt(252)
}

function maxdd_slice(mode, i0,    i, peak, dd, eq) {
    peak = 1; dd = 0; eq = 1
    for (i = i0 + 1; i <= n; i++) {
        if (mode == "v4") eq *= (1 + ret_v4[i])
        else if (mode == "mom") eq *= (1 + ret_mom[i])
        else eq *= (1 + ret_mr[i])
        if (eq > peak) peak = eq
        if ((eq - peak) / peak < dd) dd = (eq - peak) / peak
    }
    return dd
}

NR == 1 { next }
{
    dt[++n] = $1
    px[n] = $4 + 0
}
END {
    if (n < 60) { print "SKIP " FILENAME > "/dev/stderr"; exit 1 }
    pct[1] = 0
    for (i = 2; i <= n; i++) pct[i] = px[i] / px[i-1] - 1

    for (i = 20; i <= n; i++) signal_v4[i] = decide_v4(i)

    i0 = 0
    for (i = 20; i <= n; i++) {
        if (in_window(dt[i])) { i0 = i; break }
    }
    if (i0 == 0) {
        print "SKIP " code " no days in window" > "/dev/stderr"
        exit 1
    }

    buy = hold = sell = 0
    wuwen_sum = calm_sum = cons_sum = 0
    news_hit = tick_hit = 0
    days = 0
    for (i = 20; i <= n; i++) {
        if (!in_window(dt[i])) continue
        days++
        if (dt[i] in news_score) news_hit++
        if (dt[i] in tick_buy_pct) tick_hit++
        if (signal_v4[i] == 1) buy++
        else if (signal_v4[i] == 0) hold++
        else sell++
        wuwen_sum += wuwen_pct[i]
        calm_sum += calm[i]
        cons_sum += consensus[i]
    }
    if (days < 5) {
        print "SKIP " code " window too short (" days ")" > "/dev/stderr"
        exit 1
    }

    pct_buy = buy / days
    pct_hold = hold / days
    pct_sell = sell / days
    mean_wuwen = wuwen_sum / days
    mean_calm = calm_sum / days
    mean_consensus = cons_sum / days
    tick_cov = tick_hit / days
    news_cov = news_hit / days

    run_equity_slice("v4", i0)
    run_equity_slice("mom", i0)
    run_equity_slice("mr", i0)

    eq_v4 = total_return_slice("v4", i0)
    eq_mom = total_return_slice("mom", i0)
    eq_mr = total_return_slice("mr", i0)
    eq_bh = px[n] / px[i0] - 1

    sh_v4 = sharpe_slice("v4", i0)
    sh_mom = sharpe_slice("mom", i0)
    sh_mr = sharpe_slice("mr", i0)

    mdd_v4 = maxdd_slice("v4", i0)
    mdd_mom = maxdd_slice("mom", i0)
    mdd_mr = maxdd_slice("mr", i0)

    cnt = 0; sx = 0; sy = 0; sxx = 0; syy = 0; sxy = 0
    for (i = 20; i < n; i++) {
        if (!in_window(dt[i])) continue
        x = signal_v4[i]; y = pct[i+1]
        cnt++; sx += x; sy += y; sxx += x*x; syy += y*y; sxy += x*y
    }
    denom = sqrt(cnt*sxx - sx*sx) * sqrt(cnt*syy - sy*sy)
    corr = (denom > 0) ? (cnt*sxy - sx*sy) / denom : 0

    printf("%s,%s,%d,%s,%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
        code, name, days, date_from, date_to, overlap_only,
        pct_buy, pct_hold, pct_sell,
        mean_wuwen, mean_calm, mean_consensus,
        eq_v4, eq_mom, eq_mr, eq_bh,
        sh_v4, sh_mom, sh_mr,
        mdd_v4, mdd_mom, mdd_mr,
        corr, tick_cov, news_cov)
}
