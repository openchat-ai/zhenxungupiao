#!/usr/bin/env python3
"""
震巽股票 — 平衡三进制策略实证回测
数据源: AkShare (开源) A 股前复权日线
逻辑与 ternary_signal.ty / 原 indicators 设计一致:
  四指标各产出 trit ∈ {-1,0,+1}，求和取符号得唯一信号
"""
from __future__ import annotations

import json
import math
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path

import akshare as ak
import numpy as np
import pandas as pd
from scipy import stats

OUT = Path(__file__).resolve().parent / "output"
Trit = int  # -1, 0, 1

UNIVERSE = [
    ("600519", "贵州茅台"),
    ("000001", "平安银行"),
    ("601318", "中国平安"),
    ("600036", "招商银行"),
    ("000858", "五粮液"),
    ("601012", "隆基绿能"),
    ("600900", "长江电力"),
    ("000333", "美的集团"),
]


def load_hist(code: str) -> pd.DataFrame | None:
    raw = ak.stock_zh_a_hist(
        symbol=code, period="daily", start_date=START, end_date=END, adjust="qfq"
    )
    if raw is None or len(raw) < 252:
        return None
    df = raw.rename(columns={"日期": "date"}).sort_values("date").reset_index(drop=True)
    if (df["收盘"] <= 0).any():
        return None
    if df["收盘"].pct_change().abs().max() > 0.5:
        return None
    return df

START, END = "20180101", "20241231"
HOLD_DAYS = [1, 5, 10, 20]  # 信号后 forward return 窗口


def trit(x: float) -> Trit:
    if x > 0:
        return 1
    if x < 0:
        return -1
    return 0


def sma(s: pd.Series, n: int) -> pd.Series:
    return s.rolling(n, min_periods=n).mean()


def rsi(close: pd.Series, period: int = 14) -> pd.Series:
    delta = close.diff()
    gain = delta.clip(lower=0)
    loss = -delta.clip(upper=0)
    avg_gain = gain.ewm(alpha=1 / period, min_periods=period, adjust=False).mean()
    avg_loss = loss.ewm(alpha=1 / period, min_periods=period, adjust=False).mean()
    rs = avg_gain / avg_loss.replace(0, np.nan)
    return 100 - (100 / (1 + rs))


def macd_hist(close: pd.Series, fast: int = 12, slow: int = 26, sig: int = 9) -> pd.Series:
    ema_f = close.ewm(span=fast, adjust=False).mean()
    ema_s = close.ewm(span=slow, adjust=False).mean()
    line = ema_f - ema_s
    signal = line.ewm(span=sig, adjust=False).mean()
    return line - signal


def compute_votes(df: pd.DataFrame) -> pd.DataFrame:
    c = df["收盘"]
    ma5, ma20, ma10 = sma(c, 5), sma(c, 20), sma(c, 10)
    r = rsi(c, 14)
    mh = macd_hist(c)

    v_ma = (ma5 - ma20).apply(trit)
    v_trend = (c - ma10).apply(trit)
    v_rsi = pd.Series(
        np.where(r < 35, 1, np.where(r > 65, -1, 0)), index=df.index, dtype=int
    )
    v_macd = mh.apply(lambda x: trit(x) if not np.isnan(x) else 0)

    votes = pd.DataFrame(
        {"ma": v_ma, "trend": v_trend, "rsi": v_rsi, "macd": v_macd},
        index=df.index,
    )
    s = votes.sum(axis=1)
    votes["sum"] = s
    votes["signal"] = s.apply(trit)  # balanced ternary majority via sign
    return votes


def binary_ma_signal(df: pd.DataFrame) -> pd.Series:
    c = df["收盘"]
    diff = sma(c, 5) - sma(c, 20)
    return diff.apply(lambda x: 1 if x > 0 else -1 if x < 0 else 0)


def simulate(
    df: pd.DataFrame,
    signal: pd.Series,
    mode: str = "ternary",
) -> pd.Series:
    """
    ternary: +1 满仓, -1 空仓, 0 维持
    binary:  +1 满仓, -1 空仓, 无持有态时 0 视为空仓
  aggressive_binary: 仅 ±1，0 按上一日方向
    """
    ret = df["收盘"].pct_change().fillna(0)
    pos = pd.Series(0.0, index=df.index)
    prev = 0.0
    for i, sig in enumerate(signal):
        if mode == "ternary":
            if sig == 1:
                prev = 1.0
            elif sig == -1:
                prev = 0.0
            # 0: hold prev
        elif mode == "binary":
            prev = 1.0 if sig == 1 else 0.0
        else:
            prev = 1.0 if sig >= 0 else 0.0
        pos.iloc[i] = prev
    strat_ret = pos.shift(1).fillna(0) * ret
    return (1 + strat_ret).cumprod()


def max_drawdown(equity: pd.Series) -> float:
    peak = equity.cummax()
    dd = (equity - peak) / peak
    return float(dd.min())


def sharpe(daily_ret: pd.Series, rf: float = 0.02) -> float:
    excess = daily_ret - rf / 252
    if excess.std() == 0 or len(excess) < 2:
        return 0.0
    return float(excess.mean() / excess.std() * math.sqrt(252))


@dataclass
class StockResult:
    code: str
    name: str
    n_days: int
    pct_buy: float
    pct_hold: float
    pct_sell: float
    ternary_total_return: float
    binary_total_return: float
    buyhold_return: float
    ternary_sharpe: float
    binary_sharpe: float
    buyhold_sharpe: float
    ternary_mdd: float
    binary_mdd: float
    buyhold_mdd: float
    ternary_turnover_pa: float
    binary_turnover_pa: float


def turnover_pa(pos: pd.Series) -> float:
    chg = pos.diff().abs().fillna(0)
    return float(chg.sum() / len(pos) * 252)


def forward_return_stats(df: pd.DataFrame, signal: pd.Series) -> dict:
    close = df["收盘"]
    out = {}
    for h in HOLD_DAYS:
        fwd = close.shift(-h) / close - 1
        for label, val in [("buy", 1), ("hold", 0), ("sell", -1)]:
            mask = signal == val
            r = fwd[mask].dropna()
            if len(r) >= 30:
                out[f"fwd{h}d_{label}_mean"] = float(r.mean())
                out[f"fwd{h}d_{label}_n"] = int(len(r))
                t, p = stats.ttest_1samp(r, 0.0, nan_policy="omit")
                out[f"fwd{h}d_{label}_tstat"] = float(t)
                out[f"fwd{h}d_{label}_pval"] = float(p)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    results: list[StockResult] = []
    all_fwd: list[dict] = []
    pooled_rows = []

    for code, name in UNIVERSE:
        try:
            df = load_hist(code)
        except Exception as e:
            print(f"skip {code}: {e}")
            continue
        if df is None:
            print(f"skip {code}: invalid data")
            continue
        df.to_csv(OUT / f"hist_{code}.csv", index=False)
        votes = compute_votes(df)
        sig = votes["signal"]
        n = len(sig.dropna())
        dist = sig.value_counts(normalize=True)

        eq_t = simulate(df, sig, "ternary")
        eq_b = simulate(df, binary_ma_signal(df), "binary")
        eq_bh = (1 + df["收盘"].pct_change().fillna(0)).cumprod()

        ret_t = eq_t.pct_change().fillna(0)
        ret_b = eq_b.pct_change().fillna(0)
        ret_bh = eq_bh.pct_change().fillna(0)

        pos_t = pd.Series(np.nan, index=df.index)
        prev = 0.0
        for i, s in enumerate(sig):
            if s == 1:
                prev = 1.0
            elif s == -1:
                prev = 0.0
            pos_t.iloc[i] = prev

        sr = StockResult(
            code=code,
            name=name,
            n_days=n,
            pct_buy=float(dist.get(1, 0)),
            pct_hold=float(dist.get(0, 0)),
            pct_sell=float(dist.get(-1, 0)),
            ternary_total_return=float(eq_t.iloc[-1] - 1),
            binary_total_return=float(eq_b.iloc[-1] - 1),
            buyhold_return=float(eq_bh.iloc[-1] - 1),
            ternary_sharpe=sharpe(ret_t),
            binary_sharpe=sharpe(ret_b),
            buyhold_sharpe=sharpe(ret_bh),
            ternary_mdd=max_drawdown(eq_t),
            binary_mdd=max_drawdown(eq_b),
            buyhold_mdd=max_drawdown(eq_bh),
            ternary_turnover_pa=turnover_pa(pos_t),
            binary_turnover_pa=turnover_pa(
                binary_ma_signal(df).apply(lambda x: 1.0 if x == 1 else 0.0)
            ),
        )
        results.append(sr)

        fwd = forward_return_stats(df, sig)
        fwd["code"] = code
        fwd["name"] = name
        all_fwd.append(fwd)

        for _, row in votes.dropna().iterrows():
            pooled_rows.append(
                {
                    "sum": row["sum"],
                    "signal": row["signal"],
                    "ma": row["ma"],
                    "trend": row["trend"],
                    "rsi": row["rsi"],
                    "macd": row["macd"],
                }
            )

    res_df = pd.DataFrame([asdict(r) for r in results])
    res_df.to_csv(OUT / "backtest_by_stock.csv", index=False)

    # 汇总统计
    summary = {
        "generated_at": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
        "data_source": "AkShare stock_zh_a_hist (qfq)",
        "period": f"{START}–{END}",
        "n_stocks": len(results),
        "ternary_mean_return": float(res_df["ternary_total_return"].mean()),
        "binary_mean_return": float(res_df["binary_total_return"].mean()),
        "buyhold_mean_return": float(res_df["buyhold_return"].mean()),
        "ternary_mean_sharpe": float(res_df["ternary_sharpe"].mean()),
        "binary_mean_sharpe": float(res_df["binary_sharpe"].mean()),
        "ternary_mean_mdd": float(res_df["ternary_mdd"].mean()),
        "binary_mean_mdd": float(res_df["binary_mdd"].mean()),
        "ternary_mean_hold_pct": float(res_df["pct_hold"].mean()),
        "ternary_mean_turnover": float(res_df["ternary_turnover_pa"].mean()),
        "binary_mean_turnover": float(res_df["binary_turnover_pa"].mean()),
        "ternary_beats_binary_count": int(
            (res_df["ternary_total_return"] > res_df["binary_total_return"]).sum()
        ),
        "ternary_beats_buyhold_count": int(
            (res_df["ternary_total_return"] > res_df["buyhold_return"]).sum()
        ),
    }

    # 池化 forward return：按 signal 分组
    pool = pd.DataFrame(pooled_rows)
    for h in HOLD_DAYS:
        # 需要重新算池化 — 简化：用 all_fwd 平均
        for label in ("buy", "hold", "sell"):
            key = f"fwd{h}d_{label}_mean"
            vals = [f[key] for f in all_fwd if key in f]
            if vals:
                summary[f"avg_{key}"] = float(np.mean(vals))
            pk = f"fwd{h}d_{label}_pval"
            pvals = [f[pk] for f in all_fwd if pk in f]
            if pvals:
                summary[f"avg_{pk}"] = float(np.mean(pvals))

    # sum 与次日收益相关（复用已下载数据）
    all_sig_ret = []
    for code, name in UNIVERSE:
        csv_path = OUT / f"hist_{code}.csv"
        if csv_path.exists():
            df = pd.read_csv(csv_path)
        else:
            continue
        votes = compute_votes(df)
        nxt = df["收盘"].pct_change().shift(-1)
        for i in votes.dropna().index:
            if i + 1 < len(nxt):
                all_sig_ret.append(
                    {
                        "sum": votes.loc[i, "sum"],
                        "signal": votes.loc[i, "signal"],
                        "nxt": nxt.iloc[i],
                    }
                )
    ar = pd.DataFrame(all_sig_ret)
    if len(ar) > 100:
        summary["corr_sum_vs_nextday_ret"] = float(ar["sum"].corr(ar["nxt"]))
        summary["corr_signal_vs_nextday_ret"] = float(ar["signal"].corr(ar["nxt"]))
        for s in (-4, -3, -2, -1, 0, 1, 2, 3, 4):
            sub = ar[ar["sum"] == s]["nxt"].dropna()
            if len(sub) >= 50:
                summary[f"sum{s}_nextday_mean"] = float(sub.mean())
                summary[f"sum{s}_n"] = int(len(sub))

    # 持有态稀缺性 & 波动率分层（验证「中」是否对应低波动）
    vol_rows = []
    for code, _ in UNIVERSE:
        p = OUT / f"hist_{code}.csv"
        if not p.exists():
            continue
        df = pd.read_csv(p)
        votes = compute_votes(df)
        rv = df["收盘"].pct_change().rolling(20).std()
        for sig, label in [(1, "buy"), (0, "hold"), (-1, "sell")]:
            m = votes["signal"] == sig
            v = rv[m].dropna()
            if len(v) >= 20:
                vol_rows.append({"signal": label, "vol20": float(v.mean())})
    if vol_rows:
        vdf = pd.DataFrame(vol_rows)
        for label in ("buy", "hold", "sell"):
            sub = vdf[vdf["signal"] == label]["vol20"]
            if len(sub):
                summary[f"vol20_{label}_mean"] = float(sub.mean())
        if "vol20_hold_mean" in summary and "vol20_buy_mean" in summary:
            summary["vol20_hold_vs_buy_ratio"] = float(
                summary["vol20_hold_mean"] / summary["vol20_buy_mean"]
            )

    with open(OUT / "backtest_summary.json", "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

  # markdown report
    lines = [
        "# 平衡三进制策略实证回测报告",
        "",
        f"- 生成时间: {summary['generated_at']}",
        f"- 数据: {summary['data_source']}",
        f"- 区间: {summary['period']}",
        f"- 样本: {summary['n_stocks']} 只 A 股蓝筹股",
        "",
        "## 组合绩效（均值）",
        "",
        "| 策略 | 累计收益均值 | Sharpe 均值 | 最大回撤均值 | 年化换手均值 |",
        "|------|-------------|------------|-------------|-------------|",
        f"| **三进制投票** | {summary['ternary_mean_return']:.2%} | {summary['ternary_mean_sharpe']:.2f} | {summary['ternary_mean_mdd']:.2%} | {summary['ternary_mean_turnover']:.1f} |",
        f"| 二元均线 | {summary['binary_mean_return']:.2%} | {summary['binary_mean_sharpe']:.2f} | {summary['binary_mean_mdd']:.2%} | {summary['binary_mean_turnover']:.1f} |",
        f"| 买入持有 | {summary['buyhold_mean_return']:.2%} | — | — | 0 |",
        "",
        f"- 三进制 **持有态占比** 均值: {summary['ternary_mean_hold_pct']:.1%}",
        f"- 三进制收益 > 二元: {summary['ternary_beats_binary_count']}/{summary['n_stocks']} 只",
        f"- 三进制收益 > 买入持有: {summary['ternary_beats_buyhold_count']}/{summary['n_stocks']} 只",
        "",
        "## 信号后 forward return（池化均值）",
        "",
        "| 窗口 | 买入(+1) | 持有(0) | 卖出(-1) |",
        "|------|---------|--------|---------|",
    ]
    for h in HOLD_DAYS:
        b = summary.get(f"avg_fwd{h}d_buy_mean", float("nan"))
        ho = summary.get(f"avg_fwd{h}d_hold_mean", float("nan"))
        s = summary.get(f"avg_fwd{h}d_sell_mean", float("nan"))
        lines.append(f"| {h} 日 | {b:.3%} | {ho:.3%} | {s:.3%} |")

    lines += [
        "",
        "## 投票和与次日收益",
        "",
        f"- corr(sum, 次日收益) = {summary.get('corr_sum_vs_nextday_ret', 0):.4f}",
        f"- corr(signal, 次日收益) = {summary.get('corr_signal_vs_nextday_ret', 0):.4f}",
        "",
        "## 分标的明细",
        "",
        "见 `backtest_by_stock.csv`",
    ]
    (OUT / "BACKTEST_REPORT.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
