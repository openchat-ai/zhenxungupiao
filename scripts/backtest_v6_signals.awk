#!/usr/bin/awk -f
# v6 逐笔多维特征 → 买入/卖出指示对照
# -v mode= 见 decide_* 函数
# -v featfile= tick_features_daily.csv
# -v date_from= -v date_to=

BEGIN {
    FS = ","
    eta_shock = 3.0
    eta_mid   = 2.0
    wuwen_alert = 2
    sigma6 = 6
    sigma7 = 7
    tick_buy = 55
    tick_sell = 45
    rf = 0.02
    if (date_from == "") date_from = "2026-01-01"
    if (date_to == "") date_to = "2099-12-31"
    if (mode == "") mode = "flow_pure"

    if (featfile != "") {
        while ((getline line < featfile) > 0) {
            split(line, a, ",")
            if (a[1] == "date" || a[2] != code) continue
            k = a[1]
            day_buy[k] = a[3] + 0
            vw_buy[k] = a[5] + 0
            open30[k] = a[7] + 0
            am_buy[k] = a[8] + 0
            pm_buy[k] = a[9] + 0
            tail_buy[k] = a[10] + 0
            am_pm_delta[k] = a[11] + 0
            big_buy[k] = a[12] + 0
            flow_chg[k] = a[14] + 0
        }
        close(featfile)
    }
}

function abs(x) { return x < 0 ? -x : x }

function yoyo_trit(x) {
    if (x > 0) return 2
    if (x < 0) return 0
    return 1
}

function in_window(d) {
    return (d >= date_from && d <= date_to && (d in day_buy))
}

function flow_trit(p) {
    if (p < 0) return 1
    if (p >= tick_buy) return 2
    if (p <= tick_sell) return 0
    return 1
}

function flow_to_sig(t) {
    if (t == 2) return 1
    if (t == 0) return -1
    return 0
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

function vote_perturb(i,    p) {
    if (i < 1) return 1
    p = abs(pct[i]) * 100
    if (p >= eta_shock) return 0
    if (p >= eta_mid) return 1
    return 2
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

function decide_six(i,    s) {
    s = vote_ma(i) + vote_trend(i) + vote_rsi_simple(i) + vote_macd_simple(i)
    s += vote_perturb(i) + vote_psych(i)
    if (s < sigma6) return -1
    if (s == sigma6) return 0
    return 1
}

function delta_trit(d) {
    if (d >= 5) return 2
    if (d <= -5) return 0
    return 1
}

function feat_val(d,    p, delta) {
    if (mode == "vw_pure") p = vw_buy[d]
    else if (mode == "open30_pure") p = open30[d]
    else if (mode == "big_pure") p = big_buy[d]
    else if (mode == "delta_pure") return flow_to_sig(delta_trit(am_pm_delta[d]))
    else if (mode == "tail_pure") p = tail_buy[d]
    else if (mode == "chg_pure") return flow_to_sig(yoyo_trit(flow_chg[d]))
    else p = day_buy[d]
    return flow_to_sig(flow_trit(p))
}

function decide_flow_pure(i,    d) {
    d = dt[i]
    if (!(d in day_buy)) return 0
    return feat_val(d)
}

function decide_vw7(i,    d, v7, s) {
    s = vote_ma(i) + vote_trend(i) + vote_rsi_simple(i) + vote_macd_simple(i)
    s += vote_perturb(i) + vote_psych(i)
    d = dt[i]
    if (d in vw_buy && vw_buy[d] >= 0) {
        v7 = flow_trit(vw_buy[d])
        s += v7
    } else v7 = 1
    if (s < sigma7) return -1
    if (s == sigma7) return 0
    return 1
}

function decide_delta7(i,    d, v7, s, delta) {
    s = vote_ma(i) + vote_trend(i) + vote_rsi_simple(i) + vote_macd_simple(i)
    s += vote_perturb(i) + vote_psych(i)
    d = dt[i]
    if (d in am_pm_delta) {
        delta = am_pm_delta[d]
        if (delta >= 5) v7 = 2
        else if (delta <= -5) v7 = 0
        else v7 = 1
        s += v7
    } else v7 = 1
    if (s < sigma7) return -1
    if (s == sigma7) return 0
    return 1
}

function decide_big7(i,    d, v7, s) {
    s = vote_ma(i) + vote_trend(i) + vote_rsi_simple(i) + vote_macd_simple(i)
    s += vote_perturb(i) + vote_psych(i)
    d = dt[i]
    if (d in big_buy && big_buy[d] >= 0) {
        v7 = flow_trit(big_buy[d])
        s += v7
    } else v7 = 1
    if (s < sigma7) return -1
    if (s == sigma7) return 0
    return 1
}

function decide_contra(i,    d, p, ret) {
    d = dt[i]
    if (!(d in day_buy)) return 0
    p = day_buy[d]
    ret = pct[i] * 100
    # 价跌 + 主动买强 → 吸筹买；价涨 + 主动卖强 → 派发卖
    if (ret <= -1.5 && p >= tick_buy) return 1
    if (ret >= 1.5 && p <= tick_sell) return -1
    if (p >= tick_buy) return 1
    if (p <= tick_sell) return -1
    return 0
}

function decide_open30_gap(i,    d, p) {
    d = dt[i]
    if (!(d in open30) || open30[d] < 0) return 0
    p = open30[d]
    if (p >= tick_buy) return 1
    if (p <= tick_sell) return -1
    return 0
}

function decide_combo(i,    d, sig, p, delta, v7, s) {
    # 六票 + 成交量加权第7票 + delta 否决
    sig = decide_six(i)
    d = dt[i]
    if (!(d in day_buy)) return sig
    p = vw_buy[d]
    delta = am_pm_delta[d]
    if (sig == 1 && (p <= tick_sell || delta <= -8)) return 0
    if (sig == -1 && (p >= tick_buy || delta >= 8)) return 0
    if (sig != 0) return sig
    # 六票持平时，用 flow 打破
    s = vote_ma(i) + vote_trend(i) + vote_rsi_simple(i) + vote_macd_simple(i)
    s += vote_perturb(i) + vote_psych(i)
    if (p >= 0) {
        v7 = flow_trit(p)
        s += v7
    }
    if (s < sigma7) return -1
    if (s == sigma7) return 0
    return 1
}

function decide_volatile_flow(i,    d, p) {
    d = dt[i]
    if (!(d in day_buy)) return decide_six(i)
    if (abs(pct[i]) * 100 < 1.0) return decide_six(i)
    p = day_buy[d]
    if (p >= tick_buy) return 1
    if (p <= tick_sell) return -1
    return 0
}

function decide_flow_delta(i,    d, p, delta, score) {
    d = dt[i]
    if (!(d in day_buy)) return 0
    p = day_buy[d]
    delta = am_pm_delta[d]
    score = 0
    if (p >= tick_buy) score++
    if (p <= tick_sell) score--
    if (delta >= 5) score++
    if (delta <= -5) score--
    if (score >= 2) return 1
    if (score <= -2) return -1
    if (score == 1) return 1
    if (score == -1) return -1
    return 0
}

function decide_intensity(i,    d, p, delta, vw, score) {
    d = dt[i]
    if (!(d in day_buy)) return 0
    p = day_buy[d]
    delta = am_pm_delta[d]
    vw = vw_buy[d]
    score = (p - 50) * 0.4 + (vw - 50) * 0.3 + delta * 0.3
    if (score >= 3) return 1
    if (score <= -3) return -1
    return 0
}

function pick_signal(i) {
    if (mode ~ /_pure$/) return decide_flow_pure(i)
    if (mode == "flow_delta") return decide_flow_delta(i)
    if (mode == "intensity") return decide_intensity(i)
    if (mode == "vw7") return decide_vw7(i)
    if (mode == "delta7") return decide_delta7(i)
    if (mode == "big7") return decide_big7(i)
    if (mode == "contra") return decide_contra(i)
    if (mode == "open30_gap") return decide_open30_gap(i)
    if (mode == "combo") return decide_combo(i)
    if (mode == "volatile_flow") return decide_volatile_flow(i)
    return decide_flow_pure(i)
}

function run_slice(i0,    i, sig, next_pos) {
    next_pos = 0
    for (i = 1; i <= n; i++) {
        if (i > i0) ret[i] = (px[i] / px[i-1] - 1) * next_pos
        if (i >= 20 && in_window(dt[i])) {
            sig = pick_signal(i)
            signal[i] = sig
            if (sig == 1) next_pos = 1
            else if (sig == -1) next_pos = 0
        }
    }
}

function total_ret(i0,    i, eq) {
    eq = 1
    for (i = i0 + 1; i <= n; i++) eq *= (1 + ret[i])
    return eq - 1
}

function sharpe_slice(i0,    i, m, s, c, v) {
    m = 0; c = 0
    for (i = i0 + 1; i <= n; i++) { m += ret[i]; c++ }
    if (c < 2) return 0
    m /= c
    s = 0
    for (i = i0 + 1; i <= n; i++) {
        v = ret[i] - m
        s += v * v
    }
    s = sqrt(s / (c - 1))
    if (s == 0) return 0
    return (m - rf/252) / s * sqrt(252)
}

function corr_xy(i0, use_gap,    i, cnt, sx, sy, sxx, syy, sxy, x, y, d) {
    cnt = 0; sx = sy = sxx = syy = sxy = 0
    for (i = i0; i < n; i++) {
        if (!in_window(dt[i])) continue
        x = signal[i]
        if (use_gap) y = gap[i]
        else y = pct[i+1]
        cnt++
        sx += x; sy += y; sxx += x*x; syy += y*y; sxy += x*y
    }
    d = sqrt(cnt*sxx - sx*sx) * sqrt(cnt*syy - sy*sy)
    if (d <= 0) return 0
    return (cnt*sxy - sx*sy) / d
}

function corr_feat_gap(i0,    i, cnt, sx, sy, sxx, syy, sxy, x, y, d, dd) {
    cnt = 0; sx = sy = sxx = syy = sxy = 0
    for (i = i0; i < n; i++) {
        if (!in_window(dt[i])) continue
        dd = dt[i]
        if (mode == "vw_pure" || mode == "vw7" || mode == "combo") x = vw_buy[dd]
        else if (mode == "open30_pure" || mode == "open30_gap") x = open30[dd]
        else if (mode == "big_pure" || mode == "big7") x = big_buy[dd]
        else if (mode == "delta_pure" || mode == "delta7") x = am_pm_delta[dd]
        else if (mode == "tail_pure") x = tail_buy[dd]
        else if (mode == "chg_pure") x = flow_chg[dd]
        else x = day_buy[dd]
        if (x < 0) continue
        y = gap[i]
        cnt++
        sx += x; sy += y; sxx += x*x; syy += y*y; sxy += x*y
    }
    d = sqrt(cnt*sxx - sx*sx) * sqrt(cnt*syy - sy*sy)
    if (d <= 0) return 0
    return (cnt*sxy - sx*sy) / d
}

function pct_buy(i0,    i, c, b) {
    c = 0; b = 0
    for (i = i0; i <= n; i++) {
        if (!in_window(dt[i])) continue
        c++
        if (signal[i] == 1) b++
    }
    return (c > 0) ? 100 * b / c : 0
}

NR == 1 { next }
{
    dt[++n] = $1
    op[n] = $3 + 0
    px[n] = $4 + 0
}
END {
    if (n < 60) exit 1
    pct[1] = 0
    gap[n] = 0
    for (i = 2; i <= n; i++) pct[i] = px[i] / px[i-1] - 1
    for (i = 1; i < n; i++) {
        if (op[i+1] > 0 && px[i] > 0) gap[i] = op[i+1] / px[i] - 1
    }

    i0 = 0
    for (i = 20; i <= n; i++) {
        if (in_window(dt[i])) { i0 = i; break }
    }
    if (i0 == 0) exit 1

    days = 0
    for (i = 20; i <= n; i++) if (in_window(dt[i])) days++

    run_slice(i0)

    eq = total_ret(i0)
    sh = sharpe_slice(i0)
    eq_bh = px[n] / px[i0] - 1
    c_next = corr_xy(i0, 0)
    c_gap = corr_xy(i0, 1)
    c_feat_gap = corr_feat_gap(i0)
    pb = pct_buy(i0)

    printf("%s,%s,%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
        code, name, mode, days, eq, eq_bh, sh,
        c_next, c_gap, c_feat_gap, pb)
}
