#!/usr/bin/awk -f
# 导出 v5 三进制档 flow_v5_CODE.tri（仅 2026 tick 窗口日）
# 格式 v2: TRI\x02 + u16 n + n×(v4,tail,veto,ret,veto_flag)

BEGIN {
    FS = ","
    eta_shock = 3.0
    eta_mid   = 2.0
    sigma6 = 6
    sigma7 = 7
    tick_buy = 55
    tick_sell = 45
    if (date_from == "") date_from = "2026-01-01"
    if (date_to == "") date_to = "2099-12-31"
    if (tickfile == "") tickfile = "research/archive/tick_hist_daily.csv"
    if (tailfile == "") tailfile = "research/archive/tick_tail_daily.csv"
    while ((getline line < tickfile) > 0) {
        split(line, fld, ",")
        gsub(/\r/, "", fld[2])
        if (fld[1] == "date" || fld[2] != code) continue
        day_buy[fld[1]] = fld[3] + 0
    }
    close(tickfile)
    while ((getline line < tailfile) > 0) {
        split(line, fld, ",")
        gsub(/\r/, "", fld[2])
        if (fld[1] == "date" || fld[2] != code) continue
        tail_buy[fld[1]] = fld[3] + 0
    }
    close(tailfile)
}

function abs(x) { return x < 0 ? -x : x }

function yoyo_trit(x) {
    if (x > 0) return 2
    if (x < 0) return 0
    return 1
}

function sig_to_trit(s) {
    if (s == 1) return 2
    if (s == -1) return 0
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

function vote_ma(i,    ma3, ma5) {
    ma3 = sma(i, 3); ma5 = sma(i, 5)
    if (ma3 < 0 || ma5 < 0) return 1
    return yoyo_trit(ma3 - ma5)
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

function vote_macd_simple(i,    ma2, ma4) {
    ma2 = sma(i, 2); ma4 = sma(i, 4)
    if (ma2 < 0 || ma4 < 0) return 1
    return yoyo_trit(ma2 - ma4)
}

function vote_perturb(i) {
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
    if (sig == 1 && p <= tick_sell) return 0
    if (sig == -1 && p >= tick_buy) return 0
    return sig
}

function veto_flag(i,    sig, d, p) {
    sig = decide_six(i)
    d = dt[i]
    if (!(d in day_buy)) return 0
    p = day_buy[d]
    if (sig == 1 && p <= tick_sell) return 1
    if (sig == -1 && p >= tick_buy) return 1
    return 0
}

function ret_trit(i) {
    if (i >= n) return 1
    if (px[i+1] > px[i]) return 2
    if (px[i+1] < px[i]) return 0
    return 1
}

function write_u16(x) {
    printf "%c%c", x % 256, int(x / 256) % 256
}

NR == 1 { next }
{
    dt[++n] = $1
    px[n] = $4 + 0
}

END {
    if (n < 25) exit 1
    pct[1] = 0
    for (i = 2; i <= n; i++) pct[i] = px[i] / px[i-1] - 1

    m = 0
    for (i = 20; i <= n; i++) {
        if (!in_window(dt[i])) continue
        m++
        v4[m] = sig_to_trit(decide_v4(i))
        tail[m] = sig_to_trit(decide_tail(i))
        veto[m] = sig_to_trit(decide_veto(i))
        ret[m] = ret_trit(i)
        vflag[m] = veto_flag(i)
    }
    if (m < 1) exit 1

    printf "TRI%c", 2
    write_u16(m)
    for (i = 1; i <= m; i++) printf "%c", v4[i]
    for (i = 1; i <= m; i++) printf "%c", tail[i]
    for (i = 1; i <= m; i++) printf "%c", veto[i]
    for (i = 1; i <= m; i++) printf "%c", ret[i]
    for (i = 1; i <= m; i++) printf "%c", vflag[i]
}
