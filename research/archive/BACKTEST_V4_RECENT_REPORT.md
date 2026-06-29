# 震巽 v4 近段回测对照

## 为什么要做近段？

全样本 corr≈0 且 v4 收益变差，部分因 2025–26 行情与新闻/逐笔层未覆盖。
本报告切两段：

1. **2025+**：宏观近段（价量票全参与）
2. **tickcov**：tick_hist 实际覆盖窗（七票 + 逐笔 100%）
3. **overlap**：仅有新闻或逐笔数据的交易日

## 全样本 v4（对照）

```json
{
  "version": "v4",
  "generated_at": "2026-06-29T16:20:12Z",
  "engine": "scripts/backtest_v4.awk (7-vote + news eta + tick hist)",
  "n_stocks": 8,
  "v4_mean_return": -0.386795,
  "momentum_mean_return": -0.433055,
  "meanrev_mean_return": -0.246226,
  "buyhold_mean_return": -0.282635,
  "v4_mean_sharpe": 0.180574,
  "v4_mean_hold_pct": 0.022206,
  "v4_mean_wuwen_vote_pct": 23.141958,
  "corr_signal_nextday_mean": -0.000060,
  "tick_coverage_mean_pct": 0.056628,
  "news_coverage_mean_pct": 0.002769,
  "v4_beats_momentum_count": 5,
  "v4_beats_meanrev_count": 3,
  "v4_beats_buyhold_count": 4
}
```

## 近段 2025+

```json
{
  "version": "v4_recent",
  "generated_at": "2026-06-29T16:20:57Z",
  "date_from": "2025-01-01",
  "date_to": "2026-12-31",
  "overlap_only": 0,
  "n_stocks": 8,
  "v4_mean_return": -0.079501,
  "momentum_mean_return": -0.017987,
  "meanrev_mean_return": -0.036597,
  "buyhold_mean_return": -0.074463,
  "v4_mean_sharpe": -0.541209,
  "corr_signal_nextday_mean": -0.024444,
  "tick_coverage_mean_pct": 0.321229,
  "news_coverage_mean_pct": 0.000000,
  "v4_beats_momentum_count": 2,
  "v4_beats_buyhold_count": 4
}
```

## 逐笔 archive 覆盖窗（tickcov）

```json
{
  "version": "v4_recent",
  "generated_at": "2026-06-29T16:20:57Z",
  "date_from": "2026-01-05",
  "date_to": "2026-06-29",
  "overlap_only": 0,
  "n_stocks": 8,
  "v4_mean_return": -0.083962,
  "momentum_mean_return": -0.122567,
  "meanrev_mean_return": -0.047254,
  "buyhold_mean_return": -0.156974,
  "v4_mean_sharpe": -1.483555,
  "corr_signal_nextday_mean": -0.025744,
  "tick_coverage_mean_pct": 1.000000,
  "news_coverage_mean_pct": 0.000000,
  "v4_beats_momentum_count": 6,
  "v4_beats_buyhold_count": 6
}
```

## 逐笔窗 2026-06-16~29（旧 9 日对照）

```json
{
  "version": "v4_recent",
  "generated_at": "2026-06-29T16:20:58Z",
  "date_from": "2026-06-16",
  "date_to": "2026-06-29",
  "overlap_only": 0,
  "n_stocks": 8,
  "v4_mean_return": 0.004915,
  "momentum_mean_return": -0.018036,
  "meanrev_mean_return": -0.001472,
  "buyhold_mean_return": -0.038402,
  "v4_mean_sharpe": 0.544964,
  "corr_signal_nextday_mean": 0.119036,
  "tick_coverage_mean_pct": 1.000000,
  "news_coverage_mean_pct": 0.000000,
  "v4_beats_momentum_count": 6,
  "v4_beats_buyhold_count": 8
}
```

## 重叠窗（新闻∪逐笔有数据日）

```json
{
  "version": "v4_recent",
  "generated_at": "2026-06-29T16:20:58Z",
  "date_from": "2025-01-01",
  "date_to": "2026-12-31",
  "overlap_only": 1,
  "n_stocks": 8,
  "v4_mean_return": -0.083962,
  "momentum_mean_return": -0.122567,
  "meanrev_mean_return": -0.047254,
  "buyhold_mean_return": -0.156974,
  "v4_mean_sharpe": -1.483555,
  "corr_signal_nextday_mean": -0.025744,
  "tick_coverage_mean_pct": 1.000000,
  "news_coverage_mean_pct": 0.000000,
  "v4_beats_momentum_count": 6,
  "v4_beats_buyhold_count": 6
}
```
