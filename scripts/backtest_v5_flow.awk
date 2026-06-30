#!/usr/bin/awk -f
# v5 逐笔特征对照：v4 全日第7票 | 尾盘30分第7票 | 六票+flow否决
# -v mode=v4|tail|veto
# -v tailfile= -v tickfile= -v date_from= -v date_to=

BEGIN {
    FS = ","
    eta_shock = 3.0
    eta_mid   = 2.0
    calm_pct  = 1.0
    wuwen_alert = 2
    sigma6 = 6
    sigma7 = 7
    tick_buy = 55
    tick_sell = 45
    rf = 0.02
    if (date_from == "") date_from = "2026-01-01"
    if (date_to == "") date_to = "2099-12-31"
    if (mode == "") mode = "v4"
    veto_n = 0

    if (tickfile != "") {
        while ((getline line < tickfile) > 0) {
            split(line, a, ",")
            if (a[1] == "date" || a[2] != code) continue
            day_buy[a[1]] = a[3] + 0
        }
        close(tickfile)
    }
    if (tailfile != "") {
        while ((getline line < tailfile) > 0) {
            split(line, a, ",")
            if (a[1] == "date" || a[2] != code) continue
            tail_buy[a[1]] = a[3] + 0
            if (a[6] != "") day_buy[a[1]] = a[6] + 0
        }
        close(tailfile)
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

function flow_trit(p) {
    if (p < 0) return 1
    if (p >= tick_buy) return 2
    if (p <= tick_sell) return 0
    return 1
}

function decide_six(i,    v1, v2, v3, v4, v5, v6, s) {
    v1 = vote_ma(i); v2 = vote_trend(i); v3 = vote_rsi_simple(i)
    v4 = vote_macd_simple(i); v5 = vote_perturb(i); v6 = vote_psych(i)
    s = v1 + v2 + v3 + v4 + v5 + v6
    if (s < sigma6) return -1
    if (s == sigma6) return 0
    return 1
}

function decide_v4(i,    v7, s, d, p) {
    s = vote_ma(i) + vote_trend(i) + vote_rsi_simple(i) + vote_macd_simple(i)
    s += vote_perturb(i) + vote_psych(i)
    d = dt[i]
    if (d in day_buy) {
        p = day_buy[d]
        v7 = flow_trit(p)
        s += v7
    } else v7 = 1
    if (s < sigma7) return -1
    if (s == sigma7) return 0
    return 1
}

function decide_tail(i,    v7, s, d, p) {
    s = vote_ma(i) + vote_trend(i) + vote_rsi_simple(i) + vote_macd_simple(i)
    s += vote_perturb(i) + vote_psych(i)
    d = dt[i]
    if (d in tail_buy) {
        p = tail_buy[d]
        if (p < 0) v7 = 1
        else v7 = flow_trit(p)
        s += v7
    } else v7 = 1
    if (s < sigma7) return -1
    if (s == sigma7) return 0
    return 1
}

function decide_veto(i,    sig, d, p) {
    sig = decide_six(i)
    d = dt[i]
    if (!(d in day_buy)) return sig
    p = day_buy[d]
    if (sig == 1 && p <= tick_sell) { veto_n++; return 0 }
    if (sig == -1 && p >= tick_buy) { veto_n++; return 0 }
    return sig
}

function pick_signal(i) {
    if (mode == "tail") return decide_tail(i)
    if (mode == "veto") return decide_veto(i)
    return decide_v4(i)
}

function run_slice(i0,    i, sig, next_pos, r) {
    next_pos = 0
    for (i = 1; i <= n; i++) {
        if (i > i0) {
            r = (px[i] / px[i-1] - 1) * next_pos
            ret[i] = r
        }
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
        if (use_gap) {
            if (i >= n) continue
            y = gap[i]
        } else y = pct[i+1]
        cnt++
        sx += x; sy += y; sxx += x*x; syy += y*y; sxy += x*y
    }
    d = sqrt(cnt*sxx - sx*sx) * sqrt(cnt*syy - sy*sy)
    if (d <= 0) return 0
    return (cnt*sxy - sx*sy) / d
}

function corr_flow_gap(i0,    i, cnt, sx, sy, sxx, syy, sxy, x, y, d) {
    cnt = 0; sx = sy = sxx = syy = sxy = 0
    for (i = i0; i < n; i++) {
        if (!in_window(dt[i])) continue
        d = dt[i]
        if (mode == "tail") {
            if (!(d in tail_buy) || tail_buy[d] < 0) continue
            x = tail_buy[d]
        } else {
            if (!(d in day_buy)) continue
            x = day_buy[d]
        }
        y = gap[i]
        cnt++
        sx += x; sy += y; sxx += x*x; syy += y*y; sxy += x*y
    }
    d = sqrt(cnt*sxx - sx*sx) * sqrt(cnt*syy - sy*sy)
    if (d <= 0) return 0
    return (cnt*sxy - sx*sy) / d
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
    for (i = 2; i <= n; i++) {
        pct[i] = px[i] / px[i-1] - 1
    }
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

  veto_n = 0
    run_slice(i0)

    eq = total_ret(i0)
    sh = sharpe_slice(i0)
    eq_bh = px[n] / px[i0] - 1
    c_next = corr_xy(i0, 0)
    c_gap = corr_xy(i0, 1)
    c_flow_gap = corr_flow_gap(i0)
    veto_pct = (mode == "veto") ? veto_n / days : 0

    printf("%s,%s,%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
        code, name, mode, days, eq, eq_bh, sh,
        c_next, c_gap, c_flow_gap, veto_pct)
}
