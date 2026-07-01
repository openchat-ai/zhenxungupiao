#!/usr/bin/awk -f
# 震巽股票 — 实战级诚实评估引擎（纯 awk，零依赖）
# Rigorous out-of-sample evaluation of the buy/hold/sell signals with
# realistic A-share transaction costs. Reuses the SAME seven-vote (decide_v4),
# momentum (SMA5/20) and mean-reversion (RSI14) rules as scripts/backtest_v4.awk.
#
# Emits LONG-format rows: one per (code, segment, mode) so the shell aggregator
# can pool the information-coefficient (IC) sufficient statistics across stocks.
#
# Params (-v):
#   code=        stock code (for labeling)
#   split_date=  first date of the out-of-sample window (default 2024-01-01)
#   c_buy=       one-way BUY cost fraction  (commission + slippage)
#   c_sell=      one-way SELL cost fraction (commission + slippage + stamp duty)
#
# Segments: "is" (date <  split_date) and "oos" (date >= split_date).
# Modes:    v4 (seven-vote), mom (momentum), mr (mean-reversion), bh (buy&hold).

BEGIN {
    FS = ","
    if (split_date == "") split_date = "2024-01-01"
    # A-share defaults (2023+): 佣金~万2.5 双边 + 滑点~万5 双边 + 印花税万5 卖出单边
    if (c_buy  == "") c_buy  = 0.00075   # 0.025% commission + 0.05% slippage
    if (c_sell == "") c_sell = 0.00125   # + 0.05% stamp duty on sells
    rf = 0.02
    # seven-vote thresholds (identical to backtest_v4.awk)
    eta_shock = 3.0; eta_mid = 2.0; calm_pct = 1.0
    wuwen_alert = 2; sigma_neutral = 7
}

function abs(x) { return x < 0 ? -x : x }
function yoyo_trit(x) { if (x > 0) return 2; if (x < 0) return 0; return 1 }

function sma(i, m,    s, j) {
    if (i < m) return -1
    s = 0
    for (j = 0; j < m; j++) s += px[i - j]
    return s / m
}
function vote_ma(i,    a, b)   { a = sma(i,3); b = sma(i,5); if (a<0||b<0) return 1; return yoyo_trit(a-b) }
function vote_trend(i,    b)   { b = sma(i,5); if (b<0) return 1; return yoyo_trit(px[i]-b) }
function vote_rsi_simple(i,  d){ if (i<3) return 1; d = px[i]-px[i-3]; return yoyo_trit(d) }
function vote_macd_simple(i, a,b){ a=sma(i,2); b=sma(i,4); if (a<0||b<0) return 1; return yoyo_trit(a-b) }
function vote_perturb_price(i, p){ if (i<1) return 1; p=abs(pct[i])*100; if (p>=eta_shock) return 0; if (p>=eta_mid) return 1; return 2 }
function vote_psych(i,    dc, uc, hi, lo, j) {
    if (i < 5) return 1
    dc = 0
    if (px[i-1] < px[i-2]) dc++
    if (px[i]   < px[i-1]) dc++
    if (dc >= 2) return 0
    uc = 0
    if (px[i-1] > px[i-2]) uc++
    if (px[i]   > px[i-1]) uc++
    hi = px[i]; lo = px[i]
    for (j = 1; j <= 4; j++) { if (px[i-j] > hi) hi = px[i-j]; if (px[i-j] < lo) lo = px[i-j] }
    if (px[i] <= lo && px[i] < px[i-1]) return 0
    if (uc >= 2 && px[i] >= hi) return 2
    return 1
}
function decide_v4(i,    v1,v2,v3,v4,v5,v6,v7,s) {
    v1=vote_ma(i); v2=vote_trend(i); v3=vote_rsi_simple(i)
    v4=vote_macd_simple(i); v5=vote_perturb_price(i); v6=vote_psych(i)
    v7=1                                  # 第7票逐笔：全史无数据 → 持
    s = v1+v2+v3+v4+v5+v6+v7
    if (s < sigma_neutral) return -1
    if (s == sigma_neutral) return 0
    return 1
}
function rsi14(i,    gain, loss, j, d) {
    if (i < 14) return 50
    gain = 0; loss = 0
    for (j = 0; j < 14; j++) { d = px[i-j]-px[i-j-1]; if (d>0) gain+=d; else loss-=d }
    if (loss == 0) return 100
    return 100 - 100/(1 + gain/loss)
}
function signal_momentum(i,  d){ d = sma(i,5)-sma(i,20); if (d<0) return -1; if (d>0) return 1; return 0 }
function signal_meanrev(i,   r){ r = rsi14(i); if (r<35) return 1; if (r>65) return -1; return 0 }

function seg_of(i) { return (dt[i] < split_date) ? "is" : "oos" }

# Simulate one long/flat strategy with costs; accumulate per-segment stats.
# sig(i): +1 enter/stay long, -1 exit/stay flat, 0 keep previous position.
function run(mode,    i, sig, pos, prevpos, gross, cost, net, seg) {
    delete N; delete SUMR; delete SUMR2; delete PROD; delete TRN
    pos = 0; prevpos = 0
    for (i = 20; i <= n; i++) {
        # return realized on day i from position held INTO day i (decided at i-1)
        if (i > 20) {
            seg = seg_of(i)
            gross = (px[i]/px[i-1] - 1) * prevpos
            cost = 0
            # position change took effect at close of i-1 → charge here
            if (pos > prevpos) cost = (pos - prevpos) * c_buy
            else if (pos < prevpos) cost = (prevpos - pos) * c_sell
            net = gross - cost
            N[seg]++; SUMR[seg] += net; SUMR2[seg] += net*net; TRN[seg] += (pos!=prevpos)?1:0
            NET[mode, seg, N[seg]] = net           # keep for equity/mdd
            NETSEG[mode, seg, N[seg]] = seg
        }
        prevpos = pos
        # decide position to hold INTO day i+1
        if (mode == "bh") sig = 1
        else if (mode == "v4") sig = sv4[i]
        else if (mode == "mom") sig = signal_momentum(i)
        else sig = signal_meanrev(i)
        if (sig == 1) pos = 1
        else if (sig == -1) pos = 0
        # sig==0 → keep pos
    }
    # IC sufficient stats: signal(i) vs next-day gross return pct[i+1]
    for (i = 20; i < n; i++) {
        seg = seg_of(i+1)
        if (mode == "bh") continue
        if (mode == "v4") x = sv4[i]
        else if (mode == "mom") x = signal_momentum(i)
        else x = signal_meanrev(i)
        y = pct[i+1]
        IC_N[mode,seg]++; IC_SX[mode,seg]+=x; IC_SY[mode,seg]+=y
        IC_SXX[mode,seg]+=x*x; IC_SYY[mode,seg]+=y*y; IC_SXY[mode,seg]+=x*y
    }
    for (seg in N) emit(mode, seg)
}

function seg_sharpe(mode, seg,    i, m, s, v, c) {
    c = N[seg]; if (c < 2) return 0
    m = SUMR[seg]/c
    s = SUMR2[seg] - c*m*m
    if (s <= 0) return 0
    s = sqrt(s/(c-1))
    if (s == 0) return 0
    return (m - rf/252)/s * sqrt(252)
}
function seg_totret(mode, seg,    k, eq) {
    eq = 1
    for (k = 1; k <= N[seg]; k++) eq *= (1 + NET[mode, seg, k])
    return eq - 1
}
function seg_mdd(mode, seg,    k, eq, peak, dd) {
    eq = 1; peak = 1; dd = 0
    for (k = 1; k <= N[seg]; k++) {
        eq *= (1 + NET[mode, seg, k])
        if (eq > peak) peak = eq
        if ((eq-peak)/peak < dd) dd = (eq-peak)/peak
    }
    return dd
}
function emit(mode, seg,    tr, sh, md) {
    tr = seg_totret(mode, seg); sh = seg_sharpe(mode, seg); md = seg_mdd(mode, seg)
    printf("%s,%s,%s,%d,%.6f,%.6f,%.6f,%d,%d,%.6f,%.6f,%.6f,%.6f,%.6f\n",
        code, seg, mode, N[seg], tr, sh, md, TRN[seg],
        IC_N[mode,seg]+0, IC_SX[mode,seg]+0, IC_SY[mode,seg]+0,
        IC_SXX[mode,seg]+0, IC_SYY[mode,seg]+0, IC_SXY[mode,seg]+0)
}

NR == 1 { next }
{ dt[++n] = $1; px[n] = $4 + 0 }
END {
    if (n < 300) { print "SKIP " FILENAME " too short" > "/dev/stderr"; exit 1 }
    pct[1] = 0
    for (i = 2; i <= n; i++) pct[i] = px[i]/px[i-1] - 1
    for (i = 20; i <= n; i++) sv4[i] = decide_v4(i)
    run("v4"); run("mom"); run("mr"); run("bh")
}
